///
///  MancalaGameModel_GKAI-Extension.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 2/22/20.
/// ============LICENSE_START=======================================================
/// Copyright (c) 2018 Razeware LLC
/// Modification Copyright © 2019 Alexander Scott Beaty. All rights reserved.
/// Modification License:
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================
/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import GameKit

/**
 Implements the main functions of ```GKGameModel```,_ copy(with:), var players, var activePlayer, setGameModel(_:), isWin(for:), gameModelUpdates(for:), apply(_:), and score(for:)_
 Documentation for these functions is provided by the GKGameModel API.
 All other functions are comprise a holistic heuristic that the AI uses to make "its best choice."
 
 Based on code from the tutorial found at  https://www.raywenderlich.com/834-gameplaykit-tutorial-artificial-intelligence
 By Ryan Ackerman
 */
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
    // The following methods are mandated by the GKGameModel protocol
    
    /// Holds a reference to the players in the game. In our case, mancalaPlayer1 and mancalaPlayer2
    var players: [GKGameModelPlayer]? {
        if let playersArray = allPlayers {
            return playersArray
        } else {
            print("ERROR: allPlayers == nil in GKAI-Extension")
            return nil
        }
    }
    
    /// A pointer to the _activePlayer of the current GameModel
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
    
    /// Helper function for ```gameModelUpdates(for)```. Looks for all available legal moves for a player.
    func validMoves(for player: MancalaPlayer) -> [Move] {
        do {
            let playerBoardIterator = try player.findPit("1", pits)
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
        } catch let error {
            fatalError(error.localizedDescription)
        }
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
    
    // MARK: - Basic tactics
    
    // Since the game ends when a player clears his side, and consequently gains all the beads remaining in his opponent's side, the AI should prioritize getting 0 beads on its side
    func isClearedSide(for player: GKGameModelPlayer) -> Bool {
        guard let player = player as? MancalaPlayer else {
            return false
        }
        return player.sumPlayerSide(pits) == 0
    }
    
    ///Allows Strategist AI extension to determine whether this player got a bonus turn after the last turn was taken
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
    
    ///Allows Strategist AI extension to determine whether this player got a capture after the last turn was taken
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
    
    /// The most basic metric for the Strategist to determine who is winning
    func hasMoreBeadsInBase(for player: GKGameModelPlayer) -> Bool {
        guard let player = player as? MancalaPlayer else {
            return false
        }
        do {
            let baseP1_Iterator = try mancalaPlayer1.findPit("BASE", pits)
            let baseP2_Iterator = try mancalaPlayer2.findPit("BASE", pits)
            
            if let basePitP1 = *baseP1_Iterator, let basePitP2 = *baseP2_Iterator {
                if player.playerId == 1 {
                    return basePitP1.beads > basePitP2.beads
                } else {
                    return basePitP2.beads > basePitP1.beads
                }
            } else {
                return false
            }
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

//MARK: - Advanced Tactics
    
    
    /// Allows the strategist to determine whether the state of the board has opportunity for getting bonus turns on the next turn
    ///
    /// + Returns: The number, between 1-6, of how many pits could be played to acheive bonus turns on the next turn for this player
    /// - Parameter player: the ```GKGameModelPlayer``` who will be affected by this calculation
    func prepositioningForBonusTurns(for player: GKGameModelPlayer) -> Int {
        guard let player = player as? MancalaPlayer else { return 0 }
        do {
            let boardIterator = try player.findPit(PitNodeName.pit_1.rawValue, pits)
            let halfBoardLength = pits.length/2
            let fullLoop = pits.length - 1
            var bonusPositions = 0
            
            for _ in 1...halfBoardLength - 1 {
                if let pit = *boardIterator {
                    let pitNameVal = PitNodeName(rawValue: pit.name)
                    if let pitNumber = pitNameVal?.integerRawValue() {
                        let beadsForBonus = halfBoardLength - pitNumber
                        if pit.beads % fullLoop == beadsForBonus {
                            bonusPositions += 1
                        }
                    }
                }
                ++boardIterator
            }
            return bonusPositions
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    /// Allows the strategist to determine whether the state of the board has opportunity for getting captures on the next turn
    ///
    /// Five is the highest expected return value. Since you need at least one empty pit to capture from, the maximum number of pits that could have their last bead land in the empty pit to cause the capture would be = 6 total pits on your side, minus 1 empty pit to capture from equals 5 non-empty pits to start the turn and end in a capture.
    ///
    /// - Interesting Side Note:
    ///
    ///     The probability of getting more pits prepositioned for capture goes up as you increase the number of empty pits that can be captured from, until you reach 3. However, this method does not calculate probability since it is supposed to be called after a move is applied by the strategist, so that the board in its future state can be analyzed. Therefore, each non-empty pit will have a real value in the future state that we will check for capture potential.
    /// + Returns: The number, between 1-5, of how many pits could be played to acheive a capture on the next turn for this player
    /// - Parameter player: the ```GKGameModelPlayer``` who will be affected by this calculation
    func prepositioningForCapture(for player: GKGameModelPlayer) -> Int {
        guard let player = player as? MancalaPlayer else { return 0 }
        let emptyPits = findEmptyPits(for: player)
        let nonEmptyPits = findNonEmptyPits(for: player)
        var adjacentPits = [PitNodeName]()
        var score = 0
        
        // get the adjacent pits names (the ones one the opponent's side of the board which are across from the empty pits on our side
        for pitName in emptyPits {
            if let oppoName = pitName.opposingPitName() {
                if let oppoPitName = PitNodeName(rawValue: oppoName) {
                    adjacentPits.append(oppoPitName)
                }
            }
        }
        
        // Get the opponent player to later find the PitNodes for the names in adjacentPits
        let opponent: MancalaPlayer
        if player.playerId == 1 {
            opponent = mancalaPlayer2
        } else {
            opponent = mancalaPlayer1
        }
        
        // Translate the list of PitNodeNames in adjacentPits into a list of PitNodes in opposingPitsList
        let opposingPitsList = findPits(using: adjacentPits, player: opponent)
        // Whittle downs the list by only using opponent pits that have beads to capture and return the PitNodeNames
        let oppoPitNamesToCapture = compareBeads(in: opposingPitsList, using:
                                                        { oppoBeads in
                                                            return oppoBeads > 0 })
        // Return 0 if the opponent does not have non-empty pits to capture
        if oppoPitNamesToCapture.isEmpty { return 0 }
        
        
        // Filter the emptyPits on our side to just those across from our opponent non-empty pits
        let potentialCaptureFromPitNames = emptyPits.filter{ emptyPitName in
            
            for oppoName in oppoPitNamesToCapture {
                if let ourPit = oppoName.opposingPitName() {
                    if let testPitName = PitNodeName(rawValue: ourPit) {
                        return emptyPitName == testPitName
                    }
                }
            }
            return false
        }
        
        // Get the non-empty pits
        let potentialStartingPits = findPits(using: nonEmptyPits, player: player)
        var numBeadsForCapture = 0
        // Compare each "capture-from" with each of the potentialStartingPits to measure the distance between each pair. If that distance is equal to the number of beads in the starting pit, then choosing that starting pit will result in a capture.
        for capturePit in potentialCaptureFromPitNames {
            if let a = capturePit.integerRawValue() {
                for (i, startingPit) in nonEmptyPits.enumerated() {
                    // Find the distance between them
                    if let b = startingPit.integerRawValue() {
                        if a > b {
                            numBeadsForCapture = a - b
                        } else {
                            // Wrap-around capture
                            numBeadsForCapture = (pits.length - 1) - (b - a)
                        }
                    }
                    let startingPitNode = potentialStartingPits[i]
                    if startingPitNode.beads == numBeadsForCapture {
                        // This pit would result in a capture
                        score += 1
                    }
                }
            }
        }
        
        return score
    }
    
    /// Use a simple formula to compare the beads of all pits belonging to a player. The pits examined are in the ```gameBoard``` of this GameModel.
    ///
    /// The ```gameBoard``` is the CircularLinkedList<PitNode> that belongs to this GameModel. The player's pits that will be examined are the pits 1-6, excluding the BASE.
    /// - Returns: A list of ```PitNodeName```s filtered by the expression in the ```formula```
    /// - Parameters:
    ///   - formula: a simple closure to evaluate givenBeads against a boolean expression
    ///   - player: the ```MancalaPlayer``` whose pits will be filtered and returned in the list of ```PitNodeName```s
    func compareBeadsInPits(using formula: (_ givenBeads: Int)->Bool, player: MancalaPlayer) -> [PitNodeName] {
        do {
            let boardIterator = try player.findPit(PitNodeName.pit_1.rawValue, pits)
            let halfBoardLength = pits.length/2
            var pitNames = [PitNodeName]()
            
            for _ in 1...halfBoardLength - 1 {
                if let pit = *boardIterator {
                    if formula(pit.beads) {
                        if let pitNameVal = PitNodeName(rawValue: pit.name) {
                            pitNames.append(pitNameVal)
                        }
                    }
                }
                ++boardIterator
            }
            return pitNames
        } catch let error {
                fatalError(error.localizedDescription)
        }
    }
    
    /// Wrapper for ```compareBeadsInPits``` to select only a player's empty pits
    func findEmptyPits(for player: MancalaPlayer) -> [PitNodeName] {
        return compareBeadsInPits(using: { givenBeads in
                                            return givenBeads == 0 },
                                            player: player)
    }
    
    /// Wrapper for ```compareBeadsInPits``` to select only a player's pits that are not empty
    func findNonEmptyPits(for player: MancalaPlayer) -> [PitNodeName] {
        return compareBeadsInPits(using: { givenBeads in
                                            return givenBeads > 0 },
                                            player: player)
    }
    
    /// Given a he list of ```PitNodeName```s, this method directly selects those pits from the ```gameBoard``` for a given player.
    ///
    /// Since this method uses MancalaPlayer.findPit(_:,_:), it will only seek the pits for the given player (either player 1 or 2). Also, the input of ```[PitNodeName]``` does not specify the player, just the pit names.
    /// - Returns: A list of ```PitNode```s matching the given list of ```PitNodeName```s for the ```player```
    /// - Parameters:
    ///   - pitNodeNames: the specific pits to search for. Must be predefined.
    ///   - player: the player whose pits are to be searched
    func findPits(using pitNodeNames: [PitNodeName], player: MancalaPlayer) -> [PitNode] {
        var pitList = [PitNode]()
        
        for nodeName in pitNodeNames {
            do {
                let boardIterator = try player.findPit(nodeName.rawValue, pits)
                if let pit = *boardIterator {
                    pitList.append(pit)
                }
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }
        return pitList
    }
    
    /// Use a simple formula to compare the beads in a specified list of ```PitNode```s using the given formula.
    ///
    /// The algorithm is agnostic regarding which MancalaPlayer owns the pits in the ```pitList```
    /// - Parameters:
    ///   - pitList: A predefined collection of pits
    ///   - formula: a simple closure to evaluate givenBeads against a boolean expression
    func compareBeads(in pitList: [PitNode], using formula: (_ givenBeads: Int)->Bool)-> [PitNodeName] {
        var pitNames = [PitNodeName]()
        
        for pit in pitList {
            if formula(pit.beads) {
                if let pitNameVal = PitNodeName(rawValue: pit.name) {
                    pitNames.append(pitNameVal)
                }
            }
        }
        return pitNames
    }
}//EoE

/// Used to quickly convert between a ``` PitNode.name``` string and the int it represents.
enum PitNodeName: String {
    case pit_1 = "1"
    case pit_2 = "2"
    case pit_3 = "3"
    case pit_4 = "4"
    case pit_5 = "5"
    case pit_6 = "6"
    case pit_Base = "BASE"
    
    func opposingPitName() -> String? {
        if let pitNumber = self.integerRawValue() {
            let oppositePitNumber = 7 - pitNumber
            return String(oppositePitNumber)
        }
        return nil
    }
    
    func integerRawValue() -> Int? {
        if let intRaw = Int(self.rawValue) {
            return intRaw
        }
        return nil
    }
    
    init?(by int: Int) {
        let str = String(int)
        self.init(rawValue: str)
    }
}
