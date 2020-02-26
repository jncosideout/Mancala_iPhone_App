//
//  Strategist.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 11/19/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import GameplayKit

struct Strategist {
    
    private let strategist: GKMinmaxStrategist = {
        let strategist = GKMinmaxStrategist()
        
        strategist.maxLookAheadDepth = 4
        strategist.randomSource = GKARC4RandomSource()
        
        return strategist
    }()
    
    var board: GameModel {
        didSet {
            strategist.gameModel = board
        }
    }
    
    var bestChoice: (player: Int, pit: String)? {
        print("in \(#function), called by board \(board) ")
        if let move = strategist.bestMove(for: board._activePlayer) as? Move {
            return move.choice
        }
        
        return nil
    }
    
}
