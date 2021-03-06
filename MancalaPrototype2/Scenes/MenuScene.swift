//
//  MenuScene.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import GameKit
import SpriteKit

class MenuScene: SKScene, Alertable {
    
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
    var gameViewController: UIViewController?
    var showSlide = 0

    // MARK: - Init
    convenience init(with savedGames: [GameModel]?) {
        self.init()
        if let allSavedGames = savedGames {
            savedGameModels = allSavedGames
             //we break the dependency injection rule and use a singleton in order to save local games before launching an Online Game
            SKScene.savedGameModels = allSavedGames
        } else {
            print("WARNING! savedGameModels in MenuScene is nil")
        }
    }
    
    override init() {
        super.init(size: .zero)
        scaleMode = .resizeFill
        walkthroughText = getContent(numPages: numPagesWalkthrough, filePath: firstTimeWalkthroughFilePath)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        feedbackGenerator.prepare()
        GameCenterHelper.helper.currentMatch = nil
        
        setUpScene(in: view)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(authenticationChanged(_:)),
            name: .authenticationChanged,
            object: nil)
        
        addObserverForPresentGame()
        addObserverForPresentSettings()
        
//        if !UserDefaults.hasLaunchedFirstTime {
////            if let message1 = walkthroughText {
////                showAlert(withTitle: "Connecting with friends", message: message1[2])
////                showAlert(withTitle: "Starting Online Games", message: message1[1])
////                showAlert(withTitle: "Welcome to Mancala World!", message: message1[0])
//            instructionsNode.isHidden = false
//            instructionsNode.animatePopUpFadeIn()
//            fadeAllButtonsAlpha(to: 0.25)
////            }
//        }
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        setUpScene(in: view)
    }
    
    private func setUpScene(in view: SKView?) {
        guard viewWidth > 0 else {
            return
        }
 
        backgroundColor = .background
        
        var runningYOffset = CGFloat(0.0)
        
        let buttonWidth: CGFloat = viewWidth / 3 - (sceneMargin * 2)
        let safeAreaTopInset = view?.window?.safeAreaInsets.top ?? 0
        let buttonSize = CGSize(width: buttonWidth, height: buttonWidth * 3 / 11)
        
        settingsButton = ButtonNode(image: "settings-gear", size: buttonSize) {
            self.view?.presentScene(SettingsScene(vsComp: false, with: self.savedGameModels), transition: SKScene.transition)
        }
        let settingsY_Offset = viewHeight - safeAreaTopInset - buttonSize.height/2 - sceneMargin
        let settingsX_Offset = viewWidth - safeAreaTopInset  - buttonSize.width/2 - sceneMargin
        settingsButton.position = CGPoint(x: settingsX_Offset, y: settingsY_Offset)
        settingsButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(settingsButton)
        
        runningYOffset += safeAreaTopInset
        let logoNode = SKSpriteNode(imageNamed: "Mancala-logo")
        //let aspectRatio = logoNode.size.width / logoNode.size.height
//        var adjustedGroundWidth = view?.bounds.width ?? logoNode.size.width
//        adjustedGroundWidth *= 0.5
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
        versusHumanButton = ButtonNode("2 Player\nMode", size: buttonSize) {
            self.view?.presentScene(MenuScene_2(vsComp: false, with: self.savedGameModels), transition: SKScene.transition)
        }
        
        versusComputerButton = ButtonNode("Versus\nComputer", size: buttonSize) {
            self.view?.presentScene(MenuScene_2(vsComp: true, with: self.savedGameModels), transition: SKScene.transition)
        }
        
        onlineButton = ButtonNode("Online\nGame", size: buttonSize) {
            UserNotificationsHelper.askForPermission()
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
        
         if !UserDefaults.hasLaunchedFirstTime {
            if let messages1 = walkthroughText {
                let messages2: [String] = messages1.dropLast(1)
                addInstructionsNode(to: view ?? SKView(), messages2)
                instructionsNode.isHidden = false
                instructionsNode.animatePopUpFadeIn()
                fadeAllButtonsAlpha(to: 0.25)
            }
        }
    }

    func addInstructionsNode(to view: SKView, _ text: [String]) {
        let width = viewWidth - sceneMargin
        let height = viewHeight - sceneMargin
        let size = CGSize(width: width, height: height)
        instructionsNode = InstructionsNode("Hello", size: size, newInstructions: text) {
            self.instructionsNode.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0, duration: 1),
                SKAction.run {
                    self.showSlide += 1
                    if self.showSlide < self.instructionsNode.instructions.count {
                        self.instructionsNode.plainText = self.instructionsNode.instructions[self.showSlide]
                    } else {
                        self.instructionsNode.removeFromParent()
                        self.fadeAllButtonsAlpha(to: 1.0)
                        self.showSlide = 0
                    }
                },
                SKAction.fadeAlpha(to: 1, duration: 1)
            ]))
        }
        instructionsNode.position = CGPoint(x: sceneMargin/2, y: sceneMargin/2)
        instructionsNode.zPosition = GameScene.NodeLayer.ui.rawValue
        instructionsNode.alpha = 1.0
        instructionsNode.isHidden = true
        addChild(instructionsNode)
    }
    
    func fadeAllButtonsAlpha(to value: CGFloat) {
        versusHumanButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        versusComputerButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        if GameCenterHelper.isAuthenticated {
            onlineButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        }
        settingsButton.run(SKAction.fadeAlpha(to: value, duration: 1))
    }
    //MARK: Notifications
    @objc private func authenticationChanged(_ notification: Notification) {
        if UserDefaults.hasLaunchedFirstTime {
            onlineButton.isEnabled = notification.object as? Bool ?? false
        }
    }
    
    let modelMap : [ String : Model ] = [
        "i386"       : .simulator,
        "x86_64"     : .simulator,
        "iPod1,1"    : .iPod1,
        "iPod2,1"    : .iPod2,
        "iPod3,1"    : .iPod3,
        "iPod4,1"    : .iPod4,
        "iPod5,1"    : .iPod5,
        "iPad2,1"    : .iPad2,
        "iPad2,2"    : .iPad2,
        "iPad2,3"    : .iPad2,
        "iPad2,4"    : .iPad2,
        "iPad2,5"    : .iPadMini1,
        "iPad2,6"    : .iPadMini1,
        "iPad2,7"    : .iPadMini1,
        "iPhone3,1"  : .iPhone4,
        "iPhone3,2"  : .iPhone4,
        "iPhone3,3"  : .iPhone4,
        "iPhone4,1"  : .iPhone4S,
        "iPhone5,1"  : .iPhone5,
        "iPhone5,2"  : .iPhone5,
        "iPhone5,3"  : .iPhone5C,
        "iPhone5,4"  : .iPhone5C,
        "iPad3,1"    : .iPad3,
        "iPad3,2"    : .iPad3,
        "iPad3,3"    : .iPad3,
        "iPad3,4"    : .iPad4,
        "iPad3,5"    : .iPad4,
        "iPad3,6"    : .iPad4,
        "iPhone6,1"  : .iPhone5S,
        "iPhone6,2"  : .iPhone5S,
        "iPad4,1"    : .iPadAir1,
        "iPad4,2"    : .iPadAir2,
        "iPad4,4"    : .iPadMini2,
        "iPad4,5"    : .iPadMini2,
        "iPad4,6"    : .iPadMini2,
        "iPad4,7"    : .iPadMini3,
        "iPad4,8"    : .iPadMini3,
        "iPad4,9"    : .iPadMini3,
        "iPad6,3"    : .iPadPro9_7,
        "iPad6,11"   : .iPadPro9_7,
        "iPad6,4"    : .iPadPro9_7_cell,
        "iPad6,12"   : .iPadPro9_7_cell,
        "iPad6,7"    : .iPadPro12_9,
        "iPad6,8"    : .iPadPro12_9_cell,
        "iPad7,3"    : .iPadPro10_5,
        "iPad7,4"    : .iPadPro10_5_cell,
        "iPhone7,1"  : .iPhone6plus,
        "iPhone7,2"  : .iPhone6,
        "iPhone8,1"  : .iPhone6S,
        "iPhone8,2"  : .iPhone6Splus,
        "iPhone8,4"  : .iPhoneSE,
        "iPhone9,1"  : .iPhone7,
        "iPhone9,2"  : .iPhone7plus,
        "iPhone9,3"  : .iPhone7,
        "iPhone9,4"  : .iPhone7plus,
        "iPhone10,1" : .iPhone8,
        "iPhone10,2" : .iPhone8plus,
        "iPhone10,3" : .iPhoneX,
        "iPhone10,4" : .iPhone8,
        "iPhone10,5" : .iPhone8plus,
        "iPhone10,6" : .iPhoneX,
        "iPhone11,2" : .iPhoneXS,
        "iPhone11,4" : .iPhoneXSmax,
        "iPhone11,6" : .iPhoneXSmax,
        "iPhone11,8" : .iPhoneXR,
        "iPhone12,1" : .iPhone11,
        "iPhone12,3" : .iPhone11Pro,
        "iPhone12,5" : .iPhone11ProMax
    ]
}//EoC
