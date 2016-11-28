//
//  AppDelegate.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 07.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	
	var profileManager: ProfileManager?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
		guard let first = paths.first else {
			fatalError("No user documents directory, cannot continue")
		}
		
		let manager = ProfileManager(dir: URL(fileURLWithPath: first))
		(window?.rootViewController as? RootViewController)?.profileManager = manager
		profileManager = manager
		
		return true
	}
}

