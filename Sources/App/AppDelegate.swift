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
	
	var profileManager: ProfileManager?
	
	var rootViewController: RootViewController?
	
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		rootViewController = window?.rootViewController as? RootViewController
		
		let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
		guard let first = paths.first else {
			fatalError("No user documents directory, cannot continue")
		}
		do {
			let dir = URL(fileURLWithPath: first).appendingPathComponent("C-Tracker")
			let manager = try ProfileManager(dir: dir)
			rootViewController?.profileManager = manager
			profileManager = manager
		}
		catch let error {
			fatalError("\(error) at \(first)")
		}
		
		NSLog("APP STARTED. C3-PRO is using FHIR v\(C3PROFHIRVersion). Profile manager is storing to «\(profileManager!.directory.path)»")
		return true
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
		rootViewController?.updateBadges()
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
//						let data = try! JSONSerialization.data(withJSONObject: resource.asJSON(), options: .prettyPrinted)
//						print(String(data: data, encoding: String.Encoding.utf8)!)
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

