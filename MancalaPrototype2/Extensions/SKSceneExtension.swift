//
//  SKSceneExtension.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 2/21/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//

import Foundation
import SpriteKit
import GameKit
/**
 The bnefit of putting loadAndDisplay(match:) in an extension, is that it allows us to open a match from a local notification received in any scene in the app
 The trade off is that we no longer can use dependency injection with savedGameModels when moving to and from scenes and the Online Game
 */
extension SKScene {
    
    static let transition = SKTransition.push(with: .up, duration: 0.3)
    static var savedGameModels: [GameModel]?
    

    func loadAndDisplay(match: GKTurnBasedMatch) {
        
        //save local games before loading online match
        //UPDATE: using shared appDelegate instance to retrieve savedGamesArray after returning from online match
//        if let savedGameArray = SKScene.savedGameModels {
//            SavedGameStore(withUpdated: savedGameArray)
//        }
        match.loadMatchData { (data, error) in
            let model: GameModel
            if let theError = error {
                print("ERROR: Could not load match\n" + theError.localizedDescription)
                return
            }
            if let gkMatchData = data {
                model = GameModel(fromGKMatch: gkMatchData)
            } else {
                print("error loading gameData: \(String(describing: error))" )
                model = GameModel(newGame: true)
            }
            
            GameCenterHelper.helper.currentMatch = match
            GameCenterHelper.helper.checkOutcome(match, model)
            if let localPlayer =  match.localParticipant.first, let matchHistory = GameCenterHelper.helper.matchHistory {
                if matchHistory.allGamesPlayed != nil {
                    matchHistory.allGamesPlayed!.updateValue(localPlayer.matchOutcome, forKey: match.matchID)
                } else {
                    matchHistory.loadAllGamesPlayedDict()
                }
            }
            
            model.vsOnline = true
            if model.turnNumber == 0 && model.playerTurn == 1 {
                model.gameData.firstPlayerID = match.currentParticipant?.player?.playerID ?? ""
                model.playerPerspective = model.playerTurn
                model.gameData.oldPitsList = model.saveGameBoardToList(model.pits)
                model.localPlayerNumber = 1
                let gameScene = GameScene(model: model)
                gameScene.thisGameType = .vsOnline
            
                self.view?.presentScene(gameScene, transition: SKScene.transition)
            } else {
                // to find out if the local player is player 1 or 2
                var activePlayer: Bool
                if GKLocalPlayer.local.playerID == model.gameData.firstPlayerID {
                    model.gameData.playerPerspective = 1
                    model.playerPerspective = 1
                    model.localPlayerNumber = 1
                } else {
                    model.gameData.playerPerspective = 2
                    model.playerPerspective = 2
                    model.localPlayerNumber = 2
                }
                if model.playerPerspective == model.playerTurn {
                    activePlayer = true
                } else {
                    activePlayer = false
                }
                self.view?.presentScene(ReplayScene(model_: model, activePlayer), transition: SKScene.transition)
            }
            
        }
    }
    //MARK: - notifications
    @objc func presentGame(_ notification: Notification) {
         guard let match = notification.object as? GKTurnBasedMatch else {
             return
         }
         loadAndDisplay(match: match)
     }
    
    func addObserverForPresentGame() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(presentGame(_:)),
            name: .presentGame,
            object: nil)
    }
    
    @objc func presentSettings(_ notification: Notification) {
        self.view?.presentScene(SettingsScene(vsComp: false, with: SKScene.savedGameModels))
    }
    
    func addObserverForPresentSettings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(presentSettings(_:)),
            name: .presentSettings,
            object: nil)
    }
    
}

