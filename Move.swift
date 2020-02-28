//
//  Move.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 11/19/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import GameplayKit

class Move: NSObject, GKGameModelUpdate {
    
    enum Score: Int {
        case none = 0
        case moreBeadsInBase = 7
        case capture = 8
        case bonus = 9
        case clearedSide = 10
        case win = 11
    }
    
    var value: Int = 0
    var choice: (player: Int, pit: String)
    
    init(_ choice: (Int, String)) {
        self.choice = choice
    }
}
