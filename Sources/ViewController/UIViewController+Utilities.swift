//
//  UIViewController+Utilities.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 25.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import AVFoundation
import Smooch


extension UIViewController {
	
	func show(error: Error, title: String = "Error".sccs_loc, onDismiss: ((UIAlertAction) -> Void)? = nil) {
		app_logIfDebug("Presenting error: \(error)")
		let msg = ([NSCocoaErrorDomain, NSURLErrorDomain, AVFoundationErrorDomain].contains(error._domain)) ? error.localizedDescription : "\(error)"
		show(message: msg, title: title, onDismiss: onDismiss)
	}
	
	func show(message: String, title: String?, onDismiss: ((UIAlertAction) -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK".sccs_loc, style: .cancel, handler: onDismiss))
		present(alert, animated: true)
	}
	
	/**
	Show the contact form via Smooch. Will display a non-localized error if `cSmoochToken` is not set since you shouldn't be using this
	method if you haven't set up Smooch.
	*/
	@IBAction func showHelp(_ sender: AnyObject?) {
		if let token = cSmoochToken {
			let settings = SKTSettings(appId: token)
			settings.conversationStatusBarStyle = .lightContent
			Smooch.initWith(settings) { (error: Error?, userInfo: [AnyHashable : Any]?) in
				Smooch.show()
			}
		}
		else {
			show(message: "The app is not set up with a contact point", title: "Cannot Contact")
		}
	}
	
	func dismissModal(_ sender: AnyObject?) {
		dismiss(animated: nil != sender)
	}
}
