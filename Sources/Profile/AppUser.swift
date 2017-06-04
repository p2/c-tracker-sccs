//
//  User.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 5/15/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import HealthKit
import C3PRO


/**
*  The user of the app.
*/
final class AppUser: User {
	
	public var userId: String?
	public var name: String?
	public var email: String?
	public var password: String?
	public var sessionToken: String?
	
	public var birthDate: Date? {
		didSet {
			_humanBirthday = nil
		}
	}
	public var biologicalSex: HKBiologicalSex = .notSet
	public var bloodType: HKBloodType = .notSet
	public var ethnicity: String?
	
	public var bodyheight: HKQuantity? {
		didSet {
			_humanHeight = nil
		}
	}
	public var bodyweight: HKQuantity? {
		didSet {
			_humanWeight = nil
		}
	}
	
	var profileImage: Data?
	public var isSampleUser = false
	
	
	// MARK: - Medical Data
	
	public func updateMedicalData(from user: User) {
		birthDate = user.birthDate
		biologicalSex = user.biologicalSex
		bodyheight = user.bodyheight
		bodyweight = user.bodyweight
		bloodType = user.bloodType
		ethnicity = user.ethnicity
	}
	
	
	// MARK: - Enrollment
	
	public internal(set) var enrollmentDate: Date?
	
	public func didEnroll(on date: Date) {
		enrollmentDate = date
	}
	
	public internal(set) var linkedDate: Date?
	
	public internal(set) var linkedAgainst: URL?
	
	public func didLink(on date: Date, against url: URL) {
		linkedDate = date
		linkedAgainst = url
	}
	
	
	// MARK: - Tasks
	
	public internal(set) var tasks = [UserTask]()
	
	/// All the tasks that are not yet completed nor expired
	public var tasksOutstanding: [UserTask] {
		return tasks.filter() { return !($0.completed || $0.expired) }
	}
	
	public var tasksPast: [UserTask] {
		return tasks.filter() { return $0.completed || $0.expired }.reversed()
	}
	
	public func add(task: UserTask) throws {
		if let assigned = task.assignedTo, assigned.userId != self.userId {
			throw NSError()	// TODO: create error
		}
		tasks.append(task)
	}
	
	
	// MARK: - Human Readable
	
	public var humanSummary: String {
		var parts = (biologicalSex != .notSet) ? [biologicalSex.symbolString] : [String]()
		if let bd = humanBirthday, !bd.isEmpty {	parts.append(bd)	}
		if let he = humanHeight, !he.isEmpty {	parts.append(he)	}
		if let we = humanWeight, !we.isEmpty {	parts.append(we)	}
		return parts.count > 0 ? parts.joined(separator: "; ") : "Gender, birthday, height, weight".sccs_loc
	}
	
	public var humanBirthday: String? {
		if nil == _humanBirthday, let bday = birthDate {
			let formatter = DateFormatter()
			formatter.dateStyle = .medium
			formatter.timeStyle = .none
			_humanBirthday = formatter.string(from: bday)
		}
		return _humanBirthday
	}
	var _humanBirthday: String?
	
	public var humanSex: String {
		return biologicalSex.humanString
	}
	
	public var humanHeight: String? {
		if nil == _humanHeight, let height = bodyheight {
			let formatter = LengthFormatter()
			formatter.isForPersonHeightUse = true
			_humanHeight = formatter.string(fromMeters: height.doubleValue(for: HKUnit.meter()))
		}
		return _humanHeight
	}
	var _humanHeight: String?
	
	public var humanWeight: String? {
		if nil == _humanWeight, let weight = bodyweight {
			let formatter = MassFormatter()
			formatter.isForPersonMassUse = true
			_humanWeight = formatter.string(fromKilograms: weight.doubleValue(for: HKUnit.gramUnit(with: .kilo)))
		}
		return _humanWeight
	}
	var _humanWeight: String?
}

