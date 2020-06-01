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
 Main UI for playing the game. Interacts with the GameModel to present the gameboard to the user and update it, animate the the moves of the players, and accepts user input play the game and relay changes to the GameModel.
 
 Based on code from the tutorial found at https:www.raywenderlich.com/7544-game-center-for-ios-building-a-turn-based-game#
 By Ryan Ackerman
 */
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
    var model: GameModel!
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
    var thisGameType = GameType.vsHuman
    
    var animationTimer: Timer?
    var animationsFinished = true
    var lastActivePlayer = 0
    
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
    
    convenience init(model: GameModel) {
        self.init()
        self.model = model
    }
    
    override init() {
        super.init(size: .zero)
        
        scaleMode = .resizeFill
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Responsible for calling ```setUpScene``` and adding observers for notifications. Also runs "Game Over" message if user is returning to a saved game that has been finished.
     */
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        successGenerator.prepare()
        feedbackGenerator.prepare()
        
        setUpScene(in: view)
        
        setupGameOverMessageActions(false)
        if model.winner != nil {
            runMessageNodeActions()
        }
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        setUpScene(in: view)
    }
    
    // MARK: - Setup
    /**
     Responsible for adding all child nodes to the scene, including game board and buttons.
     */
    func setUpScene(in view: SKView?) {
        guard viewWidth > 0 else {
            return
        }
        removeAllChildren()
        backgroundColor = .background
        if UserDefaults.backgroundAnimationType != .none {
            if let setup = UserDefaults.backgroundAnimationType.getColorArrays() {
                if let linear_ = setup.linear {
                    GradientNode.makeLinearNode(with: self, view: view!, linearGradientColors: linear_, animate: true)
                } else {
                    GradientNode.makeLinearNode(with: self, view: view!, linearGradientColors: GradientNode.billiardFelt, animate: false)
                }
                GradientNode.makeRadialNode(with: self, view: view!, colors:  setup.radial)
            }
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
        
        //MARK: - Buttons
        let buttonSize = CGSize(width: 125, height: 50)
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
        
        let playerLabelSize = CGSize(width: 75, height: 35)
        
        let playerLabel_TopText = model.playerPerspective == 1 ? "P2" : "P1"
        var playerLabel_TopSize = getSizeConstraintsFor(string: playerLabel_TopText, minSize: playerLabelSize)
        playerLabel_TopSize.width *= 1.5
        playerLabel_TopSize.height *= 1.5

        let playerLabel_Top = InformationNode(playerLabel_TopText, size: playerLabel_TopSize, named: nil)
        
        // Use lineNodes of boardNode to place the "top" player label adjacent to the player2 mid-point lineNode
        var x: CGFloat
        var y: CGFloat
        var positionInScene: CGPoint?
        if let node = boardNode.player2LineNode, let parent = node.parent {
            positionInScene = node.scene?.convert(node.position, from: parent)
        }
        
        // Place playerLabel_Top just below the middle of the mid-lineNode on player 2's side of the board
        if let posInScene = positionInScene {
            y = posInScene.y - playerLabel_TopSize.height * 1.75 + 3 // + 3 because of lineWidth on lineNode
            x = posInScene.x - playerLabel_TopSize.width / 2
        } else {
            // Otherwise, place playerLabel_Top outside the top-left corner of the board
            y = runningYOffset + boardSideLength / 4
            x = sceneMargin / 2
        }
        
        playerLabel_Top.position = CGPoint(
            x: x,
            y: y
        )
        playerLabel_Top.zPosition = NodeLayer.background.rawValue
        
        addChild(playerLabel_Top)
        
        var playerLabel_BottomText = model.playerPerspective == 1 ? "P1" : "P2"
        if thisGameType == .vsOnline {
            playerLabel_BottomText = "You"
        }
        var playerLabel_BottomSize = getSizeConstraintsFor(string: playerLabel_BottomText, minSize: playerLabelSize)
        playerLabel_BottomSize.width *= 1.5
        playerLabel_BottomSize.height *= 1.5
        
        let playerLabel_Bottom = InformationNode(playerLabel_BottomText, size: playerLabel_BottomSize, named: nil)
        
        // Use lineNodes of boardNode to place playerLabel_Bottom adjacent to the player1 mid-point lineNode
        if let node = boardNode.player1LineNode, let parent = node.parent {
            positionInScene = node.scene?.convert(node.position, from: parent)
        }
        
        // Place playerLabel_Bottom just above the middle of the mid-lineNode on player 1's side of the board
        if let posInScene = positionInScene {
            y = posInScene.y + playerLabel_BottomSize.height * 0.75 - 3 // - 3 because of lineWidth on lineNode
            x = posInScene.x - playerLabel_BottomSize.width / 2
        } else {
            // Otherwise, place playerLabel_Bottom outside the bottom-right corner of the board
            y = runningYOffset - boardSideLength / 4 - playerLabelSize.height / 2
            x = viewWidth - sceneMargin - playerLabelSize.width
        }
        
        playerLabel_Bottom.position = CGPoint(
            x: x,
            y: y
        )
        playerLabel_Bottom.zPosition = NodeLayer.background.rawValue
        
        addChild(playerLabel_Bottom)
        
        loadTokens()
    }
    
    // MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { touch in
            handleTouch(touch)
        }
    }
    
    /**
     Used to filter for certain conditions before passing the UITouch and its location to ```handlePick(at:)```
     
     Place any code here to execute before the UITouch is used to find a game token and update pits
     */
    func handleTouch(_ touch: UITouch) {
        if thisGameType == .vsOnline {
            guard !isSendingTurn && GameCenterHelper.helper.canTakeTurnForCurrentMatch else {
                return
            }
        }
        
        guard model.winner == nil else {
            return
        }
        
        let location = touch.location(in: self)
        
        handlePick(at: location)
        
    }
    
    // MARK: - animation functions
    /**
     Handles animating pits on the board for an entire move.
     
     Must pass in board iterator from a MancalaPlayer
     pre-advanced to correct pit
     */
    func updatePitsFrom(_ tokenIterator: LinkedListIterator<TokenNode>, capture: Bool) {
        
        let inHand = animateTokens
        var actions = [SKAction]()
        var pitAction = SKAction()
        animationTimeCounter = 0
        var wrapAroundCapture = false
        
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
                
                if willOverlap && i <= overlapDifference {
                    let firstLap = i < allTokenNodes.length - 1
                    pitAction = tokenNode.animatePreviousBeads(firstLap, with: animationDuration)
                } else {
                    pitAction = tokenNode.animateCurrentValue(with: animationDuration)
                }
                
                capturelabel: if capture {
                    
                    guard let pre_captureFromPit = model._activePlayer.preCaptureFromPit else {
                        return
                    }
                    if i == inHand && token_pit == pre_captureFromPit {
                        //we only animate capturePit once (before animateAfterCapture())
                        break //exit while loop
                    }
                    
                    //If we're animating with beads fewer than required for a wrap-around, we skip animateBeforeCapture()
                    
                    if i == 0 {
                        var prevBeads = token_pit.mostRecentBeads
                        // Special Case: When a wrap-around capture ends where it starts, we need to check the starting pit's mostRecentBeads before the turn began
                        if pre_captureFromPit.mostRecentBeads == allTokenNodes.length - 1 {
                            prevBeads = pre_captureFromPit.mostRecentBeads
                        }
                        if prevBeads >= allTokenNodes.length / 2 + 1 {
                            wrapAroundCapture = true
                            break capturelabel
                        }
                    } else {
                        if !wrapAroundCapture {
                            break capturelabel
                        }
                    }
                    
                    //this is for animating the stealFrom pit or the base pit before stealing takes place in a wrap around capture
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
    
    /**
     Helper function used in updatePitsFrom(:capture) 
     
     During a capture, it's possible that the beads are sown wrapping around the board in a round-trip. In this scenario the pit that is captured from and the base pit of the capturing player will need to be animated twice, once for their value before the capture and once each after.
     */
    func animateBeforeCapture(_ tokenNode: TokenNode) -> (SKAction?) {
        
        var action: SKAction?
        
        guard let preStealPit = model._activePlayer.preStolenFromPit else {
            return nil
        }
        
        if tokenNode.pit == preStealPit  {
            action = tokenNode.animateMostRecent(with: animationDuration)
        }
        
        guard let basePit = model._activePlayer.basePitAfterCapture else {
            return nil
        }
        
        if tokenNode.pit == basePit {
            action = tokenNode.animateMostRecent(with: animationDuration)
        }
        
        return action
        
    }
    
    /**
     Helper function for ```updatePits(from:)``` to coordinate the capturing animation sequence
     */
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
        let captureFromPitAction3 = captureFromToken.animateCurrentValue(with: animationDuration)
        
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
    
    /**
     Coordinate the Clearing animation at the end of the game
     
     The game ends when one player clears their side. That player takes all the beads left on the other player's side and adds them to his base. This logic has already been triggered by the GameModel and this function animates the result of that.
     */
    func animateClearingPlayerTakesAll(from nonClearingPlayer: Int){
        let pit = PitNode(player: nonClearingPlayer, name: "1")
        var actions = [SKAction.wait(forDuration: 4 * animationWait)]
        var tokenIterator = findTokenNode(with: pit, in: allTokenNodes)
        
        for _ in 1...((allTokenNodes.length / 2) - 1) {
            
            if let nonClearingPlayerToken = *tokenIterator {
                guard let nodeName = nonClearingPlayerToken.name else {
                    fatalError("In " + #function + "could not get nodeName from nonClearingPlayerToken in")
                }
                let prevBeads = nonClearingPlayerToken.pit.mostRecentBeads
                
                if nonClearingPlayerToken.pit.player == nonClearingPlayer && nonClearingPlayerToken.pit.name != "BASE" && prevBeads != 0 {
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
        globalActions.append(SKAction.wait(forDuration: 2 * animationWait))
        globalActions.append(SKAction.sequence(actions))

    }
    
    /**
     These are initialized eary in setUpScene(in:) because it takes too much computation to generate them when they are needed each time.
     */
    func setupColorChangeActions() {
        changeMessageNodeRed = messageNode.getBackgroundAnimation(color: .red, duration: animationDuration * 2.5)
        changeMessageNodeGreen = messageNode.getBackgroundAnimation(color: .green, duration: animationDuration * 1.25)
        changeMessageNodeBlue = messageNode.getBackgroundAnimation(color: .blue, duration: animationDuration * 1.25)
    }
    
    // MARK: - Spawning
    /**
     Translates the pits in the gameboard of the model to their ```boardPointNodes``` on the ```boardNode```
     */
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
    
    /**
     Helper function for ```loadTokens``` which creates the TokenNodes, adds them to ```allTokenNodes``` and the ```boardNode```
     */
    private func spawnToken(at point: CGPoint, pit: PitNode) {
        let tokenNode = TokenNode(pit)
        
        tokenNode.zPosition = NodeLayer.token.rawValue
        tokenNode.position = point
        allTokenNodes.enqueue(tokenNode)
        
        boardNode.addChild(tokenNode)
    }
    
    // MARK: - Helpers
    /**
     Loads and displays the MenuScene (or MenuScene_2 depending on the context)
     */
    func returnToMenu() {
        switch thisGameType {
        case .vsHuman, .vsAI:
            let menuType = thisGameType == .vsAI
            let setup = (vsComp: menuType, transition: GameViewController.Transitions.Down)
            NotificationCenter.default.post(name: .showMenuScene_2, object: setup)
        case .vsOnline:
            NotificationCenter.default.post(name: .showMenuScene, object: nil)
        }
    }
    
    /**
     Uses a TokenNode to find the matching TokenNode in a CircularLinkedList of TokenNodes
     
     - Parameters:
         - tokenNode: the tokenNode to find whose pit matches a token in ```allTokens```
         - allTokens: the container of TokenNodes to search in, usually the ```allTokenNodes```  list of the GameScene
     */
    func findTokenNode(with tokenNode: TokenNode, in allTokens: CircularLinkedList<TokenNode>) -> LinkedListIterator<TokenNode> {
        let tempPit = tokenNode.pit
       
        return findTokenNode(with: tempPit, in: allTokens)
        
    }
    
    
    /// Uses a PitNode to find the matching TokenNode in a CircularLinkedList of TokenNodes
    /// - Parameters:
    ///   - pitNode: use this PitNode to find the TokenNode with the matching PitNode in ```allTokens```
    ///   - allTokens: the container of TokenNodes to search in, usually the ```allTokenNodes``` list of the GameScene
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
    
    /// Helper function for handleTouch(_:). Determines if the user touched on a TokenNode, and if so, kicks off gameplay for the active player
    /// - Parameter location: the location of the touch that has already been translated into the parent node's coordinate system. Assuming the GameScene.boardNode is the parent node, this will resolve into a pit on the game board. If not, nothing happens.
    private func handlePick(at location: CGPoint) {
        let node = atPoint(location)
        
        guard let nodeName = node.name,
            nodeName.contains(TokenNode.tokenNodeName),
            let tokenNode = node as? TokenNode
            else { return }
        
        if animationsFinished {
            let pit = tokenNode.pit
            updateGameBoard(player: pit.player, name: pit.name)
        }
    }
    
    func showConnectionError(_ error: String, completionBlock: (() -> Void)? = nil) {
        showAlert(withTitle: "Server Error", message: error, completion: completionBlock)
    }
    
    // MARK: - Game logic
    
    /// Exectutes a player's turn. All gameplay logic is activated in this method and the state of the board is animated after. Finally, the message to display to the player is determined based on the state of the GameModel and the rest of the gameplay logic is executed for this turn.
    ///
    /// In order to uncouple this method, the parameters have been set to reflect the data of the pit the player chose, instead of passing the pit directly to this method.
    /// - Parameters:
    ///   - player: the number of the player who's executing this turn (1 or 2)
    ///   - name: the name of the pit that was chosen by the player
    func updateGameBoard(player: Int, name: String) {
        lastActivePlayer = player
        let pit = PitNode(player: player, name: name)
        
        animateTokens  = model.playPhase1(pit.player, pit.name)
        
        if 0 < animateTokens{
            
            let tokenIterator = findTokenNode(with: pit, in: allTokenNodes)
            
            if model._activePlayer.captured <= 0 {//normal move, no capture
                
                
                //overlapping move
                if animateTokens >= allTokenNodes.length {
                    let fullLap = allTokenNodes.length - 1
                    overlapDifference = animateTokens - fullLap
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
            var message = String()
            var lastPlayerCaptured = false
            
            if model.hasBonusTurn || model.isCapturingPiece {
                message = model.messageToDisplay
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
                updateMessageNode(with: playerTurnText, changeColor: nil)
            } else {
                //either last player got bonus or captured
                updateMessageNode(with: message, changeColor: colorAction)
                if lastPlayerCaptured {
                    messageGlobalActions.append(messageNode.animateInfoNode(text: playerTurnText, changeColorAction: nil))
                    
                }
            }
            // Checks if there is a winner first, then...
            setupGameOverMessageActions(lastPlayerCaptured)
            processGameUpdate()
        }    
    }
    
    /// Updates the text of ```messageNode``` and animates it if necessary
    /// - Parameters:
    ///   - message: a custom message or the default stored in model.messageToDisplay
    ///   - changeColor: a prefabricated SKAction specifically created for the backgroundNode of the ```messageNode```
    func updateMessageNode(with message: String?, changeColor: SKAction?) {
        let messageActions: SKAction
        if let theMessage = message {
            messageActions = messageNode.animateInfoNode(text: theMessage, changeColorAction: changeColor)
        } else {
            messageActions = messageNode.animateInfoNode(text: model.messageToDisplay, changeColorAction: changeColor)
        }
        
        messageGlobalActions.append(SKAction.wait(forDuration: animationWait * animationTimeCounter))
        messageGlobalActions.append(messageActions)

    }
    
    /// Checks the state of the GameModel to determine what to do next and run the necessary animations
    ///
    /// 1. Checks for a winner, sets up the final animation, and sends the final turn (in an Online match)
    /// 2. Sets up impact generators. In an Online match, GameCenterHelper play passes to the next player
    /// 3. Runs all ```boardNode``` and ```messageNode``` actions
    func processGameUpdate(){
        
        if let _winner = model.winner {
            
            isSendingTurn = true
            //must not run animateClearingPlayerTakesAll(from:)
            //if game ends by capturing
            if !(model.sum1 == 0 && model.sum2 == 0) {
                var nonClearingPlayer = 0
                if 0 == model.sum1 {
                    nonClearingPlayer = 2
                } else {
                    nonClearingPlayer = 1
                }
                
                
                let winnerBasePit = PitNode(player: _winner, name: "BASE")
                let basePitIterator = findTokenNode(with: winnerBasePit, in: allTokenNodes)
                let basePitToken = *basePitIterator
                let basePit = basePitToken?.pit
                
                
                if let _basePit = basePit {
                    let prevBeads = _basePit.mostRecentBeads
                    if prevBeads < _basePit.beads {
                        animateClearingPlayerTakesAll(from: nonClearingPlayer)
                    }
                }
            }
            
            if thisGameType == .vsOnline {
                GameCenterHelper.helper.sendFinalTurn(model) { [weak self] error in
                    defer {
                        self?.isSendingTurn = false
                    }
                    if let e = error {
                        let errorMsg = e.localizedDescription
                        print("Error sendFinalTurn: \(errorMsg)")
                        self?.showConnectionError(errorMsg) {
                            self?.returnToMenu()
                        }
                    }
                    
                }
            }
        } else if model.hasBonusTurn {
            successGenerator.notificationOccurred(.success)
            successGenerator.prepare()
            if thisGameType == .vsOnline {
                GameCenterHelper.helper.updateButDontEndTurn(model) { [weak self] error in
                    defer {
                        self?.isSendingTurn = false
                    }
                    
                    if let e = error {
                        let errorMsg = e.localizedDescription
                        print("Error saving match data: \(errorMsg)")
                        self?.showConnectionError(errorMsg) {
                            self?.returnToMenu()
                        }
                    }
                }
            }
        } else {
            feedbackGenerator.impactOccurred()
            feedbackGenerator.prepare()
            
            isSendingTurn = true
            
            if model.lastPlayerCaptured {
                successGenerator.notificationOccurred(.success)
                successGenerator.prepare()
        
            }
              
            if model.playerTurn == 1 {
                model.gameData.turnNumber += 1
            }
            
            if thisGameType == .vsOnline {
                GameCenterHelper.helper.endTurn(model) { [weak self] error in
                    defer {
                        self?.isSendingTurn = false
                    }
                    
                    if let e = error {
                        let errorMsg = e.localizedDescription
                        print("Error ending turn: \(errorMsg)")
                        self?.showConnectionError(errorMsg) {
                            self?.returnToMenu()
                        }
                    }
                    
                }
            }
        }
        
        configureAndRunActions()
    }
    
    
    /// The actions are run after a timer has been set to keep the user from interacting with the game board before the animations have finished
    func configureAndRunActions() {
        animationsFinished = false
        var timerScheduledInterval = animationTimeCounter * animationWait
        
        //to wait for "Player captured X beads!" info text animation to end
        if model.lastPlayerCaptured, lastActivePlayer != model._activePlayer.player {
            timerScheduledInterval += 2
        }
        boardNode.run(SKAction.sequence(globalActions))
        globalActions.removeAll()
        runMessageNodeActions()
        
        //to wait for all animations to end before accepting more gameplay input
        animationTimer = Timer.scheduledTimer(withTimeInterval: timerScheduledInterval, repeats: false, block: { _ in
            self.animationsFinished = true
        })
    }
    
    func runMessageNodeActions() {
        messageNode.run(SKAction.sequence(messageGlobalActions))
        messageGlobalActions.removeAll()
    }  
    
    /// Checks for a winner and queues the game-over ```messageNode``` actions
    /// - Parameter lastPlayerCaptured: This may be obsolete. It was used to add a little extra waiting time before running the ```messageNode``` action sequence
    func setupGameOverMessageActions(_ lastPlayerCaptured: Bool) {
        if model.winner != nil {
            var infoActions = [SKAction]()
            for winText in model.winnerTextArray {
                infoActions.append(messageNode.animateInfoNode(text: winText, changeColorAction: changeMessageNodeBlue, duration: 1.5))
            }
            messageGlobalActions.append(contentsOf: infoActions)
        }
    }
}//EoC
