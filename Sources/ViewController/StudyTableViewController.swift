//
//  StudyTableViewController.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 7/15/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import MediaPlayer
import C3PRO


class StudyTableViewController: UITableViewController {
	
	lazy var sections = [
		StudySection(title: "About this Study".sccs_loc, imageName: "listitem_about", htmlPage: "AboutTheStudy"),
		StudySection(title: "Who Can Participate?".sccs_loc, imageName: "listitem_participants", htmlPage: "WhoCanParticipate"),
		StudySection(title: "What is Hepatitis C?".sccs_loc, imageName: "listitem_hepc", htmlPage: "AboutHepC"),
		StudySection(title: "Spread the Word".sccs_loc, imageName: "listitem_share", controllerClass: ShareTableViewController.self),
		StudySection(title: "About SCCS".sccs_loc, imageName: "listitem_howitworks", htmlPage: "AboutSCCS"),
	]
	
	
	// MARK: - View Tasks
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if let head = tableView.tableHeaderView?.subviews.first?.layer {
			head.borderColor = UIColor(white: 0.8, alpha: 0.9).cgColor
			head.borderWidth = 1.0 / UIScreen.main.scale
		}
		
		// C Tracker logo as title view
		let img = UIImage(named: "ctracker")
		let imgview = UIImageView(image: img)
		navigationItem.titleView = imgview
	}
	
	
	// MARK: - Table Data Source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sections.count
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 68.0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "CellText", for: indexPath) as! StudyTextTableViewCell
		let section = indexPath.row >= sections.count ? sections.last! : sections[indexPath.row]
		cell.titleLabel?.text = section.title
		cell.imgView?.image = section.image
		cell.accessoryType = ("listitem_play" == section.imageName) ? .none : .disclosureIndicator		// TODO: bit of a hack
		
		return cell
	}
	
	
	// MARK: - Table Delegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let section = indexPath.row >= sections.count ? sections.last! : sections[indexPath.row]
		if let html = section.htmlPage {
			let web = WebViewController()
			web.startURL = Bundle.main.url(forResource: html, withExtension: "html")
			navigationController?.pushViewController(web, animated: true)
		}
		else if let klass = section.controllerClass {
			let vc = klass.init(style: .grouped)
			navigationController?.pushViewController(vc, animated: true)
		}
		else if let story = section.storyboardId {
			if let vc = storyboard?.instantiateViewController(withIdentifier: story) {
				navigationController?.pushViewController(vc, animated: true)
			}
			else {
				c3_logIfDebug("Failed to instantiate view controller “\(story)” from storyboard \(storyboard)")
			}
		}
		tableView.deselectRow(at: indexPath, animated: true)
	}
}


class StudySection {
	
	var title: String
	
	var imageName: String?
	
	var image: UIImage?
	
	var htmlPage: String?
	
	var controllerClass: UITableViewController.Type?
	
	var storyboardId: String?
	
	init(title: String, imageName: String) {
		self.title = title
		self.imageName = imageName
		self.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
	}
	
	convenience init(title: String, imageName: String, htmlPage: String?) {
		self.init(title: title, imageName: imageName)
		self.htmlPage = htmlPage
	}
	
	convenience init(title: String, imageName: String, controllerClass: UITableViewController.Type?) {
		self.init(title: title, imageName: imageName)
		self.controllerClass = controllerClass
	}
	
	convenience init(title: String, imageName: String, storyboardId: String?) {
		self.init(title: title, imageName: imageName)
		self.storyboardId = storyboardId
	}
}


// MARK: - 

class StudyTextTableViewCell: UITableViewCell {
	
	@IBOutlet var titleLabel: UILabel?
	
	@IBOutlet var imgView: UIImageView?
}

