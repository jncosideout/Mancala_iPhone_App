//
//  MancalaGameModel_GKAI-Extension.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 2/22/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//

import Foundation
import GameKit

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
extension GameModel {
    
    func prepositioningForBonusTurns(for player: GKGameModelPlayer) -> Int {
        guard let player = player as? MancalaPlayer else { return 0 }
        
        let boardIterator = player.findPit(PitNodeNames.pit_1.rawValue, pits)
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
        let boardIterator = player.findPit(PitNodeNames.pit_1.rawValue, pits)
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
            let boardIterator = player.findPit(nodeName.rawValue, pits)
            if let pit = *boardIterator {
                pitList.append(pit)
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
