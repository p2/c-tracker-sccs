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
	
	override open var healthKitTypes: HealthKitTypes {
		let types = super.healthKitTypes
		var writes = types.quantityTypesToWrite
		writes.insert(HKQuantityType.quantityType(forIdentifier: .height)!)
		writes.insert(HKQuantityType.quantityType(forIdentifier: .bodyMass)!)
		return HealthKitTypes(readCharacteristics: types.characteristicTypesToRead, readQuantities: types.quantityTypesToRead, writeQuantities: writes)
	}
	
	/**
	Uses `readUserDataFromHealthKit()` to read user data from HealthKit and `persistMedicalData(from:)` to store the data.
	
	- parameter supplementedBy: If provided, data coming back empty from HealthKit will be taken from this user object
	- parameter callback:       Callback to call when data has been fetched
	*/
	public func updateMedicalDataFromHealthKit(supplementedBy: User? = nil, callback: @escaping ((User?) -> ())) {
		readUserDataFromHealthKit() { user in
			if var user = user {
				if let supplementedBy = supplementedBy {
					if .notSet == user.biologicalSex {
						user.biologicalSex = supplementedBy.biologicalSex
					}
					if nil == user.birthDate {
						user.birthDate = supplementedBy.birthDate
					}
					if nil == user.bodyheight {
						user.bodyheight = supplementedBy.bodyheight
					}
					if nil == user.bodyweight {
						user.bodyweight = supplementedBy.bodyweight
					}
				}
				do {
					try self.persistMedicalData(from: user)
				}
				catch {
					c3_warn("Failed to persist medical data: \(error)")
				}
			}
			callback(user)
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
		guard HKHealthStore.isHealthDataAvailable() else {
			c3_logIfDebug("HKHealthStorage has no health data available")
			callback?(nil)
			return
		}
		
		let group = DispatchGroup()
		var user = userType.init()
		var hasData = false
		
		do {
			user.biologicalSex = try healthStore.biologicalSex().biologicalSex
			//hasData = true	// as of iOS 10, this will not throw when access has not been given
		}
		catch let error {
			c3_logIfDebug("Failed to retrieve gender from HealthKit: \(error)")
		}
		
		do {
			user.birthDate = try healthStore.dateOfBirth()
			hasData = true
		}
		catch let error {
			c3_logIfDebug("Failed to retrieve date of birth from HealthKit: \(error)")
		}
		
		group.enter()
		healthStore.c3_latestSample(ofType: .height) { quantity, error in
			if let quant = quantity {
				user.bodyheight = quant
				hasData = true
			}
			else if let error = error {
				c3_logIfDebug("Failed to retrieve body height from HealthKit: \(error)")
			}
			group.leave()
		}
		
		group.enter()
		healthStore.c3_latestSample(ofType: .bodyMass) { quantity, error in
			if let quant = quantity {
				user.bodyweight = quant
				hasData = true
			}
			else if let error = error {
				c3_logIfDebug("Failed to retrieve body weight from HealthKit: \(error)")
			}
			group.leave()
		}
		
		group.notify(queue: DispatchQueue.main) {
			callback?(hasData ? user : nil)
		}
	}
	
	/**
	Stores medical data (height and weight) to HealthKit.
	*/
	public func storeMedicalDataToHealthKit() throws {
		guard HKHealthStore.isHealthDataAvailable() else {
			throw C3Error.healthKitNotAvailable
		}
		guard let user = user else {
			return
		}
		if let height = user.bodyheight {
			let now = Date()
			let type = HKQuantityType.quantityType(forIdentifier: .height)!
			let sample = HKQuantitySample(type: type, quantity: height, start: now, end: now)
			healthStore.save(sample) { success, error in
				if let error = error {
					c3_logIfDebug("Failed to store bodyheight to HealthKit: \(error)")
				}
			}
		}
		if let weight = user.bodyweight {
			let now = Date()
			let type = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
			let sample = HKQuantitySample(type: type, quantity: weight, start: now, end: now)
			healthStore.save(sample) { success, error in
				if let error = error {
					c3_logIfDebug("Failed to store bodyweight to HealthKit: \(error)")
				}
			}
		}
	}
}

