//
//  UIViewController+Utilities.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 25.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit


extension UIViewController {
	
	func show(error: Error, title: String = "Error".sccs_loc, onDismiss: ((UIAlertAction) -> Void)? = nil) {
		app_logIfDebug("Presenting error: \(error)")
		let msg = ([NSCocoaErrorDomain, NSURLErrorDomain].contains(error._domain)) ? error.localizedDescription : "\(error)"
		show(message: msg, title: title, onDismiss: onDismiss)
	}
	
	func show(message: String, title: String?, onDismiss: ((UIAlertAction) -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK".sccs_loc, style: .cancel, handler: onDismiss))
		present(alert, animated: true)
	}
}
