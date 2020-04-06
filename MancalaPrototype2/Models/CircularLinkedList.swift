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
/**
    Data structure of linked nodes of type ```Elem``` where the last node is linked to the first node
 
 ### Best Practices
    1. Try not to move the ```last``` pointer to any other node once the ```CircularLinkedList``` has been created.
 
        The methods of this class are assuming that ```last``` remains fixed on its node
    2. The list is always initialized with ```last = nil```
 */
public class CircularLinkedList<Elem: Codable>: NSObject, NSCoding {
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(last, forKey: Keys.last)
        aCoder.encode(length, forKey: Keys.length)
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        last = aDecoder.decodeObject(forKey: Keys.last) as! NodeType<Elem>?
        length = aDecoder.decodeInteger(forKey: Keys.length)
    }
    
    
    private var last: NodeType<Elem>?
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
    
    public func advanceLast() {
        last = last?.link
    }
    /**
        append a node to the end of this list
            
        if list is empty, creates a single node list
     
     
        - Parameter q: ```<Elem>``` type of ```q```  must be of same type of this ```CircularLinkedList<Elem>```
     */
    public func enqueue(_ q: Elem) {
        
        let newNode = NodeType<Elem>(q)      // new node
        
        if last == nil {                     // if empty list
            last = newNode                   // create single node list
            newNode.link = newNode
            
        } else {
            newNode.link = last?.link        // append node to end list
            last?.link = newNode
            last = newNode
        }
        
        length += 1
    }
    
    /**
        Removes the node pointed to by ```last``` ,  and moves the ```last``` pointer to the next node in the list
     
     - Returns: the ```info``` of the last node. If list is empty, returns ```nil```
     */
    @discardableResult func dequeue() -> Elem?  {
        
        if isEmpty {
            length = 0
            return nil
        }
        
        var node = last          // set ptr to last node
        let x = node?.info       // set return value
        
        if last?.link === last  {// if single node
            last = nil           // set list to empty
            return nil
        } else {
            last = last?.link    // advance last to next node
        }
        node?.link = nil
        node = nil               // delete node
        
        length -= 1
        return x
        
        
    }
    
    deinit {
        
        while !isEmpty {
            dequeue()
        }
    }
    /**
        Rolls out the info contained in each node of this list
     */
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
