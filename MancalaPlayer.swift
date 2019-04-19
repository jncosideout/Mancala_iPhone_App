import Foundation


public class PitNode {
    
    public var name: String
    public var player: Int
    public var beads: Int
    
    public init (){
        name = ""
        player = 1
        beads = 4
    }
}

public class MancalaPlayer {
    
    public var sum = 0
    public var bonusTurn = false
    public var player: Int
    public var winner = 0
    var captured = 0

    //default constructor
    public init (player: Int) {
        
        self.player = player
    }
    
    public func fillHoles(_ choice: String, _ gameboard: CircularLinkedList<PitNode>) -> Int {
        
        let iter_pit = findPit(choice, gameboard)
        var inHand = 0
        captured = 0
        
        guard let pit = *iter_pit else {
            print("1st iter_pit returned nil")
            return -1
        }
        
        guard 0 != pit.beads else {
            print("Cannot choose pit that is empty")
            return -1
        }
        
        bonusTurn = false
        
        inHand = pit.beads
        let updateButtonImages = inHand
        pit.beads = 0
        
        while inHand > 0 {
            
            ++iter_pit        //move to next pit
            
            // '*' is overloaded to dereference and give address if ref type
            if let pit2 = *iter_pit  { //optional binding, may return nil
                
                if 1 == inHand {
                    if pit2.player == player && pit2.name == "BASE" {
                        bonusTurn = true
                        print("Player  \(player)  gets a bonus turn! \n")
                    }
                    if 0 == pit2.beads && pit2.name != "BASE" && pit2.player == player {
                        captured = capture(fromPit: pit2, gameboard)
                        captured -= 1
                        print("Player  \(player) captured  \(captured) beads from opposing pit!\n")
                    }
                    
                }
                
                if pit2.player != player && pit2.name == "BASE" {
                    //skip your opponent's base!
                    continue
                }
                
                pit2.beads += 1
                inHand = inHand - 1
            } else {
                print("2nd iter_pit returned nil")
                return -1
            }
        }//end while
        return updateButtonImages
    }
    
    public func sumPlayerSide(_ gameboard: CircularLinkedList<PitNode>) -> Int {
        
        let iter_pit = findPit("1", gameboard)
        var beads = 0
        
        
        var tSum = 0
        
        for _ in 1...6 {//is this inclusive ... <= 6 ??? but we need exclusive .. < 6
            
            if let pit = *iter_pit {
                
                if pit.player != player || pit.name == "BASE" {
                    print("sumPlayerSide found BASE")
                    break
                }
                
                beads = pit.beads
                tSum = tSum + beads
                
                ++iter_pit
                
            } else {//end conditional binding for '*iter_pit'
                print("iter_pit returned nil")
                return 0
            }
        }
        sum = tSum
        
        return sum
    }
    
    public func findPit(_ pit: String, _ gameboard: CircularLinkedList<PitNode>) -> LinkedListIterator<PitNode> {
        
        let myIter = gameboard.circIter
        
        ++myIter//move to "first" pit (player 1, pit #1)
        
        for _ in 1...14 {//  need < 14
            
            if let tempPit = *myIter {
                
                if (tempPit.name == pit && tempPit.player == player) {
                    return myIter
                } else {
                    ++myIter
                }
            }
        }
        
        print("failed to find pit")
        return myIter
    }
    
    public func capture(fromPit: PitNode?, _ gameboard: CircularLinkedList<PitNode>) -> Int {
        
        var captured = 0
        if let yourPit = fromPit {//need else to handle nil
            
            print("player \(yourPit.player) is capturing from pit \(yourPit.name)")
            
            
            let iter_oppo = gameboard.circIter //iterator for opponent, or opposite pit
            ++iter_oppo//move to "first" pit (player 1, pit #1)
            
            //to find the pit across the board from us...
            var targetStr = yourPit.name
            guard var target = Int(targetStr) else {
                print("yourPit.name: \(yourPit.name), is not a number")
                return 0
            }
            target = -1 * (target - 7)
            targetStr = String(target)
            
            var tempPit = *iter_oppo
                
            findOppositePit: for _ in 1...14 {//same as findPit() except != player
                
                guard tempPit != nil else {
                    print("tempPit was nil")
                    return 0
                }
                
                if tempPit?.name == targetStr && tempPit?.player != player {
                    
                    guard 0 != tempPit?.beads else {//prevent capture of nothing
                        print("Opponent has nothing to capture!\n")
                        return 0
                    }
                    
                    //found the pit to steal from
                    break findOppositePit
                    
                }else{
                    ++iter_oppo
                    tempPit = *iter_oppo
                }
            }//end findOppositePit

                
                if let pit_oppo = *iter_oppo {//pit of opponent or opposite
                    captured = pit_oppo.beads
                    pit_oppo.beads = 0
                    captured = captured + 1 //the one bead that initiated capture gets added
                    yourPit.beads = yourPit.beads - 1//bc have not finished fillHoles, last bead will go here, but it was included in capture
                    
                    //add captured to our base
                    let iter_myBase = findPit("BASE", gameboard)
                    
                    if let myBase = *iter_myBase {
                        myBase.beads += captured
                    } else {
                        print("could not add captured beads to base")
                    }
                    
                } else {
                    print("pit_oppo was nil")
                    return 0
                }
 
        } else {
            print("fromPit was nil ")
            return 0
        }
        return captured
    }
}//EoC
