//
//  GameData.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 8/10/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation
/**
 Serializable struct used for saving GameData to disk or for transferring over a network
 
 All data in this class must reflect the MancalaGameModel. It should not have any members outside of the set of members in that class.
 */
struct GameData: Codable {
    
    init() {
        
        pitsList = [PitNode]()
        oldPitsList = [PitNode]()
        playerTurn = 1
        playerPerspective = 1
        playerTurnText = "Player \(playerTurn)'s turn"
        winner = nil
        turnNumber = 0
        firstPlayerID = ""
        lastPlayerID = ""
        lastMovesList = [[Int : String]]()
        winnerTextArray = [String]()
        onlineGameOver = false
    }
    
    var pitsList: [PitNode]
    var oldPitsList: [PitNode]
    var playerTurn: Int
    var playerPerspective: Int
    var playerTurnText: String
    var winner: Int?
    var turnNumber: Int
    var firstPlayerID: String
    var lastPlayerID: String
    var lastMovesList: [[Int : String]]
    var winnerTextArray: [String]
    var onlineGameOver: Bool
}
