//
//  MancalaGameModel.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation
import GameKit

class GameModel: NSObject {//removed Codable ASB 06/29/19 //changed struct to class, added NSCoding 7/27/19
    
    var winner: Int?
    var pits: CircularLinkedList<PitNode>
    let mancalaPlayer1 = MancalaPlayer.allPlayers[0]
    let mancalaPlayer2 = MancalaPlayer.allPlayers[1]
    var _activePlayer: MancalaPlayer
    var updateTokenNodes = 0
    var playerTurn: Int
    var sum1 = 0
    var sum2 = 0
    var playerTurnText = ""
    var winnerTextArray = [String]()
    var playerPerspective: Int  //debug: set = 2 to start with player 2 on bottom
    var gameData: GameData
    var turnNumber: Int
    var lastMovesList: [[Int : String]]
    
    //GKGameModel AI
    var bonusForPlayer: Int?
    var captureForPlayer: Int?

    static let player1Perspective = [
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
    
    var messagesToDisplay: [String] {
        if winner != nil {
            return winnerTextArray
        }
        
        if isCapturingPiece {
            return [_activePlayer.captureText!]
        }
        
        if hasBonusTurn {
            return [_activePlayer.bonusTurnText!]
        }
        
        return [playerTurnText]
    }
    
    var isCapturingPiece: Bool {
        return _activePlayer.captureText != nil
    }
    
    var hasBonusTurn: Bool{
        return _activePlayer.bonusTurnText != nil
    }
    
    var lastPlayerCaptured: Bool {
        return _activePlayer.bonusTurn
    }
    
    var lastPlayerBonusTurn: Bool {
        return _activePlayer.captured > 0
    }
    
    var lastPlayerCaptureText: String? {
        switchActivePlayer()
        let captureText = _activePlayer.captureText
        switchActivePlayer()
        return captureText
    }
    
    var lastPlayerBonusText: String? {
        switchActivePlayer()
        let bonusText = _activePlayer.bonusTurnText
        switchActivePlayer()
        return bonusText
    }
    
    
    //MARK: Initializers
  init(newGame: Bool) { //new game
        gameData = GameData()
        playerTurn = gameData.playerTurn
        playerPerspective = gameData.playerPerspective
        _activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
        pits = CircularLinkedList<PitNode>()
    
        if newGame {
            pits = GameModel.buildGameboard(pitsPerPlayer: 6)
        }
        turnNumber = gameData.turnNumber
        playerTurnText = gameData.playerTurnText
        lastMovesList = gameData.lastMovesList

    }
    
    init(replayWith gameData: GameData, for activePlayer: Bool) {
        self.gameData = gameData
        if let _playerTurn = gameData.lastMovesList.first?.keys.first {
            playerTurn = _playerTurn
        } else {
            playerTurn = gameData.playerTurn == 1 ? 2 : 1
        }//playerTurn should now be equal to the last player who moved, who's turn is being replayed
        
        if activePlayer {//gameData.playerTurn holds the actual current playerTurn, and gameData.playerPerspective refllects the turn of the last player to move
            playerPerspective = gameData.playerPerspective == 1 ? 2 : 1//reversed because the current player was not the last to move. We are replaying the opponent's move, and playerPerspective does not belong to the local player, it comes from our opponent
        } else {//otherwise, the local player is viewing the game after he moved, he is not the active player and the replay will present his last move to him
            playerPerspective = gameData.playerPerspective
        }
        _activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2//our opponent
        pits = GameModel.initGameboard(from: gameData.oldPitsList)//coming from opponent
        turnNumber = gameData.turnNumber
        playerTurnText = gameData.playerTurnText
        lastMovesList = gameData.lastMovesList

    }
    
    convenience init(from gameData: GameData) {
        self.init(newGame: true)
        self.gameData = gameData
        setUpGame(from: gameData)
        
    }
    
    convenience init(fromGKMatch gkMatchData: Data) {
        self.init(newGame: false)
        
        if !gkMatchData.isEmpty {
            do {
                gameData = try JSONDecoder().decode(GameData.self, from: gkMatchData)
                pits = GameModel.initGameboard(from: gameData.pitsList)
                playerTurn = gameData.playerTurn
                _activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
                turnNumber = gameData.turnNumber
                playerTurnText = gameData.playerTurnText
                winner = gameData.winner
                winnerTextArray = winnerTextArray
            } catch {
                print("error loading gkMatchData: \(error.localizedDescription)")
            }
        } else {
            pits = GameModel.buildGameboard(pitsPerPlayer: 6)
        }

        playerTurnText = gameData.playerTurnText
        printBoard(pits)
    }
   
    func setUpGame(from gameData: GameData) {
        if gameData.pitsList.count > 0 {
            pits = GameModel.initGameboard(from: gameData.pitsList)
        } else {
            pits = GameModel.buildGameboard(pitsPerPlayer: 6)//ASB TEMP magic number
        }
        playerTurn = gameData.playerTurn
        _activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
        playerPerspective = gameData.playerPerspective
        winner = gameData.winner
        playerTurnText = gameData.playerTurnText
        winnerTextArray = gameData.winnerTextArray
    }
    
    func resetGame() {
        mancalaPlayer1.resetPlayer()
        mancalaPlayer2.resetPlayer()
        updateTokenNodes = 0
        sum1 = 0
        sum2 = 0
        playerTurnText = ""
        winnerTextArray = [String]()
        turnNumber = 0
        lastMovesList = [[Int : String]]()
        
        //GKGameModel AI
        bonusForPlayer = 0
        captureForPlayer = 0
    }
    
    func copyModel(from model: GameModel) {
        pits = model._activePlayer.copyBoard(from: model.pits)
        playerTurn = model.playerTurn
        _activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
        playerPerspective = model.playerPerspective
        winner = model.winner
        playerTurnText = model.playerTurnText
    }
    
    func loadSavedGame(from url: URL) {
        if let nsData = NSData(contentsOf: url) {
            do {
                let data = Data(referencing: nsData)
                gameData = try JSONDecoder().decode(GameData.self, from: data)
                pits = GameModel.initGameboard(from: gameData.pitsList)
                playerTurn = gameData.playerTurn
                _activePlayer = playerTurn == 1 ? mancalaPlayer1 : mancalaPlayer2
                playerTurnText = gameData.playerTurnText
                winner = gameData.winner
                winnerTextArray = gameData.winnerTextArray
            } catch {
                print("error loading gameData: \(error)")
            }
        } else {
            print("no data in url")
            pits = GameModel.buildGameboard(pitsPerPlayer: 6) 
        }
    }
    
    //MARK: play functions
    func playPhase1 (_ player: Int,_ pit: String ) -> Int{
        lastMovesList.append([player : pit])
        bonusForPlayer = nil
        captureForPlayer = nil
        
        if player != _activePlayer.player || pit == "BASE" {
            return -1
        }
        
        updateTokenNodes = _activePlayer.fillHoles(pit, pits)
        
        return updateTokenNodes
    }
    
    func playPhase2() -> String {
        
        var bonus_count = 0
        var bonus = false
        bonus = determineBonusAndCapture()
        
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
            determineWinner(sum1, sum2)
            return ""
        } else {
            playerTurnText = ""
            playerTurnText += "Player \(playerTurn)'s turn."
            print(playerTurnText)

            return playerTurnText
        }
    }
    
    func determineBonusAndCapture() -> Bool{
        if _activePlayer.bonusTurn {
            bonusForPlayer = _activePlayer.playerId
        }
        
        if _activePlayer.captured > 0 {
            captureForPlayer = _activePlayer.playerId
        }
        
        return _activePlayer.bonusTurn
    }
    
    func determineWinner(_ sum1: Int, _ sum2: Int) {
        
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
                clearingPlayerTakesAll(from: 2)
                pit_base1.beads += sum2
            } else {
                clearingPlayerTakesAll(from: 1)
                pit_base2.beads += sum1
            }
            
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
        gameData.winnerTextArray = winnerTextArray
        mancalaPlayer1.bonusTurnText = nil
        mancalaPlayer1.captureText = nil
        mancalaPlayer2.bonusTurnText = nil
        mancalaPlayer2.captureText = nil
    }
    
    func clearingPlayerTakesAll(from player: Int) {
        
        let iterator = pits.circIter
        
        for _ in 1...pits.length {
            if let pit = *iterator {
                if pit.player == player && pit.name != "BASE" {
                    pit.beads = 0
                    if pit.previousBeads! < 0 {
                        pit.previousBeads = 0
                    }
                }
            }
            ++iterator
        }
    }
    
    //mutating
    func switchActivePlayer(){
        
        _activePlayer = _activePlayer.player == 2 ? mancalaPlayer1 : mancalaPlayer2//change players
    }
    
    //MARK: board setup
    
    static func initGameboard(from pitsList: [PitNode]) -> CircularLinkedList<PitNode> {
        let pitsCLL = CircularLinkedList<PitNode>()
        
        let checkPit = PitNode(player: 2, name: "BASE")
        
        guard pitsList.count > 0 else {
            fatalError("pitsList.count = \(pitsList.count)")
        }
        guard pitsList[0] == checkPit else {
            print("pitsList[0] not equal to BASE pit: \(pitsList[0])")
            return pitsCLL
        }
        
        for pit in pitsList {
            let copyOfPit = pit.copyPit()
            pitsCLL.enqueue(copyOfPit)
        }
        if pitsCLL.length != 14 {
            fatalError("Expected pitsCLL length = 14, got \(pitsCLL.length)")
        }
        pitsCLL.advanceLast()  // to point 'last' at Player 2's BASE
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
                        pitN.beads = 6
                        pitN.name = String(pit)
                    } else if pit == 2 {
                        pitN.beads = 5
                        pitN.name = String(pit)
                    } else if pit == 3 {
                        pitN.beads = 4
                        pitN.name = String(pit)
                    } else if pit == 4 {
                        pitN.beads = 3
                        pitN.name = String(pit)
                    } else if pit == 5 {
                        pitN.beads = 2
                        pitN.name = String(pit)
                    } else if pit == 6 {
                        pitN.beads = 1
                        pitN.name = String(pit)
                    } else if pit == 7 {
                        pitN.beads = 0
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
    
    static func buildGameboardTEST_END_GAME(pitsPerPlayer: Int ) -> CircularLinkedList<PitNode> {
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
                        pitN.beads = 1
                        pitN.name = String(pit)
                    } else if pit == 6 {
                        pitN.beads = 0
                        pitN.name = String(pit)
                    } else if pit == 7 {
                        pitN.beads = 30
                        pitN.name = "BASE"
                    }
                } else {    //player 2
                    if pit == 1 {
                        pitN.beads = 4
                        pitN.name = String(pit)
                    } else if pit == 2 {
                        pitN.beads = 4
                        pitN.name = String(pit)
                    } else if pit == 3 {
                        pitN.beads = 6
                        pitN.name = String(pit)
                    } else if pit == 4 {
                        pitN.beads = 0
                        pitN.name = String(pit)
                    } else if pit == 5 {
                        pitN.beads = 0
                        pitN.name = String(pit)
                    } else if pit == 6 {
                        pitN.beads = 0
                        pitN.name = String(pit)
                    } else if pit == 7 {
                        pitN.beads = 13
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
    
    func saveGameData() {
        gameData.playerTurn = playerTurn
        gameData.playerTurnText = playerTurnText
        gameData.winner = winner
        gameData.winnerTextArray = winnerTextArray
        gameData.pitsList.removeAll()
        gameData.pitsList = saveGameBoardToList(pits)
        gameData.playerPerspective = playerPerspective
        gameData.lastMovesList = lastMovesList
    }
    
    func saveDataToSend() -> Data {
        saveGameData()
        var data = Data()
        print("saving gameboard to send to opponent")
        do {
            try data = JSONEncoder().encode(gameData)
            return data
        } catch {
            print("error saving game data to send: \(error)" )
        }
        
        return data
    }
    
    func saveGameBoardToList(_ pits: CircularLinkedList<PitNode>) -> [PitNode] {
        guard pits.length > 0 else {
            fatalError("in saveGameBoardToList(), pits.lenth = \(pits.length)")
        }
        let copiedBoard = _activePlayer.copyBoard(from: pits)
        var pitsList = [PitNode]()
        var i = 0
        while !pits.isEmpty || i < pits.length {
            if let pit = copiedBoard.dequeue() {
                pitsList.append(pit)
            } else {
                break
            }
            i += 1
        }
        let lastPit = pitsList.popLast()
        
        return pitsList
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

extension GameModel: GKGameModel {
    
    //MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        print("in \(#function), called by board \(self) ")
        let copy = GameModel(newGame: true)
        print("copy = \(copy)")
        copy.setGameModel(self)
        return copy
    }
    
    //MARK: GKGameModel
    var players: [GKGameModelPlayer]? {
        return MancalaPlayer.allPlayers
    }
    
    var activePlayer: GKGameModelPlayer? {
        return _activePlayer
    }
    
    func setGameModel(_ gameModel: GKGameModel) {
        if let model = gameModel as? GameModel {
            print("in \(#function), called by board \(self) ")
            print("set equal to board \(model) ")
            copyModel(from: model)
        }
    }
    
    func isWin(for player: GKGameModelPlayer) -> Bool {
        guard let player = player as? MancalaPlayer else {
            return false
        }
        print("in \(#function) for \(player.player), board \(self) ")
        if let _winner = winner {
            print("playerId \(player.player) == winner \(_winner)")
            return player.playerId == _winner
        } else {
            return false
        }
    }
    
    func gameModelUpdates(for player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        guard let player = player as? MancalaPlayer else { return nil }
        print("in \(#function) for \(player.player), board \(self) ")
        if isWin(for: player) {
            return nil
        }
        print("back in \(#function) for \(player.player), board \(self) ")
        return validMoves(for: player)
    }
    
    func validMoves(for player: MancalaPlayer) -> [Move] {
        let playerBoardIterator = player.findPit("1", pits)
        var moves = [Move]()
        
        for _ in 1...pits.length/2 - 1 {
            if let pit = *playerBoardIterator {
                if pit.beads > 0 && pit.name != "BASE" && pit.player == player.playerId {
                    moves.append(Move((player.playerId, pit.name)))
                }
            }
            ++playerBoardIterator
        }
        return moves
    }
    
    func apply(_ gameModelUpdate: GKGameModelUpdate) {
        guard let move = gameModelUpdate as? Move else { return }
        print("in \(#function), called by board \(self) ")
        print("with move .player == \(move.choice.player), .pit == \(move.choice.pit)")
        playPhase1(move.choice.player, move.choice.pit)
        playPhase2()
    }
    
    func score(for player: GKGameModelPlayer) -> Int {
        guard let player = player as? MancalaPlayer else {
            return Move.Score.none.rawValue
        }
        print("back in \(#function) for \(player.player), board \(self) ")
        if isWin(for: player) {
            print("SCORE: \(Move.Score.win.rawValue) = \(Move.Score.win) ")
            return Move.Score.win.rawValue
        } else if isClearedSide(for: player) {
            print("SCORE: \(Move.Score.clearedSide.rawValue) = \(Move.Score.clearedSide)")
            return Move.Score.clearedSide.rawValue
        } else if isBonusTurn(for: player) {
            print("SCORE: \(Move.Score.bonus.rawValue) = \(Move.Score.bonus)")
            return Move.Score.bonus.rawValue
        } else if isCapture(for: player) {
            print("SCORE: \(Move.Score.capture.rawValue) = \(Move.Score.capture)")
            return Move.Score.capture.rawValue
        } else {
            let bonusPositioning = prepositioningForBonusTurns(for: player)
            print("SCORE: using prepositioningForBonusTurns is \(bonusPositioning)")
            if bonusPositioning > 0 {
                return bonusPositioning
            } else {
                let capturePositioning = prepositioningForCapture(for: player)
                print("SCORE: using prepositioningForCapture is \(capturePositioning)")
                if capturePositioning > 0 {
                    return capturePositioning
                } else if hasMoreBeadsInBase(for: player) {
                    print("SCORE:  \(Move.Score.moreBeadsInBase) = \(Move.Score.moreBeadsInBase.rawValue)")
                    return Move.Score.moreBeadsInBase.rawValue
                }
            }
        }
        print("SCORE: \(Move.Score.none) = \(Move.Score.none.rawValue)")
        return Move.Score.none.rawValue
    }
    
    func isClearedSide(for player: GKGameModelPlayer) -> Bool {
        guard let player = player as? MancalaPlayer else {
            return false
        }
        return player.sumPlayerSide(pits) == 0
    }
    
    func isBonusTurn(for player: GKGameModelPlayer) -> Bool {
        guard let player = player as? MancalaPlayer else {
            return false
        }
        
        if let _bonusFor = bonusForPlayer {
            return player.playerId == _bonusFor
        } else {
            return false
        }
    }
    
    func isCapture(for player: GKGameModelPlayer) -> Bool {
        guard let player = player as? MancalaPlayer else {
            return false
        }
        
        if let _captureFor = captureForPlayer {
            return player.playerId == _captureFor
        } else {
            return false
        }
    }
    
    func hasMoreBeadsInBase(for player: GKGameModelPlayer) -> Bool {
        guard let player = player as? MancalaPlayer else {
            return false
        }
        
        let baseP1_Iterator = mancalaPlayer1.findPit("BASE", pits)
        let baseP2_Iterator = mancalaPlayer2.findPit("BASE", pits)
        
        if let basePitP1 = *baseP1_Iterator, let basePitP2 = *baseP2_Iterator {
            if player.playerId == 1 {
                return basePitP1.beads > basePitP2.beads
            } else {
                return basePitP2.beads > basePitP1.beads
            }
        } else {
            return false
        }
    }
}//EoE GKGameModel
