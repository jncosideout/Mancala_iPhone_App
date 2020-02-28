//
//  InstructionsSKView.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 2/26/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//

import Foundation
import SpriteKit

class InstructionsNode : TouchNode {
   
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    

    private let backgroundNode: BackgroundNode
    private let labelNode: SKLabelNode
    var instructions: [String]? {
        didSet{
            instructionsCount = instructions?.count ?? 0
            text = instructions?[0]
        }
    }
    private var instructionsCount = 0
    private var showSlide = 0
    
    var text: String? {
        get {
            return labelNode.text
        }
        set {
            labelNode.text = newValue
        }
    }
    
    init(_ text: String, size: CGSize, actionBlock: ActionBlock? = nil, newInstructions: [String]? = nil) {
        backgroundNode = BackgroundNode(kind: .recessed, size: size)
        backgroundNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        
        let font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        labelNode = SKLabelNode(fontNamed: font.fontName)
        labelNode.fontSize = font.pointSize
        labelNode.fontColor = .black
        labelNode.numberOfLines = 0
        labelNode.text = text
        labelNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - labelNode.frame.height / 2 + 2
        )
        
        super.init()
        
        addChild(backgroundNode)
        addChild(labelNode)
        
        self.actionBlock = transitionSlide
    }
    
    
    func animatePopUpFadeIn() {
        run(SKAction.fadeAlpha(to: 1, duration: 1))
    }
    
    func transitionSlide() {
        run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0, duration: 1),
            SKAction.run {
                self.showSlide += 1
                if self.showSlide < self.instructionsCount {
                    self.text = self.instructions?[self.showSlide]
                } else {
                    self.removeFromParent()
                }
            },
            SKAction.fadeAlpha(to: 1, duration: 1)
        ]))
        
    }

}//EoC
