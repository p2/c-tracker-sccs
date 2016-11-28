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
		didLoad(user: sample)
	}
	
	@IBAction func aboutTheApp(_ sender: AnyObject?) {
		
	}
	
	@IBAction func aboutSCCS(_ sender: AnyObject?) {
		
	}
	
	@IBAction func showHelp(_ sender: AnyObject?) {
		
	}
	
	func didLoad(user: User) {
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
			if let target = (segue.destination as? UINavigationController)?.topViewController as? LinkViewController {
				target.tokenDataConfirmed = { data in
					target.dismiss(animated: true) {
						let profile = ProfileManager.userFromToken(data)
						self.didLoad(user: profile)
					}
				}
				target.tokenDataRefuted = { error in
					target.dismiss(animated: true) {
						self.show(error: error, title: "Not You".sccs_loc)
					}
				}
			}
		}
	}
	
	@IBAction func exitLink(segue:UIStoryboardSegue) {
	}
}

