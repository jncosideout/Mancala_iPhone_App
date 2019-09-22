//
//  PitNode.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 8/31/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation

private struct PitNodeKeys {
    static let name = "name"
    static let player = "player"
    static let beads = "beads"
    static let previousBeads = "previousBeads"
    static let coordP1 = "coordP1"
    static let coordP2 = "coordP2"
    
}

public class PitNode2: NSObject, NSCoding {
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PitNodeKeys.name)
        aCoder.encode(player, forKey: PitNodeKeys.player)
        aCoder.encode(beads, forKey: PitNodeKeys.beads)
        aCoder.encode(previousBeads, forKey: PitNodeKeys.previousBeads)
        aCoder.encode(coordP1, forKey: PitNodeKeys.coordP1)
        aCoder.encode(coordP2, forKey: PitNodeKeys.coordP2)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObject(forKey: PitNodeKeys.name) as! String
        player = aDecoder.decodeInteger(forKey: PitNodeKeys.player)
        beads = aDecoder.decodeInteger(forKey: PitNodeKeys.beads)
        previousBeads = aDecoder.decodeObject(forKey: PitNodeKeys.previousBeads) as! Int?
        coordP1 = aDecoder.decodeObject(forKey: PitNodeKeys.coordP1) as! GameModel.GridCoordinate
        coordP2 = aDecoder.decodeObject(forKey: PitNodeKeys.coordP2) as! GameModel.GridCoordinate
    }
    
    public static func == (lhs: PitNode2, rhs: PitNode2) -> Bool {
        return (lhs.name == rhs.name) && (lhs.player == rhs.player)
    }
    
    
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
    
    func copyPit() -> PitNode2 {
        let pit = PitNode2()
        
        pit.name = self.name
        pit.player = self.player
        pit.beads = self.beads
        pit.previousBeads = self.previousBeads ?? nil
        pit.coordP1 = self.coordP1
        pit.coordP2 = self.coordP2
        return pit
    }
}


public class PitNode: NSObject, Codable {
    
    
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


