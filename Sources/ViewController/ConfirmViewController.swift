//
//  ConfirmViewController.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 09.09.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit


/**
A view controller that can be handed a dictionary with claims and a `whenDone` callback. The user is shown all claims and given the option
to respond "Yes" or "No" on whether they are accurate. The `whenDone` callback is called with a success flag when the user has reviewed all
claims.

Currently supported:

- sub (name)
- birthdate
*/
class ConfirmViewController: UITableViewController {
	
	public var claims: [String: Any]? {
		didSet {
			var confirmable = [String: Any]()
			claims?.filter() { ["sub", "birthdate"].contains($0.key) }.forEach() { confirmable[$0.key] = $0.value }
			confirmableClaims = confirmable.isEmpty ? nil : confirmable
			if isViewLoaded {
				tableView.reloadData()
			}
		}
	}
	
	private var confirmableClaims: [String: Any]?
	
	var confirmed = Set<Int>()
	
	var refuted = Set<Int>()
	
	public var whenDone: ((_ success: Bool) -> Void)?
	
	
	// MARK: - Confirming
	
	@IBAction func didConfirm(_ sender: UIButton) {
		if let all = sender.superview?.subviews {
			for other in all {
				if other.tag > 0, let other = other as? UIButton {
					other.isSelected = false
				}
			}
		}
		sender.isSelected = true
		if 1 == sender.tag {
			refuted.insert(sender.superview?.tag ?? 0)
		}
		else if 2 == sender.tag {
			confirmed.insert(sender.superview?.tag ?? 0)
		}
		checkIfDone()
	}
	
	func checkIfDone() {
		if (confirmed.union(refuted)).count >= tableView(tableView, numberOfRowsInSection: 0) {
			if let whenDone = whenDone {
				whenDone(0 == refuted.count)
			}
			else {
				NSLog("WARNING: no `whenDone` closure assigned, cannot communicate result from \(self)")
			}
		}
	}
	
	@IBAction func cancel(_ sender: AnyObject?) {
		presentingViewController?.dismiss(animated: (nil != sender))
	}
	
	
	// MARK: - Table View Data Source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return confirmableClaims?.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ConfirmData", for: indexPath)
		if let cell = cell as? ConfirmDataCell {
			let key = detailKey(at: indexPath.row)
			cell.topic?.text = topicName(for: key)
			cell.data?.text = confirmableClaims?[key] as? String
			cell.yesButton?.superview?.tag = indexPath.row
		}
		return cell
	}
	
	// MARK: - Helper
	
	func detailKey(at index: Int) -> String {
		switch index {
		case 0:  return "sub"
		case 1:  return "birthdate"
		default: return "sub"
		}
	}
	
	func topicName(for key: String) -> String {
		switch key {
		case "sub":       return "Your name is".sccs_loc
		case "birthdate": return "You were born on".sccs_loc
		default:          return "Your {key} is".sccs_loc.replacingOccurrences(of: "{key}", with: key)
		}
	}
}


class ConfirmDataCell: UITableViewCell {
	
	@IBOutlet var topic: UILabel?
	
	@IBOutlet var data: UILabel?
	
	@IBOutlet var noButton: UIButton?
	
	@IBOutlet var yesButton: UIButton?
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		yesButton?.isHighlighted = false
		yesButton?.isSelected = false
		noButton?.isHighlighted = false
		noButton?.isSelected = false
	}
}

