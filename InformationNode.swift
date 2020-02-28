//
//  InformationNode.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import SpriteKit

public enum backgroundNodeAnimationColor {
    case red
    case green
    case blue
}

final class InformationNode: TouchNode {
    private let backgroundNode: BackgroundNode
    private let labelNode: SKLabelNode
    
    var text: String? {
        get {
            return labelNode.text
        }
        set {
            labelNode.text = newValue
        }
    }
    
    init(_ text: String, size: CGSize, actionBlock: ActionBlock? = nil, named: String?) {
        backgroundNode = BackgroundNode(kind: .pill, size: size)
        backgroundNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        
        let font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        labelNode = SKLabelNode(fontNamed: font.fontName)
        labelNode.fontSize = font.pointSize
        labelNode.fontColor = .black
        labelNode.text = text
        labelNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - labelNode.frame.height / 2 + 2
        )
        
        super.init()
        
        addChild(backgroundNode)
        addChild(labelNode)
        
        if let newName = named {
            name = newName
        } else {
            name = "InformationNodeName"
        }
        
        self.actionBlock = actionBlock
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getBackgroundAnimation(color: UIColor, duration: TimeInterval) -> SKAction {
        return backgroundNode.changeColor(color: color, duration: duration)
    }
    
    func animateInfoNode(textArray: [String], changeColorAction: SKAction?, duration: TimeInterval = 2) -> SKAction {
        var actions = [SKAction]()
        guard let nodeName = backgroundNode.name else { return SKAction() }

        let backgroundAction: SKAction = {
            var action = SKAction()
            if let changeColor = changeColorAction {
                action = changeColor
            }
            return action
        }()
        
        for text in textArray {
            actions.append(
                SKAction.sequence([
                    SKAction.run{self.text = text},
                    SKAction.run(backgroundAction, onChildWithName: nodeName),
                    SKAction.wait(forDuration: duration)
                ])
            )
        }
        return SKAction.sequence(actions)
    }
    

    
}
