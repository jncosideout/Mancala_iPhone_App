//
//  PropertyListable.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 8/29/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation

public protocol PropertyListable {
    associatedtype PropertyListType
    var propertyListRepresentation: PropertyListType { get }
    init(propertyList: PropertyListType)
}

extension Int: PropertyListable {
    public typealias PropertyListType = Int
    public var propertyListRepresentation: PropertyListType { return self }
    public init(propertyList: PropertyListType) {
        self.init(propertyList)
    }
}

extension String: PropertyListable {
    public typealias PropertyListType = String
    public var propertyListRepresentation: PropertyListType { return self }
    public init(propertyList: PropertyListType) {
        self.init(stringLiteral: propertyList)
    }
}

protocol PropertyNames {
    func propertyNames() -> [String]
}

extension PropertyNames {
    func propertyNames() -> [String] {
        return Mirror.init(reflecting: self).children.compactMap{ $0.label }
    }
}

public class Serializable: NSObject, PropertyNames {
    
    override public var description: String {
        return "\(self.toDictionary())"
    }
    
}

extension Serializable {
    public func toDictionary() -> NSDictionary {
        //let aClass: AnyClass? = type(of: self)
        //var propertiesCount: CUnsignedInt = 0
        let propertiesInAClass = self.propertyNames()
                                //UnsafeMutablePointer<objc_property_t>? = class_copyPropertyList(aClass, &propertiesCount)
        let propertiesCount = propertiesInAClass.count
        let propertiesDictionary: NSMutableDictionary = NSMutableDictionary()
        
        var i = 0
        while i < Int(propertiesCount) {
            
            //let property = propertiesInAClass[i]
            let propName = propertiesInAClass[i]
            //let propName = String(cString: property_getName(property), encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            //let propertyType = property_getAttributes(property)
            let propValue: Any! = self.value(forKey: propName)
            
            if propValue is Serializable {
                propertiesDictionary.setValue((propValue as! Serializable).toDictionary(), forKey: propName)
            } else if propValue is Array<Serializable> {
                var subArray = Array<NSDictionary>()
                for item in (propValue as! Array<Serializable>) {
                    subArray.append(item.toDictionary())
                }
                propertiesDictionary.setValue(subArray, forKey: propName)
            } else if propValue is NSData {
                propertiesDictionary.setValue((propValue as! NSData).base64EncodedString(options: []), forKey: propName)
            } else if propValue is Bool {
                propertiesDictionary.setValue((propValue as! Bool), forKey: propName)
            } else if propValue is NSDate {
                let date = propValue as! NSDate
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "Z"
                let dateString = NSString(format: "/Date(%.0f000%@)/", date.timeIntervalSince1970, dateFormatter.string(from: date as Date))
                propertiesDictionary.setValue(dateString, forKey: propName)
                
            } else {
                propertiesDictionary.setValue(propValue, forKey: propName)
            }
            i += 1
        }
        
        return propertiesDictionary
    }
    
    public func toJSON() -> Data! {
        let dictionary = self.toDictionary()
        var data: Data!
        do {
            try data = JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions(rawValue: 0))
            return data
        } catch {
            print("toJSON failed: \(error.localizedDescription)")
        }
        return Data()
    }
    
    public func toJSONString() -> NSString {
        return NSString(data: self.toJSON(), encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue).rawValue)!
    }
}


