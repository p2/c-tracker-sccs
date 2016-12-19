//
//  AppError.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 29.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import Foundation


/**
Errors raised in the app.
*/
public enum AppError: Error, CustomStringConvertible {
	
	case generic(String)
	
	/// No user has been enrolled at this time.
	case noUserEnrolled
	
	/// The schedule's file-format, or a date format string, is invalid.
	case invalidScheduleFormat(String)
	
	/// The format for the completed tasks has an error.
	case invalidCompletedTasksFormat(String)
	
	/// Some JWT data was refuted.
	case jwtDataRefuted
	
	
	// MARK: - CustomStringConvertible
	
	public var description: String {
		switch self {
		case .generic(let str):                     return str;
		case .noUserEnrolled:                       return "Not enrolled in the study yet".sccs_loc
		case .invalidScheduleFormat(let str):       return "Schedule format is invalid".sccs_loc + ":\n\n" + str
		case .invalidCompletedTasksFormat(let str): return "Completed task format is invalid".sccs_loc + ":\n\n" + str
		case .jwtDataRefuted:                       return "You refuted some of the information contained in the code".sccs_loc
		}
	}
}


/**
Prints the given message to stdout if `DEBUG` is defined and true. Prepends filename, line number and method/function name.
*/
public func app_logIfDebug(_ message: @autoclosure () -> String, function: String = #function, file: NSString = #file, line: Int = #line) {
	#if DEBUG
		print("[\(file.lastPathComponent):\(line)] \(function)  \(message())")
	#endif
}

