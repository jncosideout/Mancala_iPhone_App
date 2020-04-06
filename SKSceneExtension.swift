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

extension SKScene {
    
    static let transition = SKTransition.push(with: .up, duration: 0.3)
    static var savedGameModels: [GameModel]?
    

    func loadAndDisplay(match: GKTurnBasedMatch) {
        
        //save local games before loading online match
        if let savedGameArray = SKScene.savedGameModels {
            SavedGameStore(withUpdated: savedGameArray)
        }
        match.loadMatchData { (data, error) in
            let model: GameModel
            
            if let gkMatchData = data {
                model = GameModel(fromGKMatch: gkMatchData)
            } else {
                print("error loading gameData: \(String(describing: error))" )
                model = GameModel(newGame: true)
            }
            
            GameCenterHelper.helper.currentMatch = match
            GameCenterHelper.helper.checkOutcome(match, model)
            
            if model.turnNumber == 0 && model.playerTurn == 1 {
                model.gameData.firstPlayerID = match.currentParticipant?.player?.playerID ?? ""
                model.playerPerspective = model.playerTurn
                model.gameData.oldPitsList = model.saveGameBoardToList(model.pits)
                
                let gameScene = GameScene(model: model)
                gameScene.thisGameType = .vsOnline
            
                self.view?.presentScene(gameScene, transition: SKScene.transition)
            } else {
                // to find out if the local player is player 1 or 2
                var activePlayer: Bool
                if GKLocalPlayer.local.playerID == model.gameData.firstPlayerID {
                    model.playerPerspective = 1
                } else {
                    model.playerPerspective = 2
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
}

