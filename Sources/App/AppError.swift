//
//  AppError.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 29.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//



public enum AppError: Error {
	
	case generic(String)
	
	/// No user has been enrolled at this time.
	case noUserEnrolled
	
	/// The date format string is invalid.
	case invalidScheduleFormat(String)
}

