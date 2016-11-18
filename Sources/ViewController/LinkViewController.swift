//
//  LinkViewController.swift
//  CHIP_Clinic-App
//
//  Created by Pascal Pfiffner on 06.09.16.
//  Copyright © 2016 CHIP. All rights reserved.
//

import UIKit
import SMART
import JWT


class LinkViewController: UIViewController {
	
	@IBOutlet var scanArea: UIView?
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// fake QR code
		let qr = UIImage(named: "QR.png")
		let img = UIImageView(image: qr)
		img.translatesAutoresizingMaskIntoConstraints = false
		scanArea?.addSubview(img)
		scanArea?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[img]|", options: [], metrics: nil, views: ["img": img]))
		scanArea?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[img]|", options: [], metrics: nil, views: ["img": img]))
	}
	
	
	// MARK: - Code Scanning
	
	@IBAction func scanToken(_ sender: AnyObject?) {
		do {
			let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJhdWQiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJqdGkiOiI4MkYyNzk3OUE5MzYiLCJleHAiOiIxNjczNDk3Mjg4Iiwic3ViIjoiU2FyYWggUGVzIiwiYmlydGhkYXkiOiIxOTc2LTA0LTI4In0.e_Fo1vrmn_EjQSN2gp0Pf9a1AI07tvFLnx5UEsLynO0"	// valid until Jan 2023
//			let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJhdWQiOiJodHRwczovL2lkbS5jMy1wcm8uaW8iLCJqdGkiOiI4MkYyNzk3OUE5MzYiLCJleHAiOiIxNDczNDk3Mjg4Iiwic3ViIjoiU2FyYWggUGVzIiwiYmlydGhkYXkiOiIxOTc2LTA0LTI4In0._Y3PHBwGajDt_tdCcFOxLTdFj1kiosYBreKLF9IQ4qU"
			let secret = "secret"
			try didScan(token: token, withSecret: secret)
		}
		catch let error {
			show(error: error, title: "Invalid Code".sccs_loc)
		}
	}
	
	func didScan(token: String, withSecret secret: String) throws {
		guard let secretData = secret.data(using: String.Encoding.utf8) else {
			throw NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot convert secret to data"])
		}
		let payload = try JWT.decode(token, algorithm: .hs256(secretData), verify: true, audience: nil, issuer: "https://idm.c3-pro.io")
		print(payload)
		confirmTokenData(payload)
	}
	
	
	// MARK: - Confirmation
	
	func confirmTokenData(_ data: [String: Any]) {
		if let navi = storyboard?.instantiateViewController(withIdentifier: "ConfirmRoot") as? UINavigationController {
			if let vc = navi.viewControllers.first as? ConfirmViewController {
				var details = [String: Any]()
				data.filter() { ["sub", "birthday"].contains($0.key) }.forEach() { details[$0.key] = $0.value }
				vc.details = details
				vc.whenDone = { success in
					self.dismiss(animated: true)
					if success {
						self.didConfirmTokenData()
					}
					else {
						self.didRefuteTokenData()
					}
				}
				present(navi, animated: true)
			}
			else {
				fatalError("The ”ConfirmRoot” navigation controller's first view controller must be a «ConfirmViewController» but is \(navi.viewControllers.first?.description ?? "nil")")
			}
		}
		else {
			fatalError("There is no “ConfirmRoot” view controller in storyboard \(storyboard?.description ?? "nil")")
		}
	}
	
	func didConfirmTokenData() {
		do {
			try loadProfile()
		}
		catch let error {
			show(error: error, title: "Could not load Profile".sccs_loc)
		}
	}
	
	func didRefuteTokenData() {
		let error = NSError(domain: NSCocoaErrorDomain, code: 354, userInfo: [NSLocalizedDescriptionKey: "You refuted some of the information contained in the code"])
		show(error: error, title: "Incorrect Data".sccs_loc)
	}
	
	
	// MARK: - Profile Data
	
	func loadProfile() throws {
		if let url = Bundle.main.url(forResource: "SamplePatient", withExtension: "json") {
			let data = try Data(contentsOf: url)
			let json = try JSONSerialization.jsonObject(with: data, options: []) as! FHIRJSON
			let patient = Patient(json: json)
			try didLoad(profile: patient)
		}
	}
	
	func didLoad(profile: Patient) throws {
		try ProfileManager.shared.use(patient: profile)
	}
	
	
	// MARK: - Utilities
	
	func show(error: Error, title: String) {
		let msg = (NSCocoaErrorDomain == error._domain) ? error.localizedDescription : "\(error)"
		let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
		present(alert, animated: true)
	}
}

