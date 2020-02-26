//
//  BackgroundNode.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import SpriteKit

class BackgroundNode: SKSpriteNode {
    enum Kind {
        case pill
        case recessed
    }
    
    typealias ComputedFloat = () -> CGFloat
    var originalColor: UIColor
    var originalSize: CGSize
    var originalKind: Kind
    var originalTexture: SKTexture
    

    init(kind: Kind, size: CGSize, color: UIColor? = nil) {

        originalColor = color ?? .white
        originalSize = size
        originalKind = kind
        
        originalTexture = BackgroundNode.pillOrRecessed(kind, size, color)
        super.init(texture: originalTexture, color: .clear, size: size)
        name = "BackgroundNodeName"
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeColor(color: UIColor, duration: TimeInterval) -> SKAction {
        let colorizeAction = SKAction.colorize(with: color, colorBlendFactor: 0.5, duration: duration)
        let reversedColorize = SKAction.colorize(with: originalColor, colorBlendFactor: 0.5, duration: duration)
        return SKAction.sequence([colorizeAction, reversedColorize])
    }
    
    static func pillOrRecessed(_ kind: Kind,_ size: CGSize,_ color: UIColor?) -> SKTexture {
        let texture: SKTexture
        switch kind {
        case .pill:
            texture = SKTexture.pillBackgroundTexture(of: size, color: color)
        default:
            texture = SKTexture.recessedBackgroundTexture(of: size)
        }
        return texture
    }
    
    func growWidth(over time: TimeInterval) -> SKAction {
        var growAction = SKAction()
        let originalPosition = position
//        if let parentNode = parent {
        growAction = SKAction.sequence([
            SKAction.run{ self.position.x = -(self.originalSize.width)/2},
            SKAction.moveTo(x: originalPosition.x, duration: time)
                    ])
//        }
        return growAction
    }
}
