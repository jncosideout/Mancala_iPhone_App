///
///  GameViewController.swift
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

import UIKit
import SpriteKit

/**
 The root view controller. First point for dependency injections coming from ```appDelegate```. Uses Notification Observer/Selector pattern to centralize dispatch of SKScenes.

 Initializes the view hierarchy to use SKScenes from this point on. Sets up ```GameCenterHelper```
 */
final class GameViewController: UIViewController {
    
    var savedGameModels: [GameModel]!
    var matchHistory: MatchHistory!
    
    // These SKScenes will be presented when a notification is reaceived
    var menuScene: MenuScene!
        
    lazy var menuScene_2: MenuScene_2 = {
        let menuSc_2 = MenuScene_2(vsComp: false, with: savedGameModels)
        return menuSc_2
    }()
    
    var vsHumanGameScene: GameScene {
        let vsHumanGS = GameScene(model: savedGameModels[1])
        vsHumanGS.thisGameType = .vsHuman
        return vsHumanGS
    }
    
    var ai_gameScene: AI_GameScene {
        let ai_GS = AI_GameScene(model: savedGameModels[0])
        ai_GS.thisGameType = .vsAI
        return ai_GS
    }

    
    // Make sure our view is recognized as an SKView
    var skView: SKView {
        return view as! SKView
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func loadView() {
        view = SKView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register notification observers
        addObserverForShowMenuScene()
        addObserverForShowMenuScene_2()
        addObserverForShowGameScene()
        addObserverForShowAI_GameScene()
        // Declared in GameViewControllerExtension.swift
        addObserverForPresentGame()
        addObserverForPresentSettings()
        addObserverForContinueOnlineGame()
        
        // Initialize the SKScenes
        menuScene = MenuScene()

        // present the main MenuScene
        skView.presentScene(menuScene)
        // Set up the GameCenterHelper singleton
        GameCenterHelper.helper.viewController = self
        GameCenterHelper.helper.matchHistory = self.matchHistory
    }
    
    //MARK: - Notifications
    
    /// Selector function for ```showMenuScene``` notification.
    @objc private func showMenuScene(_ notification: Notification) {
        if let didMoveToViewFirstTime = notification.object as? Bool {
            // If this notification was triggered in the SettingsScene.firstTimeWalkthroughToggle, we must reset didMoveToViewFirstTime
            menuScene.didMoveToViewFirstTime = didMoveToViewFirstTime
        }
        skView.presentScene(menuScene, transition: Transitions.Down.getValue())
    }

    /// Registers the GameViewController to receive ```showMenuScene```  notifications
    func addObserverForShowMenuScene() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showMenuScene(_:)),
            name: .showMenuScene,
            object: nil)
    }
    
    /// Selector function for ```showMenuScene_2``` notification.
    @objc private func showMenuScene_2(_ notification: Notification) {
        let setup = notification.object as? (vsComp: Bool, transition: Transitions) ?? (vsComp: true, transition: Transitions.Up)
        menuScene_2.vsComputer = setup.vsComp
        skView.presentScene(menuScene_2, transition: setup.transition.getValue())
    }
    
    /// Registers the GameViewController to receive ```showMenuScene_2```  notifications
    func addObserverForShowMenuScene_2() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showMenuScene_2(_:)),
            name: .showMenuScene_2,
            object: nil)
    }

    /// Selector function for ```showGameScene``` notification.
    @objc private func showGameScene(_ notification: Notification) {
        if UserDefaults.backgroundAnimationType != .none {
            skView.presentScene(vsHumanGameScene)
        } else {
            skView.presentScene(vsHumanGameScene, transition: Transitions.Up.getValue())
        }
    }

    /// Registers the GameViewController to receive ```showGameScene```  notifications
    func addObserverForShowGameScene() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showGameScene(_:)),
            name: .showGameScene,
            object: nil)
    }
    
    /// Selector function for ```showAI_GameScene``` notification.
    @objc private func showAI_GameScene(_ notification: Notification) {
        if UserDefaults.backgroundAnimationType != .none {
            skView.presentScene(ai_gameScene)
        } else {
            skView.presentScene(ai_gameScene, transition: Transitions.Up.getValue())
        }
    }

    /// Registers the GameViewController to receive ```showAI_GameScene```  notifications
    func addObserverForShowAI_GameScene() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showAI_GameScene),
            name: .showAI_GameScene,
            object: nil)
    }

}
