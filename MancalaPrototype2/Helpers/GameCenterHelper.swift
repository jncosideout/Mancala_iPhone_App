//
//  GameCenterHelper.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//
import GameKit
import UserNotifications

final class GameCenterHelper: NSObject, GKGameCenterControllerDelegate {
    
    typealias CompletionBlock = (Error?) -> Void
    var savedGameStore: SavedGameStore!
    static let helper = GameCenterHelper()
    var viewController: UIViewController?
    var currentMatchMakerVC: GKTurnBasedMatchmakerViewController?
    var currentMatch: GKTurnBasedMatch?
    var matchHistory: MatchHistory!
     
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
            
                return model.messageToDisplay }()
        
        match.endTurn(
            withNextParticipants: match.others,
            turnTimeout: GKExchangeTimeoutDefault,
            match: model.saveDataToSend(),
            completionHandler: completion)

    }
    
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
    
    // .none .quit .won .lost .tied
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
            UserNotificationsHelper.scheduleNotifications(for: match, player)
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


