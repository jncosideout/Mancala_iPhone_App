///
///  NotificationNameExtension.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 3/8/20.
/// ============LICENSE_START=======================================================
/// Copyright (c) 2018 Razeware LLC
/// Modification Copyright © 2020 Alexander Scott Beaty. All rights reserved.
/// Modification License:
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================

import Foundation

/**
 Based on code from the tutorial found at https:www.raywenderlich.com/7544-game-center-for-ios-building-a-turn-based-game#
 By Ryan Ackerman
 */
extension Notification.Name {
    static let presentOnlineGame = Notification.Name("presentOnlineGame")
    static let authenticationChanged = Notification.Name("authenticationChanged")
    static let presentSettings = Notification.Name("presentSettings")
    static let showMenuScene = Notification.Name("showMenuScene")
    static let showMenuScene_2 = Notification.Name("showMenuScene_2")
    static let showGameScene = Notification.Name("showGameScene")
    static let showAI_GameScene = Notification.Name("showAI_GameScene")
    static let continueOnlineGame = Notification.Name("continueOnlineGame")
}
