//
//  UserDefaultsExtension.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 2/21/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//
import Foundation

extension UserDefaults {
    
    class var allowGradientAnimations: Bool {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: UserDefaults.Keys.AllowGradientAnimations) == nil {
            UserDefaults.set(allowGradientAnimations: true)
        }
        
        return defaults.bool(forKey: UserDefaults.Keys.AllowGradientAnimations)
    }
    
    class func set(allowGradientAnimations: Bool) {
        let defaults = UserDefaults.standard

        defaults.set(allowGradientAnimations, forKey: UserDefaults.Keys.AllowGradientAnimations)
    }
    
    class var numberOfWonGames: Int {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: UserDefaults.Keys.NumberOfWonGames) == nil {
            UserDefaults.set(numberOfWonGames: 0)
        }
        
        return defaults.integer(forKey: UserDefaults.Keys.NumberOfWonGames)
    }
    
    class func set(numberOfWonGames: Int) {
        let defaults = UserDefaults.standard

        defaults.set(numberOfWonGames, forKey: UserDefaults.Keys.NumberOfWonGames)
    }
    
    struct Keys {
        private init(){}
        static let AllowGradientAnimations = "allowGradientAnimations"
        static let NumberOfWonGames = "numberOfWonGames"
    }
    
    
}
