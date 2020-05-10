///
///  MenuScene_2.swift
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

import GameKit
import SpriteKit
import UserNotifications

/**
 Sub-menu for choosing a new game or continuing the saved game.
 
 + Important: Because this SKScene is used for both "VS Human" (2 Player mode) and "VS Computer" modes, the ```savedGameModels``` [GameModel] must contain exactly 2 elements, where the first element [0] is the ```GameData``` of "VS Computer" mode and the second element [1] is the ```GameData``` of "VS Human" or "2 Player Mode." Changing this will break things.
 */
class MenuScene_2: MenuScene {
    
    private var savedLocalButton: ButtonNode!
    private var newLocalButton: ButtonNode!
    var backButton: ButtonNode!
    var vsComputer: Bool
    private var gameTypeNode: InformationNode!
    // MARK: - Init
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     The primary init that must be used for this class, since the player always launches a "local" game via this SKScene and therefore it must have access to the saved local game data.
     */
    required convenience init(vsComp: Bool, with savedGames: [GameModel]?) {
        self.init()
        vsComputer = vsComp
        if let newSavedGames = savedGames {
            self.savedGameModels = newSavedGames
        } else {
            fatalError("warning! savedGamesStore in MenuScene_2 = nil")
        }
    }

    override init() {
        // Formality: must initialize all members first before super.init()
        vsComputer = false
        super.init()
    }
    
    /**
     Call setUpScene(in:) and do additional configurations.
     
     Also adds notification observers.
     */
    override func didMove(to view: SKView) {
        setUpScene(in: view)
    }
    
    /// Add all the nodes to this scene. Configure the buttons and their actions. Trigger instructionsNode animation if required.
    private func setUpScene(in view: SKView?) {
        removeAllChildren()
        guard viewWidth > 0 else {
            return
        }
        
        backgroundColor = .background
        
        var runningYOffset = CGFloat(0.0)
        
        let sceneMargin: CGFloat = 40
        let buttonWidth: CGFloat = viewWidth / 3 - (sceneMargin * 2)
        let safeAreaTopInset = view?.window?.safeAreaInsets.top ?? 0
        let buttonSize = CGSize(width: buttonWidth, height: buttonWidth * 3 / 11)
        
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
        
        let gameTypeText = vsComputer ? "Versus Computer" : "2 Player Mode"
        let gameTypeNSAString = NSAttributedString(string: gameTypeText,
                                              attributes: [
                                              .font : UIFont.systemFont(ofSize: 18, weight: .semibold)
                                              ])
        var stringSizeConstraint = CGSize(width: buttonWidth, height: buttonSize.height)
        let gameTypeNodeSize = gameTypeNSAString.boundingRect(with: stringSizeConstraint, options: [], context: nil)
        stringSizeConstraint = CGSize(width: gameTypeNodeSize.width, height: gameTypeNodeSize.height)
        stringSizeConstraint.width += sceneMargin
        stringSizeConstraint.height *= 1.5
        gameTypeNode = InformationNode(gameTypeText, size: stringSizeConstraint, named: nil)
        gameTypeNode.position = CGPoint(
            x: viewWidth / 2 - stringSizeConstraint.width / 2,
            y: viewHeight - stringSizeConstraint.height * 1.5
        )
        gameTypeNode.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(gameTypeNode)
        
        //MARK: - Buttons
        savedLocalButton = ButtonNode("Saved Game", size: buttonSize)
        {
            self.launchLocalGame()
        }
        
        newLocalButton = ButtonNode("New Game", size: buttonSize)
        {
            self.launchNewLocalGame()
        }
        
        backButton = ButtonNode("Main Menu", size: buttonSize)
        {
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
        
        // On the first launch or after the user has reset this value directly via SettingsScene
        if !UserDefaults.hasLaunchedFirstTime {
            if var messages1 = walkthroughText {
                // popLast(1) because we have shown the first 3 instructions pages on MenuScene before landing here, now we show the last, pertinent one
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
    
    /// Animate the buttons in this scene to fade. Initial purpose of this method was to unobstruct the view when ```instructionsNode``` is animated.
    override func fadeAllButtonsAlpha(to value: CGFloat) {
        savedLocalButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        newLocalButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        backButton.run(SKAction.fadeAlpha(to: value, duration: 1))
    }
    
    // MARK: - Helpers
    
    /**
     Loads and displays the MenuScene with
     */
    func returnToMenu() {
        NotificationCenter.default.post(name: .showMenuScene, object: nil)
    }
    
    /**
     Setup a new GameModel, overwrite the appropriate element of ```savedGameModels```, then display the appropriate GameScene
     */
    func launchNewLocalGame() {
        var newGame: GameModel
        let newGameData = GameData()
        if vsComputer {
            guard let vsCompGameModel = savedGameModels?[0] else { return }
            newGame = vsCompGameModel
            
        } else {
            guard let vsCompHumanModel = savedGameModels?[1] else { return }
            newGame = vsCompHumanModel
        }
        // Overwrite the GameModel
        newGame.gameData = newGameData
        newGame.resetGame()
        newGame.setUpGame(from: newGameData, copyPitsFromPitsList: true)
        
        launchLocalGame()
    }
    
    /**
     Display the appropriate GameScene
     */
    func launchLocalGame() {
        if vsComputer {
            NotificationCenter.default.post(name: .showAI_GameScene, object: nil)
        } else {
            NotificationCenter.default.post(name: .showGameScene, object: nil)
        }
    }
    
}//EoC
