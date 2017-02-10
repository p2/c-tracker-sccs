//
//  AppDelegate.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 07.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import C3PRO


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
			//	"verbose": true,
			]
			let srv = EncryptedDataQueue(baseURL: dataEndpoint, auth: authConfig, encBaseURL: encDataEndpoint, publicCertificateFile: "")
			
			// create profile manager
			let persister = try ProfilePersisterToFile(dir: dir)
			#if DEBUG
				let settings = Bundle.main.url(forResource: "ProfileSettingsDebug", withExtension: "json")!
			#else
				let settings = Bundle.main.url(forResource: "ProfileSettings", withExtension: "json")!
			#endif
			let manager = try ProfileManager(userType: AppUser.self, taskType: AppUserTask.self, settingsURL: settings, dataServer: srv, persister: persister)
			rootViewController?.profileManager = manager
			profileManager = manager
			
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
		//UINavigationBar.appearance().barTintColor = UIColor.appBarColor()
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
		prepareDueTasks()
		
		// make sure data queue is flushed
		let delay = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delay) { [weak self] in
			if let dataQueue = self?.profileManager.dataServer as? EncryptedDataQueue {
				dataQueue.flush() { error in
					if let error = error {
						app_logIfDebug("Failed to flush data queue: \(error)")
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
	
	
	// MARK: - Tasks
	
	func prepareDueTasks() {
//		let preparer = taskPreparer ?? UserTaskPreparer(user: UserManager.sharedManager.user, server: dataQueue)
//		preparer.prepareDueTasks() { [weak self] in
//			if let this = self {
//				this.taskPreparer = nil
//			}
//		}
	}
	
	func userDidReceiveTask(_ notification: Notification) {
		prepareDueTasks()
		NotificationManager.shared.ensureProperNotificationSettings()
		if let manager = profileManager {
			UserNotificationManager.shared.synchronizeNotifications(with: manager)
		}
		rootViewController.updateBadges()
	}
	
	func userDidCompleteTask(_ notification: Notification) {
		userDidReceiveTask(notification)
		
		if let task = notification.object as? UserTask {
			
			// survey completed: submit, submit current weight, then sample activity data and submit as well
			if .survey == task.type {
//				if let resource = task.resultResource {
//					c3_logIfDebug("Questionnaire completed, submitting")
//					resource.create(smart.server) { error in }
//					#if DEBUG
//						debugPrint(resource)
//					#endif
//					
//					sendLatestBodyweight()
//				}
//				else {
//					c3_logIfDebug("Questionnaire completed but no result resource received!")
//				}
//				
//				if UserDefaults.standard.activityDataSend {
//					sampleAndSendLatestActivityData()
//				}
			}
		}
	}
	
	func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, withResponseInfo responseInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
		if let identifier = identifier, let action = NotificationManagerNotificationAction(rawValue: identifier) {
			NotificationManager.shared.applyNotificationAction(action, toNotification: notification)
		}
		else {
			print("Unknown notification action: “\(identifier)”")
		}
		completionHandler()
	}
}

