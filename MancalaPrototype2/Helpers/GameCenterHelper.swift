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
            
                return model.messagesToDisplay.first }()
        
        match.endTurn(
            withNextParticipants: match.others,
            turnTimeout: GKExchangeTimeoutDefault,
            match: model.saveDataToSend(),
            completionHandler: completion)

    }
    
    func win(_ model: GameModel, completion: @escaping CompletionBlock) {
        
        guard let match = currentMatch else {
            completion(GameCenterHelperError.matchNotFound)
            return
        }
        
        let lastPlayerTurn = model.playerTurn == 1 ? 2 : 1
        let winnerIsCurrentParticipant = model.winner == lastPlayerTurn
        
        
        match.currentParticipant?.matchOutcome = winnerIsCurrentParticipant ? .won : .lost
        match.others.forEach { (other) in
            other.matchOutcome = winnerIsCurrentParticipant ? .lost : .won
        }
        
        match.endMatchInTurn(
            withMatch: model.saveDataToSend(),
            completionHandler: completion)
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
    func checkOutcome(_ match: GKTurnBasedMatch,_ model: GameModel) {
        
        if let opponent = match.others.first {
            switch opponent.matchOutcome {
            case .won:
                if GKLocalPlayer.local.playerID == model.gameData.firstPlayerID {
                    model.winner = 2
                } else {
                    model.winner = 1
                }
                
                if model.winnerTextArray.isEmpty {
                    model.winnerTextArray.append("Game Over")
                    model.winnerTextArray.append("The winner is...")
                    model.winnerTextArray.append("\(opponent.player?.alias ?? "Player " + String(model.winner!))")
                }
            case .lost:
                if GKLocalPlayer.local.playerID == model.gameData.firstPlayerID {
                    model.winner = 1
                } else {
                    model.winner = 2
                }
                
                if model.winnerTextArray.isEmpty {
                    model.winnerTextArray.append("Game Over")
                    model.winnerTextArray.append("The winner is...")
                    model.winnerTextArray.append("\(match.localParticipant.first?.player?.alias ?? "Player " + String(model.winner!))")
                }
            case .quit:
                print("they quit")
                if let localParticipant = match.localParticipant.first {
                    localParticipant.matchOutcome = .won
                    opponent.matchOutcome = .lost
                    GameCenterHelper.helper.playerForfeits(match: match, model, quitter: opponent, winner: localParticipant) { error in
                        
                        if let e = error {
                            print("Error processing opponent's forfeited match: \(e.localizedDescription)")
                        }
                    }
                }
            case .tied:
                if model.winnerTextArray.isEmpty {
                    model.winnerTextArray.append("Game Over")
                    model.winnerTextArray.append("Tied game")
                }
            default:
                if opponent.matchOutcome == .none {
                    print("opponent == .none")
                } else {
                    print(opponent.matchOutcome.rawValue)
                }
            }
        }
    }
    //MARK: - Saved Game Model Mgmt
    
}//EoC

extension Notification.Name {
    static let presentGame = Notification.Name("presentGame")
    static let authenticationChanged = Notification.Name("authenticationChanged")
}

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
    }

}
