//
//  UserTask.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 5/19/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


/**
A task a user needs to complete, such as consenting or taking a survey.
*/
class AppUserTask: UserTask {
	
	/// To be used in notification's `userInfo` dictionaries.
	static let notificationUserTaskIdKey = "user-task-id"
	
	let id: String
	
	let taskId: String
	
	let type: UserTaskType
	
	var assignedTo: User?
	
	var notificationType: NotificationManagerNotificationType?
	
	/// The day this task is due.
	var dueDate: Date?
	
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
				return "in {{days}} days".sccs_loc.replacingOccurrences(of: "{{days}}", with: "\(diff)")
			}
			
			// later than in 5 days: show date
			let formatter = DateFormatter()
			formatter.dateStyle = DateFormatter.Style.medium
			formatter.timeStyle = DateFormatter.Style.none
			return formatter.string(from: date)
		}
		return nil
	}
	
	/// The day this task has been completed.
	var completedDate: Date?
	
	var humanCompletedExpiredDate: String? {
		if let date = completedDate ?? expiredDate {
			let formatter = DateFormatter()
			formatter.dateStyle = DateFormatter.Style.medium
			formatter.timeStyle = DateFormatter.Style.none
			return formatter.string(from: date)
		}
		return nil
	}
	
	/// The day this task has expired.
	var expiredDate: Date?
	
	/// Whether this task is due.
	var due: Bool {
		if completed || expired {
			return false
		}
		if let dd = dueDate {
			return dd < Date()
		}
		return false
	}
	
	/// Whether this task is pending.
	var pending: Bool {
		return !completed && !expired && !due
	}
	
	/// Whether this task has been completed.
	var completed: Bool {
		return nil != completedDate
	}
	
	/// Whether this task has expired.
	var expired: Bool {
		return !completed && nil != expiredDate && expiredDate! < Date()
	}
	
	/// Whether this task can be reviewed.
	var canReview: Bool {
		return false
	}
	
	/// The title of this task.
	var title: String?
	
	/// The resource resulting from this task, if any.
	var resultResource: Resource?
	
	required init(id: String, taskId: String, type: UserTaskType) {
		self.id = id
		self.taskId = taskId
		self.type = type
	}
	
	
	// MARK: - Creation & Completion
	
	/** Call this method to let the user know about the new task and emit a notification. */
	func add(to user: User) throws {
		try user.add(task: self)
		assignedTo = user
		NotificationCenter.default.post(name: UserDidReceiveTaskNotification, object: self, userInfo: [kUserTaskNotificationUserKey: user])
	}
	
	/** Call this method to mark a task complete. */
	final func completed(on date: Date, with context: Any?) {
		completedDate = date
		if let context = context {
			if let resource = context as? Resource {
				resultResource = resource
			}
			else {
				app_logIfDebug("Completed task with unknown context: \(context)")
			}
		}
	}
	
	
	// MARK: - Serialization
	
	required init(serialized: [String: Any]) throws {
		id = serialized["id"] as? String ?? UUID().uuidString
		taskId = serialized["taskId"] as? String ?? ""
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
		if let done = serialized["done"] as? String {
			completedDate = DateTime(string: done)?.nsDate
		}
		if let expired = serialized["expired"] as? String {
			expiredDate = DateTime(string: expired)?.nsDate
		}
	}
	
	func serialized(minimal: Bool) -> [String: Any] {
		var errors = [FHIRValidationError]()
		
		var json = ["id": id, "taskId": taskId, "type": type.rawValue]
		if let comp = completedDate?.fhir_asDateTime() {
			json["done"] = comp.asJSON(errors: &errors)
		}
		
		if !minimal {
			if let title = title {
				json["title"] = title
			}
			if let notify = notificationType {
				json["notificationType"] = notify.rawValue
			}
			if let due = dueDate?.fhir_asDate() {
				json["due"] = due.asJSON(errors: &errors)
			}
			if let expired = expiredDate?.fhir_asDateTime() {
				json["expired"] = expired.asJSON(errors: &errors)
			}
		}
		return json
	}
	
	func serialized() -> [String: Any] {
		return serialized(minimal: false)
	}
	
	func serializedMinimal() -> [String: Any] {
		return serialized(minimal: true)
	}
}

