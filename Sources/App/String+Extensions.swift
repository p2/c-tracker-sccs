//
//  String+Extensions.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 07.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import Foundation


extension String {
	
	
	/**
	Shortcut to `NSLocalizedString`
	*/
	public var sccs_loc: String {
		return NSLocalizedString(self, comment: "")
	}
}

