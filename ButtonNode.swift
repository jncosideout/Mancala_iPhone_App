//
//  ButtonNode.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import SpriteKit

class ButtonNode: TouchNode {
    private let backgroundNode: BackgroundNode
    private let labelNode: SKLabelNode
    
    init(image: String, size: CGSize, actionBlock: ActionBlock?) {
        //self.init(text, size: size, actionBlock: actionBlock)
        backgroundNode = BackgroundNode(kind: .recessed, size: size)
        backgroundNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        labelNode = SKLabelNode()
        
        let buttonImageNode = SKSpriteNode(imageNamed: image)
        let aspectRatio = buttonImageNode.size.width / buttonImageNode.size.height
        var adjustedWidth = buttonImageNode.size.width
        adjustedWidth *= 0.5
        buttonImageNode.size = CGSize(
            width: adjustedWidth,
            height: adjustedWidth / aspectRatio
        )
        buttonImageNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        
        super.init()
        addChild(buttonImageNode)
        self.actionBlock = actionBlock
    }
    
    init(_ text: String, size: CGSize, actionBlock: ActionBlock?) {
        backgroundNode = BackgroundNode(kind: .recessed, size: size)
        backgroundNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        
        let buttonFont = UIFont.systemFont(ofSize: 24, weight: .semibold)
        
        labelNode = SKLabelNode(fontNamed: buttonFont.fontName)
        labelNode.fontSize = buttonFont.pointSize
        labelNode.fontColor = .white
        labelNode.text = text
        labelNode.numberOfLines = 0
        labelNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - labelNode.frame.height / 2
        )
        
        let shadowNode = SKLabelNode(fontNamed: buttonFont.fontName)
        shadowNode.fontSize = buttonFont.pointSize
        shadowNode.fontColor = .black
        shadowNode.text = text
        shadowNode.numberOfLines = 0
        shadowNode.alpha = 0.5
        shadowNode.position = CGPoint(
            x: labelNode.position.x + 2,
            y: labelNode.position.y - 2
        )
        
        super.init()
        
        addChild(backgroundNode)
        addChild(shadowNode)
        addChild(labelNode)
        
        self.actionBlock = actionBlock
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard isEnabled else {
            return
        }
        
        labelNode.run(SKAction.fadeAlpha(to: 0.8, duration: 0.2))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard isEnabled else {
            return
        }
        
        labelNode.run(SKAction.fadeAlpha(to: 1, duration: 0.2))
    }
}
