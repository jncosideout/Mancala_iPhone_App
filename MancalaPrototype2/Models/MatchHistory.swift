//
//  MatchHistory.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 3/6/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//

import Foundation
import GameKit

class MatchHistory {
    private enum Error: Swift.Error {
        case emptyData(String)
    }
    public enum UnlockedGameModes: Int {
        case fiveBeads = 5
        case sixBeads = 6
    }
    var allGamesPlayed: [String : GKTurnBasedMatch.Outcome]?
    //storage path for archive
    let allGamesPlayedURL: URL = {
        let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent("allGamesPlayed.archive")
    }()
    
    //MARK: - loading and saving
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
//        let totalKeys = allKeys.count
//        var i = 0
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
//                i += 1
//                if i >= totalKeys {
                self.countNumberOfWins()
                //if num wins > x
                //  send local notification to announce that the new game mode has been unlocked
                //  set boolean value to unlock new game mode
                //  boolean will unhide new game mode button in SettingsScene
                //  it will also change the num beads in pits in GameModel initGameboard(from: PitList) et al
                self.evaluateUnlockGameModesEarned()
//                }
                
            }
        }
           
        return true
    }
    
    
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
            //        check allGamesPlayed.keys if matchID does not exist
            //        if not, add to dictionary of [matchIDs : matchOutcome]
            //        save allGamesPlayed to Documents directory
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
        
    }
    
    func evaluateUnlockGameModesEarned() {
        //  send local notification to announce that the new game mode has been unlocked
        //  set boolean value to unlock new game mode
        //  boolean will unhide new game mode button in SettingsScene
        //  it will also change the num beads in pits in GameModel initGameboard(from: PitList) et al
        if UserDefaults.numberOfWonGames > 3 && !UserDefaults.unlockFiveBeadsStarting {
            UserDefaults.set(unlockFiveBeadsStarting: true)
            UserNotificationsHelper.scheduleUnlockGameNotification(after: 5.0, for: .fiveBeads)
        }
        if UserDefaults.numberOfWonGames > 5 && !UserDefaults.unlockSixBeadsStarting {
            UserDefaults.set(unlockSixBeadsStarting: true)
            UserNotificationsHelper.scheduleUnlockGameNotification(after: 6.0, for: .sixBeads)
        }
    }
    
    
}//EoC

extension GKTurnBasedMatch.Outcome : Codable {
//    private enum CodingKeys: CodingKey {
//
//    }
}
