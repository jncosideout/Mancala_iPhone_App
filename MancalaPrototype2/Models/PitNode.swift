//
//  PitNode.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 8/31/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation
/**
 The base data structure model of the Mancala gameboard
 
 ### Primary attributes
 1. ```name```:  this pit's id
    - range: 1-6, "BASE"
 2. ```player```:  the id of the player controlling this pit
    - range: 1,2
 3. ```beads```:  number of beads in the pit at the current time
    - range: 0 -> *
 ### Secondary attributes
 1. ```previousBeads```:  a queue of the history of values of ```beads``` accumulated during a move
    - used only for animating the pit during a wrap-around move
    - cleared after every move
 2. ```mostRecentBeads```: used for storing the last value of ```beads```
    - specifically used for animating a capture
 3. ```coordP1```: the point on the gameboard for this pit, from **Player 1's** perspective
 4. ```coordP1```: the point on the gameboard for this pit, from **Player 2's** perspective
 */
public class PitNode: Codable, Equatable {
    ///his pit's id
    public var name: String
    ///the id of the player controlling this pit
    public var player: Int
    ///number of beads in the pit at the current time
    public var beads: Int {
        didSet {
            previousBeads.insert(oldValue, at: 0)
            mostRecentBeads = oldValue
        }
    }
    ///a queue of the history of values of ```beads``` accumulated during a move
    public var previousBeads = [Int]()
    ///used for storing the last value of ```beads```
    public var mostRecentBeads = 0
    ///the point on the gameboard for this pit, from **Player 1's** perspective
    var coordP1: GameModel.GridCoordinate
    ///the point on the gameboard for this pit, from **Player 2's** perspective
    var coordP2: GameModel.GridCoordinate
    
    public init (){
        name = ""
        player = 1
        beads = 0
        previousBeads.popLast()
        coordP1 = GameModel.GridCoordinate(x: GameModel.GridPosition_X.max, y: GameModel.GridPosition_Y.mid)
        coordP2 = GameModel.GridCoordinate(x: GameModel.GridPosition_X.min, y: GameModel.GridPosition_Y.mid)
    }
    
    public convenience init (player: Int, name: String) {
        self.init()
        self.player = player
        self.name = name
    }
    
    public static func == (lhs: PitNode, rhs: PitNode) -> Bool {
        return (lhs.name == rhs.name) && (lhs.player == rhs.player)
    }
    
    func copyPit() -> PitNode {
        let pit = PitNode()
        
        pit.name = self.name
        pit.player = self.player
        pit.beads = self.beads
        pit.mostRecentBeads = self.mostRecentBeads
        pit.previousBeads = self.previousBeads
        pit.coordP1 = self.coordP1
        pit.coordP2 = self.coordP2
        
        return pit
    }
    
    
}//EoC


extension PitNode {
    ///Formats the printed description of a PitNode
    public var description: String {
        
        var text = "["
        
        text += """
                pit.name = \(name)
                pit.player = \(player)
                pit.beads = \(beads)
                pit.mostRecentBeads = \(mostRecentBeads)
                pit.coordP1 = \(coordP1)
                pit.coordP2 = \(coordP2)
                pit.previousBeads
                \(previousBeads)
                """
        
        return text + "]"
    }
}



