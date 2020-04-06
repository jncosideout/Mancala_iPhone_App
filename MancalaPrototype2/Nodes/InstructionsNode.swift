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
    private let textLabelNode: SKLabelNode
    var instructions: [String] {
        didSet{
            instructionsCount = instructions.count
            plainText = instructions[0]
        }
    }
    private var instructionsCount = 0
    private var showSlide = 0
    
    var plainText: String? {
        get {
            return textLabelNode.text
        }
        set {
            textLabelNode.text = newValue
        }
    }
    
    init(_ text: String, size: CGSize, newInstructions: [String], actionBlock: ActionBlock? = nil) {
        
        instructions = newInstructions
        backgroundNode = BackgroundNode(kind: .recessed, size: size)
        backgroundNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        
        let font = UIFont.systemFont(ofSize: 18, weight: .semibold)

        textLabelNode = SKLabelNode(fontNamed: font.fontName)
        super.init()
        let safeAreaInset = self.inputView?.window?.safeAreaInsets.right ?? 30

        textLabelNode.fontSize = font.pointSize
        textLabelNode.fontColor = .white
        textLabelNode.numberOfLines = 0
        textLabelNode.lineBreakMode = NSLineBreakMode.byWordWrapping
        textLabelNode.text = instructions[0]
        textLabelNode.preferredMaxLayoutWidth = size.width - safeAreaInset
        textLabelNode.verticalAlignmentMode = .center
        textLabelNode.horizontalAlignmentMode = .center
        textLabelNode.alpha = 0
        textLabelNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2// - textLabelNode.frame.height / 2
        )
        
        
        addChild(backgroundNode)
        addChild(textLabelNode)
        
        self.actionBlock = actionBlock
    }
    
    
    func animatePopUpFadeIn() {
        run(SKAction.fadeAlpha(to: 1, duration: 1))
        textLabelNode.run(SKAction.fadeAlpha(to: 1, duration: 1))
    }
    
    

}//EoC
