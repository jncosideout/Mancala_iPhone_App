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
extension SKScene {
    
    //MARK: load background from device type
    
    /// Finds this device's model and gets the corresponding prefix to the correctly sized image file 
    func loadBackgroundNode(_ viewWidth: CGFloat, _ viewHeight: CGFloat, imagePrefix: String) -> SKSpriteNode {
        var image = imagePrefix
        var deviceType = UIDevice().type
        if deviceType == .simulator {
            let modelID = UIDevice.modelIdentifier()
            if let deviceModel = mapModelID_ToDeviceModel(modelID) {
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
            image = ""
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
    
    /// Uses an internal dictionary to select the appropriate images for this device. This is outdated now that the "Launch Screen.storyboard" uses the same image set as the backgrounds in the SKScenes
    func mapModelID_ToDeviceModel(_ modelID: String) -> Model? {
        //fdsf
        
        let modelMap : [ String : Model ] = [
              "i386"       : .simulator,
              "x86_64"     : .simulator,
              "iPod1,1"    : .iPod1,
              "iPod2,1"    : .iPod2,
              "iPod3,1"    : .iPod3,
              "iPod4,1"    : .iPod4,
              "iPod5,1"    : .iPod5,
              "iPad2,1"    : .iPad2,
              "iPad2,2"    : .iPad2,
              "iPad2,3"    : .iPad2,
              "iPad2,4"    : .iPad2,
              "iPad2,5"    : .iPadMini1,
              "iPad2,6"    : .iPadMini1,
              "iPad2,7"    : .iPadMini1,
              "iPhone3,1"  : .iPhone4,
              "iPhone3,2"  : .iPhone4,
              "iPhone3,3"  : .iPhone4,
              "iPhone4,1"  : .iPhone4S,
              "iPhone5,1"  : .iPhone5,
              "iPhone5,2"  : .iPhone5,
              "iPhone5,3"  : .iPhone5C,
              "iPhone5,4"  : .iPhone5C,
              "iPad3,1"    : .iPad3,
              "iPad3,2"    : .iPad3,
              "iPad3,3"    : .iPad3,
              "iPad3,4"    : .iPad4,
              "iPad3,5"    : .iPad4,
              "iPad3,6"    : .iPad4,
              "iPhone6,1"  : .iPhone5S,
              "iPhone6,2"  : .iPhone5S,
              "iPad4,1"    : .iPadAir1,
              "iPad4,2"    : .iPadAir2,
              "iPad4,4"    : .iPadMini2,
              "iPad4,5"    : .iPadMini2,
              "iPad4,6"    : .iPadMini2,
              "iPad4,7"    : .iPadMini3,
              "iPad4,8"    : .iPadMini3,
              "iPad4,9"    : .iPadMini3,
              "iPad6,3"    : .iPadPro9_7,
              "iPad6,11"   : .iPadPro9_7,
              "iPad6,4"    : .iPadPro9_7_cell,
              "iPad6,12"   : .iPadPro9_7_cell,
              "iPad6,7"    : .iPadPro12_9,
              "iPad6,8"    : .iPadPro12_9_cell,
              "iPad7,3"    : .iPadPro10_5,
              "iPad7,4"    : .iPadPro10_5_cell,
              "iPhone7,1"  : .iPhone6plus,
              "iPhone7,2"  : .iPhone6,
              "iPhone8,1"  : .iPhone6S,
              "iPhone8,2"  : .iPhone6Splus,
              "iPhone8,4"  : .iPhoneSE,
              "iPhone9,1"  : .iPhone7,
              "iPhone9,2"  : .iPhone7plus,
              "iPhone9,3"  : .iPhone7,
              "iPhone9,4"  : .iPhone7plus,
              "iPhone10,1" : .iPhone8,
              "iPhone10,2" : .iPhone8plus,
              "iPhone10,3" : .iPhoneX,
              "iPhone10,4" : .iPhone8,
              "iPhone10,5" : .iPhone8plus,
              "iPhone10,6" : .iPhoneX,
              "iPhone11,2" : .iPhoneXS,
              "iPhone11,4" : .iPhoneXSmax,
              "iPhone11,6" : .iPhoneXSmax,
              "iPhone11,8" : .iPhoneXR,
              "iPhone12,1" : .iPhone11,
              "iPhone12,3" : .iPhone11Pro,
              "iPhone12,5" : .iPhone11ProMax
        ]
        
        return modelMap[modelID]
    }
    
    func getSizeConstraintsFor(string: String, minSize: CGSize, attributes: [NSAttributedString.Key : Any]? = nil) -> CGSize {
        
        var _attributes: [NSAttributedString.Key : Any]
        if let someAttributes = attributes {
            _attributes = someAttributes
        } else {
            _attributes = [.font : UIFont.systemFont(ofSize: 18, weight: .semibold)]
        }
            
        let textNSAString = NSAttributedString(string: string, attributes: _attributes)
        // Initial constraints will be expanded or shrank as necessary
        var minimumTextSizeConstraint = CGSize(width: minSize.width, height: minSize.height)
        let textNodeSize = textNSAString.boundingRect(with: minimumTextSizeConstraint, options: [], context: nil)
        // Re-size the constraint after getting new values
        minimumTextSizeConstraint = CGSize(width: textNodeSize.width, height: textNodeSize.height)
        return minimumTextSizeConstraint
    }
}
