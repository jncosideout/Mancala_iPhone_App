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
    var turnNumber: Int
    
    static let player1Perspective = [//ASB 07/06/19
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
    
    static let player2Perspective = [//player 2's perspective, P1 on top
        GridCoordinate(x: .mid6, y: .max),//Ply 1 Pit 1
        GridCoordinate(x: .mid5, y: .max),
        GridCoordinate(x: .mid4, y: .max),
        GridCoordinate(x: .mid3, y: .max),//Ply 1 Pit 4
        GridCoordinate(x: .mid2, y: .max),
        GridCoordinate(x: .mid1, y: .max),
        
        GridCoordinate(x: .min, y: .mid),//base P1
        
        GridCoordinate(x: .mid1, y: .min),//Ply 2 Pit 1
        GridCoordinate(x: .mid2, y: .min),
        GridCoordinate(x: .mid3, y: .min),
        GridCoordinate(x: .mid4, y: .min),//Ply 2 Pit 4
        GridCoordinate(x: .mid5, y: .min),
        GridCoordinate(x: .mid6, y: .min),
        
        GridCoordinate(x: .max, y: .mid),//base P2
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
        return activePlayer.bonusTurn
    }
    
    var lastPlayerBonusTurn: Bool {
        return activePlayer.captured > 0
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
    
    
    //MARK: Initializers
  init(newGame: Bool) { //new game
        gameData = GameData()
        playerTurn = gameData.playerTurn
        playerPerspective = gameData.playerPerspective
        activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
        pits = CircularLinkedList<PitNode>()
        if newGame {
            pits = GameModel.buildGameboard(pitsPerPlayer: 6)
        }
        turnNumber = gameData.turnNumber
        playerTurnText = gameData.playerTurnText
    }
    
    convenience init(savedGame: Bool) {
        self.init(newGame: !savedGame)
        
        if savedGame {
            print("loading data from \(gameDataArchiveURL.path)")
            
            if let nsData = NSData(contentsOf: gameDataArchiveURL) {
                do {
                    let data = Data(referencing: nsData)
                    gameData = try JSONDecoder().decode(GameData.self, from: data)
                    pits = GameModel.initGameboard(from: gameData.pitsList)
                    playerTurn = gameData.playerTurn
                    activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
                    playerTurnText = gameData.playerTurnText
                    winner = gameData.winner
                    
                } catch {
                    print("error loading gameData: \(error)")
                }
            } else {
                pits = GameModel.buildGameboardTEST(pitsPerPlayer: 6) // ASB 08/24/19
            }
            
            playerTurnText = gameData.playerTurnText
            printBoard(pits)
        }
        
    }
    
    convenience init(from gkMatchData: Data) {
        self.init(newGame: false)
        
        let nsData = NSData(data: gkMatchData)
        if !nsData.isEmpty {
            do {
                let data = Data(referencing: nsData)
                gameData = try JSONDecoder().decode(GameData.self, from: data)
                pits = GameModel.initGameboard(from: gameData.pitsList)
                playerTurn = gameData.playerTurn
                activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
                turnNumber = gameData.turnNumber
                playerTurnText = gameData.playerTurnText
                winner = gameData.winner
                
            } catch {
                print("error loading gameData: \(error.localizedDescription)")
            }
        } else {
            pits = GameModel.buildGameboardTEST(pitsPerPlayer: 6) // ASB 08/24/19
        }
        
        playerTurnText = gameData.playerTurnText
        printBoard(pits)
    }
   
    func setUpGame(from gameData: GameData) {
        pits = GameModel.buildGameboardTEST(pitsPerPlayer: 6)
        playerTurn = gameData.playerTurn
        activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
        playerPerspective = gameData.playerPerspective
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
    
    //MARK: board setup
    
    static func initGameboard(from pitsList: [PitNode]) -> CircularLinkedList<PitNode> {
        let pitsCLL = CircularLinkedList<PitNode>()
        
        let checkPit = PitNode()
        checkPit.player = 2
        checkPit.name = "BASE"
        
        guard pitsList.count > 0 else {
            fatalError("pitsList.count = \(pitsList.count)")
        }
        guard pitsList[0] == checkPit else {
            print("pitsList[0] not equal to BASE pit: \(pitsList[0])")
            return pitsCLL
        }
        
        for pit in pitsList {
            pitsCLL.enqueue(pit)
        }
        if pitsCLL.length != 14 {
            fatalError("Expected pitsCLL length = 14, got \(pitsCLL.length)")
        }
        pitsCLL.advanceLast()  // to point last at Player 2's BASE
        return pitsCLL
    }
    
    static func buildGameboard(pitsPerPlayer: Int ) -> CircularLinkedList<PitNode> {
        let pitsCLL = CircularLinkedList<PitNode>()
        
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
                    pitN.coordP1 = player1Perspective[pit - 1]
                    pitN.coordP2 = player2Perspective[pit - 1]
                } else {
                    pitN.coordP1 = player1Perspective[pit + pitsPerPlayer]
                    pitN.coordP2 = player2Perspective[pit + pitsPerPlayer]
                }
                pitsCLL.enqueue(pitN)//place pit in pits
            }
        }
        
        return pitsCLL
    }
    
    static func buildGameboardTEST(pitsPerPlayer: Int ) -> CircularLinkedList<PitNode> {
        let pits = CircularLinkedList<PitNode>()
        
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
                    pitN.coordP1 = GameModel.player1Perspective[pit - 1]
                    pitN.coordP2 = GameModel.player2Perspective[pit - 1]
                } else {
                    pitN.coordP1 = GameModel.player1Perspective[pit + pitsPerPlayer]
                    pitN.coordP2 = GameModel.player2Perspective[pit + pitsPerPlayer]
                }
                
                pits.enqueue(pitN)//place pit in pits
            }
        }
        return pits
    }
    
    func buildGameboardTEST_END_GAME(pitsPerPlayer: Int ) -> CircularLinkedList<PitNode> {
        let pits = CircularLinkedList<PitNode>()
        
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
                    pitN.coordP1 = GameModel.player1Perspective[pit - 1]
                    pitN.coordP2 = GameModel.player2Perspective[pit - 1]
                } else {
                    pitN.coordP1 = GameModel.player1Perspective[pit + pitsPerPlayer]
                    pitN.coordP2 = GameModel.player2Perspective[pit + pitsPerPlayer]
                }
                
                pits.enqueue(pitN)//place pit in pits
            }
        }
        return pits
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
    
    // MARK: - saving data
    
    func saveChanges() -> Bool {
        gameData.playerTurn = playerTurn
        gameData.playerPerspective = playerPerspective
        gameData.playerTurnText = playerTurnText
        gameData.winner = winner
        gameData.pitsList.removeAll()
        var data: Data
        saveGameBoardToList()
        
        print("saving gameboard to \(gameDataArchiveURL.path)")
        do {
            try data = JSONEncoder().encode(gameData)
            try data.write(to: gameDataArchiveURL)
            return true
        } catch {
            print("error saving game data to disk: \(error)" )
        }
        return false
    }
    
    func saveDataToSend() -> Data {
        gameData.playerTurn = playerTurn
        gameData.playerTurnText = playerTurnText
        gameData.winner = winner
        gameData.pitsList.removeAll()
        var data = Data()
        saveGameBoardToList()
        
        print("saving gameboard to send to opponent")
        do {
            try data = JSONEncoder().encode(gameData)
            return data
        } catch {
            print("error saving game data to send: \(error)" )
        }
        
        return data
    }
    
    func saveGameBoardToList() {
        guard pits.length > 0 else {
            fatalError("in saveGameBoardToList(), pits.lenth = \(pits.length)")
        }
        let copiedBoard = activePlayer.copyBoard(from: pits)
        var i = 0
        while !pits.isEmpty || i < pits.length {
            if let pit = copiedBoard.dequeue() {
                gameData.pitsList.append(pit)
            } else {
                break
            }
            i += 1
        }
        let lastPit = gameData.pitsList.popLast()
        //print(lastPit)//DEBUG
    }
    
}//EoC



// MARK: - Types

extension GameModel {
    
   
    
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
    
    struct Token:  Equatable {
        let coord: GridCoordinate
        var pit: PitNode
    }
   
}

