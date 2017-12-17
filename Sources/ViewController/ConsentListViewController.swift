//
//  ConsentListViewController.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 2/16/17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import UIKit
import C3PRO

class ConsentListViewController: UITableViewController {
	
	var availablePDFs: [(String, URL)] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "consentCell")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		loadAvailablePDFs()
	}
	
	// MARK: - PDFs
	
	func loadAvailablePDFs() {
		guard 0 == availablePDFs.count else {
			return
		}
		
		var available: [(String, URL)] = []
		let urls = Bundle.main.urls(forResourcesWithExtension: "pdf", subdirectory: "c-tracker-sccs-consent-documents") ?? []
		for url in urls {
			let name = url.deletingPathExtension().lastPathComponent
			available.append((name, url.standardizedFileURL))
		}
		availablePDFs = available.sorted { return $0.0.lowercased() < $1.0.lowercased() }
	}
	
	func pdfTuple(for indexPath: IndexPath) -> (String, URL)? {
		guard 0 == indexPath.section else {
			return nil
		}
		guard indexPath.row < availablePDFs.count else {
			return nil
		}
		return availablePDFs[indexPath.row]
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return availablePDFs.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "consentCell", for: indexPath)
		
		if let pdf = pdfTuple(for: indexPath) {
			cell.textLabel?.text = pdf.0
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let pdf = pdfTuple(for: indexPath) else {
			return
		}
		
		let pdfController = PDFViewController()
		if FileManager.default.isReadableFile(atPath: pdf.1.path) {
			if let navi = navigationController {
				pdfController.title = "Consent".sccs_loc
				pdfController.hidesBottomBarWhenPushed = true
				pdfController.startURL = pdf.1
				navi.pushViewController(pdfController, animated: true)
			}
			else {
				c3_logIfDebug("I must be embedded in a navigation controller to show the consent")
			}
		}
		else {
			c3_logIfDebug("FAILED to locate «\(pdf.1)»")
		}

	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if 0 == section {
			return "The consent you've signed is specific to the location where you've signed up for study participation.".sccs_loc
		}
		return nil
	}
}
