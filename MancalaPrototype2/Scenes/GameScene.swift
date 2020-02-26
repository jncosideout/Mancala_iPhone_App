//
//  GameScene.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    // MARK: - Enums
    
    enum GameType: Int {
        case vsHuman
        case vsAI
        case vsOnline
    }
    
    enum NodeLayer: CGFloat {
        case background = 100
        case board = 101
        case token = 102
        case ui = 1000
    }
    
    // MARK: - Properties
    var model: GameModel
    var boardNode: BoardNode!
    var messageNode: InformationNode!
    
    var allTokenNodes = CircularLinkedList<TokenNode>()
    
    let successGenerator = UINotificationFeedbackGenerator()
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    var animateTokens = 0
    let animationDuration: TimeInterval = 0.4
    let animationWait: TimeInterval = 0.45
    var animationTimeCounter = 0.0
    var willOverlap = false
    var overlapDifference = 0
    var isSendingTurn = false
    var globalActions = [SKAction]()
    var messageGlobalActions = [SKAction]()
    var thisGameType = GameType.vsHuman//asb test 01/30/20
    var savedGameModels: [GameModel]!
    
    var changeMessageNodeRed = SKAction()
    var changeMessageNodeGreen = SKAction()
    var changeMessageNodeBlue = SKAction()
    
    // MARK: Computed
    
    var viewWidth: CGFloat {
        return view?.frame.size.width ?? 0
    }
    
    var viewHeight: CGFloat {
        return view?.frame.size.height ?? 0
    }
    
    // MARK: - Init
    convenience init(fromSavedGames: [GameModel]?, gameType: GameType) {
        let gameModel: GameModel
        if let savedGames = fromSavedGames {
            
            switch gameType {
            case .vsHuman:
                gameModel = savedGames[1]
            case .vsAI:
                gameModel = savedGames[0]
            //case .vsOnline:
                //gameModel = savedGames[2]
            default:
                gameModel = GameModel(newGame: true)
            }
        } else {
            gameModel = GameModel(newGame: true)
        }
        self.init(model: gameModel)
        savedGameModels = fromSavedGames
        thisGameType = gameType
    }
    
    
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
        addObserverForPresentGame()
        
        if model.winner != nil {
            messageNode.text = ""
            let infoActions = messageNode.animateInfoNode(textArray: model.winnerTextArray, changeColorAction: changeMessageNodeBlue, duration: 3.0)
            messageNode.run(infoActions)
        }
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        setUpScene(in: view)
    }
    
    // MARK: - Setup
    
    func setUpScene(in view: SKView?) {
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
        let messageNodeHeigth = viewHeight - sceneMargin - 5
        messageNode.position = CGPoint(x: (viewWidth / 2) - messageNodeWidth / 2, y: messageNodeHeigth)
        
        addChild(messageNode)
           
        setupColorChangeActions()
        
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
        let plyWinTopText = model.playerPerspective == 1 ? "P2" : "P1"
        let playerWindowTopRight = InformationNode(plyWinTopText, size: playerWindowSize, named: nil)
        playerWindowTopRight.position = CGPoint(
            x: viewWidth - sceneMargin / 3.0 - playerWindowSize.width,
            y: runningYOffset + boardSideLength / 4 - playerWindowSize.height / 2
        )
        playerWindowTopRight.zPosition = NodeLayer.ui.rawValue
        
        addChild(playerWindowTopRight)
        
        let plyWinBottomText = model.playerPerspective == 1 ? "P1" : "P2"
        let playerWindowBottomLeft = InformationNode(plyWinBottomText, size: playerWindowSize, named: nil)
        playerWindowBottomLeft.position = CGPoint(
            x: sceneMargin / 3.0,
            y: runningYOffset - boardSideLength / 4 - playerWindowSize.height / 2
        )
        playerWindowBottomLeft.zPosition = NodeLayer.ui.rawValue
        
        addChild(playerWindowBottomLeft)
        
        loadTokens()
    }
    
    // MARK: - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { touch in
            handleTouch(touch)
        }
    }
    
    func handleTouch(_ touch: UITouch) {
        
        if thisGameType == .vsOnline {
            guard !isSendingTurn && GameCenterHelper.helper.canTakeTurnForCurrentMatch else {
                return
            }
        }
        
        guard model.winner == nil else {
            updateMessageNode(with: nil, changeColor: changeMessageNodeBlue)
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
        animationTimeCounter = 0
        
        
        var i = 0
        repeat {
            if let tokenNode = *tokenIterator {
                
                let token_pit = tokenNode.pit
                
                //skip opponent's base
                if token_pit.player != model._activePlayer.player && token_pit.name == "BASE" {
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
                    
                    guard let captureFromPit = model._activePlayer.preCaptureFromPit else {
                        return
                    }
                    if i == inHand && token_pit == captureFromPit {
                        //we only animate capturePit once (before animateAfterCapture())
                        break
                    }
                    
                    //If we're animating with beads fewer than required for a wrap-around, we skip animateBeforeCapture()
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
            }//end if let tokenNode
            animationTimeCounter += 1.0
        } while i <= inHand //end while
        
        if capture {
            actions.append(animateAfterCapture(addTo: actions))
            animationTimeCounter += 6.0
        }
        
        globalActions.append(SKAction.sequence(actions))
        
        if willOverlap {
            willOverlap = false
        }
    }
    
    func animateBeforeCapture(_ tokenNode: TokenNode) -> (SKAction?) {
        
        var action: SKAction?
        
        guard let preStealPit = model._activePlayer.preStolenFromPit else {
            return nil
        }
        
        if tokenNode.pit == preStealPit  {
            action = tokenNode.animate(with: animationDuration, previous: true)
        }
        
        guard let basePit = model._activePlayer.basePitAfterCapture else {
            return nil
        }
        
        if tokenNode.pit == basePit {
            action = tokenNode.animate(with: animationDuration, previous: true)
        }
        
        return action
        
    }
    
    func animateAfterCapture(addTo actions: [SKAction]) -> SKAction {
        
        var sequence = SKAction()
        
        
        guard let captureFromPit = model._activePlayer.preCaptureFromPit else {
            return sequence
        }
        let captureFromIterator = findTokenNode(with: captureFromPit, in: allTokenNodes)
        guard let captureFromToken = *captureFromIterator else {
            return sequence
        }
        
        let captureFromPitAction2 = captureFromToken.animateHighlight(with: animationDuration, beads: 1)
        let captureFromPitAction3 = captureFromToken.animate(with: animationDuration, previous: false)
        
        guard let stealFromPit = model._activePlayer.preStolenFromPit else {
            return sequence
        }
        let stealIterator = findTokenNode(with: stealFromPit, in: allTokenNodes)
        guard let stealToken = *stealIterator else {
            return sequence
        }
        let stealAction = stealToken.animateThroughInterval(with: animationDuration, reverse: true)
        
        guard let basePit = model._activePlayer.basePitAfterCapture else {
            return sequence
        }
        let baseIterator = findTokenNode(with: basePit, in: allTokenNodes)
        guard let baseToken = *baseIterator else {
            return sequence
        }
        let basePitAction = baseToken.animateThroughInterval(with: animationDuration, reverse: false)
        
        
        guard let captureTokenName = captureFromToken.name, let stealTokenName = stealToken.name, let baseTokenName = baseToken.name else {
            return sequence
        }
        
        sequence = SKAction.sequence([
            SKAction.run(captureFromPitAction2, onChildWithName: captureTokenName),
            SKAction.wait(forDuration: animationWait * 1.3),
            SKAction.run(captureFromPitAction3, onChildWithName: captureTokenName),
            SKAction.wait(forDuration: animationWait),
            SKAction.run(stealAction, onChildWithName: stealTokenName),
            SKAction.wait(forDuration: animationWait * 2),
            SKAction.run(basePitAction, onChildWithName: baseTokenName)
            ])
        
        return sequence
        
    }
    
    func animateClearingPlayerTakesAll(from nonClearingPlayer: Int){
        let pit = PitNode(player: nonClearingPlayer, name: "1")
        var actions = [SKAction.wait(forDuration: 4 * animationWait)]
        var tokenIterator = findTokenNode(with: pit, in: allTokenNodes)
        
        for _ in 1...((allTokenNodes.length / 2) - 1) {
            
            if let nonClearingPlayerToken = *tokenIterator {
                guard let nodeName = nonClearingPlayerToken.name else {
                    return
                }
                
                if nonClearingPlayerToken.pit.player == nonClearingPlayer && nonClearingPlayerToken.pit.name != "BASE" && nonClearingPlayerToken.pit.previousBeads != 0 {
                    let clearingAction = nonClearingPlayerToken.animateThroughInterval(with: animationDuration, reverse: true)
                    actions.append(SKAction.run(clearingAction, onChildWithName: nodeName))
                    actions.append(SKAction.wait(forDuration: animationWait))
                }
            }
            ++tokenIterator
        }
        
        let clearingPlayer = nonClearingPlayer == 1 ? 2 : 1
        pit.player = clearingPlayer
        pit.name = "BASE"
        
        tokenIterator = findTokenNode(with: pit, in: allTokenNodes)
        if let clearingPlayerBase = *tokenIterator {
        
            guard let nodeName = clearingPlayerBase.name else {
                return
            }
            let fillClearingPlayerBase = clearingPlayerBase.animateThroughInterval(with: animationDuration, reverse: false)
            actions.append(SKAction.wait(forDuration: 2 * animationWait))
            actions.append(SKAction.run(fillClearingPlayerBase, onChildWithName: nodeName))
        }
        
        globalActions.append(SKAction.sequence(actions))

    }
    
    // MARK: - Spawning
    
    func loadTokens() {
        
        let pitsIterator = model.pits.circIter
        var i = 1
        while i <= model.pits.length {
            if let pit = *pitsIterator {
                
                guard let boardPointNode = boardNode.node(
                    at: model.playerPerspective == 1 ? pit.coordP1 : pit.coordP2,
                        named: BoardNode.boardPointNodeName)
                else { return }
                
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
    
    func setupColorChangeActions() {
        changeMessageNodeRed = messageNode.getBackgroundAnimation(color: .red, duration: animationDuration * 2.5)
        changeMessageNodeGreen = messageNode.getBackgroundAnimation(color: .green, duration: animationDuration * 2.5)
        changeMessageNodeBlue = messageNode.getBackgroundAnimation(color: .blue, duration: animationDuration * 2.5)
    }
    
    func returnToMenu() {
        var menuScene = MenuScene()//ASB TEMP 1/31/20
        if let savedGames = savedGameModels {

            menuScene = MenuScene(with: savedGames)
        } else {
            if thisGameType == .vsOnline {
                let savedGameStore = SavedGameStore()
                let allSavedGames = savedGameStore.setupSavedGames()
                SKScene.savedGameModels = allSavedGames
                menuScene = MenuScene(with: allSavedGames)
            } else {
                print("warning! returnToMenu from GameScene without savedGamesStore")
            }
        }
        
        view?.presentScene(menuScene, transition: SKTransition.push(with: .down, duration: 0.3))
    }
    
    func findTokenNode(with tokenNode: TokenNode, in allTokens: CircularLinkedList<TokenNode>) -> LinkedListIterator<TokenNode> {
        
        let tempPit = tokenNode.pit
       
        return findTokenNode(with: tempPit, in: allTokens)
        
    }
    
    func findTokenNode(with pitNode: PitNode, in allTokens: CircularLinkedList<TokenNode>) -> LinkedListIterator<TokenNode> {
        
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
        updateGameBoard(player: pit.player, name: pit.name)
    }
    
    func updateGameBoard(player: Int, name: String) {
        let pit = PitNode(player: player, name: name)
        
        animateTokens  = model.playPhase1(pit.player, pit.name)
        
        if 0 < animateTokens{
            
            let tokenIterator = findTokenNode(with: pit, in: allTokenNodes)
            
            if model._activePlayer.captured <= 0 {//normal move, no capture
                
                
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
            var colorAction = SKAction()
            var messages = [String]()
            var lastPlayerCaptured = false
            
            if model.hasBonusTurn || model.isCapturingPiece {
                messages.append(model.messagesToDisplay.first!)
                if model.hasBonusTurn {
                    colorAction = changeMessageNodeGreen
                } else {
                    lastPlayerCaptured = true
                    colorAction = changeMessageNodeRed
                }
            } else {
                printPlayerTurnText = true
            }
            
            let playerTurnText = model.playPhase2()
            
            if printPlayerTurnText {
                //regular turn
                updateMessageNode(with: [playerTurnText], changeColor: nil)
            } else {
                //either last player got bonus or captured
                updateMessageNode(with: messages, changeColor: colorAction)
                if lastPlayerCaptured {
                    messageGlobalActions.append(messageNode.animateInfoNode(textArray: [playerTurnText], changeColorAction: nil))
                    
                }
            }
            
            if model.winner != nil {
                messageNode.text = ""
                let infoActions = messageNode.animateInfoNode(textArray: model.winnerTextArray, changeColorAction: changeMessageNodeBlue, duration: 3.0)
                if !lastPlayerCaptured {
                    messageGlobalActions.append(SKAction.wait(forDuration: animationWait * animationTimeCounter))
                }
                messageGlobalActions.append(infoActions)
            }
            
            processGameUpdate()
        }    
    }
    
    func updateMessageNode(with messages: [String]?, changeColor: SKAction?) {
        let messageActions: SKAction
        if let theMessages = messages {
            //messageNode.text = theMessage
            messageActions = messageNode.animateInfoNode(textArray: theMessages, changeColorAction: changeColor)
        } else {
            //messageNode.text = model.messagesToDisplay
            messageActions = messageNode.animateInfoNode(textArray: model.messagesToDisplay, changeColorAction: changeColor)
        }
        
        messageGlobalActions.append(SKAction.wait(forDuration: animationWait * animationTimeCounter))
        messageGlobalActions.append(messageActions)

    }
    
    func processGameUpdate(){
        
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
            
            if let _winner = model.winner {
                var nonClearingPlayer = 0
                if 0 == model.sum1 {
                    nonClearingPlayer = 2
                } else {
                    nonClearingPlayer = 1
                }
                
                //must not run animateClearingPlayerTakesAll(from:)
                //if game ends by capturing
                let winnerBasePit = PitNode(player: _winner, name: "BASE")
                let basePitIterator = findTokenNode(with: winnerBasePit, in: allTokenNodes)
                let basePitToken = *basePitIterator
                let basePit = basePitToken?.pit
                
                if let _basePit = basePit, let prevBeads = _basePit.previousBeads,
                    prevBeads < _basePit.beads {
                    animateClearingPlayerTakesAll(from: nonClearingPlayer)
                }
                
                if thisGameType == .vsOnline {
                    GameCenterHelper.helper.win(model) { error in
                        defer {
                            self.isSendingTurn = false
                        }
                        
                        if let e = error {
                            print("Error winning match: \(e.localizedDescription)")
                        }
                        
                    }
                }
            } else {
                
                if model.playerTurn == 1 {
                    model.gameData.turnNumber += 1
                }
                
                if thisGameType == .vsOnline {
                    GameCenterHelper.helper.endTurn(model, completion: { error in
                        defer {
                            self.isSendingTurn = false
                        }
                        
                        if let e = error {
                            print("Error ending turn: \(e.localizedDescription)")
                        }
                        
                    })
                }
            }
            
        }

        boardNode.run(SKAction.sequence(globalActions))
        messageNode.run(SKAction.sequence(messageGlobalActions))
        globalActions.removeAll()
        messageGlobalActions.removeAll()
    }
}//EoC
