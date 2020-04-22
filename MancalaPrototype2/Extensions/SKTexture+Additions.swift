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

import UIKit
import SpriteKit

/// https://www.raywenderlich.com/7544-game-center-for-ios-building-a-turn-based-game#
/// Ryan Ackerman
extension SKTexture {
    class func recessedBackgroundTexture(of size: CGSize) -> SKTexture {
        return SKTexture(image: UIGraphicsImageRenderer(size: size).image { context in
            let fillColor = UIColor(white: 0, alpha: 0.2)
            let shadowColor = UIColor(white: 0, alpha: 0.3)
            
            let shadow = NSShadow()
            shadow.shadowColor = shadowColor
            shadow.shadowOffset = .zero
            shadow.shadowBlurRadius = 5
            
            let rectanglePath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 10)
            fillColor.setFill()
            rectanglePath.fill()
            
            let drawContext = context.cgContext
            
            drawContext.saveGState()
            drawContext.clip(to: rectanglePath.bounds)
            drawContext.setShadow(offset: .zero, blur: 0)
            drawContext.setAlpha((shadow.shadowColor as! UIColor).cgColor.alpha)
            drawContext.beginTransparencyLayer(auxiliaryInfo: nil)
            let rectangleOpaqueShadow = shadowColor.withAlphaComponent(1)
            drawContext.setShadow(offset: shadow.shadowOffset, blur: shadow.shadowBlurRadius, color: rectangleOpaqueShadow.cgColor)
            drawContext.setBlendMode(.sourceOut)
            drawContext.beginTransparencyLayer(auxiliaryInfo: nil)
            
            rectangleOpaqueShadow.setFill()
            rectanglePath.fill()
            
            drawContext.endTransparencyLayer()
            drawContext.endTransparencyLayer()
            drawContext.restoreGState()
        })
    }
    
    class func pillBackgroundTexture(of size: CGSize, color: UIColor?) -> SKTexture {
        return SKTexture(image: UIGraphicsImageRenderer(size: size).image { context in
            let fillColor = color ?? .white
            let shadowColor = UIColor(white: 0, alpha: 0.3)
            
            let shadow = NSShadow()
            shadow.shadowColor = shadowColor
            shadow.shadowOffset = CGSize(width: 0, height: 1)
            shadow.shadowBlurRadius = 5
            
            let drawContext = context.cgContext
            
            let pillRect = CGRect(origin: .zero, size: size).insetBy(dx: 3, dy: 4)
            let rectanglePath = UIBezierPath(roundedRect: pillRect, cornerRadius: size.height / 2)
            
            drawContext.setShadow(offset: shadow.shadowOffset, blur: shadow.shadowBlurRadius, color: shadowColor.cgColor)
            fillColor.setFill()
            rectanglePath.fill()
        })
    }
}
