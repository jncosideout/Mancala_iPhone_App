//
//  CircularLinkedList.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation

struct Keys {
    static let last = "last"
    static let length = "length"
    
}

public class CircularLinkedList<Elem: Codable>: NSObject, NSCoding {
    
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(last, forKey: Keys.last)
        aCoder.encode(length, forKey: Keys.length)
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        last = aDecoder.decodeObject(forKey: Keys.last) as! NodeType<Elem>?
        length = aDecoder.decodeInteger(forKey: Keys.length)
    }
    
    
    var last: NodeType<Elem>?
    public var length = 0
    
    public var isEmpty: Bool {
        return last == nil
    }
  
    
    public var circIter: LinkedListIterator<Elem> {
        let temp = LinkedListIterator<Elem>(last)
        return temp
    }
    
    public override init () {
        last = nil
    }
    
    
    
    public func enqueue(_ q: Elem) {
        
        let newNode = NodeType<Elem>(q)      // new node
        
        if last == nil {               // if empty list
            last = newNode            //  create single node list
            newNode.link = newNode
            
        } else {
            newNode.link = last?.link    //  append node to end list
            last?.link = newNode
            last = newNode
        }
        
        length += 1
    }
    
    @discardableResult func dequeue() -> Elem?  {
        
        if isEmpty {
            return nil
        }
        
        var node = last       // set ptr to last node
        let x = node?.info        // set return value
        
        if node === last  {        // if single node
            last = nil      //  set list to empty
            
        } else {
            last = last?.link   //  advance last to next node
        }
        node = nil                  // delete node
        
        length -= 1
        return x
        
        
    }
    
    deinit {
        
        while !isEmpty {
            dequeue()
        }
    }
    
    public override var description: String {
        
        var text = "["
        var node = last
        var len = length
        
        while node != nil && len > 0 {
            text += "\(node!.info)"
            node = node?.link
            if node != nil { text += "," }
            len -= 1
        }
        return text + "]"
    }
    
}//EoC

public class CircularLinkedList_PN: CircularLinkedList<PitNode> {
    
    public var tail: NodeTypePitNode{
        return (last as? NodeTypePitNode? ?? nil)!
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(tail, forKey: Keys.last)
        aCoder.encode(length, forKey: Keys.length)
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        last = aDecoder.decodeObject(forKey: Keys.last) as! NodeTypePitNode
        length = aDecoder.decodeInteger(forKey: Keys.length)
    }
    
    public override init () {
        super.init()
    }
    
    public override var circIter: LinkedListIterator_PN {
        let temp = LinkedListIterator_PN(tail)
        return temp
    }
    
    
    
    public override func enqueue(_ q: PitNode) {
        
        let newNode = NodeTypePitNode(q)      // new node
        
        if last == nil {               // if empty list
            last = newNode            //  create single node list
            newNode.link = newNode
            
        } else {
            newNode.link = last?.link as? NodeTypePitNode   //  append node to end list
            last?.link = newNode
            last = newNode
        }
        
        length += 1
    }

    
}
