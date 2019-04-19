import Foundation



public class LinkedListIterator<Type>
{
    //pointer to point to the current
    //node in the linked list
    private var current: NodeType<Type>?
    
    //Default constructor
    //Postcondition: current = nil
    public init () {
        current = nil
    }
    
    //Constructor with a parameter.
    //Postcondition: current = ptr;
    public init (_ ptr: NodeType<Type>?) {
        current = ptr
    }
    
}//EoC

prefix operator *
//prefix operator & cannot be overloaded
prefix operator ++
//do not declare the infix operators == !=

extension LinkedListIterator{
    //Function to overload the dereferencing operator *.
    //Postcondition: Returns the info contained in the node.
    //if  myinfo is a value type (Struct) then myinfo should be a copy
    //if myinfo is reference type (Class) then myinfo should be a ref to orig obj
    public static prefix func * (rhs: LinkedListIterator<Type>) -> Type? {
        let myinfo = rhs.current?.info
        return myinfo
    }
    
    //not allowed to overload the & operator
    
    //overoad address of operator &
    //Postcondition: return address of info
    //prefix operator &
    ////
    //    public static prefix func & (rhs: LinkedListIterator<Type>) -> Type? {
    //        var myInfo = rhs.current?.info
    //        return myInfo
    //    }
    
    //Overload the pre-increment operator.
    //Postcondition: The iterator is advanced to the next
    //               node.
    
    public static prefix func ++ (rhs: LinkedListIterator<Type>) {
        rhs.current = rhs.current?.link
    }
    
}//EoE

extension LinkedListIterator: Equatable {
    
    //Overload the equality operator.
    //Postcondition: Returns true if this iterator is equal to
    //               the iterator specified by right,
    //               otherwise it returns the value false.
    
    public static func == (lhs: LinkedListIterator<Type>, rhs: LinkedListIterator<Type>) -> Bool {
        
        return lhs.current === rhs.current
    }
    
    //You usually implement the == operator, and use the standard library’s default implementation of the != operator that negates the result of the == operator.
    
    //Overload the not equal to operator.
    //Postcondition: Returns true if this iterator is not
    //               equal to the iterator specified by
    //               right; otherwise it returns the value
    //               false.
    //
    //    public static func != (lhs: LinkedListIterator<Type>, rhs: LinkedListIterator<Type>) -> Bool {
    //
    //        return !(lhs.current === rhs.current)
    //    }
    
}//EoE
