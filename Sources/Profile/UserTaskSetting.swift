//
//  UserTaskSetting.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 29.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import Foundation


/**
Setting for one particular scheduled task.

TODO: still unsure on the time format, CRON seems overly complicated. See `UserTaskDateFormatParser` for what's currently used.

    {
      "taskId": "{id}",
      "taskType": "<consent|survey>"
      "notificationType": "<none|once|delayable>",
      "starts": "{time-format}",
      "repeats": "{time-format}",
      "expires": "{time-format}",
      "delayMax": "{time-format}"
    }
*/
public struct UserTaskSetting {
	
	/// The identifier of the task this notification belongs to.
	let taskId: String
	
	let taskType: UserTaskType
	
	let notificationType: NotificationManagerNotificationType
	
	/// Delay before the task's notifications should kick in.
	var starts: DateComponents?
	
	/// If set, the delay between notifications for this task; must also set `expires` when a repeat interval is set.
	var repeats: DateComponents?
	
	/// After this date, no more notifications will be posted; must be present when `repeats` is set.
	var expires: DateComponents?
	
	/// How long will users be able to delay/postpone performing this task after they've been notified.
	var delayMax: DateComponents?
	
	
	init(from json: [String: String]) throws {
		taskId = json["taskId"] ?? ""		// will check at the end if it's empty, then throw
		taskType = UserTaskType(rawValue: json["taskType"] ?? "") ?? .unknown
		if let typ = json["notificationType"] {
			guard let type = NotificationManagerNotificationType(rawValue: typ) else {
				throw AppError.invalidScheduleFormat("Invalid `notificationType` string “\(typ)”")
			}
			notificationType = type
		}
		else {
			notificationType = .none
		}
		if let strt = json["starts"] {
			starts = try UserTaskDateFormatParser.parse(string: strt)
		}
		if let exp = json["expires"] {
			expires = try UserTaskDateFormatParser.parse(string: exp)
			if let rep = json["repeats"] {
				repeats = try UserTaskDateFormatParser.parse(string: rep)
			}
		}
		else if nil != json["repeats"] {
			throw AppError.invalidScheduleFormat("If `repeats` is present, must also have `expires`")
		}
		if let delay = json["delayMax"] {
			delayMax = try UserTaskDateFormatParser.parse(string: delay)
		}
		if taskId.isEmpty {
			throw AppError.invalidScheduleFormat("Must have a valid `taskId` entry")
		}
		if .unknown == taskType {
			throw AppError.invalidScheduleFormat("Must have a valid `taskType` entry")
		}
	}
	
	
	// MARK: - Dates
	
	/**
	Calculates all dates on which a notification should be emitted.
	
	- parameter starting: When the schedule should start, usually the enrollment day
	- returns: An array full of `Date`
	*/
	func scheduledTasks(starting: Date) throws -> [UserTask] {
		let cal = Calendar.current
		
		// create start date as first entry
		guard let first = cal.date(byAdding: starts ?? DateComponents(), to: starting) else {
			throw AppError.invalidScheduleFormat("Unable to add date components \(starts ?? DateComponents()) to start date")
		}
		var datetimes = [first]
		
		// create repetitions
		if let rep = repeats, let exp = expires {
			guard let end = cal.date(byAdding: exp, to: starting) else {
				throw AppError.invalidScheduleFormat("Unable to add date components \(exp) to date \(starting)")
			}
			var next = starting
			while next < end {
				guard let date = cal.date(byAdding: rep, to: next) else {
					throw AppError.invalidScheduleFormat("Unable to add date components \(rep) to date \(next)")
				}
				datetimes.append(date)
				next = date
			}
		}
		
		// create UserTask instances: add due date (without time), timezone and max delay date-time
		var tasks = [UserTask]()
		for datetime in datetimes {
			var comps = cal.dateComponents([.year, .month, .day], from: datetime)
			comps.timeZone = TimeZone(identifier: "UTC")!
			let date = cal.date(from: comps)!
			
			let task = AppUserTask(id: UUID().uuidString, taskId: taskId, type: taskType)
			task.notificationType = notificationType
			task.dueDate = date
			if let delay = delayMax {
				task.expiredDate = cal.date(byAdding: delay, to: datetime)
			}
			tasks.append(task)
		}
		
		return tasks
	}
}


public class UserTaskDateFormatParser {
	
	static func parse(string: String) throws -> DateComponents {
		// TODO: implement a nice format
		let parts = string.components(separatedBy: CharacterSet.whitespaces)
		var comps = DateComponents()
		for part in parts {
			if part.hasSuffix("h") {
				comps.hour = Int(part.replacingOccurrences(of: "h", with: ""))
			}
			else if part.hasSuffix("d") {
				comps.day = Int(part.replacingOccurrences(of: "d", with: ""))
			}
			else if part.hasSuffix("m") {
				comps.month = Int(part.replacingOccurrences(of: "m", with: ""))
			}
			else if part.hasSuffix("y") {
				comps.year = Int(part.replacingOccurrences(of: "y", with: ""))
			}
			else {
				throw AppError.invalidScheduleFormat(part)
			}
		}
		
		return comps
	}
}

