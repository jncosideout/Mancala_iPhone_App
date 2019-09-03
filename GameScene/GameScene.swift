//
//  GameScene.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import SpriteKit

final class GameScene: SKScene {
    // MARK: - Enums
    
    private enum NodeLayer: CGFloat {
        case background = 100
        case board = 101
        case token = 102
        case ui = 1000
    }
    
    // MARK: - Properties
    
    private var model: GameModel
    
    private var boardNode: BoardNode!
    private var messageNode: InformationNode!
    
    private var allTokenNodes = CircularLinkedList<TokenNode>()
    
    private let successGenerator = UINotificationFeedbackGenerator()
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private var animateTokens = 0
    private let animationDuration: TimeInterval = 0.4
    private let animationWait: TimeInterval = 0.45
    private var willOverlap = false
    private var overlapDifference = 0
    private var isSendingTurn = false
    
    // MARK: Computed
    
    private var viewWidth: CGFloat {
        return view?.frame.size.width ?? 0
    }
    
    private var viewHeight: CGFloat {
        return view?.frame.size.height ?? 0
    }
    
    // MARK: - Init
    
    init(model: GameModel) {
        self.model = model
        
        super.init(size: .zero)
        
        scaleMode = .resizeFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        successGenerator.prepare()
        feedbackGenerator.prepare()
        
        setUpScene(in: view)
        updateMessageNode(message: nil)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        setUpScene(in: view)
    }
    
    // MARK: - Setup
    
    private func setUpScene(in view: SKView?) {
        guard viewWidth > 0 else {
            return
        }
        
        backgroundColor = .background
        GradientNode.makeLinearNode(with: self, view: view!, linearGradientColors: GradientNode.sunsetPurples, animate: true)
        GradientNode.makeRadialNode(with: self, view: view!)
        
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
        
        let messageNodeWidth = viewWidth - (sceneMargin * 2)
        messageNode = InformationNode(model.messageToDisplay, size: CGSize(width: messageNodeWidth, height: 40))
        messageNode.zPosition = NodeLayer.ui.rawValue
//        let distFromTopToBoard = viewHeight - (runningYOffset + boardSideLength / 4)
        let messageNodeHeigth = viewHeight - sceneMargin - 5//distFromTopToBoard / 2 + (viewHeight - distFromTopToBoard)
        messageNode.position = CGPoint(x: (viewWidth / 2) - messageNodeWidth / 2, y: messageNodeHeigth)
        
        addChild(messageNode)
        
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
        
        loadTokens()
    }
    
    // MARK: - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { touch in
            handleTouch(touch)
        }
    }
    
    private func handleTouch(_ touch: UITouch) {
        guard !isSendingTurn && GameCenterHelper.helper.canTakeTurnForCurrentMatch else {
            return
        }
        
        guard model.winner == nil else {
            updateMessageNode(message: nil)
            return
        }
        
        let location = touch.location(in: self)
        
        handlePick(at: location)
        
    }
    
    // MARK: - animation functions
    /*
     must pass in board iterator from a MancalaPlayer
     pre-advanced to correct pit
     */
    func updatePitsFrom(_ tokenIterator: LinkedListIterator<TokenNode>, capture: Bool){
        
        let inHand = animateTokens
        var actions = [SKAction]()
        var pitAction = SKAction()
        
        
        var i = 0
        repeat {
            if let tokenNode = *tokenIterator {
                
                let token_pit = tokenNode.pit
                
                //skip opponent's base
                if token_pit.player != model.activePlayer.player && token_pit.name == "BASE" {
                    ++tokenIterator
                    continue
                }
                
                guard let nodeName = tokenNode.name else {
                    return
                }
                
                if willOverlap && i == 0 {
                    pitAction = tokenNode.animateSpecific(with: animationDuration, beads: 0)
                } else if willOverlap && i <= overlapDifference {
                    pitAction = tokenNode.animate(with: animationDuration, previous: true)
                } else {
                    pitAction = tokenNode.animate(with: animationDuration, previous: false)
                }
                
                capturelabel: if capture {
                    
                    guard let captureFromPit = model.activePlayer.preCaptureFromPit else {
                        return
                    }
                    if i == inHand && token_pit == captureFromPit {
                        //we only animate capturePit once (before animateAfterCapture())
                        break
                    }
                    
                    //If we're animating with beads less than a wrap around, we skip animateBeforeCapture()
                    if i == 0 && token_pit.previousBeads! < allTokenNodes.length / 2 + 1 {
                        break capturelabel
                    }
                    
                    //this is for animating the captureFrom pit, the stealFrom pit, or the base pit before stealing takes place in a wrap around capture
                    if let pitAction2 = animateBeforeCapture(tokenNode) {
                        pitAction = pitAction2
                    }
                }
                
                let sequence = SKAction.sequence([
                    SKAction.run(pitAction, onChildWithName: nodeName),
                    SKAction.wait(forDuration: animationWait)
                    ])
                
                actions.append(sequence)
                ++tokenIterator
                i += 1
            }//end if let
            
        } while i <= inHand //end while
        
        if capture {
            actions.append(animateAfterCapture(add:  actions))
        }
        boardNode.run(SKAction.sequence(actions))
        
        if willOverlap {
            willOverlap = false
        }
    }
    
    func animateBeforeCapture(_ tokenNode: TokenNode) -> (SKAction?) {
        
        var action: SKAction?
        
        guard let preStealPit = model.activePlayer.preStolenFromPit else {
            return nil
        }
        
        if tokenNode.pit == preStealPit  {
            action = tokenNode.animate(with: animationDuration, previous: true)
        }
        
        guard let basePit = model.activePlayer.basePitAfterCapture else {
            return nil
        }
        
        if tokenNode.pit == basePit {
            action = tokenNode.animate(with: animationDuration, previous: true)
        }
        
        return action
        
    }
    
    func animateAfterCapture(add actions: [SKAction]) -> SKAction {
        
        var sequence = SKAction()
        
        
        guard let captureFromPit = model.activePlayer.preCaptureFromPit else {
            return sequence
        }
        let captureFromIterator = findTokenNode(with: captureFromPit, in: allTokenNodes)
        guard let captureFromToken = *captureFromIterator else {
            return sequence
        }
        
        let captureFromPitAction2 = captureFromToken.animateHighlight(with: animationDuration, beads: 1)
        let captureFromPitAction3 = captureFromToken.animate(with: animationDuration, previous: false)
        
        guard let stealFromPit = model.activePlayer.preStolenFromPit else {
            return sequence
        }
        let stealIterator = findTokenNode(with: stealFromPit, in: allTokenNodes)
        guard let stealToken = *stealIterator else {
            return sequence
        }
        let stealAction = stealToken.animate(with: animationDuration, previous: false)
        
        guard let basePit = model.activePlayer.basePitAfterCapture else {
            return sequence
        }
        let baseIterator = findTokenNode(with: basePit, in: allTokenNodes)
        guard let baseToken = *baseIterator else {
            return sequence
        }
        let basePitAction = baseToken.animate(with: animationDuration, previous: false)
        
        
        guard let captureTokenName = captureFromToken.name, let stealTokenName = stealToken.name, let baseTokenName = baseToken.name else {
            return sequence
        }
        
        sequence = SKAction.sequence([
            SKAction.run(captureFromPitAction2, onChildWithName: captureTokenName),
            SKAction.wait(forDuration: animationWait * 1.15),
            SKAction.run(captureFromPitAction3, onChildWithName: captureTokenName),
            SKAction.wait(forDuration: animationWait),
            SKAction.run(stealAction, onChildWithName: stealTokenName),
            SKAction.wait(forDuration: animationWait),
            SKAction.run(basePitAction, onChildWithName: baseTokenName),
            SKAction.wait(forDuration: animationWait),
            ])
        
        return sequence
        
    }
    // MARK: - Spawning
    
    private func loadTokens() {
        
        let pitsIterator = model.pits.circIter
        var i = 1
        while i <= model.pits.length {
            if let pit = *pitsIterator {
                
                guard let boardPointNode = boardNode.node(at: pit.coord, named: BoardNode.boardPointNodeName) else {
                    return
                }
                
                spawnToken(at: boardPointNode.position, pit: pit)
                ++pitsIterator
                i += 1
            }
        }
    }
    
    private func spawnToken(at point: CGPoint, pit: PitNode) {
        let tokenNode = TokenNode(pit)
        
        tokenNode.zPosition = NodeLayer.token.rawValue
        tokenNode.position = point
        allTokenNodes.enqueue(tokenNode)
        
        boardNode.addChild(tokenNode)
    }
    
    // MARK: - Helpers
    
    private func returnToMenu() {
        view?.presentScene(MenuScene(with: model), transition: SKTransition.push(with: .down, duration: 0.3))
    }
    
    private func findTokenNode(with tokenNode: TokenNode, in allTokens: CircularLinkedList<TokenNode>) -> LinkedListIterator<TokenNode> {
        
        let tokenIterator = allTokens.circIter
        let tempPit = tokenNode.pit
        ++tokenIterator//move to "first" pit (player 1, pit #1)
        
        for _ in 1...allTokens.length {
            
            if let tempToken = *tokenIterator {
                
                if tempToken.pit == tempPit {
                    return tokenIterator
                } else {
                    ++tokenIterator
                }
            }
        }
        
        print("failed to find pit")
        return tokenIterator
        
    }
    
    private func findTokenNode(with pitNode: PitNode, in allTokens: CircularLinkedList<TokenNode>) -> LinkedListIterator<TokenNode> {
        
        let tokenIterator = allTokens.circIter
        ++tokenIterator//move to "first" pit (player 1, pit #1)
        
        for _ in 1...allTokens.length {
            
            if let tempToken = *tokenIterator {
                
                if tempToken.pit == pitNode {
                    return tokenIterator
                } else {
                    ++tokenIterator
                }
            }
        }
        
        print("failed to find pit")
        return tokenIterator
        
    }
    
    private func handlePick(at location: CGPoint) {
        let node = atPoint(location)
        
        guard let nodeName = node.name,
            nodeName.contains(TokenNode.tokenNodeName),
            let tokenNode = node as? TokenNode
            else { return }
        
        let pit = tokenNode.pit
        
        animateTokens  = model.playPhase1(pit.player, pit.name)
        
        if 0 < animateTokens{
            
            let tokenIterator = findTokenNode(with: tokenNode, in: allTokenNodes)
            
            if model.activePlayer.captured <= 0 {//normal move, no capture
                
                
                //overlapping move
                if animateTokens >= allTokenNodes.length {
                    overlapDifference = animateTokens - (allTokenNodes.length - 1)
                    willOverlap = true
                }
                updatePitsFrom(tokenIterator, capture: false)
                
                /*----- animate capture ---------*/
            } else {
                model.updateTokenNodes -= 1
                updatePitsFrom(tokenIterator, capture: true)
                
            }
            
            /*-------- finish turn -----------*/
            var printPlayerTurnText = false
            
            if model.hasBonusTurn || model.isCapturingPiece {
                updateMessageNode(message: nil)
            } else {
                printPlayerTurnText = true
            }
            
            let playerTurnOrWinnerResult = model.playPhase2()
            
            if printPlayerTurnText {
                updateMessageNode(message: playerTurnOrWinnerResult)
            }
            
            if model.winner != nil {
                messageNode.animateInfoNode(textArray: model.winnerTextArray, wait: 2)
            }
            
            processGameUpdate()
        }
    }
    
    private func updateMessageNode(message: String?) {
        
        if let theMessage = message {
            messageNode.text = theMessage
        } else {
            messageNode.text = model.messageToDisplay
        }
        
    }
    
    private func processGameUpdate(){
        
        if model.hasBonusTurn {
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
                GameCenterHelper.helper.win { error in
                    defer {
                        self.isSendingTurn = false
                    }
                    
                    if let e = error {
                        print("Error winning match: \(e.localizedDescription)")
                    }
                    
//                    self.returnToMenu()
                }
            } else {
                GameCenterHelper.helper.endTurn(model, completion: { error in
                    defer {
                        self.isSendingTurn = false
                    }
                    
                    if let e = error {
                        print("Error ending turn: \(e.localizedDescription)")
                    }
                    
//                    self.returnToMenu()
                })
            }
            
        }
    }
}//EoC
