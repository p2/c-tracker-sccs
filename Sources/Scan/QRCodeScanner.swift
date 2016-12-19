//
//  QRCodeScanner.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 19.12.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import Foundation
import AVFoundation


public class QRCodeScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
	
	/// The capture session in use.
	public internal(set) var session: AVCaptureSession
	
	/// The callback to be called on every code that is being found.
	public var didFind: ((AVMetadataMachineReadableCodeObject?) -> Void)
	
	public init(with device: AVCaptureDevice, eventHandler: @escaping ((AVMetadataMachineReadableCodeObject?) -> Void)) throws {
		didFind = eventHandler
		session = AVCaptureSession()
		super.init()
		
		let input = try AVCaptureDeviceInput(device: device)
		session.addInput(input)
		
		let captureMetadataOutput = AVCaptureMetadataOutput()
		session.addOutput(captureMetadataOutput)
		captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
		captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
	}
	
	
	// MARK: - Scanning
	
	public func startRunning() {
		session.startRunning()
	}
	
	public func stopRunning() {
		session.stopRunning()
	}
	
	
	// MARK: - AVCaptureMetadataOutputObjectsDelegate
	
	public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
		guard let objects = metadataObjects as? [AVMetadataMachineReadableCodeObject] else {
			didFind(nil)
			return
		}
		var found = false
		objects.filter() { AVMetadataObjectTypeQRCode == $0.type }.forEach() {
			found = true
			didFind($0)
		}
		if !found {
			didFind(nil)
		}
	}
}

