//
//  MancalaPlayer.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//
import Foundation
import GameKit

public class MancalaPlayer: NSObject, GKGameModelPlayer {
    
    //GKGameModel
    public var playerId: Int
    static var allPlayers = [MancalaPlayer(player: 1), MancalaPlayer(player: 2)]

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
    
    //default constructor
    public init (player: Int) {
        self.player = player
        self.playerId = player
    }
    
    public func fillHoles(_ choice: String, _ gameboard: CircularLinkedList<PitNode>) -> Int {
        
        let iter_pit = findPit(choice, gameboard)
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
        
        //check for overlapping move
        var overlapDiff = 0
        var didOverlap = false
        if inHand > gameboard.length - 1 {
            overlapDiff = inHand - gameboard.length - 2
            didOverlap = true
        }
        
        while inHand > 0 {
            //move to next pit
            ++iter_pit
            
            // '*' is overloaded to dereference and give address if ref type
            if let pit2 = *iter_pit  { //optional binding, may return nil
                
                if didOverlap && overlapDiff == inHand {
                    /*
                     In this scenario we save the board at the point just before the initiating is filled.
                     This way we can animate up to that point then animate from the initiating pit instead of  showing post-move board's pit-bead values too early
                     */
                    //copyBoard(from: gameboard)
                }
                
                if 1 == inHand {
                    // bonus turn conditions
                    if pit2.player == player && pit2.name == "BASE" {
                        bonusTurn = true
                        bonusTurnText = "Player  \(player)  gets a bonus turn! \r"
                        print(bonusTurnText ?? "")
                    }
                    // capture conditions
                    /*
                     In this scenario we save the board at the point just before the capture pit is filled.
                     This way we can animate up to that point then animate the capture instead of  showing post-capture pit-bead values too early
                     */
                    if 0 == pit2.beads && pit2.name != "BASE" && pit2.player == player {
                        preCaptureFromPit = pit2.copyPit()
                        captured = capture(fromPit: pit2, gameboard)
                        captured -= 1
                        
                        if captured > 0 {
                            if captured == 1 {
                                captureText = "Player  \(player) captured  \(captured) bead!\r"
                            } else {
                                captureText = "Player  \(player) captured  \(captured) beads!\r"
                            }
                        }
                        print(captureText ?? "")
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
        
        for _ in 1...(gameboard.length - 2)/2 {
            
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
        
        for _ in 1...gameboard.length {
            
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
            target = -1 * (target - gameboard.length/2)
            targetStr = String(target)
            
            var tempPit = *iter_oppo
            
            findOppositePit: for _ in 1...gameboard.length {//same as findPit() except != player
                
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
                preStolenFromPit = pit_oppo.copyPit()
                captured = pit_oppo.beads
                pit_oppo.beads = 0
                captured = captured + 1 //the one bead that initiated capture gets added
                yourPit.beads = yourPit.beads - 1//bc have not finished fillHoles, last bead will go here, but it was included in capture
                
                //add captured to our base
                let iter_myBase = findPit("BASE", gameboard)
                
                if let myBase = *iter_myBase {
                    myBase.beads += captured
                    basePitAfterCapture = myBase.copyPit()
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
}//EoC
