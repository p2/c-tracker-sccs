//
//  ClientDebugViewController.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 6/3/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import C3PRO
import SMART

public class ClientDebugViewController: UIViewController {
	
	public var smart: Client?
	
	@IBOutlet var clientName: UILabel?
	@IBOutlet var clientId: UILabel?
	@IBOutlet var clientSecret: UILabel?
	@IBOutlet var clientAntispam: UILabel?
	@IBOutlet var status: UITextView?
	
	override public func loadView() {
		super.loadView()
		self.view.backgroundColor = UIColor.white
		
		let scroll = UIScrollView()
		scroll.translatesAutoresizingMaskIntoConstraints = false
		scroll.preservesSuperviewLayoutMargins = true
		scroll.alwaysBounceVertical = true
		
		self.view.addSubview(scroll)
		self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scroll]|", options: [], metrics: nil, views: ["scroll": scroll]))
		self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scroll]|", options: [], metrics: nil, views: ["scroll": scroll]))
		
		let content = UIView()
		content.translatesAutoresizingMaskIntoConstraints = false
		content.preservesSuperviewLayoutMargins = true
		
		scroll.addSubview(content)
		scroll.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[c]|", options: [], metrics: nil, views: ["c": content]))
		scroll.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[c]|", options: [], metrics: nil, views: ["c": content]))
		self.view.addConstraint(NSLayoutConstraint(item: content, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0.0))
		
		// create content view
		let title = UILabel()
		title.translatesAutoresizingMaskIntoConstraints = false
		title.font = UIFont.preferredFont(forTextStyle: .headline)
		title.text = "Client Configuration"
		
		let name = UILabel()
		name.translatesAutoresizingMaskIntoConstraints = false
		name.setContentHuggingPriority(750, for: .horizontal)
		name.setContentCompressionResistancePriority(1000, for: .horizontal)
		name.font = UIFont.preferredFont(forTextStyle: .body)
		name.textColor = UIColor.gray
		name.text = "Name:"
		
		let id = UILabel()
		id.translatesAutoresizingMaskIntoConstraints = false
		id.setContentHuggingPriority(750, for: .horizontal)
		id.setContentCompressionResistancePriority(1000, for: .horizontal)
		id.font = UIFont.preferredFont(forTextStyle: .body)
		id.textColor = UIColor.gray
		id.text = "ID:"
		
		let secret = UILabel()
		secret.translatesAutoresizingMaskIntoConstraints = false
		secret.setContentHuggingPriority(750, for: .horizontal)
		secret.setContentCompressionResistancePriority(1000, for: .horizontal)
		secret.font = UIFont.preferredFont(forTextStyle: .body)
		secret.textColor = UIColor.gray
		secret.text = "Secret:"
		
		let antispam = UILabel()
		antispam.translatesAutoresizingMaskIntoConstraints = false
		antispam.setContentHuggingPriority(750, for: .horizontal)
		antispam.setContentCompressionResistancePriority(1000, for: .horizontal)
		antispam.font = UIFont.preferredFont(forTextStyle: .body)
		antispam.textColor = UIColor.gray
		antispam.text = "Antispam:"
		
		let nameVal = UILabel()
		nameVal.translatesAutoresizingMaskIntoConstraints = false
		nameVal.font = UIFont.preferredFont(forTextStyle: .body)
		nameVal.numberOfLines = 0
		clientName = nameVal
		
		let idVal = UILabel()
		idVal.translatesAutoresizingMaskIntoConstraints = false
		idVal.font = UIFont.preferredFont(forTextStyle: .body)
		idVal.numberOfLines = 0
		clientId = idVal
		
		let secretVal = UILabel()
		secretVal.translatesAutoresizingMaskIntoConstraints = false
		secretVal.font = UIFont.preferredFont(forTextStyle: .body)
		secretVal.numberOfLines = 1
		clientSecret = secretVal
		
		let antispamVal = UILabel()
		antispamVal.translatesAutoresizingMaskIntoConstraints = false
		antispamVal.font = UIFont.preferredFont(forTextStyle: .body)
		antispamVal.numberOfLines = 1
		clientAntispam = antispamVal
		
		let read = UIButton(type: .system)
		read.translatesAutoresizingMaskIntoConstraints = false
		read.titleLabel?.textColor = UIColor.red
		read.setTitle("GET", for: UIControlState())
		read.addTarget(self, action: #selector(testRead), for: .touchUpInside)
		
		let create = UIButton(type: .system)
		create.translatesAutoresizingMaskIntoConstraints = false
		create.titleLabel?.textColor = UIColor.red
		create.setTitle("POST", for: UIControlState())
		create.addTarget(self, action: #selector(testCreate), for: .touchUpInside)
		
		let forget = UIButton(type: .system)
		forget.translatesAutoresizingMaskIntoConstraints = false
		forget.titleLabel?.textColor = UIColor.red
		forget.setTitle("Forget", for: UIControlState())
		forget.addTarget(self, action: #selector(forgetClient), for: .touchUpInside)
		
		let register = UIButton(type: .system)
		register.translatesAutoresizingMaskIntoConstraints = false
		register.setTitle("Register", for: UIControlState())
		register.addTarget(self, action: #selector(registerClient), for: .touchUpInside)
		
		let status = UITextView()
		status.translatesAutoresizingMaskIntoConstraints = false
		status.isEditable = false
		status.font = UIFont.preferredFont(forTextStyle: .footnote)
		status.textColor = UIColor.gray
		status.isScrollEnabled = false
		status.textContainerInset = .zero
		status.textContainer.lineFragmentPadding = 0.0
		self.status = status
		
		content.addSubview(title)
		content.addSubview(name)
		content.addSubview(nameVal)
		content.addSubview(id)
		content.addSubview(idVal)
		content.addSubview(secret)
		content.addSubview(secretVal)
		content.addSubview(antispam)
		content.addSubview(antispamVal)
		content.addSubview(read)
		content.addSubview(create)
		content.addSubview(forget)
		content.addSubview(register)
		content.addSubview(status)
		
		let views = [
			"title": title,
			"n": name, "nv": nameVal,
			"i": id, "iv": idVal,
			"s": secret, "sv": secretVal,
			"a": antispam, "av": antispamVal,
			"rd": read, "crt": create,
			"fgt": forget, "reg": register,
			"status": status]
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[title]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[n(==a)]-[nv]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[i(==a)]-[iv]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[s(==a)]-[sv]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[a]-[av]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[rd]-[crt]-(>=8)-[fgt]-[reg]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[status]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(20)-[title]-[n(==nv)]-[i(==iv)]-[s]-[a]-(20)-[rd]-(20)-[status]-(20)-|", options: [], metrics: nil, views: views))
		content.addConstraint(NSLayoutConstraint(item: nameVal, attribute: .lastBaseline, relatedBy: .equal, toItem: name, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: idVal, attribute: .lastBaseline, relatedBy: .equal, toItem: id, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: secretVal, attribute: .lastBaseline, relatedBy: .equal, toItem: secret, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: antispamVal, attribute: .lastBaseline, relatedBy: .equal, toItem: antispam, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: create, attribute: .lastBaseline, relatedBy: .equal, toItem: read, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: forget, attribute: .lastBaseline, relatedBy: .equal, toItem: read, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: register, attribute: .lastBaseline, relatedBy: .equal, toItem: read, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
	}
	
	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateView()
	}
	
	func updateView(statusText: String? = nil) {
		guard Thread.isMainThread else {
			DispatchQueue.main.async {
				self.updateView(statusText: statusText)
			}
			return
		}
		
		clientName?.text = smart?.server.authClientCredentials?.name
		clientId?.text = smart?.server.authClientCredentials?.id.truncatedMiddle()
		clientAntispam?.text = nil
		if let antispam = smart?.server.onBeforeDynamicClientRegistration?(URL(string: "http://localhost")!).extraHeaders?["Antispam"] {
			clientAntispam?.text = antispam.truncatedMiddle()
		}
		clientSecret?.text = nil
		if let secret = smart?.server.authClientCredentials?.secret {
			clientSecret?.text = secret.truncatedMiddle()
		}
		if let stat = statusText {
			status?.text = stat
		}
		status?.sizeToFit()
	}
	
	
	// MARK: - Registration
	
	@IBAction func forgetClient() {
		status?.text = "Forgetting credentials..."
		smart?.reset()
		smart?.forgetClientRegistration()
		status?.text = "Done"
		updateView()
	}
	
	@IBAction func registerClient() {
		guard let smart = smart else {
			updateView(statusText: "Cannot test, no SMART client")
			return
		}
		
		let originalLogger = smart.server.logger
		let cachedLogger = CachedLogger(.trace)
		cachedLogger.onLog = { logger, line in
			self.updateView(statusText: logger.logString)
		}
		smart.server.logger = cachedLogger
		
		cachedLogger.debug("C3PRO", msg: "Registering...")
		smart.server.registerIfNeeded() { json, error in
			if let error = error {
				cachedLogger.warn("C3PRO", msg: "\(error)")
			}
			if let id = smart.server.authClientCredentials?.id, !id.isEmpty {
				cachedLogger.debug("C3PRO", msg: "Done")
			}
			smart.server.logger = originalLogger
		}
	}
	
	
	// MARK: - Test Requests
	
	@IBAction func testRead() {
		guard let smart = smart else {
			updateView(statusText: "Cannot test, no SMART client")
			return
		}
		
		let originalLogger = smart.server.logger
		let cachedLogger = CachedLogger(.trace)
		cachedLogger.onLog = { logger, line in
			self.updateView(statusText: logger.logString)
		}
		smart.server.logger = cachedLogger
		
		cachedLogger.debug("C3PRO", msg: "Testing GET...")
		smart.server.ready { error in
			if let error = error {
				cachedLogger.warn("C3PRO", msg: "\(error)")
				smart.server.logger = originalLogger
			} else {
				Questionnaire.read("c-tracker.survey-in-app.withdrawal", server: smart.server) { resource, error in
					if let error = error {
						cachedLogger.warn("C3PRO", msg: "Error executing `read`: \(error)")
					} else if let _ = resource {
						cachedLogger.debug("C3PRO", msg: "Success")
					} else {
						cachedLogger.debug("C3PRO", msg: "Interesting, no error but also no Questionnaire received")
					}
					smart.server.logger = originalLogger
				}
			}
		}
	}
	
	@IBAction func testCreate() {
		guard let smart = smart else {
			updateView(statusText: "Cannot test, no SMART client")
			return
		}
		
		let originalLogger = smart.server.logger
		let cachedLogger = CachedLogger(.trace)
		cachedLogger.onLog = { logger, line in
			self.updateView(statusText: logger.logString)
		}
		smart.server.logger = cachedLogger
		
		cachedLogger.debug("C3PRO", msg: "Testing POST...")
		let response = QuestionnaireResponse()
		response.status = .enteredInError
		
		smart.server.ready { error in
			if let error = error {
				cachedLogger.warn("C3PRO", msg: "\(error)")
				smart.server.logger = originalLogger
			} else {
				response.create(smart.server) { error in
					if let error = error {
						cachedLogger.warn("C3PRO", msg: "Error executing `create`: \(error)")
					} else {
						cachedLogger.debug("C3PRO", msg: "Successfully created test \(response) on \(smart.server)")
					}
					smart.server.logger = originalLogger
				}
			}
		}
	}
}


// MARK: - Utilities

extension String {
	func truncatedMiddle() -> String {
		if count < 7 {
			return "[…]"
		}
		if count < 10 {
			return substring(to: index(startIndex, offsetBy: 3)) + "[…]"
		}
		return substring(to: index(startIndex, offsetBy: 3)) + "[…]" + substring(from: index(endIndex, offsetBy: -3))
	}
}

open class CachedLogger: OAuth2Logger {
	
	/// The logger's logging level, set to `Debug` by default.
	open var level = OAuth2LogLevel.debug
	
	open var logs: [String] = []
	open var logString: String {
		return logs.joined(separator: "\n")
	}
	open var onLog: ((CachedLogger, String) -> Void)?
	
	public init(_ level: OAuth2LogLevel = OAuth2LogLevel.debug) {
		self.level = level
	}
	
	open func reset() {
		logs = []
	}
	
	// MARK: - OAuth2Logger
	
	/**
	The main log method, figures out whether to log the given message based on the receiver's logging level, then just uses `print`. Ignores
	filename, line and function.
	*/
	public func log(_ atLevel: OAuth2LogLevel, module: String?, filename: String?, line: Int?, function: String?, msg: @autoclosure() -> String) {
		if level != .off && atLevel.rawValue >= level.rawValue {
			let line = "[\(atLevel)] \(module ?? ""): \(msg())"
			logs.append(line)
			onLog?(self, line)
		}
	}
}

