///
///  AppDelegate.swift
///  MancalaPrototype2
///
///  Created by Alexander Scott Beaty on 7/30/19.
/// ============LICENSE_START=======================================================
/// Copyright (c) 2018 Razeware LLC
/// Modification Copyright © 2019 Alexander Scott Beaty. All rights reserved.
/// Modification License:
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================
/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import UserNotifications
import GameKit

@UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let savedGamesStore = SavedGameStore()
    var savedGameModels = [GameModel]()
    var matchHistory = MatchHistory()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        //Restore saved [GameData] to [GameModel] savedGameModels
        savedGameModels = savedGamesStore.setupSavedGames()
        window?.rootViewController = GameViewController()
        let gameViewController = window!.rootViewController as! GameViewController
        gameViewController.savedGameModels = savedGameModels
        gameViewController.matchHistory = matchHistory
        window?.makeKeyAndVisible()
        configureUserNotifications()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        savedGamesStore.backupAndSaveAllGames(savedGameModels)
        if matchHistory.saveData() {
            print("saved matchHistory in AppDelegate")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func UIApplicationEndBackgroundTaskError() {
        
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    private func configureUserNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UserNotificationsHelper.declareNotificationTypesAndActions()
    }
    
    ///Present local notifications received while app is open
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
    
    ///Handles local notifications received while app is open
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        switch response.actionIdentifier {
        case "PLAY_TURN":
            //get the match from the notification payload
            let userInfo = response.notification.request.content.userInfo
            let matchID = userInfo["MATCH_ID"] as! String
            GKTurnBasedMatch.load(withID: matchID) { (match, error) in
                if let match = match {
                    NotificationCenter.default.post(name: .presentGame, object: match)
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
            // Dismiss the GameCenter MatchMaker ViewController if it is present
            if let vc = GameCenterHelper.helper.currentMatchMakerVC {
                vc.dismiss(animated: true)
            }
            
        case "IGNORE_TURN":
            break
        case "SEE_UNLOCKED":
            let bitmask = ButtonBitmask.allButtons.subtracting(.beadNumber)
            NotificationCenter.default.post(name: .presentSettings, object: bitmask)
        default:
            break
        }
        completionHandler()
    }
}
