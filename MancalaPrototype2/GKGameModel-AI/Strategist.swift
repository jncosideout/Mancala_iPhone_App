///
///  Strategist.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 11/19/19.
/// ============LICENSE_START=======================================================
/// Copyright © 2019 Alexander Scott Beaty. All rights reserved.
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================

import GameplayKit

/**
 Houses a ```GKMinmaxStrategist``` and a reference to the current GameModel it is analyzing. Implements ```GKMinmaxStrategist.bestMove(for:)``` to allow this AI Strategist to calculate the best move for a player.
 */
struct Strategist {
    
    private let strategist: GKMinmaxStrategist = {
        let strategist = GKMinmaxStrategist()
        /// Increase this value to increase the number of copies of the GameModel that the strategist looks at to plan its best move. The strategist will simulate playing the game on each board for X number of moves into the future, where X is also the maxLookAheadDepth
        strategist.maxLookAheadDepth = 2
        strategist.randomSource = GKARC4RandomSource()
        
        return strategist
    }()
    
    var board: GameModel {
        didSet {
            strategist.gameModel = board
        }
    }
    
    /// Represents a ```Move``` object (which is a ```GKGameModelUpdate```) returned by calling ```GKMinmaxStrategist.bestMove(for:)```
    var bestChoice: (player: Int, pit: String)? {
        print("in \(#function), called by board \(board) ")
        if let move = strategist.bestMove(for: board._activePlayer) as? Move {
            return move.choice
        }
        
        return nil
    }
    
}
