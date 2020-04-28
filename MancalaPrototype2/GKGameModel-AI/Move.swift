///
///  Move.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 11/19/19.
/// ============LICENSE_START=======================================================
/// Copyright © 2019 Alexander Scott Beaty. All rights reserved.
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================


import GameplayKit

/**
 Implements ```GKGameModelUpdate``` to describe a move for the AI Strategist. Stores the information representing a move on the board and the value of that move to be uses by the GamplayKit AI when evaluating it.
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
