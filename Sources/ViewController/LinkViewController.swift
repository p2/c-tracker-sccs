//
//  LinkViewController.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 06.09.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import JWT
import AVFoundation


class LinkViewController: UIViewController {
	
	@IBOutlet var scanArea: UIView?
	
	var tokenDataConfirmed: (([String: Any]) -> Void)?
	
	var tokenDataRefuted: ((Error) -> Void)?
	
	var usingSampleData = false
	
	var qrCodeScanner: QRCodeScanner?
	
	var scanVideoLayer: AVCaptureVideoPreviewLayer?
	
	var scanIndicator: UIView?
	
	
	// MARK: - View
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		do {
			guard let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
				throw AppError.generic("No camera on device, cannot scan QR code")
			}
			let scanner = try QRCodeScanner(with: camera, eventHandler: { metadata in
				self.highlight(metadata: metadata)
				self.didScan(metadata: metadata)
			})
			qrCodeScanner = scanner
			
			// add video preview layer
			scanVideoLayer = AVCaptureVideoPreviewLayer(session: scanner.session)
			scanVideoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
			scanVideoLayer?.frame = scanArea?.layer.bounds ?? CGRect.zero
			if let videoLayer = scanVideoLayer {
				scanArea?.layer.addSublayer(videoLayer)
			}
			
			// initialize code highlight rectangle
			let indicator = UIView()
			indicator.layer.borderColor = UIColor.green.cgColor
			indicator.layer.borderWidth = 4.0
			indicator.layer.cornerRadius = 2.0
			scanArea?.addSubview(indicator)
			scanArea?.bringSubview(toFront: indicator)
			scanIndicator = indicator
		}
		catch {
			show(error: error, title: "Cannot Scan QR Code".sccs_loc)
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		startScanner()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		stopScanner()
	}
	
	
	// MARK: - Code Scanning
	
	func startScanner() {
		scanIndicator?.isHidden = true
		qrCodeScanner?.startRunning()
	}
	
	func stopScanner() {
		qrCodeScanner?.stopRunning()
	}
	
	func highlight(metadata: AVMetadataMachineReadableCodeObject?) {
		guard let metadata = metadata else {
			scanIndicator?.isHidden = true
			return
		}
		let object = scanVideoLayer?.transformedMetadataObject(for: metadata)
		if let rect = object?.bounds {
			scanIndicator?.isHidden = false
			scanIndicator?.frame = rect.insetBy(dx: -1 * (scanIndicator?.layer.borderWidth ?? 4.0), dy: -1 * (scanIndicator?.layer.borderWidth ?? 4.0))
		}
	}
	
	func didScan(metadata: AVMetadataMachineReadableCodeObject?) {
		if let scanned = metadata?.stringValue {
			stopScanner()
			do {
				let payload = try decodeScanned(token: scanned, using: cJWTSecret, issuer: cJWTIssuer)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					self.letUserConfirm(claims: payload)
				}
			}
			catch let error {
				show(error: error, title: "Problem with QR Code".sccs_loc, onDismiss: { action in
					self.startScanner()
				})
			}
		}
	}
	
	func decodeScanned(token: String, using secret: String, issuer: String? = nil) throws -> Payload {
		guard let secretData = secret.data(using: String.Encoding.utf8) else {
			throw AppError.generic("Cannot convert secret to data")
		}
		//print("--->  \(token)")
		return try JWT.decode(token, algorithm: .hs256(secretData), verify: true, audience: nil, issuer: issuer)
	}
	
	
	// MARK: - Confirmation
	
	func letUserConfirm(claims: [String: Any]) {
		guard let confirm = storyboard?.instantiateViewController(withIdentifier: "Confirm") as? ConfirmViewController else {
			fatalError("There is no “Confirm” view controller in storyboard \(storyboard?.description ?? "nil")")
		}
		confirm.claims = claims
		confirm.whenDone = { success in
			if success {
				self.didConfirmToken(data: claims)
			}
			else {
				self.didRefuteTokenData()
			}
		}
		navigationController?.pushViewController(confirm, animated: true)
	}
	
	func didConfirmToken(data: [String: Any]) {
		tokenDataConfirmed?(data)
	}
	
	func didRefuteTokenData() {
		tokenDataRefuted?(AppError.jwtDataRefuted)
	}
	
	
	// MARK: - Fake Tokens
	
	/** Show a QR code image in the scan area and pretend we scanned a fake JWT. */
	@IBAction func simulateTokenScan(_ sender: AnyObject?) {
		let qr = UIImage(named: "QR.png")
		let img = UIImageView(image: qr)
		img.translatesAutoresizingMaskIntoConstraints = false
		scanArea?.addSubview(img)
		scanArea?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[img]|", options: [], metrics: nil, views: ["img": img]))
		scanArea?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[img]|", options: [], metrics: nil, views: ["img": img]))
		
		self.scanFakeToken()
	}
	
	func scanFakeToken() {
		do {
			let (token, secret) = ProfileManager.sampleToken()
			let payload = try decodeScanned(token: token, using: secret)
			DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
				self.letUserConfirm(claims: payload)
			}
		}
		catch let error {
			show(error: error, title: "Invalid Code".sccs_loc)
		}
	}
}

