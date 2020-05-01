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
    var thisGameType = GameType.vsHuman
    var savedGameModels: [GameModel]!
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
    /**
     Carries the GameModel array of saved games for "2 Player Mode" (VS Human) and "VS Computer" mode. Used for dependency injection from AppDelegate.
     
     The entire system operates on the assumption that savedGames[1] contains the "VS Human" saved game and savedGames[0] contains the "VS Computer" saved game.
     - Important: Do not use this initializer unless you have a loaded [GameModel] array to pass to it. Otherwise ```savedGameModels``` will be set nil
     */
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
    
    /**
     Responsible for calling ```setUpScene``` and adding observers for notifications. Also runs "Game Over" message if user is returning to a saved game that has been finished.
     */
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        successGenerator.prepare()
        feedbackGenerator.prepare()
        
        setUpScene(in: view)
        addObserverForPresentGame()
        addObserverForPresentSettings()
        
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
        
        var plyWinBottomText = model.playerPerspective == 1 ? "P1" : "P2"
        if thisGameType == .vsOnline {
            plyWinBottomText = "You"
        }
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
     Loads and displays the MenuScene with the ```savedGameModels```
      
     Either via keeping the dependency injection chain or retrieving from the appDelegate and reinjecting to MenuScene. This keeps the number of references to ```savedGameModels``` to only the shared instance in appDelegate or the one belonging to the current SKScene
     */
    func returnToMenu() {
        var menuScene = MenuScene()//ASB TEMP 1/31/20
        if let savedGames = savedGameModels {

            menuScene = MenuScene(with: savedGames)
        } else {
            if thisGameType == .vsOnline {
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                let allSavedGames = appDelegate?.savedGameModels
                menuScene = MenuScene(with: allSavedGames)
            } else {
                print("warning! returnToMenu from GameScene without savedGamesStore")
            }
        }
        
        view?.presentScene(menuScene, transition: SKTransition.push(with: .down, duration: 0.3))
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
            
            
            if let _basePit = basePit {
                let prevBeads = _basePit.mostRecentBeads
                if prevBeads < _basePit.beads {
                    animateClearingPlayerTakesAll(from: nonClearingPlayer)
                }
            }
            
            if thisGameType == .vsOnline {
                GameCenterHelper.helper.sendFinalTurn(model) { error in
                    defer {
                        self.isSendingTurn = false
                    }
                    if let e = error {
                        print("Error winning match: \(e.localizedDescription)")
                    }
                    
                }
            }
        }
        
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
