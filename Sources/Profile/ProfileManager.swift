//
//  ProfileManager.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 07.09.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import Foundation
import SMART


class ProfileManager {
	
	static let didChangeProfileNotification = Notification.Name("ProfileManagerDidChangeProfileNotification")
	
	var user: User?
	
	let directory: URL
	
	private var url: URL {
		return directory.appendingPathComponent("User.json")
	}
	
	public init(dir: URL) {
		directory = dir
		if FileManager.default.fileExists(atPath: url.path) {
			do {
				let data = try Data(contentsOf: url)
				let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
				user = type(of: self).userFromJSON(json)
			}
			catch let error {
				print(error)
			}
		}
	}
	
	
	// MARK: - Enrollment & Withdrawal
	
	/**
	Enroll (or withdraw, if nil) the given user profile.
	*/
	func enroll(user inUser: User?) throws {
		if var user = inUser {
			user.enrollmentDate = Date()
			try type(of: self).persist(user: user, at: url)
		}
		else if FileManager.default.fileExists(atPath: url.path) {
			try FileManager.default.removeItem(at: url)
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

