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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tabBarController?.tabBar.isHidden = true
	}
	
	
	// MARK: - Routing
	
	@IBAction func doTryApp(_ sender: AnyObject?) {
		let sample = ProfileManager.sampleProfile()
		didLoad(profile: sample)
	}
	
	@IBAction func aboutTheApp(_ sender: AnyObject?) {
		
	}
	
	@IBAction func aboutSCCS(_ sender: AnyObject?) {
		
	}
	
	@IBAction func showHelp(_ sender: AnyObject?) {
		
	}
	
	func didLoad(profile: Patient) {
		do {
			try ProfileManager.shared.use(patient: profile)
			print("USING \(profile)")
			// TODO: load view controllers
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
						let profile = ProfileManager.profile(from: data)
						self.didLoad(profile: profile)
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

