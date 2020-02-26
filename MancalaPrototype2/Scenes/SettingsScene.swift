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
    //private var newLocalButton: ButtonNode!

    
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
           
           let sceneMargin: CGFloat = 40
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
           
           backButton = ButtonNode("Main Menu", size: buttonSize) {
               self.returnToMenu()
           }
           
           runningYOffset += (buttonSize.height / 2)
           backGroundAnimationToggle.position = CGPoint(x: sceneMargin, y: runningYOffset)
           addChild(backGroundAnimationToggle)
   
           backButton.position = CGPoint(x: viewWidth - sceneMargin  - buttonSize.width, y: runningYOffset)
           addChild(backButton)
       }


}
