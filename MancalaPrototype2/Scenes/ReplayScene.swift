//
//  GameScene.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import SpriteKit

final class ReplayScene: GameScene {
    
    // MARK: - Properties
    
    private var actualModel: GameModel
    private var activePlayer: Bool
    
    // MARK: - Init
    
    init(model_: GameModel,_ activePlayer: Bool) {
        self.activePlayer = activePlayer
        actualModel = model_
        super.init(model: GameModel(replayWith: actualModel.gameData))
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
        let returnButton = ButtonNode("Continue", size: buttonSize) {
            if self.model.onlineGameOver {
                
                GameCenterHelper.helper.endMatch(self.actualModel, completion: { error in
                    defer {
                        self.isSendingTurn = false
                    }
                    
                    if let e = error {
                        print("Error ending turn: \(e.localizedDescription)")
                    }
                    
                })
                self.returnToMenu()
            } else {
                self.returnToGame()
            }
        }
        returnButton.position = CGPoint(
            x: sceneMargin / 3.0,
            y: viewHeight - safeAreaTopInset - sceneMargin / 2 - (buttonSize.height)
        )
        returnButton.zPosition = NodeLayer.ui.rawValue
        
        addChild(returnButton)
        
        let replayButton = ButtonNode("Replay", size: buttonSize) {
            self.model = GameModel(replayWith: self.actualModel.gameData)
            self.model.localPlayerNumber = self.actualModel.localPlayerNumber
            self.model.vsOnline = true
            self.allTokenNodes = CircularLinkedList<TokenNode>()
            self.removeAllChildren()
            self.setUpScene(in: view)
            self.replay()
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
    private func returnToGame() {
        actualModel.gameData.oldPitsList = actualModel.saveGameBoardToList(actualModel.pits)
        
        let gameScene = GameScene(model: actualModel)
        gameScene.thisGameType = .vsOnline

        view?.presentScene(gameScene, transition: SKTransition.push(with: .down, duration: 0.3))
    }
    override func returnToMenu() {
        actualModel.gameData.oldPitsList = actualModel.saveGameBoardToList(actualModel.pits)
        super.returnToMenu()
    }
    
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
