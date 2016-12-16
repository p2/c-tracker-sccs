//
//  LicenseViewController.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 8/12/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import C3PRO


class LicenseViewController: WebViewController {
	
	override func viewDidLoad() {
		self.title = "Software Licenses".sccs_loc
		super.viewDidLoad()
		DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
			self.loadLicenses()
		}
	}
	
	func loadLicenses() {
		var html = "Our work wouldn't have been possible without the work of other great individuals.".sccs_loc
		if let licenses = Bundle.main.urls(forResourcesWithExtension: "html", subdirectory: "Licenses") {
			for url in licenses {
				if let str = try? NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) {
					html += "\n<hr>\(str)"
				}
			}
		}
		else {
			html = "No folder «Licenses» containing HTML-files found"
		}
		
		DispatchQueue.main.async {
			self.webView?.loadHTMLString(self.htmlDocWithContent(html), baseURL: URL(string: "http://localhost")!)
		}
	}
}

