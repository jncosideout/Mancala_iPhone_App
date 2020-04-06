//  Copyright © 2017 Augmented Code.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import SpriteKit

final class GradientNode {
    
    static let billiardFelt = [UIColor(red: 0.0 / 255.0, green: 51.0 / 255.0, blue: 25.0 / 255.0, alpha: 1.0),
                                UIColor(red: 0.0 / 255.0, green: 102.0 / 255.0, blue: 51.0 / 255.0, alpha: 1.0),
                                UIColor(red: 0.0 / 255.0, green: 153.0 / 255.0, blue: 76.0 / 255.0, alpha: 1.0)]
    
    static let sunsetPurples = [UIColor(red: 53.0 / 255.0, green: 92.0 / 255.0, blue: 125.0 / 255.0, alpha: 1.0),
    UIColor(red: 108.0 / 255.0, green: 91.0 / 255.0, blue: 123.0 / 255.0, alpha: 1.0),
    UIColor(red: 192.0 / 255.0, green: 108.0 / 255.0, blue: 132.0 / 255.0, alpha: 1.0)]
    
    static func makeLinearNode(with skscene: SKScene, view: SKView, linearGradientColors: [UIColor], animate: Bool) {
        
        let linearGradientSize = CGSize(width: skscene.size.width * 1, height: skscene.size.height * 1)
        
        let linearGradientLocations: [CGFloat] = [0, 0.5, 1]
        let textureCount = 8
        let textures = (0..<textureCount).map { (index) -> SKTexture in
            let angle = 2.0 * CGFloat.pi / CGFloat(textureCount) * CGFloat(index)
            return SKTexture(linearGradientWithAngle: angle, colors: linearGradientColors, locations: linearGradientLocations, size: linearGradientSize)
        }
        
        let linearGradientNode = SKSpriteNode(texture: textures.first)
        linearGradientNode.zPosition = 0
        linearGradientNode.position = CGPoint(x: skscene.size.width/2, y: skscene.size.height/2)
        skscene.addChild(linearGradientNode)
        
        if animate {
            let action = SKAction.animate(with: textures, timePerFrame: 0.3)
            linearGradientNode.run(SKAction.repeatForever(action))
        }
    }
    
    static func makeRadialNode(with skscene: SKScene, view: SKView) {
        
        let radialGradientSize = CGSize(width: skscene.size.width * 1.5, height: skscene.size.height * 1.5)
        let radialGradientColors = [UIColor.yellow, UIColor.orange]
        let radialGradientLocations: [CGFloat] = [0, 1]
        let radialGradientTexture = SKTexture(radialGradientWithColors: radialGradientColors, locations: radialGradientLocations, size: radialGradientSize)
        let radialGradientNode = SKSpriteNode(texture: radialGradientTexture)
        radialGradientNode.zPosition = 2
        radialGradientNode.position = CGPoint(x: skscene.size.width/2, y: skscene.size.height/2)
        skscene.addChild(radialGradientNode)

        let pulse = SKAction.sequence([SKAction.fadeIn(withDuration: 3.0), SKAction.fadeOut(withDuration: 1.0)])
        radialGradientNode.run(SKAction.repeatForever(pulse))
    }
}
