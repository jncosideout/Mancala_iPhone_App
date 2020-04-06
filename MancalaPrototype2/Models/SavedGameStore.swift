//
//  SavedGameStore.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 1/22/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//
import Foundation

class SavedGameStore: Codable {
    
    var allSavedGames = [GameData]()
    
    init() {
        if let archivedGames = loadSavedGame(from: gameArchiveURL) {
            allSavedGames = archivedGames
        } else {
            allSavedGames.append(GameData())
            allSavedGames.append(GameData())
        }
    }
    
    @discardableResult init(withUpdated gameModelArray: [GameModel]) {
        saveAllGames(gameModelArray)
    }
    //MARK: archiving tools for store
    
    //storage path for archive
    let gameArchiveURL: URL = {
        let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent("games.archive")
    }()
    
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
    
    func saveAllGames(_ savedGameModels: [GameModel]) {
        
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
    
    func setupSavedGames() ->[GameModel] {
        var savedGameModels = [GameModel]()
        for gameData in allSavedGames {
            let gameModel = GameModel(from: gameData)
            savedGameModels.append(gameModel)
        }
        return savedGameModels
    }
    
}//EoC
