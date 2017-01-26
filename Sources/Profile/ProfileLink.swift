//
//  ProfileLink.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 17.01.17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import JWT
import SMART


/**
You can use instances of this class to link user profiles to known participants on a remote server, by way of JWT.
*/
public class ProfileLink {
	
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
	
	
	// MARK: - Request Generation
	
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
	
	/**
	Create and decorate FHIR Patient resource as needed for the /establish endpoint.
	
	- returns: Correctly configured Patient resource
	*/
	public func patientResource(user: User, dataEndpoint: URL) throws -> Patient {
		guard let userId = user.userId else {
			throw AppError.generic("User does not have a user id")
		}
		let patient = Patient()
		let ident = Identifier()
		ident.value = userId.fhir_string
		ident.system = dataEndpoint.fhir_url
		patient.identifier = [ident]
		return patient
	}
	
	/**
	Configures a `URLRequest` that can be used to establish the link.
	*/
	public func request(linking user: User, dataEndpoint: URL) throws -> URLRequest {
		let linkEndpoint = try establishURL()
		let pat = try patientResource(user: user, dataEndpoint: dataEndpoint)
		
		var req = URLRequest(url: linkEndpoint)
		req.httpMethod = "POST"
		req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		req.addValue("application/json", forHTTPHeaderField: "Content-type")
		req.httpBody = try JSONSerialization.data(withJSONObject: try pat.asJSON(), options: [])
		return req
	}
}

