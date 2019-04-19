//
//  CircularLinkedList.swift
//
//
//  Created by Alexander Scott Beaty on 1/6/19.
//

import Foundation

public class CircularLinkedList<Elem> {
    
    private var last: NodeType<Elem>?
    private var length = 0
    
    public var isEmpty: Bool {
        return last == nil
    }
    
    public var tail: NodeType<Elem>{
        return last!
    }
    
    public var circIter: LinkedListIterator<Elem> {
        let temp = LinkedListIterator<Elem>(last)
        return temp
    }
    
    public init () {
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
        
        // else
        length += 1
    }
    
    @discardableResult func dequeue() -> Elem?  {
        
        if isEmpty {
            return nil
        }
        
        var first = tail.link       // set ptr to first node
        let x = first?.info
        // set return value
        
        if first === tail  {        // if single node
            last = nil      //  set list to empty
            
        } else {
            last?.link = first?.link   //  advance first to link node
        }
        first = nil                  // delete node
        
        length -= 1
        return x
        
        
    }
    
    deinit {
        
        while !isEmpty {
            dequeue()
        }
    }
    
}//EoC

extension CircularLinkedList: CustomStringConvertible {
    
    public var description: String {
        
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
}
