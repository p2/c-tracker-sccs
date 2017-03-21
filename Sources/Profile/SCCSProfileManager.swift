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
	
	/**
	Updates user properties by copying from the given instance, then persists.
	
	Will update medical data only if the provided `user` instance is an AppUser.
	*/
	open func persistMedicalData(from user: User) throws {
		guard let myUser = self.user else {
			throw C3Error.noUserEnrolled
		}
		if let appUser = myUser as? AppUser {
			appUser.updateMedicalData(from: user)
		}
		take(user: myUser)
		try persister?.persist(user: myUser)
	}
	
	override open func setupSchedule() throws {
		try super.setupSchedule()
		UserNotificationManager.shared.synchronizeNotifications(with: self)
	}
}

