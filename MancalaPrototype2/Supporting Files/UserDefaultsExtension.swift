///
///  UserDefaultsExtension.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 2/21/20.
/// ============LICENSE_START=======================================================
/// Copyright © 2019 Alexander Scott Beaty. All rights reserved.
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================
import Foundation

/**
 Wrappers for getters and setters to enable lazy evaluation of UserDefaults properties
 */
extension UserDefaults {
    
    class var allowGradientAnimations: Bool {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: UserDefaults.Keys.AllowGradientAnimations) == nil {
            UserDefaults.set(allowGradientAnimations: false)
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
        
    class var unlockFiveBeadsStarting: Bool {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: UserDefaults.Keys.UnlockFiveBeadsStarting) == nil {
            UserDefaults.set(unlockFiveBeadsStarting: false)
        }
        
        return defaults.bool(forKey: UserDefaults.Keys.UnlockFiveBeadsStarting)
    }
    
    class func set(unlockFiveBeadsStarting: Bool) {
        let defaults = UserDefaults.standard

        defaults.set(unlockFiveBeadsStarting, forKey: UserDefaults.Keys.UnlockFiveBeadsStarting)
    }
    
    class var unlockSixBeadsStarting: Bool {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: UserDefaults.Keys.UnlockSixBeadsStarting) == nil {
            UserDefaults.set(unlockSixBeadsStarting: false)
        }
        
        return defaults.bool(forKey: UserDefaults.Keys.UnlockSixBeadsStarting)
    }
    
    class func set(unlockSixBeadsStarting: Bool) {
        let defaults = UserDefaults.standard

        defaults.set(unlockSixBeadsStarting, forKey: UserDefaults.Keys.UnlockSixBeadsStarting)
    }
    
    class var numberOfStartingBeads: Int {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: UserDefaults.Keys.NumberOfStartingBeads) == nil {
            UserDefaults.set(numberOfStartingBeads: 4)
        }
        
        return defaults.integer(forKey: UserDefaults.Keys.NumberOfStartingBeads)
    }
    
    class func set(numberOfStartingBeads: Int) {
        let defaults = UserDefaults.standard

        defaults.set(numberOfStartingBeads, forKey: UserDefaults.Keys.NumberOfStartingBeads)
    }
    
    class var hasLaunchedFirstTime: Bool {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: UserDefaults.Keys.HasLaunchedFirstTime) == nil {
            return false
        }
        return defaults.bool(forKey: UserDefaults.Keys.HasLaunchedFirstTime)
    }
    
    class func set(hasLaunchedFirstTime: Bool) {
        let defaults = UserDefaults.standard

        defaults.set(hasLaunchedFirstTime, forKey: UserDefaults.Keys.HasLaunchedFirstTime)
    }
    
    struct Keys {
        private init(){}
        static let AllowGradientAnimations = "allowGradientAnimations"
        static let NumberOfWonGames = "numberOfWonGames"
        static let UnlockFiveBeadsStarting = "unlockFiveBeadsStarting"
        static let UnlockSixBeadsStarting = "unlockSixBeadsStarting"
        static let NumberOfStartingBeads = "numberOfStartingBeads"
        static let HasLaunchedFirstTime = "hasLaunchedFirstTime"
    }
    
    
}
