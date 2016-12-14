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
public enum AppError: Error {
	
	case generic(String)
	
	/// No user has been enrolled at this time.
	case noUserEnrolled
	
	/// The schedule's file-format, or a date format string, is invalid.
	case invalidScheduleFormat(String)
	
	/// The format for the completed tasks has an error.
	case invalidCompletedTasksFormat(String)
}


/**
Prints the given message to stdout if `DEBUG` is defined and true. Prepends filename, line number and method/function name.
*/
public func app_logIfDebug(_ message: @autoclosure () -> String, function: String = #function, file: NSString = #file, line: Int = #line) {
	#if DEBUG
		print("[\(file.lastPathComponent):\(line)] \(function)  \(message())")
	#endif
}

