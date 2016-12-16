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
	@IBOutlet var status: UILabel?
	
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
		
		let test = UIButton(type: .system)
		test.translatesAutoresizingMaskIntoConstraints = false
		test.titleLabel?.textColor = UIColor.red
		test.setTitle("Test", for: UIControlState())
		test.addTarget(self, action: #selector(ClientDebugViewController.testRequest), for: .touchUpInside)
		
		let forget = UIButton(type: .system)
		forget.translatesAutoresizingMaskIntoConstraints = false
		forget.titleLabel?.textColor = UIColor.red
		forget.setTitle("Forget", for: UIControlState())
		forget.addTarget(self, action: #selector(ClientDebugViewController.forgetClient), for: .touchUpInside)
		
		let register = UIButton(type: .system)
		register.translatesAutoresizingMaskIntoConstraints = false
		register.setTitle("Register", for: UIControlState())
		register.addTarget(self, action: #selector(ClientDebugViewController.registerClient), for: .touchUpInside)
		
		let status = UILabel()
		status.translatesAutoresizingMaskIntoConstraints = false
		status.numberOfLines = 0
		status.font = UIFont.preferredFont(forTextStyle: .footnote)
		status.textColor = UIColor.gray
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
		content.addSubview(test)
		content.addSubview(forget)
		content.addSubview(register)
		content.addSubview(status)
		
		let views = [
			"title": title,
			"n": name, "nv": nameVal,
			"i": id, "iv": idVal,
			"s": secret, "sv": secretVal,
			"a": antispam, "av": antispamVal,
			"tst": test,
			"fgt": forget,
			"reg": register,
			"status": status]
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[title]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[n(==a)]-[nv]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[i(==a)]-[iv]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[s(==a)]-[sv]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[a]-[av]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[tst]-(>=8)-[fgt]-(>=8)-[reg]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[status]-|", options: [], metrics: nil, views: views))
		content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(20)-[title]-[n(==nv)]-[i(==iv)]-[s]-[a]-(20)-[tst]-(20)-[status]-(20)-|", options: [], metrics: nil, views: views))
		content.addConstraint(NSLayoutConstraint(item: nameVal, attribute: .lastBaseline, relatedBy: .equal, toItem: name, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: idVal, attribute: .lastBaseline, relatedBy: .equal, toItem: id, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: secretVal, attribute: .lastBaseline, relatedBy: .equal, toItem: secret, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: antispamVal, attribute: .lastBaseline, relatedBy: .equal, toItem: antispam, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: forget, attribute: .centerX, relatedBy: .equal, toItem: content, attribute: .centerX, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: forget, attribute: .lastBaseline, relatedBy: .equal, toItem: test, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: register, attribute: .lastBaseline, relatedBy: .equal, toItem: test, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
	}
	
	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateView()
	}
	
	func updateView(statusText: String? = nil) {
		if !Thread.isMainThread {
			DispatchQueue.main.sync {
				self.updateView(statusText: statusText)
			}
			return
		}
		
		clientName?.text = smart?.server.authClientCredentials?.name ?? "Unnamed"
		clientId?.text = smart?.server.authClientCredentials?.id
		clientAntispam?.text = nil
		if let antispam = smart?.server.onBeforeDynamicClientRegistration?(URL(string: "http://localhost")!).extraHeaders?["Antispam"] {
			clientAntispam?.text = antispam
		}
		clientSecret?.text = nil
		if let secret = smart?.server.authClientCredentials?.secret {
			if secret.characters.count > 12 {
				clientSecret?.text = secret		// TODO: truncate?
			}
			else {
				clientSecret?.text = secret
			}
		}
		if let stat = statusText {
			status?.text = stat
		}
	}
	
	
	// MARK: - Registration
	
	@IBAction func forgetClient() {
		status?.text = "Forgetting credentials..."
		smart?.forgetClientRegistration()
		status?.text = "Done"
		updateView()
	}
	
	@IBAction func registerClient() {
		if let smart = self.smart {
			status?.text = "Registering..."
			smart.server.registerIfNeeded() { json, error in
				var stat = ""
				if let error = error {
					stat = "\(error)"
				}
				if let id = smart.server.authClientCredentials?.id, !id.isEmpty {
					stat = stat.isEmpty ? "Done" : "\(stat)\n\nStill got client credentials"
				}
				if let json = json {
					stat = stat.isEmpty ? "\(json)" : "\(stat)\n\n--- JSON ---\n\n\(json)"
				}
				self.updateView(statusText: stat)
			}
		}
		else {
			status?.text = "Cannot register, do not have a handle to a SMART client"
		}
	}
	
	
	// MARK: - Test Request
	
	@IBAction func testRequest() {
		if let smart = smart {
			updateView(statusText: "Testing...")
			Questionnaire.read("c-tracker.survey-in-app.withdrawal", server: smart.server) { resource, error in
				if let error = error {
					self.updateView(statusText: "Error: \(error)")
				}
				else if let resource = resource {
					self.updateView(statusText: "Success, sample resource received\n\n--- JSON ---\n\n\(try! resource.asJSON())")
				}
				else {
					self.updateView(statusText: "Interesting, no error but also no Bundle received")
				}
			}
		}
		else {
			updateView(statusText: "Cannot test, no SMART client")
		}
	}
}

