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
 The root view controller. First point for dependency injections coming from ```appDelegate```.

 Initializes the view hierarchy to use SKScenes from this point on. Passes dependencies from ```appDelegate``` to the first SKScene. Sets up ```GameCenterHelper```
 */
final class GameViewController: UIViewController {
    
    var savedGameModels: [GameModel]!
    var matchHistory: MatchHistory!
    
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
        
        // Pass the savedGameModels dependency
        let currentSKscene = MenuScene(with: savedGameModels)
        currentSKscene.gameViewController = self
        skView.presentScene(currentSKscene)
        // Set up the GameCenterHelper singleton
        GameCenterHelper.helper.viewController = self
        GameCenterHelper.helper.matchHistory = self.matchHistory
    }
}
