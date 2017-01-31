//
//  LinkViewController.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 06.09.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import AVFoundation


class LinkViewController: UIViewController {
	
	@IBOutlet var scanArea: UIView?
	
	@IBOutlet var instructionOverlay: UIVisualEffectView?
	@IBOutlet var instructionTitle: UILabel?
	@IBOutlet var instructionMain: UILabel?
	@IBOutlet var instructionButton: UIButton?
	@IBOutlet var simulateButton: UIButton?
	
	var tokenConfirmed: ((ProfileLink, Bool) -> Void)?
	
	var tokenRefuted: ((Error) -> Void)?
	
	var usingSampleData = false
	
	var qrCodeScanner: QRCodeScanner?
	
	var scanVideoLayer: AVCaptureVideoPreviewLayer?
	
	var scanIndicator: UIView?
	
	
	// MARK: - View
	
	override func viewDidLoad() {
		super.viewDidLoad()
		#if DEBUG
			simulateButton?.isHidden = false
		#endif
		
		do {
			guard let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
				throw AppError.generic("No camera on device, cannot scan QR code".sccs_loc)
			}
			let scanner = try QRCodeScanner(with: camera, eventHandler: { metadata in
				self.highlightArea(of: metadata)
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
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		if nil != linkToConfirm {
			instructionOverlay?.isHidden = true
			linkToConfirm = nil
		}
	}
	
	
	// MARK: - Instructional View
	
	@IBAction func hideInstructions(_ sender: AnyObject?) {
		instructionOverlay?.isHidden = true
	}
	
	
	// MARK: - Code Scanning
	
	func startScanner() {
		scanIndicator?.isHidden = true
		qrCodeScanner?.startRunning()
	}
	
	func stopScanner() {
		qrCodeScanner?.stopRunning()
	}
	
	func highlightArea(of metadata: AVMetadataMachineReadableCodeObject?) {
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
				let link = try ProfileLink(token: scanned, using: cJWTSecret, issuer: cJWTIssuer)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					self.letUserConfirm(link: link)
				}
			}
			catch let error {
				show(error: error, title: "Problem with QR Code".sccs_loc, onDismiss: { action in
					self.startScanner()
				})
			}
		}
	}
	
	
	// MARK: - Confirmation
	
	var linkToConfirm: (ProfileLink, Bool)?
	
	func letUserConfirm(link: ProfileLink, fakeProfile: Bool = false) {
		linkToConfirm = (link, fakeProfile)
		
		instructionTitle?.text = "Scanned!".sccs_loc
		instructionMain?.text = "Now, please verify your personal data in order to conclude enrollment".sccs_loc
		instructionButton?.setTitle("Verify…".sccs_loc, for: .normal)
		instructionButton?.removeTarget(self, action: nil, for: .touchUpInside)
		instructionButton?.addTarget(self, action: #selector(LinkViewController.startUserConfirm(_:)), for: .touchUpInside)
		instructionOverlay?.isHidden = false
	}
	
	func startUserConfirm(_ sender: AnyObject?) {
		guard let (link, fake) = linkToConfirm else {
			fatalError("No stored link in `linkToConfirm `")
		}
		guard let confirm = storyboard?.instantiateViewController(withIdentifier: "Confirm") as? ConfirmViewController else {
			fatalError("There is no “Confirm” view controller in storyboard \(storyboard?.description ?? "nil")")
		}
		confirm.claims = link.payload
		confirm.whenDone = { success in
			if success {
				self.didConfirm(link: link, isFake: fake)
			}
			else {
				self.didRefute()
			}
		}
		navigationController?.pushViewController(confirm, animated: true)
	}
	
	func didConfirm(link: ProfileLink, isFake: Bool) {
		tokenConfirmed?(link, isFake)
	}
	
	func didRefute() {
		tokenRefuted?(AppError.jwtDataRefuted)
	}
	
	
	// MARK: - Linking
	
	var establishLinkViewController: EstablishViewController?
	
	public func didStartLinking() {
		guard let establish = storyboard?.instantiateViewController(withIdentifier: "Establish") as? EstablishViewController else {
			fatalError("There is no “Establish” view controller in storyboard \(storyboard?.description ?? "nil")")
		}
		navigationController?.pushViewController(establish, animated: true)
		establishLinkViewController = establish
	}
	
	public func didFinishLinking(withStatus status: String) {
		establishLinkViewController?.processDone(status: status)
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
			let link = try ProfileLink(token: token, using: secret)
			DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
				self.letUserConfirm(link: link, fakeProfile: true)
			}
		}
		catch let error {
			show(error: error, title: "Invalid Code".sccs_loc)
		}
	}
}

