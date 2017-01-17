//
//  WelcomeViewController.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 07.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import SMART


class WelcomeViewController: UIViewController {
	
	var profileManager: ProfileManager!
	
	
	// MARK: - Routing
	
	@IBAction func doTryApp(_ sender: AnyObject?) {
		let sample = ProfileManager.sampleUser()
		doEnroll(user: sample)
	}
	
	@IBAction func aboutTheApp(_ sender: AnyObject?) {
		
	}
	
	@IBAction func aboutSCCS(_ sender: AnyObject?) {
		
	}
	
	@IBAction func showHelp(_ sender: AnyObject?) {
		
	}
	
	func doEnroll(user: User) {
		do {
			try profileManager.enroll(user: user)
			// emits a notification that root view controller should listen to and update the UI
		}
		catch let error {
			show(error: error, title: "Could Not Load Profile".sccs_loc)
		}
	}
	
	
	// MARK: - Segues
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if "ShowLink" == segue.identifier {
			guard let target = (segue.destination as? UINavigationController)?.topViewController as? LinkViewController else {
				fatalError("The target of the “ShowLink” segue is not a navigation controller hosting a link view controller")
			}
			target.tokenConfirmed = { link in
				let user = ProfileManager.userFromLink(link)
				target.didStartLinking()
				self.profileManager.establishLink(between: user, and: link) { error in
					if let error = error {
						// TODO: ok to fail gracefully, but attempt to establish the link later on!
						app_logIfDebug("Failed to establish link: \(error)")
					}
					target.didFinishLinking(with: "Enrolled!")
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						target.dismiss(animated: true) {
							self.doEnroll(user: user)
						}
					}
				}
			}
			target.tokenRefuted = { error in
				target.dismiss(animated: true) {
					self.show(error: error, title: "Not You".sccs_loc)
				}
			}
		}
	}
	
	@IBAction func exitLink(segue:UIStoryboardSegue) {
	}
}

