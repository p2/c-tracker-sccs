//
//  ProfileManager.swift
//  CHIP_Clinic-App
//
//  Created by Pascal Pfiffner on 07.09.16.
//  Copyright © 2016 CHIP. All rights reserved.
//

import Foundation
import SMART


let ProfileManagerDidChangePatientNotification = Notification.Name("ProfileManagerDidChangePatientNotification")


class ProfileManager {
	
	static let shared = ProfileManager()
	
	let directory: URL
	
	private var url: URL {
		return directory.appendingPathComponent("Patient.json")
	}
	
	public init() {
		let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		guard let first = paths.first else {
			fatalError("No user documents directory, cannot continue")
		}
		directory = URL(fileURLWithPath: first)
		if FileManager.default.fileExists(atPath: url.path) {
			do {
				let data = try Data(contentsOf: url)
				let json = try JSONSerialization.jsonObject(with: data, options: []) as! FHIRJSON
				patient = Patient(json: json)
			}
			catch let error {
				print(error)
			}
		}
	}
	
	
	// MARK: - Status
	
	public private(set) var patient: Patient?
	
	/** Set or unset the patient to use. */
	func use(patient: Patient?) throws {
		if let patient = patient {
			let json = patient.asJSON()
			let data = try JSONSerialization.data(withJSONObject: json, options: [])
			try data.write(to: url)
		}
		else if FileManager.default.fileExists(atPath: url.path) {
			try FileManager.default.removeItem(at: url)
		}
		
		// assign and notify
		self.patient = patient
		NotificationCenter.default.post(name: ProfileManagerDidChangePatientNotification, object: self)
	}
}

