//
//  ProfileTaskHandler.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 15.03.17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import Foundation


/**
Instances of this class can be used to perform specific actions when a user completes a task.
*/
public protocol ProfileTaskHandler {
	
	/// The manager this handler belongs to. You probably want to make this `unowned` to avoid circular references.
	var manager: ProfileManager { get }
	
	/// Where on the local filesystem the Core Motion reporter is storing data; only need to set if it's relevant to the manager, i.e. if
	/// it is supposed to automatically sample and submit activity data with questionnaires.
	var motionReporterStore: URL? { get set }
	
	
	init(manager: ProfileManager)
	
	func handle(task: UserTask)
}

