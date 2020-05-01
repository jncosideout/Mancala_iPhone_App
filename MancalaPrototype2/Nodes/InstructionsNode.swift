///
///  InstructionsSKView.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 2/26/20.
/// ============LICENSE_START=======================================================
/// Copyright (c) 2018 Razeware LLC
/// Modification Copyright © 2019 Alexander Scott Beaty. All rights reserved.
/// Modification License:
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================
/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import SpriteKit

/**
 Presents a translucent overlay on the SKScene that holds text. Owns a string array of ```instructions``` to be presented sequentially through an animation that simulates a slide show.
 
 - Important: the code to perform the slide show must be passed to this ```InstructionsNode``` through the ```actionBlock``` in init()
 
 Based on code from the tutorial found at https:www.raywenderlich.com/7544-game-center-for-ios-building-a-turn-based-game#
 By Ryan Ackerman
 */
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
    
    /// Sets the text to be shown on the InstructionsNode
    var plainText: String? {
        get {
            return textLabelNode.text
        }
        set {
            textLabelNode.text = newValue
        }
    }
    
    
    /// Initializes an Instructions node to show several blocks of text in succession.
    ///
    /// - Important: the code to perform the slide show must be passed to this ```InstructionsNode``` through the ```actionBlock``` in init()
    /// - Parameters:
    ///   - text: not used.
    ///   - size: the size of the node on the screen
    ///   - newInstructions: a string array containing the 'slides' of information to display
    ///   - actionBlock: the code to perform the slide show must be passed to this ```InstructionsNode``` through the ```actionBlock``` in init()
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
    
    /// Should be called only when the InstructionsNode is already set alpha = 0
    func animatePopUpFadeIn() {
        run(SKAction.fadeAlpha(to: 1, duration: 1))
        textLabelNode.run(SKAction.fadeAlpha(to: 1, duration: 1))
    }
    
    

}//EoC
