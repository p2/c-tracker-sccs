//
//  ProfileLink.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 17.01.17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import JWT


/**
You can use instances of this class to link user profiles to known participants on a remote server, by way of JWT.
*/
open class ProfileLink {
	
	public let token: String
	
	public let secret: String
	
	public let issuer: String?
	
	public let payload: Payload
	
	public init(token: String, using secret: String, issuer: String? = nil) throws {
		self.token = token
		self.secret = secret
		self.issuer = issuer
		guard let secretData = secret.data(using: String.Encoding.utf8) else {
			throw AppError.generic("Cannot convert secret to data")
		}
		//print("--->  \(token)")
		self.payload = try JWT.decode(token, algorithm: .hs256(secretData), verify: true, audience: nil, issuer: issuer)
	}
	
	
	// MARK: -
	
	/**
	Returns the URL against which the link can be established. Uses the token's `aud` parameter and appends `/establish` to arrive at the
	final endpoint.
	*/
	public func establishURL() throws -> URL {
		guard let aud = payload["aud"] as? String else {
			throw AppError.jwtMissingAudience
		}
		guard let url = URL(string: aud) else {
			throw AppError.jwtInvalidAudience(aud)
		}
		return url.appendingPathComponent("establish")
	}
}

