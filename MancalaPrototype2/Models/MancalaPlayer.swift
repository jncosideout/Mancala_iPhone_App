//
//  MancalaPlayer.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//
import Foundation
import GameKit
/**
 The player's representative in the game.
 This class is responsible for manipulating the gameboard during gameplay.
 
 There should only ever be two (2) MancalaPlayers in a game, Player 1 and Player 2.
 Once initialized as either Player 1 or 2, objects of this class can only manipulate their side of the board
 */
public class MancalaPlayer: NSObject, GKGameModelPlayer {
    
    //GKGameModel
    public var playerId: Int

    public var sum = 0
    public var bonusTurn = false
    public var player: Int
    public var winner = 0
    public var captured = 0
    public var preCaptureFromPit: PitNode?
    public var preStolenFromPit: PitNode?
    public var basePitAfterCapture: PitNode?
    public var captureText: String?
    public var bonusTurnText: String?
    
    ///default constructor
    public init (player: Int) {
        self.player = player
        self.playerId = player
    }
    /**
     Primary method responsible for executing a player's turn
     - Parameter choice: the name of the pit chosen by this player to begin his move. This method will only select from pits under the control of this MancalaPlayer
     - Parameter gameboard: the gameboard of the GameModel the MancalaPlayer is playing on
     - Returns: the number of beads picked up from the pit passed to the ```choice``` parameter before this method was called
     */
    public func fillHoles(_ choice: String, _ gameboard: CircularLinkedList<PitNode>) -> Int {
        do {
            let iter_pit = try findPit(choice, gameboard)
            
            var inHand = 0
            captured = 0
            bonusTurnText = nil
            captureText = nil
            bonusTurn = false
            
            guard let pit = *iter_pit else {
                print("1st iter_pit returned nil")
                return -1
            }
            
            guard 0 != pit.beads else {
                print("Cannot choose pit that is empty")
                return -1
            }
            
            inHand = pit.beads
            let updateButtonImages = inHand
            pit.beads = 0
            
            while inHand > 0 {
                //move to next pit
                ++iter_pit
                
                // '*' is overloaded to dereference and give address if ref type
                if let pit2 = *iter_pit  { //optional binding, may return nil

                    
                    if 1 == inHand {
                        // bonus turn conditions
                        if pit2.player == player && pit2.name == "BASE" {
                            bonusTurn = true
                            bonusTurnText = "Player \(player) gets a bonus turn! \r"
                            print(bonusTurnText ?? "")
                        }
                        
                        // capture conditions
                        if 0 == pit2.beads && pit2.name != "BASE" && pit2.player == player {
                            preCaptureFromPit = pit2.copyPit()
                            do {
                                captured = try capture(fromPit: pit2, gameboard)
                            } catch let error {
                                fatalError(error.localizedDescription)
                            }
                            // b/c we the one bead that initiated capture was added, we remove it
                            captured -= 1
                            
                            if captured > 0 {
                                if captured == 1 {
                                    captureText = "Player \(player) captured \(captured) bead!\r"
                                } else {
                                    captureText = "Player \(player) captured \(captured) beads!\r"
                                }
                            }
                            print(captureText ?? "")
                        }
                        
                    }
                    
                    if pit2.player != player && pit2.name == "BASE" {
                        //skip your opponent's base!
                        continue
                    }
                    // place the bead in the active pit
                    pit2.beads += 1
                    if captured > 0 {
                        pit2.beads = 0                                                                    
                    }
                    inHand = inHand - 1
                } else {
                    print("2nd iter_pit returned nil")
                    return -1
                }
            }//end while
            return updateButtonImages
            
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    /**
     - Parameter gameboard: the gameboard of the GameModel the MancalaPlayer is playing on
     - Returns: the total of all beads in pits on this player's side of the ```gameboard``` including pits # 1-6 but not this player's "BASE"
     */
    public func sumPlayerSide(_ gameboard: CircularLinkedList<PitNode>) -> Int {
        do {
            let iter_pit = try findPit("1", gameboard)
            
            var beads = 0
            var tSum = 0
            
            for _ in 1...(gameboard.length - 2)/2 {
                
                if let pit = *iter_pit {
                    
                    if pit.player != player || pit.name == "BASE" {
                        print("sumPlayerSide found unexpected pit:\n \(pit.description)")
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
        
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    /**
     Searches the ```gameboard``` to find any pit controlled by this player
     
     - Parameters:
        - pit: the name of this MancalaPlayer's pit to be found
        - gameboard: the ```CircularLinkedList<PitNode>)``` that is the ```gameboard``` this MancalaPlayer is playing on
     - Throws:pitNotFoundError
     
     */
    public func findPit(_ pit: String, _ gameboard: CircularLinkedList<PitNode>) throws -> LinkedListIterator<PitNode> {
        
        let myIter = gameboard.circIter
        
        ++myIter//move to "first" pit (player 1, pit #1)
        
        for _ in 1...gameboard.length {
            
            if let tempPit = *myIter {
                
                if (tempPit.name == pit && tempPit.player == player) {
                    return myIter
                } else {
                    ++myIter
                }
            }
        }
        
        throw Error.pitNotFoundError("Failed to find pit.")
    }
    
    /**
     Executes the capturing gameplay mechanism
    
        Because the ```findPit(_:_)``` method only seeks pits belonging to this MancalaPlayer, we must search for the opponents pit to steal from using this method
     
     ## Steps:
     1. Find the pit on the ```gameboard``` belonging to the opponent and sitting across the board from the capturing pit (```fromPit```).
     2. Transfer the beads from the opponent's adjacent pit (and the single bead that would have landed in ```fromPit```) to this player's "BASE" pit
    - Parameters:
       - fromPit: the ```PitNode``` owned by this MancalaPlayer from which the capture is initiated. This should always be the pit that the last bead fell into, and must belong to the player who began this turn.
       - gameboard: the ```CircularLinkedList<PitNode>)``` that is the ```gameboard``` this MancalaPlayer is playing on
     - Throws: ```captureError``` usually result from not finding a pitNode
     - Returns: the number of beads captured
    */
    public func capture(fromPit: PitNode?, _ gameboard: CircularLinkedList<PitNode>) throws -> Int {
        
        var captured = 0
        if let yourPit = fromPit {//need else to handle nil
            
            print("player \(yourPit.player) is capturing from pit \(yourPit.name)")
            
            
            let iter_oppo = gameboard.circIter //iterator for opponent, or opposite pit
            ++iter_oppo//move to "first" pit (player 1, pit #1)
            
            //to find the pit across the board from us...
            var targetStr = yourPit.name
            guard var target = Int(targetStr) else {
                fatalError("yourPit.name: \(yourPit.name), is not a number")
            }
            target = -1 * (target - gameboard.length/2)
            targetStr = String(target)
            
            var tempPit = *iter_oppo
            
            findOppositePit: for _ in 1...gameboard.length {//same as findPit() except != player
                
                guard tempPit != nil else {
                    let error = Error.captureError("Found nil while looking for opponent's pit to capture!")
                    throw error
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
                preStolenFromPit = pit_oppo.copyPit() //used by GameScene for animating the capture
                captured = pit_oppo.beads
                pit_oppo.beads = 0
                captured = captured + 1 //the one bead that initiated capture gets added
                //yourPit.beads = yourPit.beads - 1//bc have not finished fillHoles, last bead will go here, but it was included in capture
                
                //add captured to our base
                do {
                    let iter_myBase = try findPit("BASE", gameboard)
                    
                    if let myBase = *iter_myBase {
                        myBase.beads += captured
                        basePitAfterCapture = myBase.copyPit()
                    } else {
                        let error = Error.pitNotFoundError("myBase pit not found.\n Could not add captured beads to base.")
                        throw error
                    }
                } catch let error {
                    fatalError(error.localizedDescription)
                }
            } else {
                let error = Error.captureError("pit_oppo was nil")
                throw error
            }
            
        } else {
            let error = Error.captureError("fromPit was nil ")
            throw error
        }
        return captured
    }
    
    public func copyBoard(from originalBoard: CircularLinkedList<PitNode>) -> CircularLinkedList<PitNode> {
        
        let myIter = originalBoard.circIter
        ++myIter
        let copyBoard = CircularLinkedList<PitNode>()
        
        for _ in 1...originalBoard.length {
            if let pit = *myIter {
                let newPit = pit.copyPit()
                
                copyBoard.enqueue(newPit)
                ++myIter
            }
        }
        
        return copyBoard
    }
    
    func resetPlayer() {
        sum = 0
        bonusTurn = false
        winner = 0
        captured = 0
        preCaptureFromPit = nil
        preStolenFromPit = nil
        basePitAfterCapture = nil
        captureText = nil
        bonusTurnText = nil
    }
    
    private enum Error: Swift.Error {
        case captureError(String)
        case pitNotFoundError(String)
    }
}//EoC
