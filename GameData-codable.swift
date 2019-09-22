//
//  GameData.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 8/10/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation

struct GameData: Codable {
    
    init() {
        
        pitsList = [PitNode]()
        playerTurn = 1
        playerPerspective = 1
        playerTurnText = "Player \(playerTurn)'s turn"
        winner = nil
        turnNumber = 0
        firstPlayerID = ""
    }
    
    var pitsList: [PitNode]
    var playerTurn: Int
    var playerPerspective: Int
    var playerTurnText: String
    var winner: Int?
    var turnNumber: Int
    var firstPlayerID: String
    
}
