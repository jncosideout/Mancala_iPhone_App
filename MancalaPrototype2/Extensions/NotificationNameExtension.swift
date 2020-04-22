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

extension Notification.Name {
    static let presentGame = Notification.Name("presentGame")
    static let authenticationChanged = Notification.Name("authenticationChanged")
    static let presentSettings = Notification.Name("presentSettingsd")
}
