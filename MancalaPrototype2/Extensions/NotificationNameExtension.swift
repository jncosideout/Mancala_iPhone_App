//
//  NotificationNameExtension.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 3/8/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let presentGame = Notification.Name("presentGame")
    static let authenticationChanged = Notification.Name("authenticationChanged")
    static let presentSettings = Notification.Name("presentSettingsd")
}
