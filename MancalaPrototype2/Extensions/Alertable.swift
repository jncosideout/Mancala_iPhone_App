//
//  Alertable.swift
//  Mancala World
//
//  Created by Alexander Scott Beaty on 3/20/20.
//  Copyright © 2020 Alexander Scott Beaty. All rights reserved.
//

import SpriteKit

protocol Alertable {}

extension Alertable where Self: SKScene {
    
    //MARK: - First Time Instructions alerts
    func showAlert(withTitle title: String, message: String, completion: (()->Void)? = nil) {
        
        let alertController = DBAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .cancel)
        alertController.addAction(okAction)
        
        alertController.show(animated: true, completion: completion)
    }
    
    func showAlertWithSettings(withTitle title: String, message: String, completion: (()->Void)? = nil) {
            
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
