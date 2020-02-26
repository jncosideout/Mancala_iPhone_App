//
//  UserNotificationsHelper.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 1/5/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//

import GameKit
import UserNotifications

class UserNotificationsHelper: NSObject {
        
    static var allowMatchNotifications: Bool {
        var authorized = false
        UNUserNotificationCenter.current().getNotificationSettings() { settings in
            authorized = settings.authorizationStatus == .authorized
        }
        return authorized
    }
    //MARK: - Setup
    static func askForPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge,.alert,.sound]) { (granted, error) in
            if granted {
                print("notifications permission granted")
            } else {
                if let errorMsg = error?.localizedDescription {
                    print(errorMsg)
                }
            }
        }
    }
    
    static func scheduleNotifications(for match: GKTurnBasedMatch, _ player: GKPlayer) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings() { settings in
            guard settings.authorizationStatus == .authorized else { return }
//            guard let secureMatch = match as? NSSecureGKTurnBasedMatch else {
//                return
//            }
            
            let content = UNMutableNotificationContent()
            content.title = "\(player.alias)'s turn to play"
            if let opponentName = match.others[0].player?.alias {
                content.body = "vs " + opponentName
            }
            let matchID = match.matchID
            content.userInfo = ["MATCH_ID" : matchID]
            content.categoryIdentifier = "TAKE_ACTIVE_TURN"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            let requestID = match.matchID
            let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let theError = error?.localizedDescription {
                    print(theError)
                }
            }
        }
    }
    
    static func declareNotificationTypesAndActions() {
        //Define the custom actions
        let playTurnAction = UNNotificationAction(
            identifier: "PLAY_TURN",
            title: "Take your turn",
            options: .init(rawValue: 0))
        
        let ignoreTurnAction = UNNotificationAction(
            identifier: "IGNORE_TURN",
            title: "Ignore",
            options: .init(rawValue: 0))
        
        //Define the notification type
        let takeTurnCategory = UNNotificationCategory(
            identifier: "TAKE_ACTIVE_TURN",
            actions: [playTurnAction,ignoreTurnAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            categorySummaryFormat: "",
            options: .customDismissAction)
        
        //Register the notification type
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([takeTurnCategory])
    }
}//EoC
