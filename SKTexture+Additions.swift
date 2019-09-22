//
//  SKTexture+Additions.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import UIKit
import SpriteKit

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

//extension SKTexture: Codable {
//    
//    public func encode(to encoder: Encoder) throws {
//        
//    }
//    
//    convenience public init(from decoder: Decoder){
//        self.init()
//    }
//}
