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
    
    var pit: PitNode
    
    required init(_ pit: PitNode) {
        self.pit = pit
        
        let textureName = "Mancala_hole_(\(pit.beads))"
        let texture = SKTexture(imageNamed: textureName)
        
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
    
    func animateCurrentValue(with duration: TimeInterval) -> SKAction {
        let textureName = "Mancala_hole_(\(pit.beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        return animate(newTexture, with: duration)
    }
    
    func animateMostRecent(with duration: TimeInterval) -> SKAction {
        let textureName = "Mancala_hole_(\(pit.mostRecentBeads))"
        let newTexture = SKTexture(imageNamed: textureName)
        return animate(newTexture, with: duration)
    }
    
    func animatePreviousBeads(_ firstLap: Bool, with duration: TimeInterval) -> SKAction {
        if firstLap && pit.previousBeads.count > 0 {
            pit.previousBeads.removeLast(1)
        }
        let previousBeads = pit.previousBeads.popLast()

        let textureName = previousBeads != nil ? "Mancala_hole_(\(previousBeads!))" : "Mancala_hole_(\(pit.beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        
        return animate(newTexture, with: duration)
    }
    
    func animateSpecific(with duration: TimeInterval, beads: Int) -> SKAction {
        let textureName = "Mancala_hole_(\(beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        
        return animate(newTexture, with: duration)
    }
    
    func animateThroughInterval(with duration: TimeInterval, reverse: Bool) -> SKAction {
        
        var textures = [SKTexture]()
        var start = 0
        var end = 0
        
        let lastBeads = pit.mostRecentBeads
        
        start = lastBeads + 1
        end = pit.beads
        if reverse {
            let temp = end
            end = start - 1
            start = temp
        }
        
        for i in start...end {
            let textureName = "Mancala_hole_(\(i))"
            let newTexture = SKTexture(imageNamed: textureName)
            textures.append(newTexture)
        }
        
        let action = SKAction.animate(with: textures, timePerFrame: duration/Double(end - start))
        
        if reverse {
            return action.reversed()
        }
        
        return action
    }
    
    func animateHighlight(with duration: TimeInterval, beads: Int) -> SKAction {
        
        let textureName = "Mancala_highlight_(\(beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        
        return animate(newTexture, with: duration)
        
    }
    
    func animate(_ newTexture: SKTexture, with duration: TimeInterval) -> SKAction {
        return SKAction.sequence([SKAction.fadeOut(withDuration: duration/2),SKAction.animate(with: [newTexture], timePerFrame: duration/10),SKAction.fadeIn(withDuration: duration/2)])
    }
    
}

extension TokenNode: Codable {
    
    convenience public init(from decoder: Decoder) throws {
        self.init(PitNode())
    }
}
