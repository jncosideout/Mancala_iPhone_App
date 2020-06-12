///
///  MenuScene.swift
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


import GameKit
import SpriteKit
import UserNotifications
/**
 The forefront menu of the app. First to assume responsibility for the major dependencies injected by the GameViewController.
 */
class MenuScene: SKScene {
    
    // The feedbackGenerator creates the rumble feature when playing the game
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    var notificationsAuthorized = UserNotificationsHelper.allowMatchNotifications    
    
    var viewWidth: CGFloat {
        return view?.frame.size.width ?? 0
    }
    
    var viewHeight: CGFloat {
        return view?.frame.size.height ?? 0
    }
    
    private var versusHumanButton: ButtonNode!
    private var versusComputerButton: ButtonNode!
    private var onlineButton: ButtonNode!
    private var settingsButton: ButtonNode!
    var instructionsNode: InstructionsNode!
    let sceneMargin: CGFloat = 40
    var savedGameModels: [GameModel]!
    var backgroundImage = "Mancala-launch-"
    let firstTimeWalkthroughFilePath = Bundle.main.resourcePath! + "/firstTimeWalkthrough.bundle/firstTimeWalkthrough"
    let numPagesWalkthrough = 4
    var walkthroughText: [String]?
    var slideToShow = 0
    var didMoveToViewFirstTime = true
    // MARK: - Init
    
    
    /// Receives the saved [GameModel] from the ```GameViewController```
    /// - Parameter savedGames: The classes that interact with this one and which reference the injected [```GameModel```]  all expect that ```savedGames``` contains exactly 2 elements, and that the first element is the ```GameModel``` of "VS Computer" mode and the second element is the ```GameModel``` of "VS Human" or "2 Player Mode."
    convenience init(with savedGames: [GameModel]?) {
        self.init()
        if let allSavedGames = savedGames {
            savedGameModels = allSavedGames
             //OUTDATED: we break the dependency injection rule and use a singleton in order to save local games before launching an Online Game
            //SKScene.savedGameModels = allSavedGames
        } else {
            print("WARNING! savedGameModels in MenuScene is nil")
        }
    }
    
    /// After calling super.init(sizse:), get ```walkthroughText``` from the firstTimeWalkthrough.bundle
    ///
    /// + Important: You probably don't want to call this initializer directly or the saved games won't be loaded from disk
    override init() {
        super.init(size: .zero)
        scaleMode = .resizeFill
        walkthroughText = getContent(numPages: numPagesWalkthrough, filePath: firstTimeWalkthroughFilePath)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Call setUpScene(in:) and do additional configurations.
     
     Also adds notification observers.
     */
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        feedbackGenerator.prepare()
        // Destroy the last Online GKTurnBasedMatch
        GameCenterHelper.helper.currentMatch = nil
        
        if didMoveToViewFirstTime {
            // Add nodes to the scene
            setUpScene(in: view)
            // Register the scene to receive these types of notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(authenticationChanged(_:)),
                name: .authenticationChanged,
                object: nil)
        }
        didMoveToViewFirstTime = false
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        setUpScene(in: view)
    }
    
    /// Add all the nodes to this scene. Configure the buttons and their actions. Trigger instructionsNode animation if required.
    private func setUpScene(in view: SKView?) {
        guard viewWidth > 0 else {
            return
        }
        removeAllChildren()
        backgroundColor = .background
        
        var runningYOffset = CGFloat(0.0)
        
        let buttonWidth: CGFloat = viewWidth / 3 - (sceneMargin * 2)
        let safeAreaTopInset = view?.window?.safeAreaInsets.top ?? 0
        let buttonSize = CGSize(width: buttonWidth, height: buttonWidth * 3 / 11)
        
        settingsButton = ButtonNode(image: "settings-gear", size: buttonSize)
        {
            NotificationCenter.default.post(name: .presentSettings, object: nil)
        }
        let settingsY_Offset = viewHeight - safeAreaTopInset - buttonSize.height/2 - sceneMargin
        let settingsX_Offset = viewWidth - safeAreaTopInset  - buttonSize.width/2 - sceneMargin
        settingsButton.position = CGPoint(x: settingsX_Offset, y: settingsY_Offset)
        settingsButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(settingsButton)
        
        runningYOffset += safeAreaTopInset
        let logoNode = SKSpriteNode(imageNamed: "Mancala-logo")

        logoNode.size = CGSize(
            width: logoNode.size.width ,
            height: logoNode.size.height
        )
        logoNode.position = CGPoint(
            x: viewWidth / 2,
            y: viewHeight / 2
        )
        logoNode.zPosition = GameScene.NodeLayer.background.rawValue
        addChild(logoNode)
        
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
        
        //MARK: - Buttons
        versusHumanButton = ButtonNode("2 Player\nMode", size: buttonSize)
        {
            let setup = (vsComp: false, transition: GameViewController.Transitions.Up)
            NotificationCenter.default.post(name: .showMenuScene_2, object: setup)
        }
        
        versusComputerButton = ButtonNode("Versus\nComputer", size: buttonSize)
        {
            let setup = (vsComp: true, transition: GameViewController.Transitions.Up)
            NotificationCenter.default.post(name: .showMenuScene_2, object: setup)
        }
        
        onlineButton = ButtonNode("Online\nGame", size: buttonSize)
        {   
            // Ask for permission to send notifications
            UserNotificationsHelper.askForPermission()
            // Present the Game Center Matchmaker ViewController
            GameCenterHelper.helper.presentMatchMaker()
        }
        
        runningYOffset += (buttonSize.height / 2)
        versusHumanButton.position = CGPoint(x: sceneMargin, y: runningYOffset)
        versusHumanButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(versusHumanButton)
        
        versusComputerButton.position = CGPoint(x: viewWidth / 2 - buttonSize.width / 2, y: runningYOffset)
        versusComputerButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(versusComputerButton)
        
        onlineButton.isEnabled = GameCenterHelper.isAuthenticated
        onlineButton.position = CGPoint(x: viewWidth - sceneMargin  - buttonSize.width, y: runningYOffset)
        onlineButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(onlineButton)
        
        // On the first launch or after the user has reset this value directly via SettingsScene
         if !UserDefaults.hasLaunchedFirstTime {
            if let messages1 = walkthroughText {
                // dropLast(1) because we will show that instructions page on MenuScene_2
                let messages2: [String] = messages1.dropLast(1)
                addInstructionsNode(to: view ?? SKView(), messages2)
                instructionsNode.isHidden = false
                instructionsNode.animatePopUpFadeIn()
                fadeAllButtonsAlpha(to: 0.25)
            }
        }
    }

    /// Create and add the ```instructionsNode``` to this scene. Configure the animations for the firstTimeWalkthrough slides.
    func addInstructionsNode(to view: SKView, _ text: [String]) {
        let width = viewWidth - sceneMargin
        let height = viewHeight - sceneMargin
        let size = CGSize(width: width, height: height)
        
        instructionsNode = InstructionsNode("Hello", size: size, newInstructions: text) {
            self.instructionsNode.run(SKAction.sequence([
                // First fade out the InstructionsNode
                SKAction.fadeAlpha(to: 0, duration: 1),
                SKAction.run {
                    // Show the next slide
                    self.slideToShow += 1
                    if self.slideToShow < self.instructionsNode.instructions.count {
                        self.instructionsNode.plainText = self.instructionsNode.instructions[self.slideToShow]
                    } else {
                        // When we reach the last slide, remove the node and fade the buttons back in
                        self.instructionsNode.removeFromParent()
                        self.fadeAllButtonsAlpha(to: 1.0)
                        self.slideToShow = 0
                    }
                },
                // Always fade out the Instructions node
                SKAction.fadeAlpha(to: 1, duration: 1)
            ]))
        }
        
        instructionsNode.position = CGPoint(x: sceneMargin/2, y: sceneMargin/2)
        instructionsNode.zPosition = GameScene.NodeLayer.ui.rawValue
        instructionsNode.alpha = 1.0
        instructionsNode.isHidden = true
        addChild(instructionsNode)
    }
    
    /// Animate the buttons in this scene to fade. Initial purpose of this method was to unobstruct the view when ```instructionsNode``` is animated.
    func fadeAllButtonsAlpha(to value: CGFloat) {
        versusHumanButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        versusComputerButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        if GameCenterHelper.isAuthenticated {
            onlineButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        }
        settingsButton.run(SKAction.fadeAlpha(to: value, duration: 1))
    }
    
    //MARK: Notifications
    
    /// Selector function for authenticationChanged notification.
    @objc private func authenticationChanged(_ notification: Notification) {
        // When the firstTimeWalkthrough is being overlayed on the MenuScene, the "Online Game" button may stand out because the user was authenticated to Game Center in the background. So to keep it uniform, we need to check ```UserDefaults.hasLaunchedFirstTime```
        onlineButton.isEnabled = notification.object as? Bool ?? false
        if !UserDefaults.hasLaunchedFirstTime {
            onlineButton.looksEnabled = false
        }
        
    }
    
    
  
}//EoC
