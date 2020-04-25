///
///  MenuSceneDeviceModel.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 3/20/20.
/// ============LICENSE_START=======================================================
/// Copyright © 2020 Alexander Scott Beaty. All rights reserved.
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================

import GameKit
/// https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
extension MenuScene {
    
    //MARK: load background
    
    /// Finds this device's model and gets the corresponding prefix to the correctly sized image file  
    func loadBackgroundNode(_ viewWidth: CGFloat, _ viewHeight: CGFloat) -> SKSpriteNode {
        var image = backgroundImage
        var deviceType = UIDevice().type
        if deviceType == .simulator {
            let modelID = UIDevice.modelIdentifier()
            if let deviceModel = modelMap[modelID] {
                deviceType = deviceModel
            }
        }
        switch deviceType {
        case .iPhone4:
            fallthrough
        case .iPhone4S:
            image += " Portrait iOS 5,6@2x 20-47-07-95"
        case .iPhone5:
            fallthrough
        case .iPhoneSE:
            image += "@Retina 4"
        case .iPhone5S:
            fallthrough
        case .iPhone5C:
            fallthrough
        case .iPhone6:
            fallthrough
        case .iPhone6S:
            fallthrough
        case .iPhone7:
            fallthrough
        case .iPhone8:
            image += "-Portrait iOS 8,9@Retina HD 4.7"
        case .iPhone6plus:
            fallthrough
        case .iPhone6Splus:
            fallthrough
        case .iPhone7plus:
            image += "-iPhone portrait Retina 5.5"
        case .iPhone8plus:
            fallthrough
        case .iPhoneX:
            fallthrough
        case .iPhoneXS:
            fallthrough
        case .iPhoneXSmax:
            fallthrough
        case .iPhoneXR:
            image += deviceType.rawValue
        case .iPhone11:
            image += Model.iPhoneXR.rawValue
        case .iPhone11Pro:
            image += Model.iPhoneXS.rawValue
        case .iPhone11ProMax:
            image += Model.iPhoneXSmax.rawValue
        default:
            ""
        }
        return SKSpriteNode(imageNamed: image)
    }
        
    //MARK: - Other helpers
    
    /// Loads text files from a resource bundle
    /// - Parameters:
    ///   - numPages: Must be equal to the num of pages in the bundle
    ///   - filePath: the path to the resource bundle
    func getContent(numPages: Int, filePath: String) -> [String]? {
        var contentArray = [String]()
        do {
            for i in 1...numPages {
                let content = try String(contentsOfFile: filePath + "\(i)" + ".txt", encoding: .utf8) as String
                contentArray.append(content)
            }
            return contentArray
        } catch {
            return nil
        }
    }
    
    
}
