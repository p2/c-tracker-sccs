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
	
	/// The format for the completed tasks has an error.
	case invalidCompletedTasksFormat(String)
	
	
	// MARK: - CustomStringConvertible
	
	public var description: String {
		switch self {
		case .generic(let str):                     return str;
		case .invalidCompletedTasksFormat(let str): return "Completed task format is invalid".sccs_loc + ":\n\n" + str
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

