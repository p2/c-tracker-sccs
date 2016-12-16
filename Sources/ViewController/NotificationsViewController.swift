//
//  NotificationsViewController.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 7/17/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit


class NotificationsViewController: UITableViewController {
	
	/// Which row is a detail view showing details for the previous row?
	var detailShowingAtRow: Int?
	
	/// The profile manager in charge.
	var profileManager: ProfileManager?
	
	
	// MARK: - View Actions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Reminders".sccs_loc
		tableView.register(ToggleTableViewCell.self, forCellReuseIdentifier: "ToggleCell")
		tableView.register(DetailTableViewCell.self, forCellReuseIdentifier: "DetailCell")
		tableView.register(DateInputTableViewCell.self, forCellReuseIdentifier: "DateInputCell")
	}
	
	
	// MARK: - Actions
	
	func toggleDidChange(_ toggle: UISwitch) {
		if 35789 == toggle.tag {
			UserDefaults.standard.surveyRemindersEnable(toggle.isOn, profileManager: profileManager)
			hideDetailRow(true)
		}
	}
	
	func timeDidChange(_ sender: UIDatePicker) {
		let comps = NSCalendar.current.dateComponents([.hour, .minute], from: sender.date)
		UserDefaults.standard.surveyRemindersSet(timeOfDay: comps, profileManager: profileManager)
		let ip = IndexPath(row: 1, section: 0)
		tableView?.reloadRows(at: [ip], with: .automatic)
		tableView?.selectRow(at: ip, animated: false, scrollPosition: .none)
	}
	
	
	// MARK: - Helper
	
	lazy var timeFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .none
		formatter.timeStyle = .short
		return formatter
	}()
	
	func humanTimeFromComponents(_ components: DateComponents) -> String? {
		let date = NSCalendar.current.date(from: components)!
		return timeFormatter.string(from: date)
	}
	
	
	// MARK: - Detail Row
	
	/**
	Shows a detail row for the given row.
	*/
	func showDetailRowForRow(_ row: Int) {
		if nil != detailShowingAtRow {
			hideDetailRow(false)
		}
		
		detailShowingAtRow = row + 1
		tableView.insertRows(at: [IndexPath(row: detailShowingAtRow!, section: 0)], with: .right)
	}
	
	/**
	Returns a Bool indicating whether a detail row was removed.
	*/
	@discardableResult
	func hideDetailRow(_ deselect: Bool = true) -> Bool {
		if deselect, let selected = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: selected, animated: true)
		}
		if let showing = detailShowingAtRow {
			detailShowingAtRow = nil
			tableView.deleteRows(at: [IndexPath(row: showing, section: 0)], with: .right)
			return true
		}
		return false
	}
	
	func originalRowForRow(_ row: Int) -> Int? {
		var origRow = row
		if let showing = detailShowingAtRow {
			if showing == row {
				return nil
			}
			origRow = (row > showing) ? row-1 : row
		}
		return origRow
	}
	
	
	// MARK: - Table View Data Source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2 + (nil == detailShowingAtRow ? 0 : 1)
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if let showing = detailShowingAtRow, showing == indexPath.row {
			return detailCellForStandardRowAt(originalRowForRow(showing - 1)!, section: indexPath.section)
		}
		
		if let row = originalRowForRow(indexPath.row) {
			return standardCellForStandardRowAt(row, section: indexPath.section)
		}
		return UITableViewCell()
	}
	
	func standardCellForStandardRowAt(_ row: Int, section: Int) -> UITableViewCell {
		let indexPath = IndexPath(row: row, section: section)
		switch row {
		case 0:
			let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell", for: indexPath) as! ToggleTableViewCell
			cell.textLabel?.text = "Set Reminders".sccs_loc
			cell.detailTextLabel?.text = nil
			let toggle = cell.toggle ?? UISwitch()
			if nil == cell.toggle {
				toggle.tag = 35789
				toggle.addTarget(self, action: #selector(NotificationsViewController.toggleDidChange(_:)), for: .valueChanged)
				cell.toggle = toggle
			}
			toggle.isOn = UserDefaults.standard.surveyRemindersEnable
			cell.accessoryView = toggle
			return cell
		case 1:
			let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath) as! DetailTableViewCell
			cell.textLabel?.text = "Remind me at".sccs_loc
			let comps = UserDefaults.standard.surveyRemindersTimeOfDay
			cell.detailTextLabel?.text = humanTimeFromComponents(comps as DateComponents)
			cell.accessoryView = nil
			return cell
		default:
			return UITableViewCell()
		}
	}
	
	func detailCellForStandardRowAt(_ row: Int, section: Int) -> UITableViewCell {
		let indexPath = IndexPath(row: row, section: section)
		switch row {
		case 1:
			let cell = tableView!.dequeueReusableCell(withIdentifier: "DateInputCell", for: indexPath) as! DateInputTableViewCell
			let picker = cell.picker ?? UIDatePicker()
			if nil == cell.picker {
				picker.translatesAutoresizingMaskIntoConstraints = false
				picker.datePickerMode = .time
				picker.addTarget(self, action: #selector(NotificationsViewController.timeDidChange(_:)), for: .valueChanged)
				cell.picker = picker
				
				cell.contentView.addSubview(picker)
				cell.contentView.addConstraint(NSLayoutConstraint(item: picker, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 0.0))
				cell.contentView.addConstraint(NSLayoutConstraint(item: picker, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0))
				cell.contentView.addConstraint(NSLayoutConstraint(item: picker, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1.0, constant: -8.0))
				cell.contentView.addConstraint(NSLayoutConstraint(item: picker, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1.0, constant: -8.0))
			}
			picker.date = Calendar.current.date(from: UserDefaults.standard.surveyRemindersTimeOfDay)!
			return cell
		default:
			fatalError("No detail cell can be shown for row index \(row)")
		}
	}
	
	
	// MARK: - Table View Delegate
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if let showing = detailShowingAtRow, showing == indexPath.row {
			return 220.0
		}
		return UITableViewAutomaticDimension
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.beginUpdates()
		if let showing = detailShowingAtRow, showing == indexPath.row + 1 {
			hideDetailRow()
		}
		else if let origRow = originalRowForRow(indexPath.row) {
			if 1 == origRow {
				showDetailRowForRow(origRow)
			}
			else {
				hideDetailRow()
			}
		}
		tableView.endUpdates()
	}
	
	
	// MARK: - Cells
	
	class DetailTableViewCell: UITableViewCell {
		override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
			super.init(style: UITableViewCellStyle.value1, reuseIdentifier: reuseIdentifier)
		}

		required init?(coder aDecoder: NSCoder) {
			super.init(coder: aDecoder)
		}
	}
	
	class ToggleTableViewCell: UITableViewCell {
		var toggle: UISwitch?
	}
	
	class DateInputTableViewCell: UITableViewCell {
		var picker: UIDatePicker?
	}
}

