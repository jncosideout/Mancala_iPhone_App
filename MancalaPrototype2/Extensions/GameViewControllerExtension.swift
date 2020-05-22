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
Contains the methods for loading and presenting an online match replay scene and game scene. Uses the same pattern of "Notification Observer/ Selector' found in GameViewController.
 
 + loadAndDisiplay is called by the selector for the presentGame notification
 */
extension GameViewController: Alertable {
    
    public enum Transitions {
        case Up
        case Down
        case Open
        case Close
        func getValue() -> SKTransition {
            switch self {
            case .Up:
                return SKTrans._Up
            case .Down:
                return SKTrans._Down
            case .Open:
                return SKTrans._Open
            case .Close:
                return SKTrans._Close
            }
        }
        private struct SKTrans {
            static let _Up = SKTransition.push(with: .up, duration: 0.3)
            static let _Down = SKTransition.push(with: .down, duration: 0.3)
            static let _Open = SKTransition.doorsOpenVertical(withDuration: 0.6)
            static let _Close = SKTransition.doorsCloseVertical(withDuration: 0.6)
        }
    }
    
    /// Implements the completion handler for GKTurnBasedMatch.loadMatchData(_:).  Sets up an Online game before presenting the ```ReplayScene``` or ```GameScene``` to the user.
    /// - Parameter match: Was either chosen by the user in GameCenter or loaded from a "Your Turn" notification.
    func loadAndDisplay(match: GKTurnBasedMatch) {
        

        match.loadMatchData { [weak self] (data, error) in
            let model: GameModel
            if let theError = error {
                let errMsg = theError.localizedDescription
                print("ERROR: Could not load match\n" + errMsg)
                self?.errorLoadingMatch(errMsg)
                return
            }
            
            /// gkMatchData is the JSON representation of GameData stored in the GKTurnBasedMatch.
            if let gkMatchData = data {
                // Deserialize data and convert to GameData
                if !gkMatchData.isEmpty {
                    do {
                        let gameData = try JSONDecoder().decode(GameData.self, from: gkMatchData)
                        /// Initialize the GameModel with the GameData
                        model = GameModel(fromGKMatch: gameData)
                    } catch (let anError) {
                        let errMsg = anError.localizedDescription
                        print("error deserializing gkMatchData:\n" + errMsg)
                        self?.errorLoadingMatch(errMsg)
                        return
                    }
                } else {
                    print("gkMatchData was empty")
                    model = GameModel(newGame: true)
                }

            } else {
                print("error loading gameData: gkMatchData was nil" )
                self?.errorLoadingMatch("Please try again later")
                return
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
                model.gameData.oldPitsList = GameModel.saveGameBoardToList(model.pits, deepCopy: false)
                model.localPlayerNumber = 1
                let onlineGameScene = GameScene()
                onlineGameScene.thisGameType = .vsOnline
                onlineGameScene.model = model
                
                if UserDefaults.backgroundAnimationType != .none {
                    self?.skView.presentScene(onlineGameScene)
                } else {
                    self?.skView.presentScene(onlineGameScene, transition: Transitions.Open.getValue())
                }
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
                
                let replayScene = ReplayScene(model_: model, activePlayer)
                if UserDefaults.backgroundAnimationType != .none {
                    self?.skView.presentScene(replayScene)
                } else {
                    self?.skView.presentScene(replayScene, transition:  Transitions.Open.getValue())
                }
            }
            
        }
    }
    
    /// Helper for presenting a generic failure message
    func errorLoadingMatch(_ error: String, completionBlock: (() -> Void)? = nil) {
        showAlert(withTitle: "Error loading match data", message: error, completion: completionBlock)
    }
    //MARK: - notifications
    
    /// Selector for notifications sent or triggered by GKLocalPlayerListener.player(_:receivedTurnEventFor:didBecomeActive)
    @objc func presentOnlineGame(_ notification: Notification) {
         guard let match = notification.object as? GKTurnBasedMatch else {
             return
         }
         loadAndDisplay(match: match)
     }
    
    /// Registers an SKScene to receive and present "Your turn" notifications
    func addObserverForPresentGame() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(presentOnlineGame(_:)),
            name: .presentOnlineGame,
            object: nil)
    }
    
    /// Selector for "Unlocked new game mode" notification observer
    @objc func presentSettings(_ notification: Notification) {
        let settingsScene: SettingsScene
        // If this selector is called because of the "unlock new game mode notification,
        // it will include a ButtonBitmask that will animate the SettingsScene when presented
        // to show the new button 'start with X beads'
        if let buttonsToFade = notification.object as? ButtonBitmask {
            settingsScene = SettingsScene(buttonsToFade)
        } else {
            settingsScene = SettingsScene()
        }
        skView.presentScene(settingsScene, transition: Transitions.Up.getValue())
    }
    
    /// Registers an SKScene to receive and present "Unlocked new game mode" notifications
    func addObserverForPresentSettings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(presentSettings(_:)),
            name: .presentSettings,
            object: nil)
    }
    
    /// Selector for "continueOnlineGame" notification observer
    @objc func continueOnlineGame(_ notification: Notification) {
        let onlineGameModel = notification.object as! GameModel
        let onlineGameScene = GameScene()
        onlineGameScene.thisGameType = .vsOnline
        onlineGameScene.model = onlineGameModel
        
        if UserDefaults.backgroundAnimationType != .none {
            skView.presentScene(onlineGameScene)
        } else {
            skView.presentScene(onlineGameScene, transition: Transitions.Close.getValue())
        }
    }
    
    /// Registers an SKScene to receive   "continueOnlineGame" notifications and present the Online GameScene
    func addObserverForContinueOnlineGame() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(continueOnlineGame(_:)),
            name: .continueOnlineGame,
            object: nil)
    }
    
}

