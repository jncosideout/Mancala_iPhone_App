//
//  MenuScene.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import GameKit
import SpriteKit

final class MenuScene: SKScene {
    private let transition = SKTransition.push(with: .up, duration: 0.3)
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private var viewWidth: CGFloat {
        return view?.frame.size.width ?? 0
    }
    
    private var viewHeight: CGFloat {
        return view?.frame.size.height ?? 0
    }
    
    private var savedLocalButton: ButtonNode!
    private var newLocalButton: ButtonNode!
    private var onlineButton: ButtonNode!
    var model: GameModel
    
    // MARK: - Init
    
    convenience init(with gameModel: GameModel) {
        self.init()
        model = gameModel
    }
    
    override init() {
        model = GameModel(newGame: true)
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(presentGame(_:)),
            name: .presentGame,
            object: nil)
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
        
        savedLocalButton = ButtonNode("Saved\nLocal Game", size: buttonSize) {
            self.view?.presentScene(GameScene(model: self.model), transition: self.transition)
        }
        
        newLocalButton = ButtonNode("New\nLocal Game", size: buttonSize) {
            let newGameData = GameData()
            self.model.gameData = newGameData
            self.model.setUpGame(from: newGameData)
            self.view?.presentScene(GameScene(model: self.model), transition: self.transition)
            
        }
        
        onlineButton = ButtonNode("Online\nGame", size: buttonSize) {
            GameCenterHelper.helper.presentMatchMaker()
        }
        
        runningYOffset += (buttonSize.height / 2)
        savedLocalButton.position = CGPoint(x: sceneMargin, y: runningYOffset)
        addChild(savedLocalButton)
        
        newLocalButton.position = CGPoint(x: viewWidth / 2 - buttonSize.width / 2, y: runningYOffset)
        addChild(newLocalButton)
        
        onlineButton.isEnabled = GameCenterHelper.isAuthenticated
        onlineButton.position = CGPoint(x: viewWidth - sceneMargin  - buttonSize.width, y: runningYOffset)
        addChild(onlineButton)
    }

    //MARK: Notifications
    @objc private func authenticationChanged(_ notification: Notification) {
        onlineButton.isEnabled = notification.object as? Bool ?? false
    }
    
    @objc private func presentGame(_ notification: Notification) {
        
        guard let match = notification.object as? GKTurnBasedMatch else {
            return
        }
        
        loadAndDisplay(match: match)
    }
    
    private func loadAndDisplay(match: GKTurnBasedMatch) {
        
        match.loadMatchData { (data, error) in
            let model: GameModel
            
            if let gkMatchData = data {
                model = GameModel(from: gkMatchData)
            } else {
                print("error loading gameData: \(String(describing: error))" )
                model = GameModel(newGame: true)
            }
            
            if model.turnNumber == 0 && model.playerTurn == 1 {
                model.gameData.firstPlayerID = match.currentParticipant?.player?.playerID ?? ""
                model.playerPerspective = model.playerTurn
            } else {
                if GKLocalPlayer.local.playerID == model.gameData.firstPlayerID {
                    model.playerPerspective = 1
                } else {
                    model.playerPerspective = 2
                }
            }
            
            GameCenterHelper.helper.currentMatch = match
            self.view?.presentScene(GameScene(model: model), transition: self.transition)
        }
    }
}//EoC
