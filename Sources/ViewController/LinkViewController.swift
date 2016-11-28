//
//  LinkViewController.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 06.09.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import JWT


class LinkViewController: UIViewController {
	
	@IBOutlet var scanArea: UIView?
	
	var tokenDataConfirmed: (([String: Any]) -> Void)?
	
	var tokenDataRefuted: ((Error) -> Void)?
	
	var usingSampleData = false
	
	
	// MARK: - View
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	
	// MARK: - Code Scanning
	
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
		if let confirm = storyboard?.instantiateViewController(withIdentifier: "Confirm") as? ConfirmViewController {
			var details = [String: Any]()
			data.filter() { ["sub", "birthday"].contains($0.key) }.forEach() { details[$0.key] = $0.value }
			confirm.details = details
			confirm.whenDone = { success in
				if success {
					self.didConfirmToken(data: data)
				}
				else {
					self.didRefuteTokenData()
				}
			}
			navigationController?.pushViewController(confirm, animated: true)
		}
		else {
			fatalError("There is no “Confirm” view controller in storyboard \(storyboard?.description ?? "nil")")
		}
	}
	
	func didConfirmToken(data: [String: Any]) {
		tokenDataConfirmed?(data)
	}
	
	func didRefuteTokenData() {
		let error = NSError(domain: NSCocoaErrorDomain, code: 354, userInfo: [NSLocalizedDescriptionKey: "You refuted some of the information contained in the code".sccs_loc])
		tokenDataRefuted?(error)
	}
	
	
	// MARK: - Fake Tokens
	
	@IBAction func simulateTokenScan(_ sender: AnyObject?) {
		
		// fake QR code
		let qr = UIImage(named: "QR.png")
		let img = UIImageView(image: qr)
		img.translatesAutoresizingMaskIntoConstraints = false
		scanArea?.addSubview(img)
		scanArea?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[img]|", options: [], metrics: nil, views: ["img": img]))
		scanArea?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[img]|", options: [], metrics: nil, views: ["img": img]))
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
			self.scanFakeToken()
		}
	}
	
	func scanFakeToken() {
		do {
			let (token, secret) = ProfileManager.sampleToken()
			try didScan(token: token, withSecret: secret)
		}
		catch let error {
			show(error: error, title: "Invalid Code".sccs_loc)
		}
	}
}

