//
//  NodeType.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation

private struct NodeTypeKeys {
    static let info = "info"
    static let link = "link"
}

public class NodeType<Element: Codable>: NSObject, NSCoding {
    
    public func encode(with aCoder: NSCoder) {
        var data = Data()
        do {
            try data = JSONEncoder().encode(info)
        } catch {
            print("Error JSONEncoder: \(error.localizedDescription)")
        }
        //let element = data as! Element
        aCoder.encode(data, forKey: NodeTypeKeys.info)
        aCoder.encode(link, forKey: NodeTypeKeys.link)
    }

    
    required public init?(coder aDecoder: NSCoder) {
        
        let someData = aDecoder.decodeObject(forKey: NodeTypeKeys.info) as! Data
        var newElement: Element?
        do {
            // 3
            newElement = try JSONDecoder().decode(Element.self, from: someData)
        } catch {
            print("Error NodeType required init?(): \(error.localizedDescription)")
        }
        
        info = newElement!
        link = aDecoder.decodeObject(forKey: NodeTypeKeys.link) as? NodeType<Element>? ?? nil
    }
    
    public var  info: Element
    public var  link: NodeType<Element>?
    
    public init(_ info: Element) {
        self.info = info
    }
    
}


public class NodeTypePitNode: NodeType<PitNode>, Codable {
    
    required public init(from decoder: Decoder)  {
        super.init(PitNode())
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public var link2: NodeTypePitNode { return link as! NodeTypePitNode }
    
    public override func encode(with aCoder: NSCoder) {
        var data = Data()
        do {
            try data = JSONEncoder().encode(info)
        } catch {
            print("Error JSONEncoder: \(error.localizedDescription)")
        }
        //let element = data as! Element
        aCoder.encode(data, forKey: NodeTypeKeys.info)
        aCoder.encode(link2, forKey: NodeTypeKeys.link)
    }

    
    public override init(_ info: PitNode) {
        super.init(info)
    }
    
}

extension NSObject {
    var theClassName: String{
        return NSStringFromClass(type(of: self))
    }
}
