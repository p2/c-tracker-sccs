//
//  ProfileManager.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 07.09.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import SMART


class ProfileManager {
	
	static let didChangeProfileNotification = Notification.Name("ProfileManagerDidChangeProfileNotification")
	
	var user: User?
	
	let directory: URL
	
	var settings: ProfileManagerSettings?
	
	private var settingsURL: URL? {
		return Bundle.main.url(forResource: "ProfileSettings", withExtension: "json")
	}
	
	private var userURL: URL {
		return directory.appendingPathComponent("User.json")
	}
	
	private var scheduleURL: URL {
		return directory.appendingPathComponent("Schedule.json")
	}
	
	public init(dir: URL) throws {
		directory = dir
		if let settingsURL = settingsURL {
			let data = try Data(contentsOf: settingsURL)
			let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
			settings = try ProfileManagerSettings(with: json)
		}
		if FileManager.default.fileExists(atPath: userURL.path) {
			let data = try Data(contentsOf: userURL)
			let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
			user = type(of: self).userFromJSON(json)
		}
	}
	
	
	// MARK: - Enrollment & Withdrawal
	
	/**
	Enroll (or withdraw, if nil) the given user profile.
	*/
	func enroll(user inUser: User?) throws {
		if var user = inUser {
			user.enrollmentDate = Date()
			try type(of: self).persist(user: user, at: userURL)
			try setupSchedule()
		}
		else {
			let fm = FileManager()
			if fm.fileExists(atPath: userURL.path) {
				try fm.removeItem(at: userURL)
			}
			if fm.fileExists(atPath: scheduleURL.path) {
				try fm.removeItem(at: scheduleURL)
			}
		}
		
		// assign and notify
		user = inUser
		NotificationCenter.default.post(name: type(of: self).didChangeProfileNotification, object: self)
	}
	
	func withdraw(_ callback: (Error?) -> Void) {
		do {
			try enroll(user: nil)
			callback(nil)
		}
		catch let error {
			callback(error)
		}
	}
	
	
	// MARK: - Tasks
	
	func setupSchedule() throws {
		guard let schedulable = settings?.tasks else {
			print("There are no settings or no tasks in the settings, not setting up the user's schedule")
			return
		}
		
		// setup complete schedule
		var scheduled = [UserTask]()
		for task in schedulable {
			scheduled.append(contentsOf: try task.scheduledTasks())
		}
		scheduled.sort {
			guard let ldue = $0.dueDate else {
				return false
			}
			guard let rdue = $1.dueDate else {
				return true
			}
			return ldue < rdue
		}
		
		// serialize to file
		let data = try JSONSerialization.data(withJSONObject: ["schedule": scheduled.map() { $0.serialized() }], options: .prettyPrinted)
		try data.write(to: scheduleURL)
		print("--->  SCHEDULE WRITTEN TO \(scheduleURL)")
		
		// create a notification for the next occurence of each task per taskId
		
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
				
				return (notification, NotificationManagerNotificationType.delayable)
			}
			return nil
		default:
			return nil
		}
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
		let data = try JSONSerialization.data(withJSONObject: json, options: [])
		try data.write(to: url)
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
		if let bday = token["birthday"] as? String, bday.characters.count > 0 {
			user.birthDate = FHIRDate(string: bday)?.nsDate
		}
		return user
	}
	
	
	// MARK: - FHIR
	
	public func patient() -> Patient {
		let patient = Patient(json: nil)
		if let name = user?.name {
			patient.name = [HumanName(json: ["text": name])]
		}
		if let bday = user?.birthDate {
			patient.birthDate = bday.fhir_asDate()
		}
		return patient
	}
	
	
	// MARK: - Trying the App
	
	class func sampleUser() -> User {
		var user = self.userFromToken(["sub": "Sarah Pes", "birthday": "1976-04-28"])
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

