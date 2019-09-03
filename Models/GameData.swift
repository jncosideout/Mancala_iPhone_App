//
//  GameData.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 8/10/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation

struct GameModelKeys {
    static let pits = "pits"
    static let playerTurn = "playerTurn"
    static let playerPerspective = "playerPerspective"
    static let playerTurnText = "playerTurnText"
    static let winner = "winner"
}

class GameData: NSObject, NSCoding {
    
    override init() {
        
        pits = CircularLinkedList<PitNode>()
        playerTurn = 1
        playerPerspective = 1
        playerTurnText = "Player \(playerTurn)'s turn"
        winner = nil
    }
    
    var pits: CircularLinkedList<PitNode>
    var playerTurn: Int
    var playerPerspective: Int
    var playerTurnText: String
    var winner: Int?
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(pits, forKey: GameModelKeys.pits)
        aCoder.encode(playerTurn, forKey: GameModelKeys.playerTurn)
        aCoder.encode(playerPerspective, forKey: GameModelKeys.playerPerspective)
        aCoder.encode(playerTurnText, forKey: GameModelKeys.playerTurnText)
        aCoder.encode(winner, forKey: GameModelKeys.winner)
    }
    
    required init?(coder aDecoder: NSCoder) {//saved game
        pits = aDecoder.decodeObject(forKey: GameModelKeys.pits) as! CircularLinkedList<PitNode>
        playerTurn = aDecoder.decodeInteger(forKey: GameModelKeys.playerTurn)
        playerPerspective = aDecoder.decodeInteger(forKey: GameModelKeys.playerPerspective)
        playerTurnText = aDecoder.decodeObject(forKey: GameModelKeys.playerTurnText) as! String
        winner = aDecoder.decodeObject(forKey: GameModelKeys.winner) as! Int?
        
    }
}
