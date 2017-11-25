//
//  AppDelegate.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 07.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import C3PRO
import SMART


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?
	
	var profileManager: ProfileManager!
	
	var motionReporterStore: URL!
	
	var rootViewController: RootViewController!
	
	
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		rootViewController = window?.rootViewController as? RootViewController
		
		let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
		guard let first = paths.first else {
			fatalError("No user documents directory, cannot continue")
		}
		do {
			let dir = URL(fileURLWithPath: first).appendingPathComponent("C-Tracker")
			motionReporterStore = dir.appendingPathComponent("CoreMotion")
			
			// server configuration
			let dataRoot = URL(string: cStudyDataServerRoot)!
			let dataEndpoint = dataRoot.appendingPathComponent("fhir")
			let encDataEndpoint = dataRoot.appendingPathComponent("encfhir")
			let regEndpoint = dataRoot.appendingPathComponent("register")
			let authConfig = [
				"client_name": cStudyName,
				"registration_uri": regEndpoint.absoluteString,
				"authorize_uri": dataRoot.appendingPathComponent("oauth").absoluteString,
				"authorize_type": "client_credentials",
			]
			let srv = EncryptedDataQueue(baseURL: dataEndpoint, auth: authConfig, encBaseURL: encDataEndpoint, publicCertificateFile: "data-queue-certificate")
			srv.onBeforeDynamicClientRegistration = { url in
				let dynreg = OAuth2DynRegAppStore()
				if TARGET_OS_SIMULATOR != 0 {
					dynreg.overrideAppReceipt("NO-APP-RECEIPT")
				}
				if let antispam = cServerAntispamToken {
					dynreg.extraHeaders = ["Antispam": antispam]
				}
				return dynreg
			}
			#if DEBUG
				srv.logger = OAuth2DebugLogger(.debug)
			#endif
			
			// create profile manager
			let persister = try ProfilePersisterToFile(dir: dir)
			#if DEBUG
				let settings = Bundle.main.url(forResource: "ProfileSettingsDebug", withExtension: "json")!
			#else
				let settings = Bundle.main.url(forResource: "ProfileSettings", withExtension: "json")!
			#endif
			let manager = try SCCSProfileManager(userType: AppUser.self, taskType: AppUserTask.self, settingsURL: settings, dataServer: srv, persister: persister)
			rootViewController?.profileManager = manager
			profileManager = manager
			srv.delegate = manager
			
			// task handler
			let taskHandler = UserActivityTaskHandler(manager: manager)
			taskHandler.motionReporterStore = motionReporterStore
			manager.taskHandler = taskHandler
			
			NSLog("\n\nAPP STARTED.\n\tC3-PRO is using FHIR v\(C3PROFHIRVersion).\n\tProfile manager is storing locally to\n«\(dir.path)»\n\tand sending data to\n«\(srv.baseURL.description)»\n\n")
		}
		catch let error {
			fatalError("\(error) at \(first)")
		}
		
		// configure background fetch (for CoreMotion archiving)
		application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
		
		return true
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		UINavigationBar.appearance().tintColor = UIColor.appPrimaryColor()
		//UITabBar.appearance().barTintColor = UIColor.appBarColor()
		UITableView.appearance().backgroundColor = UIColor.appBackgroundColor()
		window?.tintColor = UIColor.appPrimaryColor()
		
		rootViewController.showSecureView()
		DispatchQueue.main.async {
			self.rootViewController.unlockApp()
		}
		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		rootViewController.lockApp()
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		rootViewController.lockApp()
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		rootViewController.unlockApp()
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		rootViewController.unlockApp()
		profileManager.prepareDueTasks()
		
		// make sure data queue is flushed
		let delay = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delay) { [weak self] in
			if let dataQueue = self?.profileManager.dataServer as? EncryptedDataQueue {
				dataQueue.flush() { error in
					if let error = error {
						app_logIfDebug("Failed to flush data queue on app did become active: \(error)")
					}
				}
			}
		}
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		rootViewController.lockApp(true)
	}
	
	
	// MARK: - Background Fetch
	
	func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		let motionReporter = CoreMotionReporter(path: motionReporterStore.path)
		motionReporter.archiveActivities { numNewActivities, error in
			if let _ = error {
				completionHandler(.failed)
			}
			else {
				completionHandler(numNewActivities > 0 ? .newData : .noData)
			}
		}
	}
	
	
	// MARK: - Local Notifications
	
	func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, withResponseInfo responseInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
		if let identifier = identifier, let action = NotificationManagerNotificationAction(rawValue: identifier) {
			NotificationManager.shared.applyNotificationAction(action, toNotification: notification)
		}
		else {
			print("Unknown notification action: “\(String(describing: identifier))”")
		}
		completionHandler()
	}
}

