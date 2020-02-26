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

public class NodeType<Element> {
    
    public var  info: Element
    public var  link: NodeType<Element>?
    
    public init(_ info: Element) {
        self.info = info
    }
    
}//EoC
