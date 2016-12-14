//
//  UserNotificationManager.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 7/17/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation


/**
An instance of this class communicates between NotificationManager and ProfileManager.
*/
class UserNotificationManager {
	
	static let shared = UserNotificationManager()
	
	private init() {}
	
	
	/**
	Makes sure all notifications are in-line with our current user defaults settings.
	
	This method cancels all notifications (if changing time of day does not cancel those that were rescheduled), then re-creates all
	reminders for the user.
	*/
	func synchronizeNotifications(with profileManager: ProfileManager?) {
		let defaults = UserDefaults.standard
		
		// cancel all notifications
		let keep = defaults.surveyRemindersEnable
		NotificationManager.shared.cancelExistingNotifications(ofTypes: [], evenRescheduled: !keep)
		
		if keep, let manager = profileManager, let tasks = manager.user?.tasks {
			NotificationManager.shared.ensureProperNotificationSettings()
			let timeOfDay = defaults.surveyRemindersTimeOfDay
			
			// re-add all tasks that want reminders (for the first occurrence only)
			var notified = [String]()
			for task in tasks {
				if !notified.contains(task.taskId) {
					if let (notification, type) = manager.notification(for: task, suggestedDate: timeOfDay) {
						NotificationManager.shared.schedule(notification, type: type)
					}
					notified.append(task.taskId)
				}
			}
		}
		defaults.synchronize()
	}
}


/**
Extend NSUserDefaults to manage survey reminders.
*/
extension UserDefaults {
	
	private var surveyRemindersEnableKey: String {
		return "reminders.surveys.enable"
	}
	
	var surveyRemindersEnable: Bool {
		if nil != string(forKey: surveyRemindersEnableKey) {
			return bool(forKey: surveyRemindersEnableKey)
		}
		return true
	}
	
	func surveyRemindersEnable(_ flag: Bool, profileManager: ProfileManager?) {
		set(flag, forKey: surveyRemindersEnableKey)
		UserNotificationManager.shared.synchronizeNotifications(with: profileManager)
	}
	
	private var surveyRemindersTimeOfDayKey: String {
		return "reminders.surveys.time-of-day"
	}
	
	var surveyRemindersTimeOfDay: DateComponents {
		let parts = array(forKey: surveyRemindersTimeOfDayKey) as? [Int]
		var comps = DateComponents()
		comps.hour = parts?.first
		comps.minute = parts?.last
		return comps
	}
	
	func surveyRemindersSet(timeOfDay: DateComponents, profileManager: ProfileManager?) {
		let parts = [timeOfDay.hour ?? 10, timeOfDay.minute ?? 00]
		set(parts, forKey: surveyRemindersTimeOfDayKey)
		UserNotificationManager.shared.synchronizeNotifications(with: profileManager)
	}
}

