//
//  MancalaGameModel.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation

class GameModel {//removed Codable ASB 06/29/19 //changed struct to class, added NSCoding 7/27/19
    
    var winner: Int?
    
    var pits: CircularLinkedList<PitNode> // ASB 06/29/19
    let mancalaPlayer1 = MancalaPlayer(player: 1)
    let mancalaPlayer2 = MancalaPlayer(player: 2)
    var activePlayer: MancalaPlayer
    var updateTokenNodes = 0
    var playerTurn: Int
    var sum1 = 0
    var sum2 = 0
    var playerTurnText = ""
    var winnerTextArray = [String]()
    var playerPerspective: Int  //debug: set = 2 to start with player 2 on bottom
    var gameData: GameData
    
    let player1Perspective = [//ASB 07/06/19 reversed positions
        GridCoordinate(x: .mid1, y: .min),//Ply 1 Pit 1
        GridCoordinate(x: .mid2, y: .min),
        GridCoordinate(x: .mid3, y: .min),
        GridCoordinate(x: .mid4, y: .min),//Ply 1 Pit 4
        GridCoordinate(x: .mid5, y: .min),
        GridCoordinate(x: .mid6, y: .min),
        
        GridCoordinate(x: .max, y: .mid),//base P1
        
        GridCoordinate(x: .mid6, y: .max),//Ply 2 Pit 1
        GridCoordinate(x: .mid5, y: .max),
        GridCoordinate(x: .mid4, y: .max),
        GridCoordinate(x: .mid3, y: .max),//Ply 2 Pit 4
        GridCoordinate(x: .mid2, y: .max),
        GridCoordinate(x: .mid1, y: .max),
        
        GridCoordinate(x: .min, y: .mid),//base P2
    ]
    
    let player2Perspective = [//player 2's perspective, reversed positions
        GridCoordinate(x: .mid6, y: .max),//Ply 1 Pit 1
        GridCoordinate(x: .mid5, y: .max),
        GridCoordinate(x: .mid4, y: .max),
        GridCoordinate(x: .mid3, y: .max),//Ply 1 Pit 4
        GridCoordinate(x: .mid2, y: .max),
        GridCoordinate(x: .mid1, y: .max),
        
        GridCoordinate(x: .min, y: .mid),//base P1
        
        GridCoordinate(x: .mid1, y: .min),//Ply 1 Pit 1
        GridCoordinate(x: .mid2, y: .min),
        GridCoordinate(x: .mid3, y: .min),
        GridCoordinate(x: .mid4, y: .min),//Ply 1 Pit 4
        GridCoordinate(x: .mid5, y: .min),
        GridCoordinate(x: .mid6, y: .min),
        
        GridCoordinate(x: .max, y: .mid),//base P1
    ]
    
    let gameDataArchiveURL: URL = {
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentDirectories.first!
        return documentDirectory.appendingPathComponent("gameData.archive")
    }()
    
    
    var messageToDisplay: String {
        //let playerName = isKnightTurn ? "Knight" : "Troll"
        if winner != nil {
            return playerTurnText
        }
        
        if isCapturingPiece {
            return activePlayer.captureText!
        }
        
        if hasBonusTurn {
            return activePlayer.bonusTurnText!
        }
        
        return playerTurnText
    }
    
    var isCapturingPiece: Bool {
        return activePlayer.captureText != nil
    }
    
    var hasBonusTurn: Bool{
        return activePlayer.bonusTurnText != nil
    }
    
    var lastPlayerCaptured: Bool {
        return activePlayer.captured > 0
    }
    
    var lastPlayerBonusTurn: Bool {
        return activePlayer.bonusTurn
    }
    
    var lastPlayerCaptureText: String? {
        switchActivePlayer()
        let captureText = activePlayer.captureText
        switchActivePlayer()
        return captureText
    }
    
    var lastPlayerBonusText: String? {
        switchActivePlayer()
        let bonusText = activePlayer.bonusTurnText
        switchActivePlayer()
        return bonusText
    }
    
    private var positions: [GridCoordinate]
    
    
    //MARK: Init
    
 
    
    init() { //new game
        gameData = GameData()
        playerTurn = gameData.playerTurn
        playerPerspective = 2//gameData.playerPerspective//DEBUG
        activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
        positions = playerPerspective == 1 ? player1Perspective : player2Perspective
        pits = gameData.pits
        
        buildGameboardTEST(pits, pitsPerPlayer: 6) // ASB 08/24/19
        
        playerTurnText = gameData.playerTurnText
        printBoard(pits)
    }
    
    convenience init(newGame: Bool) {
        self.init()
        
        if !newGame {
            print("loading data from \(gameDataArchiveURL.path)")
            
            if let nsData = NSData(contentsOf: gameDataArchiveURL) {
                do {
                    let data = Data(referencing: nsData)
                    registerConcreteSubclasses()
                    gameData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! GameData
                    pits = gameData.pits
                    playerTurn = gameData.playerTurn
                    activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
                    playerPerspective = gameData.playerPerspective
                    positions = playerPerspective == 1 ? player1Perspective : player2Perspective
                    playerTurnText = gameData.playerTurnText
                    winner = gameData.winner
                    
                } catch {
                    print("error loading gameData: \(error)")
                }
            }

            playerTurnText = gameData.playerTurnText
            printBoard(pits)
        }
        
    }
    
    convenience init(from gkMatchData: Data) {
        self.init()
        
        let nsData = NSData(data: gkMatchData)
        if !nsData.isEmpty {
            do {
                let data = Data(referencing: nsData)
                registerConcreteSubclasses()
                gameData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! GameData
                pits = gameData.pits
                playerTurn = gameData.playerTurn
                activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
                playerPerspective = gameData.playerPerspective
                positions = playerPerspective == 1 ? player1Perspective : player2Perspective
                playerTurnText = gameData.playerTurnText
                winner = gameData.winner
                
            } catch {
                print("error loading gameData: \(error.localizedDescription)")
            }
        }
        
        playerTurnText = gameData.playerTurnText
        printBoard(pits)
    }
    
    func registerConcreteSubclasses() {
        let nodePitNodeClass = NodeTypePitNode.self
        let nodePitClassName = String(describing: nodePitNodeClass)
        NSKeyedArchiver.setClassName(nodePitClassName, for: nodePitNodeClass)
        NSKeyedUnarchiver.setClass(nodePitNodeClass, forClassName: nodePitClassName)
        
        let circLinkListPitNodeClass = CircularLinkedList_PN.self
        let circLinkListPitNodeClassName = String(describing: circLinkListPitNodeClass)
        NSKeyedArchiver.setClassName(circLinkListPitNodeClassName, for: circLinkListPitNodeClass)
        NSKeyedUnarchiver.setClass(circLinkListPitNodeClass, forClassName: circLinkListPitNodeClassName)
        
    }
    
    func setUpGame(from gameData: GameData) {
        pits = gameData.pits
        buildGameboardTEST(pits, pitsPerPlayer: 6)
        playerTurn = gameData.playerTurn
        activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
        playerPerspective = gameData.playerPerspective
        positions = playerPerspective == 1 ? player1Perspective : player2Perspective
        winner = gameData.winner
        playerTurnText = gameData.playerTurnText
    }
    
    
    //MARK: play functions
    //mutating
    func playPhase1 (_ player: Int,_ pit: String ) -> Int{
        
        
        if player != activePlayer.player || pit == "BASE" {
            return -1
        }
        
        updateTokenNodes = activePlayer.fillHoles(pit, pits)
        
        if -1 == updateTokenNodes {
            //return if empty chosen pits
            return -1
            
        }
        return updateTokenNodes
    }
    
    //mutating
    func playPhase2() -> String {
        
        var bonus_count = 0
        var bonus = false
        bonus = activePlayer.bonusTurn
        
        repeat {
            playerTurn = (playerTurn == 1) ? 2 : 1//change turn
            switchActivePlayer()
            bonus_count += 1 //to switch back if bonus true
        } while (bonus_count < 2 && bonus)
        
        sum1 = mancalaPlayer1.sumPlayerSide(pits)
        sum2 = mancalaPlayer2.sumPlayerSide(pits)
        
        print("Player 1 remaining = \(sum1) \nPlayer 2 remaining = \(sum2) \n \n")
        print("After fill holes \n\n")
        printBoard(pits)
        
        if 0 == sum1 || 0 == sum2 {
            playerTurn = 0
            return determineWinner(sum1, sum2)
        } else {
            playerTurnText = ""
            playerTurnText += "Player \(playerTurn)'s turn."
            //            Choose a pit # 1-6 \r"
            //            playerTurnText += "Chose a pit from your side that is not empty \r"
            print(playerTurnText)
            return playerTurnText
            
        }
    }
    
    
    //mutating
    func determineWinner(_ sum1: Int, _ sum2: Int) -> String {
        
        playerTurnText = "game over \n"
        winnerTextArray.append(playerTurnText)
        print(playerTurnText)
        winner = nil
        let iter_base_1 = mancalaPlayer1.findPit("BASE", pits)
        let iter_base_2 = mancalaPlayer2.findPit("BASE", pits)
        
        if let pit_base1 = *iter_base_1, let pit_base2 = *iter_base_2 {
            playerTurnText = "Player 1 beads in base = \(pit_base1.beads) \nPlayer 2 beads in base = \(pit_base2.beads) \n\n"
            winnerTextArray.append(playerTurnText)
            print(playerTurnText)
            
            if 0 == sum1{
                pit_base1.beads += sum2
            } else {
                pit_base2.beads += sum1}
            
            if pit_base1.beads == pit_base2.beads {
                //tie
                winner = 0
            } else if pit_base1.beads > pit_base2.beads {
                winner = 1
            } else {
                winner = 2 }
            
            playerTurnText = "Final totals are \n Player 1 = \(pit_base1.beads) \n Player 2 =  \(pit_base2.beads) \n\n"
            winnerTextArray.append(playerTurnText)
            print(playerTurnText)
            
            if let theWinner = winner, theWinner != 0 {
                playerTurnText = "The winner is player \(theWinner)! Good work. :) \n"
                winnerTextArray.append(playerTurnText)
                print(playerTurnText)
            } else {
                playerTurnText = "Tie game. Way to go... :|\n"
                winnerTextArray.append(playerTurnText)
                print(playerTurnText)
            }
            
        } else {
            print("pit_base 1 or 2 was nil")
        }
        gameData.winner = winner ?? nil
        gameData.playerTurnText = playerTurnText
        mancalaPlayer1.bonusTurnText = nil
        mancalaPlayer1.captureText = nil
        mancalaPlayer2.bonusTurnText = nil
        mancalaPlayer2.captureText = nil
        
        return playerTurnText
    }
    
    
    //mutating
    func switchActivePlayer(){
        
        activePlayer = activePlayer.player == 2 ? mancalaPlayer1 : mancalaPlayer2//change players
    }
    
    //mutating
    func buildGameboard(_ pits: CircularLinkedList<PitNode>, pitsPerPlayer: Int ) {
        
        for player in 1...2 {
            for pit in 1...pitsPerPlayer + 1{
                
                let pitN = PitNode()
                pitN.player = player
                
                if pit == pitsPerPlayer + 1 {
                    pitN.beads = 0
                    pitN.name = "BASE"
                } else {
                    pitN.beads = 4
                    pitN.name = String(pit)
                }
                
                if player == 1 {
                    pitN.coord = positions[pit - 1]
                } else {
                    pitN.coord = positions[pit + pitsPerPlayer]
                }                //place pit in pits
                pits.enqueue(pitN)
            }
        }
    }
    
    func buildGameboardTEST(_ pits: CircularLinkedList<PitNode>, pitsPerPlayer: Int ) {
        
        for player in 1...2 {
            for pit in 1...pitsPerPlayer + 1{
                
                let pitN = PitNode()
                pitN.player = player
                
                if player == 1 {
                    if pit == 1 {
                        pitN.beads = 1
                        pitN.name = String(pit)
                    } else if pit == 2 {
                        pitN.beads = 2
                        pitN.name = String(pit)
                    } else if pit == 3 {
                        pitN.beads = 3
                        pitN.name = String(pit)
                    } else if pit == 4 {
                        pitN.beads = 4
                        pitN.name = String(pit)
                    } else if pit == 5 {
                        pitN.beads = 5
                        pitN.name = String(pit)
                    } else if pit == 6 {
                        pitN.beads = 6
                        pitN.name = String(pit)
                    } else if pit == 7 {
                        pitN.beads = 7
                        pitN.name = "BASE"
                    }
                } else {    //player 2
                    if pit == 1 {
                        pitN.beads = 8
                        pitN.name = String(pit)
                    } else if pit == 2 {
                        pitN.beads = 9
                        pitN.name = String(pit)
                    } else if pit == 3 {
                        pitN.beads = 10
                        pitN.name = String(pit)
                    } else if pit == 4 {
                        pitN.beads = 11
                        pitN.name = String(pit)
                    } else if pit == 5 {
                        pitN.beads = 12
                        pitN.name = String(pit)
                    } else if pit == 6 {
                        pitN.beads = 13
                        pitN.name = String(pit)
                    } else if pit == 7 {
                        pitN.beads = 14
                        pitN.name = "BASE"
                    }
                }
                if player == 1 {
                    pitN.coord = positions[pit - 1]
                } else {
                    pitN.coord = positions[pit + pitsPerPlayer]
                }
                //place pit in pits
                pits.enqueue(pitN)
            }
        }
    }
    
    func buildGameboardTEST_END_GAME(_ pits: CircularLinkedList<PitNode>, pitsPerPlayer: Int ) {
        
        for player in 1...2 {
            for pit in 1...pitsPerPlayer + 1{
                
                let pitN = PitNode()
                pitN.player = player
                
                if player == 1 {
                    if pit == 1 {
                        pitN.beads = 0
                        pitN.name = String(pit)
                    } else if pit == 2 {
                        pitN.beads = 0
                        pitN.name = String(pit)
                    } else if pit == 3 {
                        pitN.beads = 0
                        pitN.name = String(pit)
                    } else if pit == 4 {
                        pitN.beads = 0
                        pitN.name = String(pit)
                    } else if pit == 5 {
                        pitN.beads = 0
                        pitN.name = String(pit)
                    } else if pit == 6 {
                        pitN.beads = 1
                        pitN.name = String(pit)
                    } else if pit == 7 {
                        pitN.beads = 1
                        pitN.name = "BASE"
                    }
                } else {    //player 2
                    if pit == 1 {
                        pitN.beads = 8
                        pitN.name = String(pit)
                    } else if pit == 2 {
                        pitN.beads = 9
                        pitN.name = String(pit)
                    } else if pit == 3 {
                        pitN.beads = 10
                        pitN.name = String(pit)
                    } else if pit == 4 {
                        pitN.beads = 11
                        pitN.name = String(pit)
                    } else if pit == 5 {
                        pitN.beads = 12
                        pitN.name = String(pit)
                    } else if pit == 6 {
                        pitN.beads = 13
                        pitN.name = String(pit)
                    } else if pit == 7 {
                        pitN.beads = 14
                        pitN.name = "BASE"
                    }
                }
                if player == 1 {
                    pitN.coord = positions[pit - 1]
                } else {
                    pitN.coord = positions[pit + pitsPerPlayer]
                }
                //place pit in pits
                pits.enqueue(pitN)
            }
        }
    }
    
    func printBoard(_ gameboard: CircularLinkedList<PitNode>) {
        
        let myIter = gameboard.circIter
        
        ++myIter
        
        for _ in 1...pits.length {
            
            if let tempPit = *myIter {
                print("player:  \(tempPit.player)  pit name: \(tempPit.name) num beads: \(tempPit.beads)")
            } else {
                print("myIter could not get pit")
            }
            ++myIter
        }
        print("")
    }
    
    // MARK: - NScoding fxns
    func saveChanges() -> Bool {
        gameData.playerTurn = playerTurn
        gameData.playerPerspective = playerPerspective
        gameData.playerTurnText = playerTurnText
        gameData.winner = winner
        
        var data: Data

        print("saving gameboard to \(gameDataArchiveURL.path)")
        do {
            try data = NSKeyedArchiver.archivedData(withRootObject: gameData, requiringSecureCoding: false)
            try data.write(to: gameDataArchiveURL)
            
            return true
        } catch {
            print("error saving game data to disk: \(error)" )
        }
        return false
    }
    
    func saveDataModel() -> Data {
        gameData.playerTurn = playerTurn
        gameData.playerPerspective = playerPerspective
        gameData.playerTurnText = playerTurnText
        gameData.winner = winner
        
        var data = Data()
        
        print("saving gameboard to sent to opponent")
        do {
            try data = NSKeyedArchiver.archivedData(withRootObject: gameData, requiringSecureCoding: false)
            return data
        } catch {
            print("error saving game data to send: \(error)" )
        }
        
        return data
    }
        
    
}//EoC



// MARK: - Types

extension GameModel {
    
    enum Player: Int {
        case knight, troll
    }
    
    enum State: Int {
        case placement
        case movement
    }
    
    enum GridPosition_Y: Int, Codable {
        case min, mid, max
    }
    
    enum GridPosition_X: Int, Codable {
        case min, mid1, mid2, mid3, mid4, mid5, mid6, max
    }
    
    private struct GridCoordKeys {
        static let x = "x"
        static let y = "y"
    }
    
    public struct GridCoordinate: Codable, Equatable {
        public init(x: GridPosition_X = .min, y: GridPosition_Y = .min){
            self.x = x
            self.y = y
        }
        
        public var x: GridPosition_X
        public var y: GridPosition_Y
        
    }
//    @objc(objcGridCoordinateClass)class GridCoordinate: NSObject, NSCoding {
//        func encode(with aCoder: NSCoder) {
//            aCoder.encode(x.rawValue, forKey: GridCoordKeys.x)
//            aCoder.encode(y.rawValue, forKey: GridCoordKeys.y)
//        }
//
//        required init?(coder aDecoder: NSCoder) {
//            x = GameModel.GridPosition_X(rawValue: aDecoder.decodeInteger(forKey: GridCoordKeys.x))!
//            y = GameModel.GridPosition_Y(rawValue: aDecoder.decodeInteger(forKey: GridCoordKeys.y))!
//        }
//
//        var x: GridPosition_X
//        var y: GridPosition_Y
//
//        convenience init(x: GridPosition_X, y: GridPosition_Y) {
//            self.init()
//            self.x = x
//            self.y = y
//        }
//
//        override init() {
//            x = .max
//            y = .max
//            super.init()
//        }
//    }
    
    struct Token:  Equatable {
        let player: Player
        let coord: GridCoordinate
        var pit: PitNode
    }
    
    struct Move:  Equatable {
        var placed: GridCoordinate?
        var removed: GridCoordinate?
        var start: GridCoordinate?
        var end: GridCoordinate?
        
        init(placed: GridCoordinate?) {
            self.placed = placed
        }
        
        init(removed: GridCoordinate?) {
            self.removed = removed
        }
        
        init(start: GridCoordinate?, end: GridCoordinate?) {
            self.start = start
            self.end = end
        }
    }
}

