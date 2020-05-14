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
            static let _Open = SKTransition.doorsOpenVertical(withDuration: 0.3)
            static let _Close = SKTransition.doorsCloseVertical(withDuration: 0.3)
        }
    }
    
    /// Implements the completion handler for GKTurnBasedMatch.loadMatchData(_:).  Sets up an Online game before presenting the ```ReplayScene``` or ```GameScene``` to the user.
    /// - Parameter match: Was either chosen by the user in GameCenter or loaded from a "Your Turn" notification.
    func loadAndDisplay(match: GKTurnBasedMatch) {
        

        match.loadMatchData { [weak self] (data, error) in
            let model: GameModel
            if let theError = error {
                print("ERROR: Could not load match\n" + theError.localizedDescription)
                self?.errorLoadingMatch()
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
                    } catch {
                        print("error deserializing gkMatchData: \(error.localizedDescription)")
                        self?.errorLoadingMatch()
                        return
                    }
                } else {
                    print("gkMatchData was empty")
                    model = GameModel(newGame: true)
                }

            } else {
                print("error loading gameData: \(String(describing: error))" )
                self?.errorLoadingMatch()
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
            
                self?.skView.presentScene(onlineGameScene, transition: Transitions.Open.getValue())
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
                self?.skView.presentScene(ReplayScene(model_: model, activePlayer), transition: Transitions.Open.getValue())
            }
            
        }
    }
    
    /// Helper for presenting a generic failure message
    func errorLoadingMatch() {
        showAlert(withTitle: "Error loading match data", message: "Please check your connection and try again.")
    }
    //MARK: - notifications
    
    /// Selector for notifications sent or triggered by GKLocalPlayerListener.player(_:receivedTurnEventFor:didBecomeActive)
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
        skView.presentScene(SettingsScene(), transition: Transitions.Up.getValue())
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
        skView.presentScene(onlineGameScene, transition: Transitions.Close.getValue())
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

