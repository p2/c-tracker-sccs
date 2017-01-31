//
//  GenderPicker.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 5/19/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import HealthKit
import C3PRO


class GenderPicker: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
	
	var onValueChange: ((_ picker: GenderPicker) -> Void)?
	
	var gender = HKBiologicalSex.notSet {
		didSet {
			selectRow(gender.rawValue, inComponent: 0, animated: true)
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
		setup()
	}
	
	func setup() {
		delegate = self
		dataSource = self
	}
	
	
	// MARK: - Delegate & Data Source
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return 4
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return HKBiologicalSex(rawValue: row)!.humanString
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		gender = HKBiologicalSex(rawValue: row)!
		onValueChange?(self)
	}
}

