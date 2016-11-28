//
//  User.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 11/28/16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import Foundation
import HealthKit


public protocol User {
	
	var userId: String? { get set }
	
	var name: String? { get set }
	
	var birthDate: Date? { get }
	
	var biologicalSex: HKBiologicalSex { get }
	
	var bloodType: HKBloodType { get set }
	
	var ethnicity: String? { get }
	
	var bodyheight: HKQuantity? { get }
	
	var bodyweight: HKQuantity? { get }
	
	var profileImage: Data? { get }
	
	var enrollmentDate: Date? { get set }
	
	
	// MARK: - Tasks
	
	var tasks: [UserTask] { get set }
	
	func add(task: UserTask) throws
	
	
	// MARK: - Human Readable
	
	var humanSummary: String { get }
	
	var humanBirthday: String? { get }
	
	var humanSex: String { get }
	
	var humanHeight: String? { get }
	
	var humanWeight: String? { get }
}


extension User {
	
	static func ==(a: User, b: User) -> Bool {
		return a.userId == b.userId
	}
}

