//
//  GameCenterHelper.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//
import GameKit

final class GameCenterHelper: NSObject {
    typealias CompletionBlock = (Error?) -> Void
    
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
                print("Error authenticating to Game Center: " +
                "\(error?.localizedDescription ?? "none")")
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
            
                            return model.messageToDisplay
                        }()
        
        match.endTurn(
            withNextParticipants: match.others,
            turnTimeout: GKExchangeTimeoutDefault,
            match: model.saveDataToSend(),
            completionHandler: completion)

    }
    
    func win(completion: @escaping CompletionBlock) {
        
        guard let match = currentMatch else {
            completion(GameCenterHelperError.matchNotFound)
            return
        }
        
        match.currentParticipant?.matchOutcome = .won
        match.others.forEach { (other) in
            other.matchOutcome = .lost
        }
        
        match.endMatchInTurn(
            withMatch: match.matchData ?? Data(),
            completionHandler: completion)
    }
    
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
        print("MatchMaker vc did fail with error: \(error.localizedDescription)")
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
    
        match.endMatchInTurn(withMatch: match.matchData ?? Data())
    }
    
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        guard didBecomeActive else {
            return
        }
        
        if let vc = currentMatchMakerVC {
            currentMatchMakerVC = nil
            vc.dismiss(animated: true)
        }
        NotificationCenter.default.post(name: .presentGame, object: match)
    }

}
