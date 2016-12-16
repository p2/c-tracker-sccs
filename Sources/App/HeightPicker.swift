//
//  HeightPicker.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 5/22/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import HealthKit


class HeightPicker: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
	
	var onValueChange: ((_ picker: HeightPicker) -> Void)?
	
	var bodyheight: HKQuantity? {
		didSet {
			updateValuesFromMainValue()
			reloadAllComponents()
		}
	}
	
	var values: [HKQuantity]?
	
	var units: [HKUnit]? {
		didSet {
			updateValuesFromMainValue()
			reloadAllComponents()
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
		print("VERIFY UPDATE, should be “US” on US phone: \(Locale.current.regionCode)")
		if let current = Locale.current.regionCode, "US" == current {
			units = [
				HKUnit.foot(),
				HKUnit.inch(),
			]
		}
		else {
			units = [
				HKUnit.meterUnit(with: .centi),
			]
		}
	}
	
	override func reloadAllComponents() {
		reloadAllComponents(false)
	}
	
	func reloadAllComponents(_ animated: Bool) {
		super.reloadAllComponents()
		if let units = units, let values = values {
			var i = 0
			for value in values {
				let val = value.doubleValue(for: units[i])
				if let idx = rowIndexForValue(val, inComponent: i) {
					selectRow(idx, inComponent: i, animated: animated)
				}
				i += 1
			}
		}
	}
	
	
	// MARK: - Value Handling
	
	func updateValuesFromMainValue() {
		let height = bodyheight ?? HKQuantity(unit: HKUnit.meterUnit(with: .centi), doubleValue: 175.0)
		var newValues = [HKQuantity]()
		if let units = units {
			var quantity: HKQuantity? = nil
			for unit in units {
				var value = height.doubleValue(for: unit)
				if let prev = quantity {
					value -= prev.doubleValue(for: unit)
				}
				quantity = HKQuantity(unit: unit, doubleValue: (unit == units.last) ? value : floor(value))
				newValues.append(quantity!)
			}
		}
		values = newValues
	}
	
	func updateMainValueFromValues() {
		if let values = values {
			let unit = HKUnit.meterUnit(with: .centi)
			var cm = 0.0
			for value in values {
				cm += value.doubleValue(for: unit)
			}
			bodyheight = HKQuantity(unit: unit, doubleValue: cm)
		}
	}
	
	
	// MARK: - Value Ranges
	
	func numericMinValueForUnit(_ unit: HKUnit) -> Double {
		switch unit.unitString {
		case "ft":
			return 1.0
		case "in":
			return 0.0
		default:
			return 20.0
		}
	}
	
	func numericMaxValueForUnit(_ unit: HKUnit) -> Double {
		switch unit.unitString {
		case "ft":
			return 9.0
		case "in":
			return 11.0
		default:
			return 300.0
		}
	}
	
	func numericStepValueForUnit(_ unit: HKUnit) -> Double {
		switch unit.unitString {
		default:
			return 1.0
		}
	}
	
	func numericValueForRow(_ row: Int, inComponent component: Int) -> Double? {
		if let unit = units?[component] {
			let min = numericMinValueForUnit(unit)
			let step = numericStepValueForUnit(unit)
			return min + (Double(row) * step)
		}
		return nil
	}
	
	func stringValueForRow(_ row: Int, inComponent component: Int) -> String? {
		if let value = numericValueForRow(row, inComponent: component), let unit = units?[component] {
			return "\(value) \(unit.unitString)"
		}
		return nil
	}
	
	func rowIndexForValue(_ value: Double, inComponent component: Int) -> Int? {
		if let unit = units?[component] {
			let min = numericMinValueForUnit(unit)
			let max = numericMaxValueForUnit(unit)
			let step = numericStepValueForUnit(unit)
			let maxIdx = Int((max - min) / step) + 1
			var idx = 0
			while (idx < maxIdx) {
				if min + (Double(idx) * step) >= value {
					return idx
				}
				idx += 1
			}
			return maxIdx - 1
		}
		return nil
	}
	
	
	// MARK: - Delegate & Data Source
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return units?.count ?? 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		if let unit = units?[component] {
			let min = numericMinValueForUnit(unit)
			let max = numericMaxValueForUnit(unit)
			let step = numericStepValueForUnit(unit)
			return Int((max - min) / step) + 1
		}
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return stringValueForRow(row, inComponent: component) ?? "Not set up"
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		assert(nil != values?[component], "Should have set up value components by now")
		if let unit = units?[component] {
			values![component] = HKQuantity(unit: unit, doubleValue: numericValueForRow(row, inComponent: component)!)
		}
		updateMainValueFromValues()
		onValueChange?(self)
	}
}

