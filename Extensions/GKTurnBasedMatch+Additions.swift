//
//  GKTurnBasedMatch+Additions.swift
//  MancalaPrototype2
//
//  Created by Alexander Scott Beaty on 7/30/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import Foundation

import GameKit

extension GKTurnBasedMatch {
    var isLocalPlayersTurn: Bool {
        return currentParticipant?.player == GKLocalPlayer.local
    }
    
    var others: [GKTurnBasedParticipant] {
        return participants.filter {
            return $0.player != GKLocalPlayer.local
        }
    }
}
