//
//  ProfileManager.swift
//  CHIP_Clinic-App
//
//  Created by Pascal Pfiffner on 07.09.16.
//  Copyright © 2016 CHIP. All rights reserved.
//

import Foundation
import SMART


class ProfileManager {
	
	static let didChangePatientNotification = Notification.Name("ProfileManagerDidChangePatientNotification")
	
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
	
	/**
	Set or unset the patient to use.
	*/
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
		NotificationCenter.default.post(name: type(of: self).didChangePatientNotification, object: self)
	}
	
	/**
	Create a patient resource from confirmed token data.
	*/
	public class func profile(from token: [String: Any]) -> Patient {
		let patient = Patient(json: nil)
		if let name = token["sub"] as? String {
			patient.name = [HumanName(json: ["text": name])]
		}
		if let bday = token["birthday"] as? String {
			patient.birthDate = FHIRDate(string: bday)
		}
		
		return patient
	}
	
	
	// MARK: - Trying the App
	
	class func sampleProfile() -> Patient {
		let patient = profile(from: ["sub": "Sarah Pes", "birthday": "1976-04-28"])
		patient.id = "000-SAMPLE"
		return patient
	}
	
	class func sampleToken() -> (String, String) {
		let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJhdWQiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJqdGkiOiI4MkYyNzk3OUE5MzYiLCJleHAiOiIxNjczNDk3Mjg4Iiwic3ViIjoiU2FyYWggUGVzIiwiYmlydGhkYXkiOiIxOTc2LTA0LTI4In0.e_Fo1vrmn_EjQSN2gp0Pf9a1AI07tvFLnx5UEsLynO0"	// valid until Jan 2023
//		let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJhdWQiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJqdGkiOiI4MkYyNzk3OUE5MzYiLCJleHAiOiIxNDczNDk3Mjg4Iiwic3ViIjoiU2FyYWggUGVzIiwiYmlydGhkYXkiOiIxOTc2LTA0LTI4In0._Y3PHBwGajDt_tdCcFOxLTdFj1kiosYBreKLF9IQ4qU"
		let secret = "secret"
		
		return (token, secret)
	}
}

