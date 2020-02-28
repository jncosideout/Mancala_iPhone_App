//
//  SettingsScene.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 1/18/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//

import GameKit
import SpriteKit

class SettingsScene: MenuScene_2 {
    
    private var backGroundAnimationToggle: ButtonNode!
    private var instructionsButton: ButtonNode!
    private var instructionsNode: InstructionsNode!
    private var creditsButton: ButtonNode!
    private var creditsNode: InstructionsNode!
    
    let sceneMargin: CGFloat = 40
    let instructionsFilePath = Bundle.main.resourcePath! + "/instructions.bundle/Instructions"
    let numInstructionPages = 7
    let creditsFilePath = Bundle.main.resourcePath! + "/credits.bundle/Credits"
    let numCreditsPages = 3

    // MARK: - Init
    
    override func didMove(to view: SKView) {
        setUpScene(in: view)
        backGroundAnimationToggle.looksEnabled = UserDefaults.allowGradientAnimations
        
        addObserverForPresentGame()
    }
    
    private func setUpScene(in view: SKView?) {
           
        guard viewWidth > 0 else {
            return
        }
        
        backgroundColor = .background
        GradientNode.makeLinearNode(with: self, view: view!, linearGradientColors: GradientNode.billiardFelt, animate: false)
        
        var runningYOffset = CGFloat(0.0)
        
        let buttonWidth: CGFloat = viewWidth / 3 - (sceneMargin * 2)
        let safeAreaTopInset = view?.window?.safeAreaInsets.top ?? 0
        let buttonSize = CGSize(width: buttonWidth, height: buttonWidth * 3 / 11)
        
        runningYOffset += safeAreaTopInset
        
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
            addChild(backGroundAnimationToggle)
        
        backButton = ButtonNode("Main Menu", size: buttonSize) {
            self.returnToMenu()
        }
        
        backButton.position = CGPoint(x: viewWidth - sceneMargin  - buttonSize.width, y: runningYOffset)
        addChild(backButton)
        
        let instructionsTexts = getContent(numPages: numInstructionPages, filePath: instructionsFilePath)
        
        instructionsButton = ButtonNode("How to play", size: buttonSize) {
            self.addInstructionsNode(to: view ?? SKView(), instructionsTexts)
            self.instructionsNode.isHidden = false
            self.instructionsNode.animatePopUpFadeIn()
        }
        
        instructionsButton.position = CGPoint(
             x: sceneMargin,
             y: viewHeight - safeAreaTopInset - sceneMargin / 2 - (buttonSize.height)
        )
        addChild(instructionsButton)
        
        let creditsTexts = getContent(numPages: numCreditsPages, filePath: creditsFilePath)
        creditsButton = ButtonNode("Credits", size: buttonSize) {
            self.addCreditsNode(to: view ?? SKView(), creditsTexts)
            self.creditsNode.isHidden = false
            self.creditsNode.animatePopUpFadeIn()
        }
        
        creditsButton.position = CGPoint(
             x: viewWidth - sceneMargin - buttonSize.width,
             y: viewHeight - safeAreaTopInset - sceneMargin / 2 - (buttonSize.height)
        )
        addChild(creditsButton)
        
    }
    
    func getContent(numPages: Int, filePath: String) -> [String]? {
        var contentArray = [String]()
        do {
            for i in 1...numPages {
                let content = try String(contentsOfFile: filePath + "\(i)" + ".txt", encoding: .utf8) as String
                contentArray.append(content)
            }
            return contentArray
        } catch {
            return nil
        }
    }
    
    func addInstructionsNode(to view: SKView, _ text: [String]?) {
        let width = viewWidth - sceneMargin
        let height = viewHeight - sceneMargin
        let size = CGSize(width: width, height: height)
        instructionsNode = InstructionsNode("Hello", size: size)
        instructionsNode.position = CGPoint(x: sceneMargin/2, y: sceneMargin/2)
        instructionsNode.zPosition = 50
        instructionsNode.alpha = 0
        instructionsNode.isHidden = true
        instructionsNode.instructions = text
        addChild(instructionsNode)
    }
    
    func addCreditsNode(to view: SKView, _ text: [String]?) {
        let width = viewWidth - sceneMargin
        let height = viewHeight - sceneMargin
        let size = CGSize(width: width, height: height)
        creditsNode = InstructionsNode("Hello", size: size)
        creditsNode.position = CGPoint(x: sceneMargin/2, y: sceneMargin/2)
        creditsNode.zPosition = 50
        creditsNode.alpha = 0
        creditsNode.isHidden = true
        creditsNode.instructions = text
        addChild(creditsNode)
    }
    
}//EoC
