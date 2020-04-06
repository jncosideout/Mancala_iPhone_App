//
//  GameViewController.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import UIKit
import SpriteKit

final class GameViewController: UIViewController {
    
    //var savedGamesStore: SavedGameStore!
    var savedGameModels: [GameModel]!
    
    private var skView: SKView {
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
        
        let currentSKscene = MenuScene(with: savedGameModels)
        skView.presentScene(currentSKscene)
        GameCenterHelper.helper.viewController = self
    }
}
