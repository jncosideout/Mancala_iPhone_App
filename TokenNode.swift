//
//  TokenNode.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import SpriteKit

public final class TokenNode: SKSpriteNode {
    static let tokenNodeName = "token"
    
    private let rotateActionKey = "rotate"
    //private var previousTexture: SKTexture
    
//    var isIndicated: Bool = false {
//        didSet {
//            if isIndicated {
//                run(SKAction.repeatForever(SKAction.rotate(byAngle: 1, duration: 0.5)), withKey: rotateActionKey)
//            } else {
//                removeAction(forKey: rotateActionKey)
//                run(SKAction.rotate(toAngle: 0, duration: 0.15))
//            }
//        }
//    }
    
    var pit: PitNode
    
    required init(_ pit: PitNode) {
        self.pit = pit
        
        let textureName = "Mancala_hole_(\(pit.beads))"
        let texture = SKTexture(imageNamed: textureName)
        
        //let oldTextureName = "Mancala_hole_(\(pit.previousBeads ?? 0))"
        //let oldTexture = SKTexture(imageNamed: oldTextureName)
        //previousTexture = oldTexture
        
        super.init(
            texture: texture,
            color: .clear,
            size: texture.size().applying(CGAffineTransform.init(scaleX: 0.75, y: 0.75))
        )
        
        name = "\(TokenNode.tokenNodeName) for player: \(pit.player) pit: \(pit.name)"
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func remove() {
        run(SKAction.sequence([SKAction.scale(to: 0, duration: 0.15), SKAction.removeFromParent()]))
    }
    
    func animate(with duration: TimeInterval, previous: Bool) -> SKAction {
        
        let textureName = previous ? "Mancala_hole_(\(pit.previousBeads ?? 0))" : "Mancala_hole_(\(pit.beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        
        return SKAction.sequence([SKAction.fadeOut(withDuration: duration/2),SKAction.animate(with: [newTexture], timePerFrame: duration/10),SKAction.fadeIn(withDuration: duration/2)])
        
    }
    
    func animateSpecific(with duration: TimeInterval, beads: Int) -> SKAction {
        
        let textureName = "Mancala_hole_(\(beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        
        return SKAction.sequence([SKAction.fadeOut(withDuration: duration/2),SKAction.animate(with: [newTexture], timePerFrame: duration/10),SKAction.fadeIn(withDuration: duration/2)])
        
    }
    
    func animateHighlight(with duration: TimeInterval, beads: Int) -> SKAction {
        
        let textureName = "Mancala_highlight_(\(beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        
        return SKAction.sequence([SKAction.fadeOut(withDuration: duration/2),SKAction.animate(with: [newTexture], timePerFrame: duration/10),SKAction.fadeIn(withDuration: duration/2)])
        
    }
    
}

extension TokenNode: Codable {
    
    convenience public init(from decoder: Decoder) throws {
        self.init(PitNode())
    }
}
