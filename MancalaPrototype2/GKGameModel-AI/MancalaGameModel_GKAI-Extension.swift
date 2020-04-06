//
//  MancalaGameModel_GKAI-Extension.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 2/22/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//

import Foundation
import GameKit

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
        if let playersArray = allPlayers {
            return playersArray
        } else {
            print("ERROR: allPlayers == nil in GKAI-Extension")
            return nil
        }
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
//EoE GKGameModel

//MARK: - tactics
    func prepositioningForBonusTurns(for player: GKGameModelPlayer) -> Int {
        guard let player = player as? MancalaPlayer else { return 0 }
        do {
            let boardIterator = try player.findPit(PitNodeNames.pit_1.rawValue, pits)
            let halfBoardLength = pits.length/2
            let fullLoop = pits.length - 1
            var bonusPositions = 0
            
            for _ in 1...halfBoardLength - 1 {
                if let pit = *boardIterator {
                    let pitNameVal = PitNodeNames(rawValue: pit.name)
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
    
    func prepositioningForCapture(for player: GKGameModelPlayer) -> Int {
        guard let player = player as? MancalaPlayer else { return 0 }
        let emptyPits = findEmptyPits(for: player)
        let nonEmptyPits = findNonEmptyPits(for: player)
        var adjacentPits = [PitNodeNames]()
        var score = 0
        
        for pitName in emptyPits {
            if let oppoName = pitName.opposingPitName() {
                if let oppoPitName = PitNodeNames(rawValue: oppoName) {
                    adjacentPits.append(oppoPitName)
                }
            }
        }
        let opponent: MancalaPlayer
        if player.playerId == 1 {
            opponent = mancalaPlayer2
        } else {
            opponent = mancalaPlayer1
        }
        
        let opposingPitsList = findPits(using: adjacentPits, player: opponent)
        let oppoPitNamesToCapture = compareBeads(in: opposingPitsList, using:
                                                        { oppoBeads in
                                                            return oppoBeads > 0 })
        if oppoPitNamesToCapture.isEmpty { return 0 }
        
        var potentialCaptureFromPitNames = [PitNodeNames]()
        for oppoName in oppoPitNamesToCapture {
            if let ourPit = oppoName.opposingPitName() {
                if let testPit = PitNodeNames(rawValue: ourPit) {
                    if emptyPits.contains(testPit) {
                        potentialCaptureFromPitNames.append(testPit)
                    }
                }
            }
        }
        
        let potentialStartingPits = findPits(using: nonEmptyPits, player: player)
        var numBeadsForCapture = 0
        for capturePit in emptyPits {
            if let a = capturePit.integerRawValue() {
                for (i, startingPit) in nonEmptyPits.enumerated() {
                    if let b = startingPit.integerRawValue() {
                        if a > b {
                            numBeadsForCapture = a - b
                        } else {
                            numBeadsForCapture = (pits.length - 1) - (b - a)
                        }
                    }
                    let startingPitNode = potentialStartingPits[i]
                    if startingPitNode.beads == numBeadsForCapture {
                        score += 1
                    }
                }
            }
        }
        
        return score
    }
    
    
    func compareBeadsInPits(using formula: (_ givenBeads: Int)->Bool, player: MancalaPlayer) -> [PitNodeNames] {
        do {
            let boardIterator = try player.findPit(PitNodeNames.pit_1.rawValue, pits)
            let halfBoardLength = pits.length/2
            var pitNames = [PitNodeNames]()
            
            for _ in 1...halfBoardLength - 1 {
                if let pit = *boardIterator {
                    if formula(pit.beads) {
                        if let pitNameVal = PitNodeNames(rawValue: pit.name) {
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
    
    func findEmptyPits(for player: MancalaPlayer) -> [PitNodeNames] {
        return compareBeadsInPits(using: { givenBeads in
                                            return givenBeads == 0 },
                                            player: player)
    }
    
    func findNonEmptyPits(for player: MancalaPlayer) -> [PitNodeNames] {
        return compareBeadsInPits(using: { givenBeads in
                                            return givenBeads > 0 },
                                            player: player)
    }
    
    func findPits(using pitNodeNames: [PitNodeNames], player: MancalaPlayer) -> [PitNode] {
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
    
    func compareBeads(in pitList: [PitNode], using formula: (_ givenBeads: Int)->Bool)-> [PitNodeNames] {
        var pitNames = [PitNodeNames]()
        
        for pit in pitList {
            if formula(pit.beads) {
                if let pitNameVal = PitNodeNames(rawValue: pit.name) {
                    pitNames.append(pitNameVal)
                }
            }
        }
        return pitNames
    }
}//EoE

enum PitNodeNames: String {
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
