///
///  ButtonNode.swift
///  MancalaPrototype2
///
///  Created by Alexander Scott Beaty on 7/30/19.
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

import SpriteKit

/**
 Creates a rectangular, translucent button with foreground text. Accepts a trailing closure containing any code to be executed when this button is tapped.
 
 Based on code from the tutorial found at https:www.raywenderlich.com/7544-game-center-for-ios-building-a-turn-based-game#
 By Ryan Ackerman
 */
class ButtonNode: TouchNode {
    private let backgroundNode: BackgroundNode
    private let labelNode: SKLabelNode
    private let shadowNode: SKLabelNode
    
    /**
     Specifies an image to be displayed as a button. The ```labelNode``` and ```shadowNode``` are initialized but unused.
     */
    init(image: String, size: CGSize, actionBlock: ActionBlock?) {
        backgroundNode = BackgroundNode(kind: .recessed, size: size)
        backgroundNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        labelNode = SKLabelNode()
        shadowNode = SKLabelNode()
        
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
    
    
    /// Creates a button with a shadow effect.
    /// - Parameters:
    ///   - text: the text to put on the ```labelNode``` and ```shadowNode```
    ///   - size: the relative size of the button
    ///   - aTextColor: defaults to white
    ///   - actionBlock: is executed when this button is pressed
    init(_ text: String, size: CGSize, aTextColor: UIColor? = nil, actionBlock: ActionBlock?) {
        backgroundNode = BackgroundNode(kind: .recessed, size: size)
        backgroundNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        
        var textColor: UIColor
        if let aColor = aTextColor {
            textColor = aColor
        } else {
            textColor = UIColor.init(white: 1, alpha: 1)
        }
        // Use NSAttributedString because SKLabelNode(fontNamed:) has been deprecated in iOS 13
        let foregroundText = NSAttributedString(string: text, attributes: [
            .font : UIFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor : textColor
            ])
        
        let backgroundText = NSAttributedString(string: text, attributes: [
        .font : UIFont.systemFont(ofSize: 24, weight: .semibold)
        ])
        
        labelNode = SKLabelNode(attributedText: foregroundText)
        labelNode.numberOfLines = 0
        labelNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - labelNode.frame.height / 2
        )
        
        shadowNode = SKLabelNode(attributedText: backgroundText)
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
    
    /// Fade-out slightly when tapped
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard isEnabled else {
            return
        }
        
        labelNode.run(SKAction.fadeAlpha(to: 0.8, duration: 0.2))
    }
    
    /// Fade back in after tapped and execute ```actionBlock```
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard isEnabled else {
            return
        }
        
        labelNode.run(SKAction.fadeAlpha(to: 1, duration: 0.2))
    }
    
    /// Allows a String to convert to and from NSAttributedString and be applied to or retrieved from the foreground ```labelNode``` and background  and ```shadowNode```
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
                let foregroundText = NSAttributedString(string: newValue, attributes: [
                    .font : UIFont.systemFont(ofSize: 24, weight: .semibold),
                    .foregroundColor : UIColor.init(white: 1, alpha: 1)
                    ])
                
                let backgroundText = NSAttributedString(string: newValue, attributes: [
                    .font : UIFont.systemFont(ofSize: 24, weight: .semibold)
                    ])
                
                labelNode.attributedText = foregroundText
                shadowNode.attributedText = backgroundText
            }
        }
    }
}
