//
//  SCCSProfileManager.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 10.02.17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import Foundation
import C3PRO
import HealthKit
import SMART


public class SCCSProfileManager: ProfileManager {
	
	/** Overridden to synchronize user notifications. */
	override open func setupSchedule() throws {
		try super.setupSchedule()
		UserNotificationManager.shared.synchronizeNotifications(with: self)
	}
	
	
	/**
	Update and persists the user's name.
	*/
	public func updateUserName(to name: String) throws {
		guard var user = user else {
			throw C3Error.noUserEnrolled
		}
		user.name = name
		take(user: user)
		try persister?.persist(user: user)
	}
	
	
	// MARK: - HealthKit
	
	lazy var healthStore = HKHealthStore()
	
	/**
	Uses `readUserDataFromHealthKit()` to read user data from HealthKit and `persistMedicalData(from:)` to store the data.
	*/
	public func updateMedicalDataFromHealthKit() {
		readUserDataFromHealthKit() { user in
			if let user = user {
				do {
					try self.persistMedicalData(from: user)
				}
				catch {
					c3_warn("Failed to persist medical data: \(error)")
				}
			}
		}
	}
	
	/**
	Updates user properties by copying from the given instance, then persists.
	
	Will update medical data only if the provided `user` instance is an AppUser.
	*/
	public func persistMedicalData(from user: User) throws {
		guard let myUser = self.user else {
			throw C3Error.noUserEnrolled
		}
		if let appUser = myUser as? AppUser {
			appUser.updateMedicalData(from: user)
		}
		take(user: myUser)
		try persister?.persist(user: myUser)
	}
	
	/**
	Retrieves certain user data from HealthKit and returns a `userType` instance which has all retrievable data points assigned.
	*/
	func readUserDataFromHealthKit(_ callback: ((_ user: User?) -> Void)? = nil) {
		if HKHealthStore.isHealthDataAvailable() {
			let group = DispatchGroup()
			var user = userType.init()
			
			do {
				user.biologicalSex = try healthStore.biologicalSex().biologicalSex
			}
			catch let error {
				c3_logIfDebug("Failed to retrieve gender: \(error)")
			}
			
			do {
				user.birthDate = try healthStore.dateOfBirth()
			}
			catch let error {
				c3_logIfDebug("Failed to retrieve date of birth: \(error)")
			}
			
			group.enter()
			healthStore.c3_latestSample(ofType: .height) { quantity, error in
				if let quant = quantity {
					user.bodyheight = quant
				}
				else if let err = error {
					c3_logIfDebug("Failed to retrieve body height: \(err)")
				}
				group.leave()
			}
			
			group.enter()
			healthStore.c3_latestSample(ofType: .bodyMass) { quantity, error in
				if let quant = quantity {
					user.bodyweight = quant
				}
				else if let err = error {
					c3_logIfDebug("Failed to retrieve body weight: \(err)")
				}
				group.leave()
			}
			
			group.notify(queue: DispatchQueue.main) {
				callback?(user)
			}
		}
		else {
			c3_logIfDebug("HKHealthStorage has no health data available")
			callback?(nil)
		}
	}
}

