//
//  UserTask.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 5/19/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMART


/**
A task a user needs to complete, such as consenting or taking a survey.
*/
class AppUserTask: UserTask {
	
	/// To be used in notification's `userInfo` dictionaries.
	static let notificationUserTaskIdKey = "user-task-id"
	
	let id: String
	
	let type: UserTaskType
	
	var assignedTo: User?
	
	var notificationType: NotificationManagerNotificationType?
	
	/// The day this task is due.
	var dueDate: Date?
	
	/// Whether this task is due.
	var due: Bool {
		if completed {
			return false
		}
		if let dd = dueDate {
			return (.orderedAscending == dd.compare(Date()))
		}
		return false
	}
	
	var humanDueDate: String? {
		if let date = dueDate {
			let cal = Calendar.current
			let daysDue = cal.ordinality(of: .day, in: .era, for: date) ?? 0
			let daysNow = cal.ordinality(of: .day, in: .era, for: Date()) ?? 0
			let diff = daysDue - daysNow
			if diff < 0 {
				return "due".sccs_loc
			}
			if 0 == diff {
				return "today".sccs_loc
			}
			if 1 == diff {
				return "tomorrow".sccs_loc
			}
			if diff < 6 {
				return String(format: "in %d days".sccs_loc, diff)
			}
			
			// more than 5 days, show date
			let formatter = DateFormatter()
			formatter.dateStyle = DateFormatter.Style.medium
			formatter.timeStyle = DateFormatter.Style.none
			return formatter.string(from: date)
		}
		return nil
	}
	
	/// How long this can be delayed.
	var delayMaxDate: Date?
	
	/// The day this task has been completed.
	var completedDate: Date?
	
	var humanCompletedDate: String? {
		if let date = completedDate {
			let formatter = DateFormatter()
			formatter.dateStyle = DateFormatter.Style.medium
			formatter.timeStyle = DateFormatter.Style.none
			return formatter.string(from: date)
		}
		return nil
	}
	
	/// Whether this task has been completed.
	var completed: Bool {
		return nil != completedDate
	}
	
	/// Whether this task is pending.
	var pending: Bool {
		return !due && !completed
	}
	
	/// Whether this task can be reviewed.
	var canReview: Bool {
		return false
	}
	
	/// The title of this task.
	var title: String?
	
	/// The resource resulting from this task, if any.
	var resultResource: Resource?
	
	required init(id: String, type: UserTaskType) {
		self.id = id
		self.type = type
	}
	
	
	// MARK: - Progress
	
	func progressImage() -> UIImage {
		if completed {
			return UIImage(named: "progress_complete")!
		}
		if due {
			return UIImage(named: "progress_due")!
		}
		return UIImage(named: "progress_pending")!
	}
	
	
	// MARK: - Creation & Completion
	
	/** Call this method to let the user know about the new task and emit a notification. */
	func add(to user: User) throws {
		try user.add(task: self)
		assignedTo = user
		NotificationCenter.default.post(name: UserDidReceiveTaskNotification, object: self, userInfo: [kUserTaskNotificationUserKey: user])
	}
	
	/** Call this method to mark a task complete. */
	final func completed(by user: User, context: Any?) {
		completedDate = Date()
		NotificationCenter.default.post(name: UserDidCompleteTaskNotification, object: self, userInfo: [kUserTaskNotificationUserKey: user])
	}
	
	
	// MARK: - Serialization
	
	required init(serialized: [String: Any]) throws {
		id = serialized["id"] as? String ?? ""
		type = UserTaskType(rawValue: serialized["type"] as? String ?? "") ?? .unknown
		if id.isEmpty || .unknown == type {
			throw AppError.generic("Invalid serialization format for UserTask: \(serialized)")
		}
		if let ttl = serialized["title"] as? String {
			title = ttl
		}
		if let notify = serialized["notificationType"] as? String {
			notificationType = NotificationManagerNotificationType(rawValue: notify)
		}
		if let due = serialized["due"] as? String {
			dueDate = FHIRDate(string: due)?.nsDate
		}
		if let delayMax = serialized["delayMax"] as? String {
			delayMaxDate = DateTime(string: delayMax)?.nsDate
		}
		if let done = serialized["done"] as? String {
			completedDate = FHIRDate(string: done)?.nsDate
		}
	}
	
	func serialized() -> [String: Any] {
		var json = ["id": id, "type": type.rawValue]
		if let title = title {
			json["title"] = title
		}
		if let notify = notificationType {
			json["notificationType"] = notify.rawValue
		}
		if let due = dueDate?.fhir_asDate() {
			json["due"] = due.asJSON()
		}
		if let delayMax = delayMaxDate?.fhir_asDateTime() {
			json["delayMax"] = delayMax.asJSON()
		}
		if let comp = completedDate?.fhir_asDate() {
			json["done"] = comp.asJSON()
		}
		return json
	}
}

