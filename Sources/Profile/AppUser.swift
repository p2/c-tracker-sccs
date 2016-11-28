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
	
	var userId: String?
	var name: String?
	var email: String?
	var password: String?
	var sessionToken: String?
	
	var birthDate: Date? {
		didSet {
			_humanBirthday = nil
		}
	}
	var biologicalSex: HKBiologicalSex = .notSet
	var bloodType: HKBloodType = .notSet
	var ethnicity: String?
	
	var bodyheight: HKQuantity? {
		didSet {
			_humanHeight = nil
		}
	}
	var bodyweight: HKQuantity? {
		didSet {
			_humanWeight = nil
		}
	}
	
	var profileImage: Data?
	
	var enrollmentDate: Date?
	
	
	// MARK: - Tasks
	
	var tasks = [UserTask]()
	
	func add(task: UserTask) throws {
		if let assigned = task.assignedTo, assigned.userId != self.userId {
			throw NSError()
		}
		tasks.append(task)
	}
	
	
	// MARK: - Human Readable
	
	var humanSummary: String {
		var parts = [humanSex]
		if let bd = humanBirthday {	parts.append(bd)	}
		if let he = humanHeight {	parts.append(he)	}
		if let we = humanWeight {	parts.append(we)	}
		return parts.count > 0 ? parts.joined(separator: " ● ") : "Gender ● Birthday ● Height ● Weight".sccs_loc
	}
	
	var humanBirthday: String? {
		if nil == _humanBirthday, let bday = birthDate {
			let formatter = DateFormatter()
			formatter.dateStyle = .medium
			formatter.timeStyle = .none
			_humanBirthday = formatter.string(from: bday)
		}
		return _humanBirthday
	}
	var _humanBirthday: String?
	
	var humanSex: String {
		return ""//biologicalSex.humanString
	}
	
	var humanHeight: String? {
		if nil == _humanHeight, let height = bodyheight {
			let formatter = LengthFormatter()
			formatter.isForPersonHeightUse = true
			_humanHeight = formatter.string(fromMeters: height.doubleValue(for: HKUnit.meter()))
		}
		return _humanHeight
	}
	var _humanHeight: String?
	
	var humanWeight: String? {
		if nil == _humanWeight, let weight = bodyweight {
			let formatter = MassFormatter()
			formatter.isForPersonMassUse = true
			_humanWeight = formatter.string(fromKilograms: weight.doubleValue(for: HKUnit.gramUnit(with: .kilo)))
		}
		return _humanWeight
	}
	var _humanWeight: String?
}

