///
///  GameCenterHelper.swift
///  MancalaPrototype2
///
///  File created by Alexander Scott Beaty on 7/30/19.
/// ============LICENSE_START=======================================================
/// Copyright (c) 2018 Razeware LLC
/// Modification Copyright © 2019 Alexander Scott Beaty. All rights reserved.
/// Modification License:
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================
/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
///

import GameKit
import UserNotifications
/**
 Responsible for immediately authenticating the user to Game Center. Extends GKLocalPlayerListener to receive turn events remotely from Game Center. Presents the user interface for Game Center to the user and handles turn events triggered by the game.
 
 + Additional responsibilities:
     - After authenticating the user, check and updates MatchHistory to see if new game modes have been unlocked.
     - Presents ```GKTurnBasedMatchmakerViewController``` to allow the user to pick from their list of current games or send a match request
     - Helper functions to facilitate ending each turn and ending each match and passing the match to the next player
    - Checks and updates match outcomes in case a match ended unexpectedly
 */
final class GameCenterHelper: NSObject, GKGameCenterControllerDelegate {
    
    typealias CompletionBlock = (Error?) -> Void
    var savedGameStore: SavedGameStore!
    static let helper = GameCenterHelper()
    var viewController: UIViewController?
    var currentMatchMakerVC: GKTurnBasedMatchmakerViewController?
    var currentMatch: GKTurnBasedMatch? {
        willSet {
            if let matchID = newValue?.matchID {
                currentMatchID = matchID
            }
        }
    }
    
    var matchHistory: MatchHistory!
    var currentMatchID = "FIRST_LAUNCHED"
    
    var canTakeTurnForCurrentMatch: Bool {
        guard let match = currentMatch else {
            return true
        }
        
        return match.isLocalPlayersTurn
    }
    
    enum GameCenterHelperError: Error {
        case matchNotFound
    }
    
    static var isAuthenticated: Bool {
        return GKLocalPlayer.local.isAuthenticated
    }
    
    /**
     Authenticate the user to the GameCenter server, and present the GameCenterAuthenticationViewController if the user credentials are not saved from last session.
     After authentication completes succesfully, check the outcomes of all the users online Game Center matches, either using the matchHistory Dictionary saved to disk or by getting the list of matches directly from the server.
     */
    override init() {
        super.init()
        
        GKLocalPlayer.local.authenticateHandler = { gcAuthVC, error in
            NotificationCenter.default.post(name: .authenticationChanged, object: GKLocalPlayer.local.isAuthenticated)
            
            if GKLocalPlayer.local.isAuthenticated {
                GKLocalPlayer.local.register(self)
                
                self.matchHistory.loadAllGamesPlayedDict()
                if !self.matchHistory.updateHistoricalMatchOutcomes() {
                    self.matchHistory.updateCurrentMatchOutcomes()
                }
                               
            } else if let vc = gcAuthVC {
                self.viewController?.present(vc, animated: true)
            } else {
                if let theError = error?.localizedDescription {
                    print("Error authenticating to Game Center: " +
                theError)
                }
            }
        }
    }
    
    /// Presents the GameCenter MatchMakerViewController, which lets the user browse the list of Active or Completed games, and allows the user to create a new match. A GKMatchRequest is created in this method in case the user decides to create a new match.
    func presentMatchMaker() {
        
        guard GKLocalPlayer.local.isAuthenticated else {
            return
        }
        
        let request = GKMatchRequest()
        
        request.minPlayers = 2
        request.maxPlayers = 2
        
        request.inviteMessage = "Would you like to play Mancala World?"
        
        let vc = GKTurnBasedMatchmakerViewController(matchRequest: request)
        vc.turnBasedMatchmakerDelegate = self
        currentMatchMakerVC = vc
        viewController?.present(vc, animated: true)
    }

    //MARK: - Turn handling

    /// Saves the game data to the GKTurnBasedMatch object and sends it to the next player by calling GKTurnBasedMatch.endTurn()
    /// - Parameters:
    ///   - model: the model of the active online match being played
    ///   - completion: mainly used to throw errors
    func endTurn(_ model: GameModel, completion: @escaping CompletionBlock) {
        
        guard let match = currentMatch else {
            completion(GameCenterHelperError.matchNotFound)
            return
        }

        match.message = {
            if model.lastPlayerCaptureText != nil {
                return model.lastPlayerCaptureText
            } else if model.lastPlayerBonusText != nil {
                return model.lastPlayerBonusText
            }
        
            return model.messageToDisplay
        }()
        
        var overwrite = true
        let checkPits = model.pits.circIter
        if let player2Base = *checkPits {
            if model.gameData.pitsList.count > 0 {
                let pitListPlayer2Base = model.gameData.pitsList[0]
                overwrite = !(player2Base === pitListPlayer2Base)
            }
        }
        match.endTurn(
            withNextParticipants: match.others,
            turnTimeout: GKExchangeTimeoutDefault,
            match: model.saveDataToSend(overwritePitsList: overwrite),
            completionHandler: completion)
    }
    
    
    /// In order to prompt the opponent with a Notification, use this method instead of calling endMatch() as soon as a player ends the game, since Notifications are only sent when calling GKTurnBasedMatch.endTurn()
    /// - Parameters:
    ///   - model: the model of the active online match being played
    ///   - completion: mainly used to throw errors
    func sendFinalTurn(_ model: GameModel, completion: @escaping CompletionBlock) {
        guard let match = currentMatch else {
            completion(GameCenterHelperError.matchNotFound)
            return
        }
        assignOutcomes(to: match, model)
        model.onlineGameOver = true
        if let localParticipant = match.localParticipant.first, let localPlayer = localParticipant.player {
           model.gameData.lastPlayerID = localPlayer.playerID
        }
        match.endTurn(
            withNextParticipants: match.others,
            turnTimeout: GKExchangeTimeoutDefault,
            match: model.saveDataToSend(),
            completionHandler: completion)
    }
    
    /// Officially ends the match, and is only called by the player who **does not** end the match, but rather who is notified by the other player who actually finished the match.
    /// - Parameters:
    ///   - model: the model of the active online match being played
    ///   - completion: mainly used to throw errors
    func endMatch(_ model: GameModel, completion: @escaping CompletionBlock) {
        guard let match = currentMatch else {
            completion(GameCenterHelperError.matchNotFound)
            return
        }
        if let localPlayer = match.localParticipant.first {
            //to prevent this from being called by the player who ended the game
            if localPlayer.player?.playerID == model.gameData.lastPlayerID {
                return
            }
        }
        //we need to make sure this is only called once to end the game officially from GameCenter's perspective
        if match.status == .ended {
            return
        }
        //before endMatchInTurn is called, save lastMovesList separately
        //otherwise lastMovesList overwritten with zero values and can no longer watch replay
        let tempMovesList = model.gameData.lastMovesList
        model.saveGameData()
        model.gameData.lastMovesList = tempMovesList
        
        match.endMatchInTurn(
        withMatch: model.saveDataToSend(overwriteAllGameData: false),
        completionHandler: completion)
    }
    
    /// Saves the game data to the GKTurnBasedMatch object and sends it to GameCenter but does not pass play to the next player
    /// - Parameters:
    ///   - model: the model of the active online match being played
    ///   - completion: mainly used to throw errors
    func updateButDontEndTurn(_ model: GameModel, completion: @escaping CompletionBlock) {
        
        guard let match = currentMatch else {
            completion(GameCenterHelperError.matchNotFound)
            return
        }

        match.message = model.messageToDisplay
        
        var overwrite = true
        let checkPits = model.pits.circIter
        if let player2Base = *checkPits {
            if model.gameData.pitsList.count > 0 {
                let pitListPlayer2Base = model.gameData.pitsList[0]
                overwrite = !(player2Base === pitListPlayer2Base)
            }
        }
        //before saveCurrentTurn() is called, save lastMovesList separately
        //otherwise lastMovesList overwritten will only contain the last move if the player got a bonus turn, but hasn't finished their full turn
//        let tempMovesList = model.gameData.lastMovesList
//        model.saveGameData()
        
//        if !(model.gameData.lastMovesList.elementsEqual(tempMovesList)) {
//            model.gameData.lastMovesList = tempMovesList
//            model.gameData.lastMovesList.append(contentsOf: model.lastMovesList)
//        }
        
        let matchData = model.saveDataToSend(overwritePitsList: overwrite)
        match.saveCurrentTurn(withMatch: matchData, completionHandler: completion)
    }
    
    //MARK: - Update match

    /// Updates the GKTurnBasedMatch.participants.matchOutcomes based on the data in the GameModel.
    /// Checks to see if new game modes have been unlocked
    /// - Parameters:
    ///   - match: to be checked and mutated
    ///   - model: contains the data associated with the match
    func assignOutcomes(to match: GKTurnBasedMatch,_ model: GameModel) {
        guard let currParticipant = match.currentParticipant, let opponent = match.others.first else {
            print("""
                currParticipant == \(String(describing: match.currentParticipant)),
                opponent == \(String(describing: match.others.first)).
                    Exiting func win in GameCenterHelper
                """)
            return
        }

        let lastPlayerTurn = model.lastPlayerTurn
        let currParticipantOutcome: GKTurnBasedMatch.Outcome
        if model.winner == 0 {
            currParticipantOutcome = .tied
            currParticipant.matchOutcome = currParticipantOutcome
            opponent.matchOutcome = currParticipantOutcome
            match.message = "Tied game."
        } else {
            let winnerIsCurrentParticipant = model.winner == lastPlayerTurn
            currParticipantOutcome = winnerIsCurrentParticipant ? .won : .lost
            currParticipant.matchOutcome = currParticipantOutcome
            opponent.matchOutcome = winnerIsCurrentParticipant ? .lost : .won
            
            let winnerName: String?
            if winnerIsCurrentParticipant {
                winnerName = currParticipant.player?.alias
            } else {
                winnerName = opponent.player?.alias
            }
            if let name = winnerName {
                model.winnerTextArray.remove(at: model.winnerTextArray.endIndex - 1)
                model.winnerTextArray.append("The winner is...")
                model.winnerTextArray.append(name)
                match.message = "Game Over. \(name) wins!"
            }
        }
        matchHistory.allGamesPlayed?.updateValue(currParticipantOutcome, forKey: match.matchID)
        self.matchHistory.countNumberOfWins()
        //if num wins > 20
        //  send local notification to announce that the new game mode has been unlocked
        //  set boolean value to unlock new game mode
        //  boolean will unhide new game mode button in SettingsScene
        //  it will also change the num beads in pits in GameModel initGameboard(from: PitList) et al
        self.matchHistory.evaluateUnlockGameModesEarned()
    }
    
    /// When a player quits, the match outcomes and other data are not updated, so in this case the GKTurnBasedMatch must be updated manually.
    func playerForfeits(match: GKTurnBasedMatch, _ model: GameModel, quitter: GKTurnBasedParticipant, winner: GKTurnBasedParticipant, completion: @escaping CompletionBlock) {

        var winningPlayer = 1
        
        if #available(iOS 12.4, *) {
            if quitter.player?.gamePlayerID == model.gameData.firstPlayerID {
                winningPlayer = 2
            }
        } else {
            if quitter.player?.playerID == model.gameData.firstPlayerID {
                winningPlayer = 2
            }
        }
        
        model.winner = winningPlayer
        
        if let quitterName = quitter.player?.alias {
            model.winnerTextArray.append("\(quitterName) has forfeited the match.")
        } else {
            if winningPlayer == 2 {
                model.winnerTextArray.append("Player 1 has forfeited the match.")
            } else {
                model.winnerTextArray.append("Player 2 has forfeited the match.")
            }
        }
        
        if let winnerName = winner.player?.alias {
            model.winnerTextArray.append("\(winnerName) is the winner!")
        } else {
            model.winnerTextArray.append("Player \(winningPlayer) is the winner!")
        }
        match.message = "I saw that you forfeited the match! Do you want a rematch?"
        match.endMatchInTurn(
            withMatch: model.saveDataToSend(),
            completionHandler: completion)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        print("called gameCenterViewControllerDidFinish")
    }
    
    //MARK: - Helpers
    
    /// Checks the state of the GKTurnBasedMatch and assigns any of the following set: { .none .quit .won .lost .tied } to the local player's matchOutcome
    func checkOutcome(_ match: GKTurnBasedMatch,_ _model: GameModel? = nil) {
        printOutcomes(for: match)
        if let opponent = match.others.first, let localPlayer = match.localParticipant.first {
            switch opponent.matchOutcome {
            case .won:
                localPlayer.matchOutcome = .lost
                if let model = _model {
                    if GKLocalPlayer.local.playerID == model.gameData.firstPlayerID {
                        model.winner = 2
                    } else {
                        model.winner = 1
                    }
                    
                    if model.winnerTextArray.isEmpty {
                        if !model.gameData.winnerTextArray.isEmpty {
                            model.winnerTextArray = model.gameData.winnerTextArray
                        } else {
                            model.winnerTextArray.append("Game Over")
                            model.winnerTextArray.append("The winner is...")
                            model.winnerTextArray.append("\(opponent.player?.alias ?? "Player " + String(model.winner!))")
                        }
                    }
                }
            case .lost:
                localPlayer.matchOutcome = .won
                if let model = _model {
                    if GKLocalPlayer.local.playerID == model.gameData.firstPlayerID {
                        model.winner = 1
                    } else {
                        model.winner = 2
                    }
                    
                    if model.winnerTextArray.isEmpty {
                        if !model.gameData.winnerTextArray.isEmpty {
                            model.winnerTextArray = model.gameData.winnerTextArray
                        } else {
                            model.winnerTextArray.append("Game Over")
                            model.winnerTextArray.append("The winner is...")
                            model.winnerTextArray.append("\(localPlayer.player?.alias ?? "Player " + String(model.winner!))")
                        }
                    }
                }
            case .quit:
                print("they quit")
                localPlayer.matchOutcome = .won
                opponent.matchOutcome = .lost
                if let model = _model {
                    GameCenterHelper.helper.playerForfeits(match: match, model, quitter: opponent, winner: localPlayer) { error in
                    
                        if let e = error {
                            print("Error processing opponent's forfeited match: \(e.localizedDescription)")
                        }
                    }
                }
            
            case .tied:
                if let model = _model {
                    if model.winnerTextArray.isEmpty {
                        if !model.gameData.winnerTextArray.isEmpty {
                            model.winnerTextArray = model.gameData.winnerTextArray
                        } else {
                            model.winnerTextArray.append("Game Over")
                            model.winnerTextArray.append("Tied game")
                        }
                    }
                }
            default:
                if opponent.matchOutcome == .none {
                    print(" opponent == .none \n localPlayer == \(localPlayer.matchOutcome.rawValue)")
                } else {
                    print(opponent.matchOutcome.rawValue)
                }
            }
        }
    }

    /// Helper function to translate the matchOutcome enum to a string
    func printOutcomes(for match: GKTurnBasedMatch) {
        if let opponent = match.others.first, let localPlayer = match.localParticipant.first {
            let oppoOutcome = opponent.matchOutcome
            let localOutcome = localPlayer.matchOutcome
            let outcomes = [oppoOutcome, localOutcome]
            var opponentOutcomeString = ""
            var localPlayerOutcomeString = ""
            for (i, outcome) in outcomes.enumerated() {
                let matchOutcome: String
                switch outcome {
                case .customRange:
                    matchOutcome = "customRange"
                case .first:
                    matchOutcome = "first"
                case .second:
                    matchOutcome = "second"
                case .third:
                    matchOutcome = "third"
                case .fourth:
                    matchOutcome = "fourth"
                case .lost:
                    matchOutcome = "lost"
                case .none:
                    matchOutcome = "none"
                case .quit:
                    matchOutcome = "quit"
                case .won:
                    matchOutcome = "won"
                case .tied:
                    matchOutcome = "tied"
                case .timeExpired:
                    matchOutcome = "timeExpired"
                default:
                    matchOutcome = "unknown"
                }
                if i == 0 {
                    opponentOutcomeString = matchOutcome
                } else {
                    localPlayerOutcomeString = matchOutcome
                }
            }
            print("matchID: " + match.matchID + "\n   opponent: " + opponentOutcomeString + "\n    localPlayer: " + localPlayerOutcomeString  )
        }
    }
}//EoC

extension GameCenterHelper: GKTurnBasedMatchmakerViewControllerDelegate {
    
    func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
        viewController.dismiss(animated: true)
    }
    
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
        print("MatchMaker vc did fail with error: " + error.localizedDescription)
        
    }
    
    
}

extension GameCenterHelper: GKLocalPlayerListener {
    
    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        let activeOthers = match.others.filter { other in
            return other.status == .active
        }
        
        match.currentParticipant?.matchOutcome = .lost
        activeOthers.forEach { (participant) in
            participant.matchOutcome = .won
        }
        
        if canTakeTurnForCurrentMatch {
            match.endMatchInTurn(withMatch: match.matchData ?? Data())
        } else {
            match.participantQuitOutOfTurn(with: .lost)
        }
    }
    
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        guard didBecomeActive else {
            if match.isLocalPlayersTurn {
                UserNotificationsHelper.scheduleNotifications(for: match, player)
            }
            return
        }
        
        if let vc = currentMatchMakerVC {
            currentMatchMakerVC = nil
            vc.dismiss(animated: true)
        }
        NotificationCenter.default.post(name: .presentGame, object: match)
    }
    
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        print("Player \(player.alias)'s match ended")
        //gets called when non-currentParticipant ends the match
        //gets called when local player forfeits
        if matchHistory.allGamesPlayed == nil {
            matchHistory.loadAllGamesPlayedDict()
        }
        if !matchHistory.updateHistoricalMatchOutcomes() {
            matchHistory.updateCurrentMatchOutcomes()
        }
    }

}//EoC


