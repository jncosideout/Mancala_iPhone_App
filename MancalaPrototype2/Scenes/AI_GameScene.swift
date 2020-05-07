///
///  AI_GameScene.swift
///  MancalaPrototype2
///
///  Created by Alexander Scott Beaty
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
 Derived class of GameScene that allows the GameplayKit AI to interact with the GameScene
 */
class AI_GameScene: GameScene {
    
    // MARK: - Properties
    var strategist: Strategist!
    var aiProcessingMeter: BackgroundNode!
    
    // MARK: - Init
    
    override init(model: GameModel) {
        super.init(model: model)
        self.model.vsAI = true
        thisGameType = .vsAI
        self.model.allPlayers = [model.mancalaPlayer1,model.mancalaPlayer2]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        strategist = Strategist(board: model)
        strategist.board = model
        
        if model.playerTurn == 2 {
            processAIMove()
        }
    }
    
    // MARK: - Setup
    
    /**
      Responsible for adding all child nodes to the scene, including game board and buttons.
      */
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
        let openingMessage = model.messageToDisplay
        messageNode = InformationNode(openingMessage, size: CGSize(width: messageNodeWidth, height: 40), named: messageNodeName)
        messageNode.zPosition = NodeLayer.ui.rawValue
        let messageNodeHeight = viewHeight - sceneMargin - 5
        messageNode.position = CGPoint(x: (viewWidth / 2) - messageNodeWidth / 2, y: messageNodeHeight)
        
        addChild(messageNode)
        
        setupColorChangeActions()
        
        aiProcessingMeter = BackgroundNode(kind: .pill, size: CGSize(width: viewWidth, height: 15), color: .blue)
        aiProcessingMeter.zPosition = NodeLayer.ui.rawValue
        aiProcessingMeter.position = CGPoint(x: (viewWidth / 2), y: messageNodeHeight - 5)
        
        addChild(aiProcessingMeter)
        
        //MARK: - Buttons
        let buttonSize = CGSize(width: 100, height: 50)
        let backButton = ButtonNode("Back", size: buttonSize)
        {   [weak self] in
            self?.returnToMenu()
        }
        
        backButton.position = CGPoint(
            x: sceneMargin / 3.0,
            y: viewHeight - safeAreaTopInset - sceneMargin / 2 - (buttonSize.height)
        )
        backButton.zPosition = NodeLayer.ui.rawValue
        
        addChild(backButton)
        
        let computerWindowSize = CGSize(width: 100, height: 35)
        let plyWinTopText = "Computer"
        let playerWindowTopRight = InformationNode(plyWinTopText, size: computerWindowSize, named: nil)
        playerWindowTopRight.position = CGPoint(
            x: viewWidth - sceneMargin / 3.0 - computerWindowSize.width,
            y: runningYOffset + boardSideLength / 4 - computerWindowSize.height / 2
        )
        playerWindowTopRight.zPosition = NodeLayer.ui.rawValue
        
        addChild(playerWindowTopRight)
        
        let playerWindowSize = CGSize(width: 75, height: 35)
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
    
    // MARK: - touches
    
    /**
    Used to filter for certain conditions before passing the UITouch and its location to ```handlePick(at:)```
    
    Place any code here to execute before the UITouch is used to find a game token and update pits
    */
    override func handleTouch(_ touch: UITouch) {
        // The AI is always player 2, so do not allow user interaction unless it is their turn
        guard model._activePlayer.playerId == 1 else { return }
        super.handleTouch(touch)
    }
    
    // MARK: - AI
    
    /**
     The AI runs its calculations on the global background queue. When it is finished the time taken to perform that task is used to animate the ```aiProcessingMeter``` to give the illution of thinking. Then on the main thread we schedule the AI player's move and update the board with it
     */
     fileprivate func processAIMove() {
        var aiMeterAction = SKAction()
        // The AI must be delayed for at least the amount of time taken to animate the human (player 1)'s move
        let animationDelay = animationTimeCounter * animationWait + 2 * animationWait
        print("in \(#function), called by board \(model) ")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + animationDelay) { [unowned self] in
            // Record the current time
            let strategistTime = CFAbsoluteTimeGetCurrent()
            print("in \(#function) DispatchQueue, called by board \(self.model) ")
            // Calculate the "bestChoice" which contains the AI's move
            guard let bestChoice = self.strategist.bestChoice else {
                return
            }
            // Calculate the time it took to find the bestChoice
            let delta = CFAbsoluteTimeGetCurrent() - strategistTime
            let aiTimeCeiling = 0.75
            let aiDelay = max(delta, aiTimeCeiling)
            
            let aiMessage = "Computer is thinking"
            self.messageNode.run(self.messageNode.animateInfoNode(text: aiMessage, changeColorAction: nil))
            // Animate the aiProcessingMeter
            aiMeterAction = self.aiProcessingMeter.growWidth(over: aiDelay)
            self.aiProcessingMeter.run(aiMeterAction)
            DispatchQueue.main.asyncAfter(deadline: .now() + aiDelay) {
                // Apply the move to the GameModel, animate the consequences of the 'bestChoice' move, update the GameModel and update the MessageNode (in otherwords, every responsibility that updateGameBoard() has normally
                self.updateGameBoard(player: bestChoice.player, name: bestChoice.pit)
                self.animationTimeCounter = 0
            }
        }
    }
    
    override func updateGameBoard(player: Int, name: String) {
        // Run updateGameBoard() regardless of which player it is
        super.updateGameBoard(player: player, name: name)
        // The AI (player 2) will use processAIMove() to call updateGameBoard(player:name:) recursively
        if model._activePlayer.player == 2 {
            processAIMove()
        }
    }    
}//EoC
