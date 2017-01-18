//
//  WelcomeViewController.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 07.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import SMART
import ResearchKit
import C3PRO


class WelcomeViewController: UIViewController, ORKTaskViewControllerDelegate {
	
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
	
	/**
	Tells the profile manager to use this user going forward. Will emit a notification that the root view controller intercepts and
	consequently updates the UI, dismissing the receiver.
	*/
	func doEnroll(user: User) {
		do {
			try profileManager.enroll(user: user)
		}
		catch let error {
			show(error: error, title: "Could Not Load Profile".sccs_loc)
		}
	}
	
	func didConfirm(link: ProfileLink, in viewController: LinkViewController, isFake: Bool) {
		
		// link is confirmed, create user and attempt to establish link
		let user = ProfileManager.userFromLink(link)
		viewController.didStartLinking()
		self.profileManager.establishLink(between: user, and: link) { error in
			// TODO: allow non-fake links to fail gracefully, attempt to establish the link later on
			if !isFake, let error = error {
				self.dismiss(animated: true) {
					self.show(error: error, title: "Failed to Enroll".sccs_loc)
				}
			}
			else {
				DispatchQueue.main.async() {
					viewController.didFinishLinking(withStatus: "Enrolled!".sccs_loc)
				}
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
					self.performPermissioning(from: viewController) { error in
						self.doEnroll(user: user)
						// TODO: user gets launched into Dashboard immediately. Show some kind of greeting.
					}
				}
			}
		}
	}
	
	/**
	Creates a two-step ordered task with instructional text and the system permissioning step.
	*/
	func performPermissioning(from viewController: UIViewController, callback: @escaping ((Error?) -> Void)) {
		
		// create an intro step and a system permissioning step
		let step1 = ORKInstructionStep(identifier: "permission-intro")
		step1.title = "Welcome!".sccs_loc
		step1.text = "To get started, please allow the app to access some of the features of your phone".sccs_loc
		let step2 = SystemPermissionStep(identifier: "permission-step", permissions: profileManager.systemServicesNeeded)
		let task = ORKOrderedTask(identifier: "permissioning", steps: [step1, step2])
		let permissioning = ORKTaskViewController(task: task, taskRun: UUID())
		permissioning.delegate = self
		
		// when permissioning ends, dismiss the original view controller and load the profile
		onPermissioningEnd = { vc, error in
			vc.dismiss(animated: true) {
				callback(error)
				if let error = error {
					(self.view.window?.rootViewController ?? self).show(error: error, title: "Permissioning Error".sccs_loc)
				}
			}
		}
		viewController.dismiss(animated: false) {
			self.present(permissioning, animated: false)
		}
	}
	
	
	// MARK: - Link Segue
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if "ShowLink" == segue.identifier {
			guard let target = (segue.destination as? UINavigationController)?.topViewController as? LinkViewController else {
				fatalError("Destination for “ShowLink” is not a link view controller in storyboard «\(storyboard?.description ?? "nil")»")
			}
			target.tokenConfirmed = { link, fake in
				self.didConfirm(link: link, in: target, isFake: fake)
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
	
	
	// MARK: - ResearchKit
	
	var onPermissioningEnd: ((UIViewController, Error?) -> Void)?
	
	func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
		onPermissioningEnd?(taskViewController, error)
	}
}

