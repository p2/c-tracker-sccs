//
//  StudyContentWebViewController.swift
//  CTracker
//
//  Created by Pascal Pfiffner on 8/20/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import C3PRO


class StudyContentWebViewController: WebViewController {
	
	var htmlContent: String?
	
	lazy var htmlHeader: String = {
		return "<header><div></div></header>"
	}()
	
	override var startURL: URL? {
		didSet {
			if let url = startURL, var html = try? String(contentsOf: url, encoding: String.Encoding.utf8) {
				html = html.replacingOccurrences(of: "<body>", with: "<body>\(htmlHeader)")
				htmlContent = html as String
			}
		}
	}
	
	override func loadStartURL() {
		if let webView = webView, let html = htmlContent {
			webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL.appendingPathComponent("HTMLContent"))
		}
	}
}

