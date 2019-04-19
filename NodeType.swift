//
//  NodeType.swift
//
//
//  Created by Alexander Scott Beaty on 1/6/19.
//

import Foundation

public class NodeType<Element> {
    
    public var  info: Element
    public var  link: NodeType<Element>?
    
    public init(_ info: Element) {
        self.info = info
    }
    
    
}

