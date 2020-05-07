///
///  GameScene.swift
///  MancalaPrototype2
///
///  Created by Alexander Scott Beaty on 7/30/19.
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


import SpriteKit
/**
 Replays the last player's move in an Online match. This scene is always presented exxept for on the first player's first turn
 */
final class ReplayScene: GameScene {
    
    // MARK: - Properties
    
    // Contains the current data of the game
    private var actualModel: GameModel
    // Used to ensure that playerPerspective is set to the player who loaded the match, regardless of who's turn it is
    // This is no longer necessary
    private var activePlayer: Bool
    
    // MARK: - Init
    
    init(model_: GameModel,_ activePlayer: Bool) {
        self.activePlayer = activePlayer
        actualModel = model_
        super.init(model: GameModel(replayWith: actualModel.gameData))
        // Used to personalize the game info text for the activePlayer
        model.localPlayerNumber = actualModel.localPlayerNumber
        model.vsOnline = true
        thisGameType = .vsOnline
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        successGenerator.prepare()
        feedbackGenerator.prepare()
        
        addObserverForPresentGame()
        addObserverForPresentSettings()
        
        setUpScene(in: view)
        
        replay()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        setUpScene(in: view)
    }
    
    // MARK: - Setup
    override func setUpScene(in view: SKView?) {
        guard viewWidth > 0 else {
            return
        }
        
        backgroundColor = .background
        if UserDefaults.allowGradientAnimations {
            GradientNode.makeLinearNode(with: self, view: view!, linearGradientColors: GradientNode.sunsetPurples, animate: true)
            GradientNode.makeRadialNode(with: self, view: view!)
        } else {
              let billiardFelt = SKSpriteNode(imageNamed: "Mancala-billiard-felt-")
              billiardFelt.size = CGSize(
                  width: billiardFelt.size.width,
                  height: billiardFelt.size.height
              )
              billiardFelt.position = CGPoint(
                  x: viewWidth / 2,
                  y: viewHeight / 2
              )
              billiardFelt.zPosition = GameScene.NodeLayer.background.rawValue - 1
              addChild(billiardFelt)
        }
        
        var runningYOffset: CGFloat = 0
        
        let sceneMargin: CGFloat = 40
        let safeAreaTopInset = view?.window?.safeAreaInsets.top ?? 0
        let safeAreaBottomInset = view?.window?.safeAreaInsets.bottom ?? 0
        
        let padding: CGFloat = 48
        let boardSideLength = min(480, max(viewWidth, viewHeight) - (padding * 3))
        boardNode = BoardNode(sideLength: boardSideLength, halfNumPits: model.pits.length/2)
        boardNode.zPosition = NodeLayer.board.rawValue
        runningYOffset += safeAreaBottomInset + sceneMargin + (boardSideLength / 4)
        boardNode.position = CGPoint(
            x: viewWidth / 2,
            y: runningYOffset
        )
        
        addChild(boardNode)
        
        let messageNodeName: String? = "messageNodeName"
        let messageNodeWidth = viewWidth - (sceneMargin * 2)
        messageNode = InformationNode("Replaying last turn", size: CGSize(width: messageNodeWidth, height: 40), named: messageNodeName)
        messageNode.zPosition = NodeLayer.ui.rawValue
//        let distFromTopToBoard = viewHeight - (runningYOffset + boardSideLength / 4)
        let messageNodeHeigth = viewHeight - sceneMargin - 5//distFromTopToBoard / 2 + (viewHeight - distFromTopToBoard)
        messageNode.position = CGPoint(x: (viewWidth / 2) - messageNodeWidth / 2, y: messageNodeHeigth)
        
        addChild(messageNode)
        
        setupColorChangeActions()
        
        //MARK: - Button actions
        let buttonSize = CGSize(width: 125, height: 50)
        let returnButton = ButtonNode("Continue", size: buttonSize)
        {   [weak self] in
            // The player who ends the match does call GameCenterHelper.endMatch()
            // The reason for this functionality is to send a notification to the other player when the match is over
            // by ending the turn instead of ending the match. Therefore, the next player has the responsibility of
            // truly ending the match. That is why we check model.onlineGameOver here.
            if let onlineGameOver = self?.model.onlineGameOver, onlineGameOver {
                guard let _actualModel = self?.actualModel else { return }
                GameCenterHelper.helper.endMatch(_actualModel, completion: { error in
                    defer {
                        self?.isSendingTurn = false
                    }
                    
                    if let e = error {
                        print("Error ending turn: \(e.localizedDescription)")
                    }
                    
                })
                self?.returnToMenu()
            } else {
                self?.returnToGame()
            }
        }
        returnButton.position = CGPoint(
            x: sceneMargin / 3.0,
            y: viewHeight - safeAreaTopInset - sceneMargin / 2 - (buttonSize.height)
        )
        returnButton.zPosition = NodeLayer.ui.rawValue
        
        addChild(returnButton)
        
        // Same setup as init(model_:,_:), but call replay() after
        let replayButton = ButtonNode("Replay", size: buttonSize)
        {   [weak self, weak _actualModel = self.actualModel] in
            guard let _gameData = _actualModel?.gameData, let _localPlayer = _actualModel?.localPlayerNumber
                else { return }
            self?.model = GameModel(replayWith: _gameData)
            self?.model.localPlayerNumber = _localPlayer
            self?.model.vsOnline = true
            self?.allTokenNodes = CircularLinkedList<TokenNode>()
            self?.removeAllChildren()
            self?.setUpScene(in: view)
            self?.replay()
        }
        replayButton.position = CGPoint(
            x: viewWidth - sceneMargin / 3.0 - buttonSize.width,
            y: viewHeight - safeAreaTopInset - sceneMargin / 2 - (buttonSize.height)
        )
        replayButton.zPosition = NodeLayer.ui.rawValue
        
        addChild(replayButton)
        
        let playerWindowSize = CGSize(width: 75, height: 35)
        let plyWinTopText = model.playerPerspective == 1 ? "P2" : "P1"
        let playerWindowTopRight = InformationNode(plyWinTopText, size: playerWindowSize, named: nil)
        playerWindowTopRight.position = CGPoint(
            x: viewWidth - sceneMargin / 3.0 - playerWindowSize.width,
            y: runningYOffset + boardSideLength / 4 - playerWindowSize.height / 2
        )
        playerWindowTopRight.zPosition = NodeLayer.ui.rawValue
        
        addChild(playerWindowTopRight)
        
        let plyWinBottomText = "You"
        let playerWindowBottomLeft = InformationNode(plyWinBottomText, size: playerWindowSize, named: nil)
        playerWindowBottomLeft.position = CGPoint(
            x: sceneMargin / 3.0,
            y: runningYOffset - boardSideLength / 4 - playerWindowSize.height / 2
        )
        playerWindowBottomLeft.zPosition = NodeLayer.ui.rawValue
        
        addChild(playerWindowBottomLeft)
        
        loadTokens()
    }
    
    // MARK: - Helpers
    
    /**
     Return to the GameScene to play the current turn or go back to the menu from there.
     
     Perform any last minute saving and configuration here.
     */
    private func returnToGame() {
        // First, copy the current pits to the oldPitsList so that when/if the user takes their turn the pitsList will be updated and oldPitsList will refer to the previous turn.
        actualModel.gameData.oldPitsList = actualModel.saveGameBoardToList(actualModel.pits)
        
        let gameScene = GameScene(model: actualModel)
        gameScene.thisGameType = .vsOnline

        view?.presentScene(gameScene, transition: SKTransition.push(with: .down, duration: 0.3))
    }
    
    
    /// Replays the last move according to the last player's actions stored in ```model.lastMovesList``` and the data in ```model.oldPitsList```
    ///
    /// Each replayed turn is animated and handled the same way as a real game by ```updateGameBoard(player:,name:)```. This causes the ```globalActions``` and ```messageGlobalActions``` to be populated implicitly. 
    private func replay() {
        let wait = SKAction.wait(forDuration: 4.5 * animationWait)
        messageGlobalActions.append(wait)
        
        for move in model.lastMovesList {
            //animationTimeCounter += 1
            globalActions.append(wait)
            handleReplay(of: move)
            _ = model.lastMovesList.popLast()
        }
        if model.winner != nil {
            messageGlobalActions.popLast()
            let congratulationMessage1 = messageNode.animateInfoNode(text: "Congratulations to", changeColorAction: changeMessageNodeBlue, duration: 1.5)
            messageGlobalActions.append(congratulationMessage1)
            let winnerPlayerAlias = actualModel.winnerTextArray[actualModel.winnerTextArray.endIndex - 1]
            let congratulationMessage2 = messageNode.animateInfoNode(text: winnerPlayerAlias, changeColorAction: changeMessageNodeBlue, duration: 1.5)
            messageGlobalActions.append(congratulationMessage2)
        }
        let finalMessageAction1 = messageNode.animateInfoNode(text: "Press Continue when finished", changeColorAction: nil)
        let finalMessageAction2 = messageNode.animateInfoNode(text: "Press Replay to watch again", changeColorAction: nil)
        messageGlobalActions.append(finalMessageAction2)
        messageGlobalActions.append(finalMessageAction1)
        
        boardNode.run(SKAction.sequence(globalActions))
        globalActions.removeAll()
        runMessageNodeActions()
    }
    
    private func handleReplay(of move: [Int : String])  {
        
        guard let player = move.keys.first,
              let name = move[player]
        else { return }
        
        updateGameBoard(player: player, name: name)
    }
    
    /// This implementation of ```processGameUpdate``` strips out the GameCenterHelper method calls and does not run the ```globalActions``` or ```messageGlobalActions``` because we are running them in ```replay()```. Otherwise, it is the same.
    ///
    /// This override preserves the original structure of checking ```model.lastPlayerBonusTurn``` before ```model.winner``` whereas the base class version has reorganized that logic.
    override func processGameUpdate(){
        
        if model.lastPlayerBonusTurn {
            successGenerator.notificationOccurred(.success)
            successGenerator.prepare()
        } else {
            feedbackGenerator.impactOccurred()
            feedbackGenerator.prepare()
            
            isSendingTurn = true
            
            if model.lastPlayerCaptured {
                successGenerator.notificationOccurred(.success)
                successGenerator.prepare()
                
            }
            
            if model.winner != nil {
                var nonClearingPlayer = 0
                if 0 == model.sum1 {
                    nonClearingPlayer = 2
                } else {
                    nonClearingPlayer = 1
                }
                
                animateClearingPlayerTakesAll(from: nonClearingPlayer)
                
            } else {
                
                if model.playerTurn == 1 {
                    model.gameData.turnNumber += 1
                }   
            }
        }
    }
    
}//EoC
