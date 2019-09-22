//
//  PitNode.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 8/31/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation

@objc(objcPitNodeClass) public class PitNode: NSObject, Codable {
    
    
    public var name: String
    public var player: Int
    public var beads: Int {
        didSet {
            previousBeads = oldValue
        }
    }
    public var previousBeads: Int?
    var coordP1: GameModel.GridCoordinate
    var coordP2: GameModel.GridCoordinate
    
    public override init (){
        name = ""
        player = 1
        beads = 4
        coordP1 = GameModel.GridCoordinate(x: GameModel.GridPosition_X.max, y: GameModel.GridPosition_Y.mid)
        coordP2 = GameModel.GridCoordinate(x: GameModel.GridPosition_X.min, y: GameModel.GridPosition_Y.mid)
    }
    
    public static func == (lhs: PitNode, rhs: PitNode) -> Bool {
        return (lhs.name == rhs.name) && (lhs.player == rhs.player)
    }
    
    func copyPit() -> PitNode {
        let pit = PitNode()
        
        pit.name = self.name
        pit.player = self.player
        pit.beads = self.beads
        pit.previousBeads = self.previousBeads ?? nil
        pit.coordP1 = self.coordP1
        pit.coordP2 = self.coordP2
        
        return pit
    }
}


extension PitNode {
    
    override public var description: String {
        
        var text = "["
        
        text += """
                pit.name = \(self.name) \n
                pit.player = \(self.player) \n
                pit.beads = \(self.beads) \n
                pit.previousBeads = \(self.previousBeads ?? 0) \n
                pit.coordP1 = \(self.coordP1) \n
                pit.coordP2 = \(self.coordP2) \n
                """
        
        return text + "]"
    }
}


