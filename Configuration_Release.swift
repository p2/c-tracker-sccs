//
//  Configuration.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 11/28/2016.
//  Copyright (c) 2016 SCCS. All rights reserved.
//

import Foundation



/*

HOW TO:

Copy this file to `Configuration_Release.swift`, then adjust your production settings there. Building the app will replace this default
file with your own file during build in order to apply correct settings.

You can also copy this file to `Configuration_Debug.swift` or any other build configuration (replace "Debug" with your configuration name).

*/


/// The name of your study; will be shown in-app.
let cStudyName = "C Tracker"

/// The FHIR server's base URI.
let cStudyServerRoot = "https://c3-pro.io"

/// optional, client credentials to use from simulator.
let cServerSimulatorClientKey: String?
let cServerSimulatorClientSecret: String?

/// optional, a token to be supplied on client registration as "Antispam" header.
let cServerAntispamToken: String? = "A91DCA9156D3492E89B12832145A8899"

/// An identifier for the public key used to encrypt resources.
let cEncDataQueueKey = "N/A"

/// The issuer endpoint expected from JWT decoding; can be nil if any issuer should be allowed.
let cJWTIssuer: String? = "https://idm.c3-pro.io"

/// The secret used in the JWT.
let cJWTSecret: String = "secret"

/// Your Smooch token; leave nil to not use Smooch.
let cSmoochToken: String? = nil

/// Tumblr OAuth client key serving as api_key.
let cTumblrClientKey: String? = nil

