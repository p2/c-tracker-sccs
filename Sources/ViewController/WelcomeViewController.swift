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


class WelcomeViewController: StudyIntroCollectionViewController, ORKTaskViewControllerDelegate {
	
	var profileManager: SCCSProfileManager!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		onJoinStudy = { viewController in
			self.startEnrollment()
		}
	}
	
	
	// MARK: - Routing
	
	func startEnrollment() {
		let story = UIStoryboard(name: "Main", bundle: nil)
		if let navi = story.instantiateViewController(withIdentifier: "LinkNavi") as? UINavigationController, let linking = navi.viewControllers.first as? LinkViewController {
			linking.tokenConfirmed = { link, fake in
				self.didConfirm(link: link, in: linking, isFake: fake)
			}
			linking.tokenRefuted = { error in
				self.dismiss(animated: true) {
					self.show(error: error, title: "Not You".sccs_loc)
				}
			}
			present(navi, animated: true)
		}
		else {
			fatalError("No “LinkNavi” view controller in the storyboard or of wrong class")
		}
	}
	
	@IBAction func doTryApp(_ sender: AnyObject?) {
		let sample = profileManager.sampleUser()
		doEnroll(user: sample)
	}
	
	/**
	Tells the profile manager to use this user going forward. Will emit a notification that the root view controller intercepts and
	consequently updates the UI, dismissing the receiver.
	*/
	func doEnroll(user: User) {
		do {
			try profileManager.enroll(user: user)
			profileManager.updateMedicalDataFromHealthKit(supplementedBy: user) { user, error in
				if let error = error {
					// simply log, no need to inform the user at this point
					app_logIfDebug("Error during enrollment: \(error)")
				}
			}
		}
		catch let error {
			show(error: error, title: "Could Not Load Profile".sccs_loc)
		}
	}
	
	func didConfirm(link: ProfileLink, in viewController: LinkViewController, isFake: Bool) {
		
		// link is confirmed, create user and attempt to establish link
		let user = profileManager.userFromLink(link)
		viewController.didStartLinking()
		profileManager.establishLink(between: user, and: link) { error in
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
		step1.text = "To get started, please create a passcode first, then allow the app to access some of the features of your phone".sccs_loc
		let step3 = SystemPermissionStep(identifier: "permission-step", permissions: profileManager.systemServicesNeeded)
		let task = ORKOrderedTask(identifier: "permissioning", steps: [step1, ORKPasscodeStep(identifier: "set-passcode"), step3])
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
	
	@IBAction func exitLink(segue:UIStoryboardSegue) {
	}
	
	
	// MARK: - ResearchKit
	
	var onPermissioningEnd: ((UIViewController, Error?) -> Void)?
	
	func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
		onPermissioningEnd?(taskViewController, error)
	}
}

