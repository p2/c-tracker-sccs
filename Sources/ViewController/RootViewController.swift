//
//  RootViewController.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 4/24/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit


class RootViewController: UITabBarController {
	
	var profileManager: ProfileManager?
	
	var secureView: UIView?
	
	/// Set to true the first time `viewWillAppear` is called; used to prevent view layout issues when laying out during app launch.
	var viewDidAppear = false
	
	var mustShowSecureView = false
	
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
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewDidAppear = true
		if mustShowSecureView {
			mustShowSecureView = false
			showSecureView()
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		updateBadges()
		super.viewDidAppear(animated)
	}
	
	
	// MARK: - Profile
	
	func didLoadProfile(notification: Notification) {
		guard let manager = notification.object as? ProfileManager else {
			NSLog("Received the following notification without a ProfileManager as object, ignoring: \(notification)")
			return
		}
		updateUIAfterProfileChange(with: manager, animated: true)
	}
	
	func updateUIAfterProfileChange(with manager: ProfileManager, animated: Bool = true) {
		if nil != manager.user?.enrollmentDate {
			tabBar.isHidden = false
			if let dashNavi = storyboard?.instantiateViewController(withIdentifier: "DashboardRoot") as? UINavigationController,
				let dashboard = dashNavi.topViewController as? DashboardViewController,
				let profileNavi = storyboard?.instantiateViewController(withIdentifier: "ProfileRoot") as? UINavigationController,
				let profile = profileNavi.topViewController as? ProfileViewController,
				let sccsNavi = storyboard?.instantiateViewController(withIdentifier: "SCCSViewRoot") as? UINavigationController {
				
				dashboard.profileManager = manager
				profile.profileManager = manager
				setViewControllers([dashNavi, profileNavi, sccsNavi], animated: animated)
			}
			else {
				fatalError("At least one of “DashboardRoot”, “ProfileRoot” or “SCCSViewRoot” view controllers are missing in the storyboard or are not set up with the correct root view controllers")
			}
		}
		else {
			tabBar.isHidden = true
			if let welcome = storyboard?.instantiateViewController(withIdentifier: "Welcome") as? WelcomeViewController {
				welcome.profileManager = manager
				setViewControllers([welcome], animated: animated)
			}
			else {
				fatalError("No “Welcome” view controller in the storyboard or of wrong class")
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
	
	
	// MARK: - Secure View
	
	func showSecureView() {
		if !viewDidAppear {
			mustShowSecureView = true
			return
		}
		if let viewForSnapshot = self.view, viewForSnapshot != secureView?.superview {
			if nil == secureView {
				secureView = UIView(frame: viewForSnapshot.bounds)
				secureView!.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
				
				let blur = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
				let blurView = UIVisualEffectView(effect: blur)
				blurView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
				let appIcon = UIImage(named: "SCCS_Logo")
				let appIconImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 190.0, height: 85.0))
				
				blurView.frame = secureView!.bounds
				appIconImageView.image = appIcon
				appIconImageView.center = blurView.center
				appIconImageView.contentMode = .scaleAspectFit
				
				secureView!.addSubview(blurView)
				secureView!.addSubview(appIconImageView)
				
			}
			viewForSnapshot.insertSubview(secureView!, at: .max)
			secureView!.frame = viewForSnapshot.bounds
		}
	}
	
	func hideSecureView(_ animated: Bool) {
		mustShowSecureView = false
		if let secure = secureView {
			if animated {
				let duration = 0.25
				UIView.animate(withDuration: duration) {
					secure.alpha = 0.0
				}
				
				// cannot use UIView.animateWithDuration as it will call the "completion" callback too early due to re-layout
				let after = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds) + Double(Int64(duration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
				DispatchQueue.main.asyncAfter(deadline: after) {
					secure.removeFromSuperview()
				}
			}
			else {
				secure.removeFromSuperview()
			}
			secureView = nil
		}
	}
}

