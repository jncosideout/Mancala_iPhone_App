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
    static let coord = "coord"
    
}

public class PitNode2: NSObject, NSCoding {
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PitNodeKeys.name)
        aCoder.encode(player, forKey: PitNodeKeys.player)
        aCoder.encode(beads, forKey: PitNodeKeys.beads)
        aCoder.encode(previousBeads, forKey: PitNodeKeys.previousBeads)
        aCoder.encode(coord, forKey: PitNodeKeys.coord)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObject(forKey: PitNodeKeys.name) as! String
        player = aDecoder.decodeInteger(forKey: PitNodeKeys.player)
        beads = aDecoder.decodeInteger(forKey: PitNodeKeys.beads)
        previousBeads = aDecoder.decodeObject(forKey: PitNodeKeys.previousBeads) as! Int?
        coord = aDecoder.decodeObject(forKey: PitNodeKeys.coord) as! GameModel.GridCoordinate
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
    var coord: GameModel.GridCoordinate
    
    public override init (){
        name = ""
        player = 1
        beads = 4
        coord = GameModel.GridCoordinate(x: GameModel.GridPosition_X.max, y: GameModel.GridPosition_Y.max)
    }
    
    func copyPit() -> PitNode2 {
        let pit = PitNode2()
        
        pit.name = self.name
        pit.player = self.player
        pit.beads = self.beads
        pit.previousBeads = self.previousBeads ?? nil
        pit.coord = self.coord
        
        return pit
    }
}


@objc(objcPitNodeClass) public class PitNode: NSObject, Codable {
    
    
    public var name: String
    public var player: Int
    public var beads: Int {
        didSet {
            previousBeads = oldValue
        }
    }
    public var previousBeads: Int?
    var coord: GameModel.GridCoordinate
    
    public override init (){
        name = ""
        player = 1
        beads = 4
        coord = GameModel.GridCoordinate()
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
        pit.coord = self.coord
        
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
                pit.previousBeads = \(self.previousBeads) \n
                pit.coord
                """
        
        return text + "]"
    }
}


