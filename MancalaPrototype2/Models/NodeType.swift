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
/**
    Generic class used in linked lists
 */
public class NodeType<Element> {
    ///the data of this node. Use LinkdedListIterator to dereference the node with \* and return its ```info```
    public var  info: Element
    ///the link to the next node
    public var  link: NodeType<Element>?
    
    public init(_ info: Element) {
        self.info = info
    }
    
}//EoC
