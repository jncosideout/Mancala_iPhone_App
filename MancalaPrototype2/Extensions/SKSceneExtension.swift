///
///  SKSceneExtension.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 2/21/20.
/// ============LICENSE_START=======================================================
/// Copyright © 2019 Alexander Scott Beaty. All rights reserved.
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================

import Foundation
import SpriteKit
import GameKit
/**
 The benefit of putting loadAndDisplay(match:) in an extension, is that it allows us to open a match from a local notification received in any scene in the app
 The trade off is that we no longer can use dependency injection with savedGameModels when moving to and from scenes and the Online Game.
 
 + The first solution was to make a new global reference to savedGameModels, which is considered a use of a singleton. Normally, when returning from an Online match, the GameScene prepares the MenuScene by passing its ```savedGameModels```. At this point the singleton savedGameModels in this SKScene extension was retrieved and substituted.
 + Now the best practice is access the appDelegate directly since the dependency we were injecting is referencing the instance in the appDelegate, and we don't want to have more than one floating around.
 */
extension SKScene {
    
    static let transition = SKTransition.push(with: .up, duration: 0.3)
    //static var savedGameModels: [GameModel]?
    
    
    /// Implements the completion handler for GKTurnBasedMatch.loadMatchData(_:).  Sets up an Online game before presenting the ```ReplayScene``` or ```GameScene``` to the user.
    /// - Parameter match: Was either chosen by the user in GameCenter or loaded from a "Your Turn" notification.
    func loadAndDisplay(match: GKTurnBasedMatch) {
        
        //save local games before loading online match
        //UPDATE: using shared appDelegate instance to retrieve savedGamesArray after returning from online match
        // No longer need to create this extra reference when leaving the current SKScene before loading a GKTurnBasedMatch
//        if let savedGameArray = SKScene.savedGameModels {
//            SavedGameStore(withUpdated: savedGameArray)
//        }
        match.loadMatchData { (data, error) in
            let model: GameModel
            if let theError = error {
                print("ERROR: Could not load match\n" + theError.localizedDescription)
                return
            }
            
            /// gkMatchData is the JSON representation of GameData stored in the GKTurnBasedMatch.
            if let gkMatchData = data {
                /// Initialize the GameModel be deserializing gkMatchData
                model = GameModel(fromGKMatch: gkMatchData)
            } else {
                print("error loading gameData: \(String(describing: error))" )
                model = GameModel(newGame: true)
            }
            
            /// Give the match to GameCenterHelper so that turn-handling can take place
            GameCenterHelper.helper.currentMatch = match
            /// Update localPlayer.matchOutcome and model.winnerTextArray with current state of match
            GameCenterHelper.helper.checkOutcome(match, model)
            /// Update matchHistory.allGamesPlayed with current state of match and check if new game modes have been unlocked
            if let localPlayer =  match.localParticipant.first, let matchHistory = GameCenterHelper.helper.matchHistory {
                if matchHistory.allGamesPlayed != nil {
                    matchHistory.allGamesPlayed!.updateValue(localPlayer.matchOutcome, forKey: match.matchID)
                } else {
                    matchHistory.loadAllGamesPlayedDict()
                }
            }
            
            model.vsOnline = true
            /// If the player is starting a new match, set up the game for the first player and go directly to the GameScene
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
    
    /// Selector for "Your turn" notification observer
    @objc func presentGame(_ notification: Notification) {
         guard let match = notification.object as? GKTurnBasedMatch else {
             return
         }
         loadAndDisplay(match: match)
     }
    
    /// Registers an SKScene to receive and present "Your turn" notifications
    func addObserverForPresentGame() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(presentGame(_:)),
            name: .presentGame,
            object: nil)
    }
    
    /// Selector for "Unlocked new game mode" notification observer
    @objc func presentSettings(_ notification: Notification) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let allSavedGames = appDelegate?.savedGameModels
        self.view?.presentScene(SettingsScene(vsComp: false, with: allSavedGames))
    }
    
    /// Registers an SKScene to receive and present "Unlocked new game mode" notifications
    func addObserverForPresentSettings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(presentSettings(_:)),
            name: .presentSettings,
            object: nil)
    }
    
}

