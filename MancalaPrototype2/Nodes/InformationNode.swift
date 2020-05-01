///
///  InformationNode.swift
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
 Displays text to the user that can be updated dynamically and animated.
 
 Based on code from the tutorial found at https:www.raywenderlich.com/7544-game-center-for-ios-building-a-turn-based-game#
 By Ryan Ackerman
 */
public enum backgroundNodeAnimationColor {
    case red
    case green
    case blue
}

final class InformationNode: TouchNode {
    private let backgroundNode: BackgroundNode
    private let labelNode: SKLabelNode
    private let originalSize: CGSize
    
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
                let nsAttrString = NSAttributedString(string: newValue, attributes: [
                    .font : UIFont.systemFont(ofSize: 18, weight: .semibold)
                    ])
                
                labelNode.attributedText = nsAttrString
            }
        }
    }
    
    /// Creates a white BackgroundNode with a text SKLabelNode on top to display feedback info to the user
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
    
    /// Creates and returns a color changing action to be run on this node's ```backgroundNode```
    func getBackgroundAnimation(color: UIColor, duration: TimeInterval) -> SKAction {
        return backgroundNode.changeColor(color: color, duration: duration)
    }
    
    /// Runs an action on the ```backgroundNode```, changes the text on the ```labelNode``` and pauses the animation so the new text can be read
    func animateInfoNode(text: String, changeColorAction: SKAction?, duration: TimeInterval = 2) -> SKAction {

        guard let nodeName = backgroundNode.name else { return SKAction() }

        let backgroundAction: SKAction = {
            var action = SKAction()
            if let changeColor = changeColorAction {
                action = changeColor
            }
            return action
        }()
        
        return SKAction.sequence([
            SKAction.run(backgroundAction, onChildWithName: nodeName),
            SKAction.run{self.text = text},
            SKAction.wait(forDuration: duration)
         ])
    }
    

    
}
