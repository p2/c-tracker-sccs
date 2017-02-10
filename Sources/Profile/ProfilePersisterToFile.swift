//
//  ProfilePersisterToFile.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 10.02.17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import Foundation
import HealthKit
import SMART
import C3PRO


/**
Simple implementation of `ProfilePersister` that persists to JSON files in a protected directory.

Data pertaining to the user will be written to the following files inside `directory` the persister is configured to run. These files will
receive OS-level data protection.

- `User.json`: participant demographic information
- `Schedule.json`: A schedule of the tasks for the user for the whole course of his or her enrollment
- `Completed.json`: Which tasks have been completed
*/
public class ProfilePersisterToFile: ProfilePersister {
	
	/// The base directory we'll use.
	public let directory: URL
	
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
	}
	
	
	// MARK: - User
	
	public func loadEnrolledUser(type: User.Type) throws -> User? {
		guard FileManager.default.fileExists(atPath: userURL.path) else {
			return nil
		}
		let data = try Data(contentsOf: userURL)
		let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
		return type(of: self).userFromJSON(json, of: type)
	}
	
	public func persist(user: User) throws {
		try type(of: self).persist(user: user, at: userURL)
	}
	
	public func userDidWithdraw(user: User?) throws {
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
	}
	
	
	/**
	Serializes and writes user data to the given location.
	*/
	class func persist(user: User, at url: URL) throws {
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
		if let linked = user.linkedDate?.fhir_asDate() {
			json["linked"] = linked.description
		}
		if let linked = user.linkedAgainst?.absoluteString {
			json["linked_at"] = linked
		}
		if user.biologicalSex != .notSet {
			json["gender"] = user.biologicalSex.rawValue
		}
		if let height = user.bodyheight {
			json["height"] = "\(height.doubleValue(for: HKUnit.meterUnit(with: .centi))) cm"
		}
		if let weight = user.bodyweight {
			json["weight"] = "\(weight.doubleValue(for: HKUnit.gramUnit(with: .kilo))) kg"
		}
		let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
		try data.write(to: url, options: [.atomic, .completeFileProtection])
	}
	
	/**
	Create a user from stored JSON data.
	*/
	class func userFromJSON(_ json: [String: Any], of type: User.Type) -> User {
		var user = type.init()
		if let name = json["name"] as? String, name.characters.count > 0 {
			user.name = name
		}
		if let bday = json["birthday"] as? String, bday.characters.count > 0 {
			user.birthDate = FHIRDate(string: bday)?.nsDate
		}
		if let enrolled = json["enrolled"] as? String, enrolled.characters.count > 0 {
			user.enrollmentDate = FHIRDate(string: enrolled)?.nsDate
		}
		if let linked = json["linked"] as? String, linked.characters.count > 0 {
			user.linkedDate = FHIRDate(string: linked)?.nsDate
		}
		if let linked = json["linked_at"] as? String, linked.characters.count > 0 {
			user.linkedAgainst = URL(string: linked)
		}
		if let genderInt = json["gender"] as? Int, let gender = HKBiologicalSex(rawValue: genderInt) {
			user.biologicalSex = gender
		}
		if let height = json["height"] as? String {
			let comps = height.components(separatedBy: CharacterSet.whitespaces)
			if 2 == comps.count {
				let val = (comps[0] as NSString).doubleValue
				user.bodyheight = HKQuantity(unit: HKUnit(from: comps[1]), doubleValue: val)
			}
		}
		if let weight = json["weight"] as? String {
			let comps = weight.components(separatedBy: CharacterSet.whitespaces)
			if 2 == comps.count {
				let val = (comps[0] as NSString).doubleValue
				user.bodyweight = HKQuantity(unit: HKUnit(from: comps[1]), doubleValue: val)
			}
		}
		return user
	}
	
	
	// MARK: - Tasks
	
	/**
	Reads all scheduled tasks first – assumes that a schedule has been set up! – and then updates the instances with completed tasks.
	*/
	public func loadAllTasks(for user: User?) throws -> [UserTask] {
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
	Reads the user's scheduled tasks. Assumes that tasks have already been scheduled!
	*/
	func readScheduledTasks() throws -> [UserTask] {
		guard FileManager.default.fileExists(atPath: scheduleURL.path) else {
			return []
		}
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
	Persist information about a specific task.
	*/
	public func persist(task: UserTask) throws {
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
		//if permissioner.hasGeoLocationPermissions(always: false) {
		// TODO: use Geocoder.currentLocation()
		//tsk["location"] = "xy"
		//}
		completed.append(tsk)
		try write(json: ["completed": completed], to: completedURL)
	}
	
	public func persist(schedule: [UserTask]) throws {
		try write(json: ["schedule": schedule.map() { $0.serialized() }], to: scheduleURL)
	}
	
	
	// MARK: - Utilities
	
	private func write(json: [String: Any], to url: URL) throws {
		let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
		try data.write(to: url, options: [.atomic, .completeFileProtection])
	}
}

