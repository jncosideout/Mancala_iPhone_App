///
///  Move.swift
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
 Implements ```GKGameModelUpdate``` to describe a move for the AI Strategist. Stores the information representing a move on the board and the value of that move to be uses by the GamplayKit AI when evaluating it.
 
 Based on code from the tutorial found at  https://www.raywenderlich.com/834-gameplaykit-tutorial-artificial-intelligence
 By Ryan Ackerman
 */
class Move: NSObject, GKGameModelUpdate {
    
    /// Allows the GameplayKit AI to judge the outcome of a move
    ///
    /// Will be assigned by ```score(for player:)``` in MancalaGameModel_GKAI-Extension
    enum Score: Int {
        case none = 0
        case moreBeadsInBase = 7
        case capture = 8
        case bonus = 9
        case clearedSide = 10
        case win = 11
    }
    
    /// Required by GKGameModelUpdate. Stores the score of the move.
    var value: Int = 0
    /// Stores the player number who's taking a turn for this move, and the pit name that player chose.
    var choice: (player: Int, pit: String)
    
    init(_ choice: (Int, String)) {
        self.choice = choice
    }
}
