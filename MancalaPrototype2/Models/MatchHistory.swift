//
//  MatchHistory.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 3/6/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//

import Foundation
import GameKit
/**
 Since Game Center does not keep track of games deleted by the user in the Game Center View Controller, this class is used to store a back-up log of the outcome of every match played.
The primary purpose of this is to determine if the user (identified by their Game Center profile) has earned the right to unlock the new game modes.
 */
class MatchHistory {
    private enum Error: Swift.Error {
        case emptyData(String)
    }
    public enum UnlockedGameModes: Int {
        case fiveBeads = 5
        case sixBeads = 6
    }
    var allGamesPlayed: [String : GKTurnBasedMatch.Outcome]?
    ///storage path for archive
    let allGamesPlayedURL: URL = {
        let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent("allGamesPlayed.archive")
    }()
    
    //MARK: - loading and saving
    
    ///Load the ```allGamesPlayed``` Dictionary from disk, or create one if none is present
    func loadAllGamesPlayedDict() {
        print("baseURL" + (allGamesPlayedURL.baseURL?.absoluteString ?? "\nbaseURL not found\nabsoluteURL\n" + allGamesPlayedURL.absoluteURL.absoluteString))
        
         if let nsData = NSData(contentsOf: allGamesPlayedURL) {
             do {
                 let data = Data(referencing: nsData)
                 allGamesPlayed = try JSONDecoder().decode([String : GKTurnBasedMatch.Outcome].self, from: data)
                 print("allGamesPlayed array loaded from disk")
             } catch {
                 print("error loading allGamesPlayed: \(error)")
             }
         } else {
            allGamesPlayed = [String : GKTurnBasedMatch.Outcome]()
            print("Created new dictionary because no data in allGamesPlayed url")
         }
     
    }
    
    ///Serialize and save the data in ```allGamesPlayed```
    func saveData() -> Bool {
        var data: Data
        
        do {
            try data = JSONEncoder().encode(allGamesPlayed)
            try data.write(to: allGamesPlayedURL)
            return true
        } catch {
            print("error saving allGamesPlayed to disk \n: \(error)" )
        }
        return false
    }
    
    //MARK: - check list of all matches
    
    /**
     If ```allGamesPlayed``` has previously been saved to disk and has values, this method uses ```GKTurnBasedMatch.load(withID:)``` to check the ```matchOutcome``` of each match that was recorded as ```none```
     
     For each match, this method also checks to see if the user has unlocked any new game modes.
     */
    func updateHistoricalMatchOutcomes()-> Bool {
        guard allGamesPlayed != nil else {
            print("allGamesPlayed was not initialized \n Cannot updateHistoricalMatchOutcomes")
            return false
        }
        let allKeys = allGamesPlayed!.keys
        if allKeys.count < 1 {
            print("allGamesPlayed has no keys")
            return false
        }

        // Only update matches in ```allGamesPlayed``` that have not been finished, in case the game ended since the last time we checked
        for matchId in allKeys where allGamesPlayed?[matchId] == GKTurnBasedMatch.Outcome.none {
            GKTurnBasedMatch.load(withID: matchId) { match, error in
                if let theError = error {
                    print("ERROR: Could not load match in " + #function + "\n" + theError.localizedDescription)
                    return
                }
                guard let _match = match else {
                    print(#function + "match was nil")
                    return
                }
                GameCenterHelper.helper.checkOutcome(_match)
                for participant in _match.localParticipant {
                    self.allGamesPlayed![matchId] = participant.matchOutcome
                }

                self.countNumberOfWins()
                //if num wins > x
                //  send local notification to announce that the new game mode has been unlocked
                //  set boolean value to unlock new game mode
                //  boolean will unhide new game mode button in SettingsScene
                //  it will also change the num beads in pits in GameModel initGameboard(from: PitList) et al
                self.evaluateUnlockGameModesEarned()
                
            }
        }
           
        return true
    }
    
    /**
    Call this method if ```updateHistoricalMatchOutcomes()``` fails.
    
    Uses ```GKTurnBasedMatch.loadMatches(withID:)``` to check the ```matchOutcome``` of each match.
    
    For each match, this method also checks to see if the user has unlocked any new game modes

    + Important: ```GKTurnBasedMatch.loadMatches(withID:)``` can only retrieve the matches that currently exist in this user's Game Center profile for this app. Matches that were deleted in Game Center cannot be retrieved.
    */
    func updateCurrentMatchOutcomes() {
        guard allGamesPlayed != nil else {
            print("allGamesPlayed was not initialized \n Cannot updateCurrentMatchOutcomes")
            return
        }
        GKTurnBasedMatch.loadMatches { (allCurrentMatches, error) in
            if let theError = error {
                print("ERROR: Could not load match in MatchHistory \n" + theError.localizedDescription)
                return
            }
            // Copy the ```matchOutcome```s of each match retrieved from Game Center and add or update them in ```allGamesPlayed```
            if let allActiveMatches = allCurrentMatches {
                for match in allActiveMatches {
                    GameCenterHelper.helper.checkOutcome(match)
                    for participant in match.localParticipant {
                        self.allGamesPlayed!.updateValue(participant.matchOutcome, forKey: match.matchID)
                    }
                }
            }
            self.countNumberOfWins()
            //if num wins > x
            //  send local notification to announce that the new game mode has been unlocked
            //  set boolean value to unlock new game mode
            //  boolean will unhide new game mode button in SettingsScene
            //  it will also change the num beads in pits in GameModel initGameboard(from: PitList) et al
            self.evaluateUnlockGameModesEarned()
        }
    }
    
    /// Tallies the wins recorded in ```allGamesPlayed```
    func countNumberOfWins() {
        guard allGamesPlayed != nil else {
            print("allGamesPlayed was not initialized \n Cannot countNumberOfWins")
            return
        }
        var numWonGames = 0
        let outcomes = allGamesPlayed!.values
        for outcome in outcomes {
            if outcome == .won {
                numWonGames += 1
                UserDefaults.set(numberOfWonGames: numWonGames)
            }
        }
        print("numWonGames = \(numWonGames)")
        
    }
    
    ///  send local notification to announce that the new game mode has been unlocked
    ///
    ///  1. set boolean value to unlock new game mode
    ///  2. boolean will unhide new game mode button in SettingsScene
    ///     + it will also change the num beads in pits in GameModel initGameboard(from: PitList) et al
    func evaluateUnlockGameModesEarned() {
        if UserDefaults.numberOfWonGames > 11 && !UserDefaults.unlockFiveBeadsStarting {
            UserDefaults.set(unlockFiveBeadsStarting: true)
            UserNotificationsHelper.scheduleUnlockGameNotification(after: 5.0, for: .fiveBeads)
        }
        if UserDefaults.numberOfWonGames > 13 && !UserDefaults.unlockSixBeadsStarting {
            UserDefaults.set(unlockSixBeadsStarting: true)
            UserNotificationsHelper.scheduleUnlockGameNotification(after: 6.0, for: .sixBeads)
        }
    }
    
    
}//EoC

/// Conformance to Codable is generated by compiler but we still need to declare it here.
extension GKTurnBasedMatch.Outcome : Codable { }
