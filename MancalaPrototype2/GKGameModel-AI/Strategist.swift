///
///  Strategist.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 11/19/19.
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

import GameplayKit

/**
 Houses a ```GKMinmaxStrategist``` and a reference to the current GameModel it is analyzing. Implements ```GKMinmaxStrategist.bestMove(for:)``` to allow this AI Strategist to calculate the best move for a player.
 
 Based on code from the tutorial found at  https://www.raywenderlich.com/834-gameplaykit-tutorial-artificial-intelligence
 By Ryan Ackerman
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
