//
//  ProfileManager.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 07.09.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import SMART
import C3PRO
import HealthKit


/**
The profile manager handles the app user, which usually is the user that consented to participating in the study.

It uses the bundled file `ProfileSettings.json` to schedule tasks for the user.

Data pertaining to the user will be written to the following files inside `directory` the manager is configured to run. These files will
receive OS-level data protection.

- `User.json`: participant demographic information
- `Schedule.json`: A schedule of the tasks for the user for the whole course of his or her enrollment
- `Completed.json`: Which tasks have been completed
*/
open class ProfileManager {
	
	static let didChangeProfileNotification = Notification.Name("ProfileManagerDidChangeProfileNotification")
	
	static let userDidWithdrawFromStudyNotification = Notification.Name("UserDidWithdrawFromStudyNotification")
	
	var user: User?
	
	var server: Server?
	
	let directory: URL
	
	var settings: ProfileManagerSettings?
	
	var taskPreparer: UserTaskPreparer?
	
	var permissioner: SystemServicePermissioner?
	
	private var settingsURL: URL? {
		#if DEBUG
			return Bundle.main.url(forResource: "ProfileSettingsDebug", withExtension: "json")
		#else
			return Bundle.main.url(forResource: "ProfileSettings", withExtension: "json")
		#endif
	}
	
	/// JSON file containing user demographic information.
	private var userURL: URL {
		return directory.appendingPathComponent("User.json")
	}
	
	/// The user-specific schedule lives here.
	private var scheduleURL: URL {
		return directory.appendingPathComponent("Schedule.json")
	}
	
	/// Tasks that have been completed by the user.
	private var completedURL: URL {
		return directory.appendingPathComponent("Completed.json")
	}
	
	public init(dir: URL) throws {
		directory = dir
		
		let fm = FileManager()
		var isDir: ObjCBool = false
		if !fm.fileExists(atPath: directory.path, isDirectory: &isDir) || !isDir.boolValue {
			try fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
		}
		
		if let settingsURL = settingsURL {
			let data = try Data(contentsOf: settingsURL)
			let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
			settings = try ProfileManagerSettings(with: json)
		}
		if fm.fileExists(atPath: userURL.path) {
			let data = try Data(contentsOf: userURL)
			let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
			user = type(of: self).userFromJSON(json)
		}
		if fm.fileExists(atPath: scheduleURL.path) {
			user?.tasks = try readAllTasks()
		}
	}
	
	
	// MARK: - Enrollment & Withdrawal
	
	/**
	Enroll the given user profile.
	
	- parameter user: The User to enroll
	*/
	open func enroll(user: User) throws {
		self.user = user
		user.didEnroll(on: Date())
		
		try type(of: self).persist(user: user, at: userURL)
		try setupSchedule()
		if let server = server {
			taskPreparer = taskPreparer ?? UserTaskPreparer(user: user, server: server)
			taskPreparer!.prepareDueTasks() { [weak self] in
				if let this = self {
					this.taskPreparer = nil
				}
			}
		}
		
		NotificationCenter.default.post(name: type(of: self).didChangeProfileNotification, object: self)
	}
	
	/**
	Withdraw our user.
	*/
	open func withdraw() throws {
		user = nil
		
		let fm = FileManager()
		if fm.fileExists(atPath: userURL.path) {
			try fm.removeItem(at: userURL)
		}
		if fm.fileExists(atPath: scheduleURL.path) {
			try fm.removeItem(at: scheduleURL)
		}
		if fm.fileExists(atPath: completedURL.path) {
			try fm.removeItem(at: completedURL)
		}
		
		NotificationManager.shared.cancelExistingNotifications(ofTypes: [], evenRescheduled: true)
		NotificationCenter.default.post(name: type(of: self).didChangeProfileNotification, object: self)
	}
	
	
	// MARK: - Tasks
	
	/**
	Reads the app's profile configuration, creates `UserTask` for every scheduled task and sets up app notifications.
	*/
	func setupSchedule() throws {
		guard let user = user else {
			throw AppError.noUserEnrolled
		}
		guard let schedulable = settings?.tasks else {
			NSLog("There are no settings or no tasks in the settings, not setting up the user's schedule")
			return
		}
		
		// setup complete schedule
		let now = Date()
		var scheduled = try schedulable.flatMap() { try $0.scheduledTasks(starting: now) }
		scheduled.sort {
			guard let ldue = $0.dueDate else {
				return false
			}
			guard let rdue = $1.dueDate else {
				return true
			}
			return ldue < rdue
		}
		try scheduled.forEach() { try user.add(task: $0) }
		
		// serialize to file and create notifications
		try write(json: ["schedule": scheduled.map() { $0.serialized() }], to: scheduleURL)
		UserNotificationManager.shared.synchronizeNotifications(with: self)
	}
	
	/**
	Reads the user's scheduled tasks. Assumes that tasks have already been scheduled!
	*/
	func readScheduledTasks() throws -> [UserTask] {
		let data = try Data(contentsOf: scheduleURL)
		let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
		guard let scheduled = json["schedule"] as? [[String: Any]] else {
			throw AppError.invalidScheduleFormat("Expecting an array of schedule objects at `schedule` top level")
		}
		return try scheduled.map() { try AppUserTask(serialized: $0) }
	}
	
	/**
	Reads the tasks the user has already completed. The returned task instances are minimal representations, carrying id, taskId and
	completion date only.
	*/
	func readCompletedTasks() throws -> [UserTask] {
		if FileManager.default.fileExists(atPath: completedURL.path) {
			let existing = try Data(contentsOf: completedURL)
			let json = try JSONSerialization.jsonObject(with: existing, options: []) as! [String: Any]
			if let completed = json["completed"] {
				guard let completed = completed as? [[String: Any]] else {
					throw AppError.invalidCompletedTasksFormat("Expecting an array of completed task objects at `completed` top level")
				}
				return try completed.map() { try AppUserTask(serialized: $0) }
			}
		}
		return []
	}
	
	/**
	Reads all scheduled tasks first – assumes that a schedule has been set up! – and then updates the instances with completed tasks.
	*/
	func readAllTasks() throws -> [UserTask] {
		let tasks = try readScheduledTasks()
		let completed = try readCompletedTasks()
		return tasks.map() { task in
			if let cmpltd = completed.filter({ $0.id == task.id }).first {
				var copy = task
				copy.completedDate = cmpltd.completedDate
				return copy
			}
			else {
				return task
			}
		}
	}
	
	
	/**
	Create a notification suitable for the given task, influenced by the suggested date given.
	
	- returns: A tuple with the actual notification [0] and the notification type [1]
	*/
	func notification(for task: UserTask, suggestedDate: DateComponents?) -> (UILocalNotification, NotificationManagerNotificationType)? {
		if task.completed {
			return nil
		}
		switch task.type {
		case .survey:
			if let dd = task.dueDate {
				var comps = Calendar.current.dateComponents([.year, .month, .day], from: dd)
				comps.hour = suggestedDate?.hour ?? 10
				comps.minute = suggestedDate?.minute ?? 0
				let date = Calendar.current.date(from: comps)
				
				let notification = UILocalNotification()
				notification.alertBody = "We'd like you to complete another survey".sccs_loc
				notification.fireDate = date
				notification.timeZone = TimeZone.current
				notification.repeatInterval = NSCalendar.Unit.day
				notification.userInfo = [
					AppUserTask.notificationUserTaskIdKey: task.id
				]
				
				return (notification, NotificationManagerNotificationType.delayable)
			}
			return nil
		default:
			return nil
		}
	}
	
	func userDidComplete(task: UserTask, on date: Date, context: Any?) throws {
		guard task.completed else {
			throw AppError.invalidCompletedTasksFormat("The task \(task) has not been marked as completed yet")
		}
		task.completed(on: date)
		var completed = [[String: Any]]()
		
		// read what's already completed
		if FileManager.default.fileExists(atPath: completedURL.path) {
			let existing = try Data(contentsOf: completedURL)
			let json = try JSONSerialization.jsonObject(with: existing, options: []) as! [String: Any]
			if let alreadyCompleted = json["completed"] {
				guard let alreadyCompleted = alreadyCompleted as? [[String: Any]] else {
					throw AppError.invalidCompletedTasksFormat("Expecting an array of completed task objects at `completed` top level")
				}
				completed.append(contentsOf: alreadyCompleted)
			}
		}
		
		// add completed task and persist
		let tsk: [String: Any] = task.serializedMinimal()
		//let permissioner = SystemServicePermissioner()
		//if permissioner.hasGeoLocationPermissions(always: false) {
			// TODO: use Geocoder.currentLocation()
			//tsk["location"] = "xy"
		//}
		completed.append(tsk)
		try write(json: ["completed": completed], to: completedURL)
		
		// handle task context
		if let context = context {
			if let resource = context as? Resource {
				app_logIfDebug("--->  COMPLETED TASK WITH RESOURCE: \(try! resource.asJSON())")
			}
			else {
				app_logIfDebug("Completed task with unknown context: \(context)")
			}
		}
		
		// send notification
		var userInfo = [String: Any]()
		if let user = user {
			userInfo[kUserTaskNotificationUserKey] = user
		}
		NotificationCenter.default.post(name: UserDidCompleteTaskNotification, object: task, userInfo: userInfo)
	}
	
	
	// MARK: - Service Permissions
	
	public func hasPermission(for service: SystemService) -> Bool {
		permissioner = permissioner ?? SystemServicePermissioner()
		return permissioner!.hasPermission(for: service)
	}
	
	public func requestPermission(for service: SystemService, callback: @escaping ((Error?) -> Void)) {
		permissioner = permissioner ?? SystemServicePermissioner()
		permissioner!.requestPermission(for: service, callback: callback)
	}
	
	var healthKitTypes: HealthKitTypes {
		let hkCRead = Set<HKCharacteristicType>([
			HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex)!,
			HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!,
			])
		let hkQRead = Set<HKQuantityType>([
//			HKQuantityType.quantityType(forIdentifier: .height)!,
//			HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
			HKQuantityType.quantityType(forIdentifier: .stepCount)!,
			HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
			HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
			])
		return HealthKitTypes(readCharacteristics: hkCRead, readQuantities: hkQRead, writeQuantities: Set())
	}
	
	
	// MARK: - Serialization
	
	/**
	Serializes and writes user data to the given location.
	*/
	public class func persist(user: User, at url: URL) throws {
		var json = [String: Any]()
		if let name = user.name {
			json["name"] = name
		}
		if let bday = user.birthDate?.fhir_asDate() {
			json["birthday"] = bday.description
		}
		if let enrolled = user.enrollmentDate?.fhir_asDate() {
			json["enrolled"] = enrolled.description
		}
		let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
		try data.write(to: url, options: [.atomic, .completeFileProtection])
	}
	
	/**
	Create a user from stored JSON data.
	*/
	public class func userFromJSON(_ json: [String: Any]) -> User {
		let user = AppUser()
		if let name = json["name"] as? String, name.characters.count > 0 {
			user.name = name
		}
		if let bday = json["birthday"] as? String, bday.characters.count > 0 {
			user.birthDate = FHIRDate(string: bday)?.nsDate
		}
		if let enrolled = json["enrolled"] as? String, enrolled.characters.count > 0 {
			user.enrollmentDate = FHIRDate(string: enrolled)?.nsDate
		}
		return user
	}
	
	/**
	Create a user from confirmed token data.
	*/
	public class func userFromToken(_ token: [String: Any]) -> User {
		let user = AppUser()
		if let name = token["sub"] as? String, name.characters.count > 0 {
			user.name = name
		}
		if let bday = token["birthdate"] as? String, bday.characters.count > 0 {
			user.birthDate = FHIRDate(string: bday)?.nsDate
		}
		return user
	}
	
	
	// MARK: - FHIR
	
	public func patient() -> Patient {
		let patient = Patient()
		if let name = user?.name {
			patient.name = [HumanName()]
			patient.name?.first?.text = FHIRString(name)
		}
		if let bday = user?.birthDate {
			patient.birthDate = bday.fhir_asDate()
		}
		return patient
	}
	
	
	// MARK: - Utilities
	
	private func write(json: [String: Any], to url: URL) throws {
		let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
		try data.write(to: url, options: [.atomic, .completeFileProtection])
	}
	
	
	// MARK: - Trying the App
	
	class func sampleUser() -> User {
		var user = self.userFromToken(["sub": "Sarah Pes", "birthdate": "1976-04-28"])
		user.userId = "000-SAMPLE"
		return user
	}
	
	class func sampleToken() -> (String, String) {
		let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJhdWQiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJqdGkiOiI4MkYyNzk3OUE5MzYiLCJleHAiOiIxNjczNDk3Mjg4Iiwic3ViIjoiU2FyYWggUGVzIiwiYmlydGhkYXkiOiIxOTc2LTA0LTI4In0.e_Fo1vrmn_EjQSN2gp0Pf9a1AI07tvFLnx5UEsLynO0"	// valid until Jan 2023
//		let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJhdWQiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJqdGkiOiI4MkYyNzk3OUE5MzYiLCJleHAiOiIxNDczNDk3Mjg4Iiwic3ViIjoiU2FyYWggUGVzIiwiYmlydGhkYXkiOiIxOTc2LTA0LTI4In0._Y3PHBwGajDt_tdCcFOxLTdFj1kiosYBreKLF9IQ4qU"
		let secret = "secret"
		
		return (token, secret)
	}
}

