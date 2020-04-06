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
    private let originalSize: CGSize
    
    var text: String {
        get {
            if let text = labelNode.attributedText?.string {
                return text
            } else {
                return ""
            }
        }
        set {
            if newValue != "" {
                let nsAttrString = NSAttributedString(string: newValue,
                                                attributes: [
                                                    .font : UIFont.systemFont(ofSize: 18, weight: .semibold)
                                                ])
                
                labelNode.attributedText = nsAttrString
            }
        }
    }
    
    init(_ text: String, size: CGSize, actionBlock: ActionBlock? = nil, named: String?) {
        originalSize = size
        backgroundNode = BackgroundNode(kind: .pill, size: size)
        backgroundNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        
        let foregroundText = NSAttributedString(string: text, attributes: [
                    .font : UIFont.systemFont(ofSize: 18, weight: .semibold)
                    ])
        
        labelNode = SKLabelNode(attributedText: foregroundText)
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
    
    func animateInfoNode(text: String, changeColorAction: SKAction?, duration: TimeInterval = 2) -> SKAction {
//        var actions = [SKAction]()
        guard let nodeName = backgroundNode.name else { return SKAction() }

        let backgroundAction: SKAction = {
            var action = SKAction()
            if let changeColor = changeColorAction {
                action = changeColor
            }
            return action
        }()
        
//        for text in textArray {
//        actions.append(
        return SKAction.sequence([
            SKAction.run(backgroundAction, onChildWithName: nodeName),
            SKAction.run{self.text = text},
            SKAction.wait(forDuration: duration)
         ])
//        )
//        }
//        return SKAction.sequence(actions)
    }
    

    
}
