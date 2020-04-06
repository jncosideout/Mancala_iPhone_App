//
//  GameScene.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import SpriteKit

class AI_GameScene: GameScene {
    
    // MARK: - Properties
    var strategist: Strategist!
    var aiProcessingMeter: BackgroundNode!
    
    // MARK: - Init
    
    override init(model: GameModel) {
        super.init(model: model)
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
    
    override func setUpScene(in view: SKView?) {
        guard viewWidth > 0 else {
            return
        }
        
        backgroundColor = .background
        if UserDefaults.allowGradientAnimations {
            GradientNode.makeLinearNode(with: self, view: view!, linearGradientColors: GradientNode.sunsetPurples, animate: true)
            GradientNode.makeRadialNode(with: self, view: view!)
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
        let openingMessage = model.messagesToDisplay.first
        messageNode = InformationNode(openingMessage ?? "Welcome", size: CGSize(width: messageNodeWidth, height: 40), named: messageNodeName)
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
        let buttonSize = CGSize(width: 125, height: 50)
        let menuButton = ButtonNode("Menu", size: buttonSize) {
            self.returnToMenu()
        }
        menuButton.position = CGPoint(
            x: sceneMargin / 3.0,
            y: viewHeight - safeAreaTopInset - sceneMargin / 2 - (buttonSize.height)
        )
        menuButton.zPosition = NodeLayer.ui.rawValue
        
        addChild(menuButton)
        
        let playerWindowSize = CGSize(width: 75, height: 35)
        let plyWinTopText = "AI"
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
    
    // MARK: - touches
    override func handleTouch(_ touch: UITouch) {
        guard model._activePlayer.playerId == 1 else { return }
        super.handleTouch(touch)
    }
    
    // MARK: - AI
     fileprivate func processAIMove() {
        var aiMeterAction = SKAction()
        let animationDelay = animationTimeCounter * animationWait + 2 * animationWait
        print("in \(#function), called by board \(model) ")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + animationDelay) { [unowned self] in
            let strategistTime = CFAbsoluteTimeGetCurrent()
            print("in \(#function) DispatchQueue, called by board \(self.model) ")
            guard let bestChoice = self.strategist.bestChoice else {
                return
            }
            
            let delta = CFAbsoluteTimeGetCurrent() - strategistTime
            let aiTimeCeiling = 0.75
            let aiDelay = max(delta, aiTimeCeiling)
            
            let aiMessage = "AI is thinking"
            self.messageNode.run(self.messageNode.animateInfoNode(textArray: [aiMessage], changeColorAction: nil))
            aiMeterAction = self.aiProcessingMeter.growWidth(over: aiDelay)
            self.aiProcessingMeter.run(aiMeterAction)
            DispatchQueue.main.asyncAfter(deadline: .now() + aiDelay) {
            
                self.updateGameBoard(player: bestChoice.player, name: bestChoice.pit)
                self.animationTimeCounter = 0
            }
        }
    }
    
    override func updateGameBoard(player: Int, name: String) {
        super.updateGameBoard(player: player, name: name)
        if model._activePlayer.player == 2 {
            processAIMove()
        }
    }    
}//EoC
