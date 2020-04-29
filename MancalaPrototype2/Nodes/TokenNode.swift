///
///  TokenNode.swift
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
 The UI representation of the PitNodes. Allows TokenNodes to animate themselves for a variety of situations.
 
 Based on code from the tutorial found at https:www.raywenderlich.com/7544-game-center-for-ios-building-a-turn-based-game#
 By Ryan Ackerman
 */
public final class TokenNode: SKSpriteNode {
    /// The generic identifier for all TokenNodes. Used as a prefix to ```SKSpriteNode.name```
    static let tokenNodeName = "token"
    
    private let rotateActionKey = "rotate"
    
    /// The PitNode that this TokenNode represents
    var pit: PitNode
    
    /// Initialize with the image showing the beads of this TokenNode's PitNode
    ///
    /// - Parameter pit: The PitNode given to this TokenNode. Its initial beads value is used to get the initial SKTexture image of this TokenNode
    required init(_ pit: PitNode) {
        self.pit = pit
        
        let textureName = "Mancala_hole_(\(pit.beads))"
        let texture = SKTexture(imageNamed: textureName)
        
        super.init(
            texture: texture,
            color: .clear,
            size: texture.size().applying(CGAffineTransform.init(scaleX: 0.75, y: 0.75))
        )
        
        // SKSpriteNode name for this unique TokenNode
        name = "\(TokenNode.tokenNodeName) for player: \(pit.player) pit: \(pit.name)"
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// An animation that shrinks the TokenNode and removes it from the SKScene
    func remove() {
        run(SKAction.sequence([SKAction.scale(to: 0, duration: 0.15), SKAction.removeFromParent()]))
    }
    
    
    /// Animate the on-screen bead value to show the current bead value
    /// - Parameter duration: Total time will be stretched to 1.1 * duration when animation is complete
    func animateCurrentValue(with duration: TimeInterval) -> SKAction {
        let textureName = "Mancala_hole_(\(pit.beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        return animate(newTexture, with: duration)
    }
    
    
    /// Animate the on-screen bead value to show the PitNode's last bead value
    /// - Parameter duration: Total time will be stretched to 1.1 * duration when animation is complete
    func animateMostRecent(with duration: TimeInterval) -> SKAction {
        let textureName = "Mancala_hole_(\(pit.mostRecentBeads))"
        let newTexture = SKTexture(imageNamed: textureName)
        return animate(newTexture, with: duration)
    }
    
    
    /// Allows this TokenNode to be animated during a multiple-lap wrap-around move. When the starting pit contains beads > (gameBoard.length - 1), it will result in at least one wrap- around. During each move, each pit stores its previous bead values in a FIFO queue called ```PitNode.previousBeads```. This method will be called repeatedly on each "lap" of the animation so that the this TokenNode is shown with each of its historical values in sequential order instead of jumping straight to its "cuurent" value.
    /// - Parameters:
    ///   - firstLap: True if this is the firstLap of a multiple-lap wrap-around move
    ///   - duration: Total time will be stretched to 1.1 * duration when animation is complete
    func animatePreviousBeads(_ firstLap: Bool, with duration: TimeInterval) -> SKAction {
        // The "current" bead value of each PitNode is always added to the end of the ```previousBeads``` queue so it needs to be discarded on the first lap
        if firstLap && pit.previousBeads.count > 0 {
            pit.previousBeads.removeLast(1)
        }
        // The last value in the list is the oldest
        let previousBeads = pit.previousBeads.popLast()

        let textureName = previousBeads != nil ? "Mancala_hole_(\(previousBeads!))" : "Mancala_hole_(\(pit.beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        
        return animate(newTexture, with: duration)
    }
    
    
    /// Allow a TokenNode to be animated with an abitrary bead-value image
    /// - Parameters:
    ///   - duration: Total time will be stretched to 1.1 * duration when animation is complete
    ///   - beads: The number of beads to show when animating
    func animateSpecific(with duration: TimeInterval, beads: Int) -> SKAction {
        let textureName = "Mancala_hole_(\(beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        
        return animate(newTexture, with: duration)
    }
    
    
    /// Animates every bead value between the TokenNode's ```PitNode.mostRecentBeads``` to its "current" beads.
    /// - Parameters:
    ///   - duration: Total time will be equal to 'duration', but the speed will be Duration/Frames
    ///   - reverse: True causes the animation to start with the PitNode's "current" beads and end with it's ```mostRecentBeads```
    func animateThroughInterval(with duration: TimeInterval, reverse: Bool) -> SKAction {
        
        var textures = [SKTexture]()
        var start = 0
        var end = 0
        
        let lastBeads = pit.mostRecentBeads
        
        start = lastBeads + 1
        end = pit.beads
        if reverse {
            let temp = end
            end = start - 1
            start = temp
        }
        
        for i in start...end {
            let textureName = "Mancala_hole_(\(i))"
            let newTexture = SKTexture(imageNamed: textureName)
            textures.append(newTexture)
        }
        
        let action = SKAction.animate(with: textures, timePerFrame: duration/Double(end - start))
        
        if reverse {
            return action.reversed()
        }
        
        return action
    }
    
    /// Use a "highlighted" version of the image that represents the current bead value when animating.
    /// - Parameter duration: Total time will be stretched to 1.1 * duration when animation is complete
    func animateHighlight(with duration: TimeInterval, beads: Int) -> SKAction {
        
        let textureName = "Mancala_highlight_(\(beads))"
        let newTexture = SKTexture(imageNamed: textureName)
        
        return animate(newTexture, with: duration)
        
    }
    
    
    /// The base method that all the animation methods in this class should call.
    /// - Parameters:
    ///   - newTexture: an image in xcassets that visually represents a number of beads in a pit
    ///   - duration: The variable that controls the time to fade out, change texture, and fade back in
    func animate(_ newTexture: SKTexture, with duration: TimeInterval) -> SKAction {
        return SKAction.sequence([SKAction.fadeOut(withDuration: duration/2),SKAction.animate(with: [newTexture], timePerFrame: duration/10),SKAction.fadeIn(withDuration: duration/2)])
    }
    
}

/// Not currently used
extension TokenNode: Codable {
    
    convenience public init(from decoder: Decoder) throws {
        self.init(PitNode())
    }
}
