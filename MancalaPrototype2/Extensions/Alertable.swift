///
///  Alertable.swift
///  Mancala World
///
///  Created by Alexander Scott Beaty on 3/20/20.
/// ============LICENSE_START=======================================================
/// Copyright © 2020 Alexander Scott Beaty. All rights reserved.
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================

import SpriteKit

// Default arguments aren't allowed in a protocol method, thus all methods are placed in an extension
protocol Alertable {}

/**
 Wrappers for presenting UIAlertControllers from an SKScene. Must be used in combination with a new UIWindow (provided by DBAlertController)
 https://stackoverflow.com/questions/39557344/swift-spritekit-how-to-present-alert-view-in-gamescene/39580087#39580087
 */
extension Alertable {
    
    /// Shows a generic info alert  with "OK" action
    func showAlert(withTitle title: String, message: String, extraAction: UIAlertAction? = nil, completion: (()->Void)? = nil) {
        
        // Provides a alertViewController on its own UIWindow
        let alertController = DBAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .cancel) { _ in
            completion?()
        }
        alertController.addAction(okAction)
        if let anotherAction = extraAction {
            alertController.addAction(anotherAction)
        }
        
        alertController.show(animated: true, completion: nil)
    }
    
    /// Shows an alert with the option to go to the external iOS settings for this app
    func showAlertWithSettings(withTitle title: String, message: String, completion: (()->Void)? = nil) {
            
        // Provides a alertViewController on its own UIWindow
        let alertController = DBAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "Ok", style: .cancel)
        alertController.addAction(okAction)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        alertController.addAction(settingsAction)
        
        alertController.show(animated: true, completion: completion)
    }
}

extension SKScene: Alertable {}
