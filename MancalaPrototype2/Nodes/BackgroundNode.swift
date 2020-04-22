///
///  BackgroundNode.swift
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
        growAction = SKAction.sequence([
            SKAction.run{ self.position.x = -(self.originalSize.width)/2},
            SKAction.moveTo(x: originalPosition.x, duration: time)
                    ])
        return growAction
    }
}
