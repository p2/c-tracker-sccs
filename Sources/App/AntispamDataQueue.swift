//
//  AntispamDataQueue.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 12/3/17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import Foundation
import C3PRO
import SMART

/**
An encrypted data queue that's able to supply an "Antispam" header.
*/
class AntispamDataQueue: EncryptedDataQueue {
	
	let antispamToken: String?
	
	public init(baseURL: URL, auth: OAuth2JSON?, encBaseURL: URL, publicCertificateFile: String, antispamToken: String?) {
		self.antispamToken = antispamToken
		super.init(baseURL: baseURL, auth: auth, encBaseURL: encBaseURL, publicCertificateFile: publicCertificateFile)
	}
	
	required init(baseURL: URL, auth: OAuth2JSON?) {
		fatalError("init(baseURL:auth:) cannot be used on `AntispamDataQueue`, use init(baseURL:auth:encBaseURL:publicCertificateFile:antispamToken:)")
	}
	
	override open func performRequest(against path: String, handler: FHIRRequestHandler, callback: @escaping ((FHIRServerResponse) -> Void)) {
		if let antispamToken = antispamToken {
			var antispam = FHIRRequestHeaders()
			antispam.customHeaders = ["Antispam": antispamToken]
			handler.add(headers: antispam)
		}
		super.performRequest(against: path, handler: handler, callback: callback)
	}
}
