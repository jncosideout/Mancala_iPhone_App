//
//  MenuScene.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import GameKit
import SpriteKit

class MenuScene: SKScene {
    
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
    var savedGameModels: [GameModel]!
    
    // MARK: - Init
    convenience init(with savedGames: [GameModel]?) {
        self.init()
        if let allSavedGames = savedGames {
            savedGameModels = allSavedGames
            SKScene.savedGameModels = allSavedGames
        } else {
            print("WARNING! savedGameModels in MenuScene is nil")
        }
    }
    
    override init() {
        super.init(size: .zero)
        scaleMode = .resizeFill
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
        GradientNode.makeLinearNode(with: self, view: view!, linearGradientColors: GradientNode.billiardFelt, animate: false)
        
        var runningYOffset = CGFloat(0.0)
        
        let sceneMargin: CGFloat = 40
        let buttonWidth: CGFloat = viewWidth / 3 - (sceneMargin * 2)
        let safeAreaTopInset = view?.window?.safeAreaInsets.top ?? 0
        let buttonSize = CGSize(width: buttonWidth, height: buttonWidth * 3 / 11)
        
        settingsButton = ButtonNode(image: "settings-gear", size: buttonSize) {
            self.view?.presentScene(SettingsScene(vsComp: false, with: self.savedGameModels), transition: SKScene.transition)
        }
        let settingsY_Offset = viewHeight - safeAreaTopInset - buttonSize.height/2 - sceneMargin
        let settingsX_Offset = viewWidth - safeAreaTopInset  - buttonSize.width/2 - sceneMargin
        settingsButton.position = CGPoint(x: settingsX_Offset, y: settingsY_Offset)
        addChild(settingsButton)
        
        runningYOffset += safeAreaTopInset
        
        let logoNode = SKSpriteNode(imageNamed: "Mancala-logo")
        let aspectRatio = logoNode.size.width / logoNode.size.height
        var adjustedGroundWidth = view?.bounds.width ?? logoNode.size.width
        adjustedGroundWidth *= 0.5
        logoNode.size = CGSize(
            width: adjustedGroundWidth,
            height: adjustedGroundWidth / aspectRatio
        )
        logoNode.position = CGPoint(
            x: viewWidth / 2,
            y: viewHeight / 2
        )
        addChild(logoNode)
        //MARK: - Buttons
        versusHumanButton = ButtonNode("Versus\nHuman", size: buttonSize) {
            self.view?.presentScene(MenuScene_2(vsComp: false, with: self.savedGameModels), transition: SKScene.transition)
        }
        
        versusComputerButton = ButtonNode("Versus\nComputer", size: buttonSize) {
            self.view?.presentScene(MenuScene_2(vsComp: true, with: self.savedGameModels), transition: SKScene.transition)
        }
        
        onlineButton = ButtonNode("Online\nGame", size: buttonSize) {
            UserNotificationsHelper.askForPermission()
            GameCenterHelper.helper.presentMatchMaker()
            SKScene.savedGameModels = self.savedGameModels
        }
        
        runningYOffset += (buttonSize.height / 2)
        versusHumanButton.position = CGPoint(x: sceneMargin, y: runningYOffset)
        addChild(versusHumanButton)
        
        versusComputerButton.position = CGPoint(x: viewWidth / 2 - buttonSize.width / 2, y: runningYOffset)
        addChild(versusComputerButton)
        
        onlineButton.isEnabled = GameCenterHelper.isAuthenticated
        onlineButton.position = CGPoint(x: viewWidth - sceneMargin  - buttonSize.width, y: runningYOffset)
        addChild(onlineButton)
    }

    //MARK: Notifications
    @objc private func authenticationChanged(_ notification: Notification) {
        onlineButton.isEnabled = notification.object as? Bool ?? false
    }
}//EoC
