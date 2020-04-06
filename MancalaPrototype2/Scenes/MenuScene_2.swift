//
//  MenuScene.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import GameKit
import SpriteKit

class MenuScene_2: MenuScene {
    
    private var savedLocalButton: ButtonNode!
    private var newLocalButton: ButtonNode!
    var backButton: ButtonNode!
    private var vsComputer: Bool
    
    // MARK: - Init
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(vsComp: Bool, with savedGames: [GameModel]?) {
        self.init()
        vsComputer = vsComp
        if let newSavedGames = savedGames {
            self.savedGameModels = newSavedGames
        } else {
            print("warning! savedGamesStore in MenuScene_2 = nil")
        }
    }

    override init() {
        vsComputer = false
        super.init()
    }
    override func didMove(to view: SKView) {
        setUpScene(in: view)
        addObserverForPresentGame()
        addObserverForPresentSettings()
    }
    
    private func setUpScene(in view: SKView?) {
        guard viewWidth > 0 else {
            return
        }
        
        backgroundColor = .background
        //GradientNode.makeLinearNode(with: self, view: view!, linearGradientColors: GradientNode.billiardFelt, animate: false)
        
        var runningYOffset = CGFloat(0.0)
        
        let sceneMargin: CGFloat = 40
        let buttonWidth: CGFloat = viewWidth / 3 - (sceneMargin * 2)
        let safeAreaTopInset = view?.window?.safeAreaInsets.top ?? 0
        let buttonSize = CGSize(width: buttonWidth, height: buttonWidth * 3 / 11)
        
        runningYOffset += safeAreaTopInset
        
        //let logoNode = loadBackgroundNode(viewWidth, viewHeight)
        let logoNode = SKSpriteNode(imageNamed: "Mancala-logo")
        logoNode.size = CGSize(
            width: logoNode.size.width ,
            height: logoNode.size.height
        )
//        logoNode.size = CGSize(
//            width: adjustedGroundWidth,
//            height: adjustedGroundWidth / aspectRatio
//        )
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
        savedLocalButton = ButtonNode("Saved Game", size: buttonSize) {
            if self.vsComputer {

                self.view?.presentScene(AI_GameScene(fromSavedGames: self.savedGameModels, gameType: .vsAI), transition: SKScene.self.transition)
            } else {

                self.view?.presentScene(GameScene(fromSavedGames: self.savedGameModels, gameType: .vsHuman), transition: SKScene.self.transition)
            }
        }
        
        newLocalButton = ButtonNode("New Game", size: buttonSize) {
            var newGame: GameModel
            let newGameData = GameData()
            if self.vsComputer {
                
                newGame = self.savedGameModels[0]
                newGame.gameData = newGameData
                newGame.resetGame()
                newGame.setUpGame(from: newGameData)
                
                self.view?.presentScene(AI_GameScene(fromSavedGames: self.savedGameModels, gameType: .vsAI), transition: SKScene.transition)
            } else {
                
                newGame = self.savedGameModels[1]
                newGame.gameData = newGameData
                newGame.resetGame()
                newGame.setUpGame(from: newGameData)
                
                self.view?.presentScene(GameScene(fromSavedGames: self.savedGameModels, gameType: .vsHuman), transition: SKScene.transition)
            }
        }
        
        backButton = ButtonNode("Main Menu", size: buttonSize) {
            self.returnToMenu()
        }
        
        runningYOffset += (buttonSize.height / 2)
        savedLocalButton.position = CGPoint(x: sceneMargin, y: runningYOffset)
        savedLocalButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(savedLocalButton)
        
        newLocalButton.position = CGPoint(x: viewWidth / 2 - buttonSize.width / 2, y: runningYOffset)
        newLocalButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(newLocalButton)
        
        backButton.position = CGPoint(x: viewWidth - sceneMargin  - buttonSize.width, y: runningYOffset)
        backButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(backButton)
        
        if !UserDefaults.hasLaunchedFirstTime {
            if var messages1 = walkthroughText {
                if let messages2 = messages1.popLast() {
                    addInstructionsNode(to: view ?? SKView(), [messages2])
                    instructionsNode.isHidden = false
                    instructionsNode.animatePopUpFadeIn()
                    fadeAllButtonsAlpha(to: 0.25)
                    UserDefaults.set(hasLaunchedFirstTime: true)
                }
            }
        }
    }

    override func fadeAllButtonsAlpha(to value: CGFloat) {
        savedLocalButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        newLocalButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        backButton.run(SKAction.fadeAlpha(to: value, duration: 1))
    }
    
    // MARK: - Helpers
    
    func returnToMenu() {
        let menuScene: MenuScene
        if let savedGames = savedGameModels {
            menuScene = MenuScene(with: savedGames)
        } else {
            menuScene = MenuScene()//ASB TEMP 1/31/20
            print("warning! returnToMenu from MenuScene_2 without savedGamesStore")
        }
        
        view?.presentScene(menuScene, transition: SKTransition.push(with: .down, duration: 0.3))
    }
    
}//EoC
