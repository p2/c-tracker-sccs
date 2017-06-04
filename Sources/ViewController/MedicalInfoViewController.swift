//
//  MedicalInfoViewController.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 5/19/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import HealthKit


/**
Allow to edit medical info:

1. Gender
2. Birthday
3. Height
4. Weight
*/
class MedicalInfoViewController : UITableViewController {
	
	var profileManager: SCCSProfileManager! {
		didSet {
			overwriteLocalUserFromManager()
		}
	}
	
	private var user: AppUser?
	
	func overwriteLocalUserFromManager() {
		user = AppUser()
		if let managedUser = profileManager?.user {
			user?.updateMedicalData(from: managedUser)
		}
	}
	
	/// Which row is a detail view showing details for the previous row?
	var detailShowingAtRow: Int?
	
	var inputShowingAtRow: Int?
	var inputFieldShowing: UITextField?
	
	var heightOrWeightChanged = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let discard = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(MedicalInfoViewController.askToDiscard))
		navigationItem.rightBarButtonItem = discard
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		storeInputFieldDataIfPresent()
		if let user = user {
			try? profileManager.persistMedicalData(from: user)
			if heightOrWeightChanged {
				try? profileManager.storeMedicalDataToHealthKit()
			}
		}
	}
	
	
	// MARK: - User Data
	
	func birthdayDidChange(_ picker: UIDatePicker) {
		user?.birthDate = picker.date
		tableView?.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
	}
	
	@IBAction
	func loadFromHealthApp(_ sender: AnyObject?) {
		if let button = sender as? UIButton {
			button.isEnabled = false
		}
		profileManager.updateMedicalDataFromHealthKit(supplementedBy: user) { user in
			if let button = sender as? UIButton {
				button.isEnabled = true
			}
			if let _ = user {
				self.overwriteLocalUserFromManager()
				self.tableView.reloadData()
			}
			else {
				let alert = UIAlertController(title: "Error".sccs_loc, message: "It seems you have not given permission to C Tracker to read from Health".sccs_loc, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK".sccs_loc, style: .cancel, handler: nil))
				alert.addAction(UIAlertAction(title: "Permissions...".sccs_loc, style: .default) { action in
					self.askForPermission() { shallRetry, error in
						if let error = error {
							self.show(error: error)
						}
						else if shallRetry {
							self.loadFromHealthApp(nil)
						}
					}
				})
				self.present(alert, animated: true)
			}
		}
	}
	
	func askForPermission(callback: @escaping (Bool, Error?) -> ()) {
		let genderType = HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!
		if .notDetermined == profileManager.healthStore.authorizationStatus(for: genderType) {
			profileManager.permissioner.requestPermission(for: .healthKit(profileManager.healthKitTypes)) { error in
				callback(true, error)
			}
		}
		else if !UIApplication.shared.openURL(URL(string: "x-apple-health://")!) {
			callback(false, AppError.generic("Please open Health App and go to “Sources” » “C Tracker”".sccs_loc))
		}
		else {
			callback(false, nil)
		}
	}
	
	func askToDiscard() {
		let alert = UIAlertController(
			title: "Unset Medical Data?".sccs_loc,
			message: "This will unset your medical data for the study. You can later re-enter this data manually.".sccs_loc,
			preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Cancel".sccs_loc, style: .cancel, handler: nil))
		alert.addAction(UIAlertAction(title: "Reset".sccs_loc, style: .destructive) { action in
			self.discardAll()
		})
		present(alert, animated: true, completion: nil)
	}
	
	func discardAll() {
		user?.biologicalSex = .notSet
		user?.birthDate = nil
		user?.bodyheight = nil
		user?.bodyweight = nil
		self.tableView.reloadData()
	}
	
	
	// MARK: - Detail Row
	
	func showDetailRowForRow(_ row: Int) {
		hideInputKeyboard()
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
	
	
	// MARK: - Keyboard Input
	
	func showInputKeyboard(_ row: Int) {
		if hideDetailRow(false) {
			inputShowingAtRow = row - 1
		}
		else {
			inputShowingAtRow = row
		}
		tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
	}
	
	func hideInputKeyboard() {
		storeInputFieldDataIfPresent()
		if let input = inputShowingAtRow {
			inputShowingAtRow = nil
			tableView.reloadRows(at: [IndexPath(row: input, section: 0)], with: .none)
		}
	}
	
	func storeInputFieldDataIfPresent() {
		if let field = inputFieldShowing {
			if let weight = field.text, !weight.isEmpty {
				let quant = HKQuantity(unit: weightInputUnit(), doubleValue: (weight as NSString).doubleValue)
				let kilo = quant.doubleValue(for: HKUnit.gramUnit(with: .kilo))
				user?.bodyweight = (kilo >= 3.0 && kilo < 800.0) ? quant : nil
				if nil != user?.bodyweight {
					heightOrWeightChanged = true
				}
			}
			else {
				user?.bodyweight = nil
			}
			field.resignFirstResponder()
			inputFieldShowing = nil
		}
	}
	
	func weightInputUnit() -> HKUnit {
		if let current = Locale.current.regionCode {
			if "US" == current {
				return HKUnit.pound()
			}
			if "UK" == current {
				return HKUnit.stone()
			}
		}
		return HKUnit.gramUnit(with: .kilo)
	}
	
	func inputFieldWithUnit(_ unit: HKUnit) -> UITextField {
		let unitLabel = UILabel()
		unitLabel.translatesAutoresizingMaskIntoConstraints = false
		unitLabel.font = UIFont.preferredFont(forTextStyle: .body)
		unitLabel.textColor = UIColor.gray
		unitLabel.text = "\(unit.unitString) "
		unitLabel.sizeToFit()
		
		let txt = UITextField(frame: CGRect(x: 0, y: 0, width: 80, height: round(unitLabel.font.pointSize * 1.9)))
		txt.translatesAutoresizingMaskIntoConstraints = true
		txt.borderStyle = .roundedRect
		txt.font = UIFont.preferredFont(forTextStyle: .body)
		txt.rightView = unitLabel
		txt.rightViewMode = .always
		txt.keyboardType = UIKeyboardType.numberPad
		
		return txt
	}
	
	
	// MARK: - Table View Data Source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 4 + (nil == detailShowingAtRow ? 0 : 1)
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if let showing = detailShowingAtRow, showing == indexPath.row {
			return detailCellForStandardRowAt(originalRowForRow(showing - 1)!)
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "C3DataCell", for: indexPath) as! MedicalInfoDataTableViewCell
		setupCellForStandardRow(cell, row: originalRowForRow(indexPath.row)!)
		
		return cell
	}
	
	func setupCellForStandardRow(_ cell: MedicalInfoDataTableViewCell, row: Int) {
		cell.detailTextLabel?.text = nil
		
		switch row {
		case 0:
			cell.textLabel?.text = "Gender".sccs_loc
			cell.detailTextLabel?.text = user?.humanSex
		case 1:
			cell.textLabel?.text = "Birthday".sccs_loc
			cell.detailTextLabel?.text = user?.humanBirthday
		case 2:
			cell.textLabel?.text = "Height".sccs_loc
			cell.detailTextLabel?.text = user?.humanHeight
		case 3:
			cell.textLabel?.text = "Weight".sccs_loc
			cell.detailTextLabel?.text = user?.humanWeight
		default:
			break
		}
		
		if let input = inputShowingAtRow, input == row {
			let txt = inputFieldWithUnit(weightInputUnit())
			if let bw = user?.bodyweight {
				txt.text = "\(round(10 * bw.doubleValue(for: weightInputUnit())) / 10)"
			}
			inputFieldShowing = txt
			cell.accessoryView = txt
			cell.detailTextLabel?.text = nil
			txt.becomeFirstResponder()
		}
		else {
			cell.accessoryView = nil
		}
	}
	
	func detailCellForStandardRowAt(_ row: Int) -> UITableViewCell {
		let indexPath = IndexPath(row: row, section: 0)
		switch row {
		case 0:
			let cell = tableView!.dequeueReusableCell(withIdentifier: "C3GenderPickerCell", for: indexPath) as! MedicalInfoPickerTableViewCell
			if let picker = cell.picker as? GenderPicker {
				picker.gender = user?.biologicalSex ?? .notSet
				picker.onValueChange = { [weak self] picker in
					self?.user?.biologicalSex = picker.gender
					self?.tableView?.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
				}
			}
			return cell
		case 1:
			let cell = tableView!.dequeueReusableCell(withIdentifier: "C3DateInputCell", for: indexPath) as! MedicalInfoDateInputTableViewCell
			if let picker = cell.picker {
				if let bday = user?.birthDate {
					picker.date = bday as Date
				}
				picker.addTarget(self, action: #selector(MedicalInfoViewController.birthdayDidChange(_:)), for: .valueChanged)
			}
			return cell
		case 2:
			let cell = tableView!.dequeueReusableCell(withIdentifier: "C3HeightPickerCell", for: indexPath) as! MedicalInfoPickerTableViewCell
			if let picker = cell.picker as? HeightPicker {
				picker.bodyheight = user?.bodyheight
				picker.onValueChange = { [weak self] picker in
					self?.heightOrWeightChanged = true
					self?.user?.bodyheight = picker.bodyheight
					self?.tableView?.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
				}
			}
			return cell
		case 3:
			fatalError("No detail cell can be shown for row index 3")
		default:
			return tableView!.dequeueReusableCell(withIdentifier: "C3GenderPickerCell", for: indexPath) as! MedicalInfoPickerTableViewCell
		}
	}
	
	
	// MARK: - Table View Delegate
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if let showing = detailShowingAtRow, showing == indexPath.row {
			return 162.0
		}
		return UITableViewAutomaticDimension
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.beginUpdates()
		if let showing = detailShowingAtRow, showing == indexPath.row + 1 {
			hideDetailRow()
		}
		else if let input = inputShowingAtRow, input == indexPath.row {
			hideInputKeyboard()
		}
		else if let origRow = originalRowForRow(indexPath.row) {
			if 3 == origRow {
				showInputKeyboard(indexPath.row)
			}
			else {
				showDetailRowForRow(origRow)
			}
		}
		tableView.endUpdates()
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
	}
}


// MARK: - Cells

class MedicalInfoDataTableViewCell : UITableViewCell {
	
}

class MedicalInfoPickerTableViewCell : UITableViewCell {
	@IBOutlet var picker: UIPickerView?
}

class MedicalInfoDateInputTableViewCell : UITableViewCell {
	@IBOutlet var picker: UIDatePicker?
}

