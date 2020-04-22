///
///  SettingsScene.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 1/18/20.
/// ============LICENSE_START=======================================================
/// Copyright (c) 2018 Razeware LLC
/// Modification Copyright © 2020 Alexander Scott Beaty. All rights reserved.
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

class SettingsScene: MenuScene_2 {
    
    private var backGroundAnimationToggle: ButtonNode!
    private var instructionsButton: ButtonNode!
    private var creditsButton: ButtonNode!
    private var creditsNode: InstructionsNode!
    private var beadNumberToggle: ButtonNode!
    private var numberOfBeads = NumStartingBeads(rawValue: UserDefaults.numberOfStartingBeads)
    private var firstTimeWalkthroughToggle: ButtonNode!
    private var externalSettings: ButtonNode!

    let instructionsFilePath = Bundle.main.resourcePath! + "/instructions.bundle/Instructions"
    let numInstructionPages = 7
    let creditsFilePath = Bundle.main.resourcePath! + "/credits.bundle/Credits"
    let numCreditsPages = 3
    
    // MARK: - Init
    
    override func didMove(to view: SKView) {
        setUpScene(in: view)
        backGroundAnimationToggle.looksEnabled = UserDefaults.allowGradientAnimations
        
        addObserverForPresentGame()
        addObserverForPresentSettings()
    }
    
    private func setUpScene(in view: SKView?) {
           
        guard viewWidth > 0 else {
            return
        }
        //backgroundImage = "Mancala-billiard-felt-"

        backgroundColor = .background
        //GradientNode.makeLinearNode(with: self, view: view!, linearGradientColors: GradientNode.billiardFelt, animate: false)
        
        
        var runningYOffset = CGFloat(0.0)
        
        let buttonWidth: CGFloat = viewWidth / 3 - (sceneMargin * 2)
        let safeAreaTopInset = view?.window?.safeAreaInsets.top ?? 0
        let buttonSize = CGSize(width: buttonWidth, height: buttonWidth * 3 / 11)
        
        runningYOffset += safeAreaTopInset
        
//        let logoNode = loadBackgroundNode(viewWidth, viewHeight)
//
//        logoNode.size = CGSize(
//            width: logoNode.size.width ,
//            height: logoNode.size.height
//        )
//        logoNode.position = CGPoint(
//            x: viewWidth / 2,
//            y: viewHeight / 2
//        )
//        logoNode.zPosition = GameScene.NodeLayer.background.rawValue
//        addChild(logoNode)
//
        
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
        //MARK: - backGroundAnimationToggle
        backGroundAnimationToggle = ButtonNode("Background\nAnimations", size: buttonSize) {
             if UserDefaults.allowGradientAnimations {
                 self.backGroundAnimationToggle.looksEnabled = false
                 UserDefaults.set(allowGradientAnimations: false)
             } else {
                 self.backGroundAnimationToggle.looksEnabled = true
                 UserDefaults.set(allowGradientAnimations: true)
             }
        }
        
        runningYOffset += (buttonSize.height / 2)
        backGroundAnimationToggle.position = CGPoint(x: sceneMargin, y: runningYOffset)
        backGroundAnimationToggle.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(backGroundAnimationToggle)
        
        //MARK: - backButton
        backButton = ButtonNode("Main Menu", size: buttonSize) {
            self.returnToMenu()
        }
        
        backButton.position = CGPoint(x: viewWidth - sceneMargin  - buttonSize.width, y: runningYOffset)
        backButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(backButton)
        
        //MARK: - firstTimeWalkthroughToggle
        firstTimeWalkthroughToggle = ButtonNode("First time\nWalkthrough", size: buttonSize) {
             if UserDefaults.hasLaunchedFirstTime {
                 self.firstTimeWalkthroughToggle.looksEnabled = false
                 UserDefaults.set(hasLaunchedFirstTime: false)
                self.showAlert(withTitle: "Walkthrough activated", message: "Go back to Main Menu and choose \"2 Player\" or \"Versus Computer\" to see the walkthrough istructions.\nAfterward, you won't see them again until you press this button again")
             } else {
                 self.firstTimeWalkthroughToggle.looksEnabled = true
                 UserDefaults.set(hasLaunchedFirstTime: true)
             }
        }
        runningYOffset = viewHeight / 2 - (buttonSize.height / 2)
        firstTimeWalkthroughToggle.position = CGPoint(x: sceneMargin, y: runningYOffset)
        firstTimeWalkthroughToggle.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(firstTimeWalkthroughToggle)
        
        //MARK: - externalSettings button
        externalSettings = ButtonNode("External\nSettings", size: buttonSize) {
            self.showAlertWithSettings(withTitle: "Go to device's settings for Mancala World", message: "This action opens your device's settings menu for this app")
        }
        externalSettings.position = CGPoint(x: viewWidth - sceneMargin - buttonSize.width, y: runningYOffset)
        externalSettings.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(externalSettings)
        
        let instructionsTexts = getContent(numPages: numInstructionPages, filePath: instructionsFilePath)
        
        //MARK: - instructionsButton
        instructionsButton = ButtonNode("How to play", size: buttonSize) {
            self.addInstructionsNode(to: view ?? SKView(), instructionsTexts ?? [String]())
            self.instructionsNode.isHidden = false
            self.instructionsNode.animatePopUpFadeIn()
            self.fadeAllButtonsAlpha(to: 0.25)
        }
        
        instructionsButton.position = CGPoint(
             x: sceneMargin,
             y: viewHeight - safeAreaTopInset - sceneMargin / 2 - (buttonSize.height)
        )
        instructionsButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(instructionsButton)
        
        //MARK: - creditsButton
        let creditsTexts = getContent(numPages: numCreditsPages, filePath: creditsFilePath)
        creditsButton = ButtonNode("Credits", size: buttonSize) {
            self.addCreditsNode(to: view ?? SKView(), creditsTexts ?? [String]())
            self.creditsNode.isHidden = false
            self.creditsNode.animatePopUpFadeIn()
            self.fadeAllButtonsAlpha(to: 0.25)
        }
        
        creditsButton.position = CGPoint(
             x: viewWidth - sceneMargin - buttonSize.width,
             y: viewHeight - safeAreaTopInset - sceneMargin / 2 - (buttonSize.height)
        )
        creditsButton.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(creditsButton)
        
        //MARK: - beadNumberToggle
        var numBeadsString = String(numberOfBeads?.rawValue ?? 4)
        var beadToggleString = "Start with\n" + numBeadsString + " beads"
        beadNumberToggle = ButtonNode(beadToggleString, size: buttonSize) {
            switch self.numberOfBeads {
            case .four:
                if UserDefaults.unlockFiveBeadsStarting {
                    UserDefaults.set(numberOfStartingBeads: 5)
                } 
            case .five:
                if UserDefaults.unlockSixBeadsStarting {
                    UserDefaults.set(numberOfStartingBeads: 6)
                } else {
                    UserDefaults.set(numberOfStartingBeads: 4)
                }
            case .six:
                UserDefaults.set(numberOfStartingBeads: 4)
            default:
                print("numberOfBeads enum has no matching value")
            }
            self.numberOfBeads = NumStartingBeads(rawValue: UserDefaults.numberOfStartingBeads)
            numBeadsString = String(self.numberOfBeads?.rawValue ?? 4)
            beadToggleString = "Start with\n" + numBeadsString + " beads"
            self.beadNumberToggle.text = beadToggleString
        }
        beadNumberToggle.isHidden = !UserDefaults.unlockFiveBeadsStarting
        beadNumberToggle.position = CGPoint(
            x: viewWidth/2 - buttonSize.width/2,
            y: viewHeight - safeAreaTopInset - sceneMargin / 2 - buttonSize.height
        )
        beadNumberToggle.zPosition = GameScene.NodeLayer.ui.rawValue
        addChild(beadNumberToggle)
        
    }
    
    func addCreditsNode(to view: SKView, _ text: [String]) {
        let width = viewWidth - sceneMargin
        let height = viewHeight - sceneMargin
        let size = CGSize(width: width, height: height)
        creditsNode = InstructionsNode("Hello", size: size, newInstructions: text) {
            self.creditsNode.run(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0, duration: 1),
                    SKAction.run {
                        self.showSlide += 1
                        if self.showSlide < self.creditsNode.instructions.count {
                            self.creditsNode.plainText = self.creditsNode.instructions[self.showSlide]
                        } else {
                            self.creditsNode.removeFromParent()
                            self.fadeAllButtonsAlpha(to: 1.0)
                            self.showSlide = 0
                        }
                    },
                    SKAction.fadeAlpha(to: 1, duration: 1)
                ]))
        }
        creditsNode.position = CGPoint(x: sceneMargin/2, y: sceneMargin/2)
        creditsNode.zPosition = GameScene.NodeLayer.ui.rawValue
        creditsNode.alpha = 0
        creditsNode.isHidden = true
        addChild(creditsNode)
    }
        
    private enum NumStartingBeads: Int {
        case four = 4
        case five = 5
        case six = 6
    }
    
    override func fadeAllButtonsAlpha(to value: CGFloat) {
        backGroundAnimationToggle.run(SKAction.fadeAlpha(to: value, duration: 1))
        instructionsButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        creditsButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        beadNumberToggle.run(SKAction.fadeAlpha(to: value, duration: 1))
        firstTimeWalkthroughToggle.run(SKAction.fadeAlpha(to: value, duration: 1))
        backButton.run(SKAction.fadeAlpha(to: value, duration: 1))
        externalSettings.run(SKAction.fadeAlpha(to: value, duration: 1))
    }
}//EoC
