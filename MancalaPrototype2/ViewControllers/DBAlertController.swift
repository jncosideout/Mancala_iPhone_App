///
///  DBAlertController.swift
///  DBAlertController
///
///  Created by Dylan Bettermann on 5/11/15.
///  Copyright (c) 2015 Dylan Bettermann. All rights reserved.
///  SPDX-License-Identifier: MIT

import UIKit

/**
 When you want to display your UIAlertController you must display it on a new UIWindow instead of the SKScene's rootViewController key window
 
1. Make your window the key and visible window (window.makeKeyAndVisible())
2. Just use a plain UIViewController instance as the rootViewController of the new window. (window.rootViewController = UIViewController())
3.  Present your UIAlertController on your window's rootViewController
 
 A couple things to note:

 Your UIWindow must be strongly referenced. If it's not strongly referenced it will never appear (because it is released). I recommend using a property, but I've also had success with an associated object.
 To ensure that the window appears above everything else (including system UIAlertControllers), I set the windowLevel. (window.windowLevel = UIWindowLevelAlert + 1)
 */
public class DBAlertController: UIAlertController {
    // The UIWindow that will be at the top of the window hierarchy. The DBAlertController instance is presented on the rootViewController of this window.
    private lazy var alertWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = DBClearViewController()
        window.backgroundColor = UIColor.clear
        window.windowLevel = .alert
        return window
    }()
    
    /**
    Present the DBAlertController on top of the visible UIViewController.
    
    - parameter flag:       Pass true to animate the presentation; otherwise, pass false. The presentation is animated by default.
    - parameter completion: The closure to execute after the presentation finishes.
    */
    public func show(animated flag: Bool = true, completion: (()->Void)? = nil) {
        if let rootViewController = alertWindow.rootViewController {
            alertWindow.makeKeyAndVisible()
            
            rootViewController.present(self, animated: flag, completion: completion)
        }
    }
    
}//EoC

// In the case of view controller-based status bar style, make sure we use the same style for our view controller
private class DBClearViewController: UIViewController {
    fileprivate override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIApplication.shared.statusBarStyle
    }
    fileprivate override var prefersStatusBarHidden: Bool {
        return UIApplication.shared.isStatusBarHidden
    }
    
}//EoC
