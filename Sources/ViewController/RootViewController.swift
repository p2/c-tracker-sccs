//
//  RootViewController.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 4/24/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import C3PRO


class RootViewController: LockableTabBarController {
	
	var profileManager: SCCSProfileManager?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(RootViewController.didLoadProfile), name: ProfileManager.didChangeProfileNotification, object: nil)
		if let profileManager = profileManager {
			updateUIAfterProfileChange(with: profileManager)
		}
		else {
			tabBar.isHidden = true
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		updateBadges()
		super.viewDidAppear(animated)
	}
	
	
	// MARK: - Profile
	
	func didLoadProfile(notification: Notification) {
		guard let manager = notification.object as? SCCSProfileManager else {
			NSLog("Received the following notification without a SCCSProfileManager as object, ignoring: \(notification)")
			return
		}
		updateUIAfterProfileChange(with: manager, animated: true)
	}
	
	func updateUIAfterProfileChange(with manager: SCCSProfileManager, animated: Bool = true) {
		if nil != manager.user?.enrollmentDate {
			tabBar.isHidden = false
			if let dashNavi = storyboard?.instantiateViewController(withIdentifier: "DashboardRoot") as? UINavigationController,
				let dashboard = dashNavi.topViewController as? DashboardViewController,
				let profileNavi = storyboard?.instantiateViewController(withIdentifier: "ProfileRoot") as? UINavigationController,
				let profile = profileNavi.topViewController as? ProfileViewController,
				let sccsNavi = storyboard?.instantiateViewController(withIdentifier: "SCCSViewRoot") as? UINavigationController {
				
				dashboard.profileManager = manager
				dashboard.motionReporter = CoreMotionReporter(path: (UIApplication.shared.delegate as! AppDelegate).motionReporterStore.path)
				profile.profileManager = manager
				setViewControllers([dashNavi, profileNavi, sccsNavi], animated: animated)
			}
			else {
				fatalError("At least one of “DashboardRoot”, “ProfileRoot” or “SCCSViewRoot” view controllers are missing in the storyboard or are not set up with the correct root view controllers")
			}
		}
			
		// not yet enrolled
		else {
			tabBar.isHidden = true
			do {
				let welcome = try StudyIntroCollectionViewController.fromStoryboard(named: "StudyIntro") as! WelcomeViewController
				welcome.config = try StudyIntroConfiguration(json: "StudyOverview")
				welcome.profileManager = profileManager
				setViewControllers([welcome], animated: animated)
			}
			catch {
				fatalError("StudyIntro is not properly set up: \(error)")
			}
		}
	}
	
	
	// MARK: - Badges
	
	func updateBadges() {
		if let item = viewControllers?.first?.tabBarItem {
			var numDueTasks = 0
			profileManager?.user?.tasks.forEach() {
				if $0.due {
					numDueTasks += 1
				}
			}
			
			item.badgeValue = (numDueTasks > 0) ? "\(numDueTasks)" : nil
			UIApplication.shared.applicationIconBadgeNumber = numDueTasks
		}
	}
	
	override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
		super.setViewControllers(viewControllers, animated: animated)
		updateBadges()
	}
}

