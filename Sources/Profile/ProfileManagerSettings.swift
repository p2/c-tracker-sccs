//
//  ProfileManagerSettings.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 29.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import Foundation


/**
Settings for ProfileManager. Also see `UserTaskSetting`, which takes care of settings applied in "notifications".

    {
      "tasks": [
        { ... }
      ]
    }
*/
public struct ProfileManagerSettings {
	
	var tasks: [UserTaskSetting]?
	
	init(with json: [String: Any]) throws {
		if let tsks = json["tasks"] as? [[String: String]] {
			tasks = try tsks.map() { try UserTaskSetting(from: $0) }
		}
	}
}

