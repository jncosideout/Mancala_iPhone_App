//
//  SavedGameStore.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 1/22/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//
import Foundation

/**
 Supports saving to disk and loading the ```GameData``` for the "VS Human" and "VS Computer" local game modes
 
 The ```SavedGameStore``` and its ```allSavedGames``` are not injected into the GameViewController nor passed to the SKScenes. Instead, a [```GameModel```] array is passed which is initialized with the ```GameData``` in ```allSavedGames```. When the appDelegate calls applicationDidEnterBackground(_:) the ```SavedGameStore``` saves ```allSavedGames``` to disk. At this time, ```allSavedGames``` needs to be overwritten with the data from the injected [```GameModel```] array.
 
 The separation is partly for uncoupling reasons, but also because of the attributes of the containers [```GameModel```] and [```GameData```]. The [```GameModel```] array is useful for maintaining references to the data, but GameModels are not optimized for serializiation. ```GameData``` is a struct so it cannot be passed by reference, but it conforms to Codable so it can be serialized.
 + Important: The classes that interact with this one and which reference the injected [```GameModel```] which corresponds to it, all expect that ```allSavedGames``` contains exactly 2 elements, and that the first element is the ```GameData``` of "VS Computer" mode and the second element is the ```GameData``` of "VS Human" or "2 Player Mode." Changing this will break things.
 */
class SavedGameStore: Codable {
    
    ///The classes that interact with this one all expect that ```allSavedGames``` contains exactly 2 elements, and that the first element is the ```GameData``` of "VS Computer" mode and the second element is the ```GameData``` of "VS Human" or "2 Player Mode." Changing this will break things.
    var allSavedGames = [GameData]()
    
    /// Loads saved games from disk according to ```gameArchiveURL``` or creates brand new ```GameData``` if for the "VS Human" and "VS Computer" local game modes
    init() {
        if let archivedGames = loadSavedGame(from: gameArchiveURL) {
            allSavedGames = archivedGames
        } else {
            allSavedGames.append(GameData())
            allSavedGames.append(GameData())
        }
    }
    
    /// Wrapper for backupAndSaveAllGames. Initializes SavedGameStore without loading from disk
    ///
    ///  Used to save the [```GameModel```]  dependency before loading an Online game. Since using appDelegate's reference, this has been deprecated.
    @discardableResult init(withUpdated gameModelArray: [GameModel]) {
        backupAndSaveAllGames(gameModelArray)
    }
    
    //MARK: archiving tools for store
    
    ///storage path for archive
    let gameArchiveURL: URL = {
        let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent("games.archive")
    }()
    
    /// Simple JSONEncoder wrapper for ```allSavedGames```
    func saveGames() -> Bool {
        var data: Data
        
        do {
            try data = JSONEncoder().encode(allSavedGames)
            try data.write(to: gameArchiveURL)
            return true
        } catch {
            print("error saving game data to disk: \(error)" )
        }
        return false
    }
    
    /// Simple JSONDecoder wrapper for assigning data to ```allSavedGames```
    func loadSavedGame(from url: URL) -> [GameData]? {
        var archivedGames: [GameData]?
        if let nsData = NSData(contentsOf: url) {
            do {
                let data = Data(referencing: nsData)
                archivedGames = try JSONDecoder().decode([GameData].self, from: data)
                print("archivedGames array loaded from disk")
            } catch {
                print("error loading gameData: \(error)")
            }
        } else {
            print("no data in gameArchiveURL")
            return nil
        }
        return archivedGames
    }

    
    /// Extracts the ```GameData``` from an array of ```GameModel```s and overwrites the ```GameData``` of  ```allSavedGames```, then saves  ```allSavedGames``` to disk.
    ///
    /// - Parameter savedGameModels: Usually this is a reference to the external ```GameModel``` array which corresponds to ```allSavedGames``` in this ```SavedGameStore```.
    func backupAndSaveAllGames(_ savedGameModels: [GameModel]) {
        allSavedGames.removeAll()
        
        for i in 0...savedGameModels.count - 1 {
            let gameModel = savedGameModels[i]
            gameModel.saveGameData()
            allSavedGames.append(gameModel.gameData)
        }
        
        let success1 = saveGames()
        if success1 {
            print("saved array of game data")
        } else {
            print("could not save game data")
        }
    }
    
    /// Returns an array of ```GameModel```s initialized with the ```GameData``` of  ```allSavedGames```.
    func setupSavedGames() ->[GameModel] {
        var savedGameModels = [GameModel]()
        for gameData in allSavedGames {
            let gameModel = GameModel(from: gameData)
            savedGameModels.append(gameModel)
        }
        return savedGameModels
    }
    
}//EoC
