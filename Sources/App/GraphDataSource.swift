//
//  GraphDataSource.swift
//  CTracker
//
//  Created by Pascal Pfiffner on 26/07/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import C3PRO


/**
Data source for ResearchKit's pie chart view, reporting core motion activity.
*/
class PieDataSource: NSObject, ORKPieChartViewDataSource {
	
	var report: ActivityReport? {
		didSet {
			nonZeroActivities = report?.last?.coreMotionActivities?.filter() { 0.0 != $0.duration.value?.decimal ?? 0.0 }
		}
	}
	
	/// All activity sums that are not zero; needed to prevent ResearchKit crash: https://github.com/ResearchKit/ResearchKit/issues/691
	private(set) var nonZeroActivities: [CoreMotionActivitySum]?
	
	init(report: ActivityReport?) {
		self.report = report
		self.nonZeroActivities = report?.last?.coreMotionActivities?.filter() { 0.0 != $0.duration.value?.decimal ?? 0.0 }
	}
	
	func numberOfSegments(in pieChartView: ORKPieChartView) -> Int {
		return nonZeroActivities?.count ?? 0
	}
	
	func pieChartView(_ pieChartView: ORKPieChartView, valueForSegmentAt index: Int) -> CGFloat {
		if let durations = nonZeroActivities, durations.count > index {
			return CGFloat(NSDecimalNumber(decimal: durations[index].duration.value?.decimal ?? 0.0))
		}
		return 0.0
	}
	
	func pieChartViewDISABLEDMETHOD(_ pieChartView: ORKPieChartView, titleForSegmentAtIndex index: Int) -> String {
		if let durations = nonZeroActivities, durations.count > index {
			return durations[index].type.humanName
		}
		return ""
	}
	
	func pieChartView(_ pieChartView: ORKPieChartView, colorForSegmentAt index: Int) -> UIColor {
		if let durations = nonZeroActivities, durations.count > index {
			return durations[index].preferredColorWithSaturation(0.7, brightness: 0.94)
		}
		return UIColor.lightGray
	}
}


/**
Base graph data source class for core motion activity.
*/
class GraphDataSource: NSObject, ORKValueRangeGraphChartViewDataSource {
	
	var report: ActivityReport?
	
	init(report: ActivityReport?) {
		self.report = report
		super.init()
	}
	
	
	// MARK: - Delegate
	
	func numberOfPlots(in graphChartView: ORKGraphChartView) -> Int {
		return report?.last?.coreMotionActivities?.count ?? 0
	}
	
	func graphChartView(_ graphChartView: ORKGraphChartView, numberOfDataPointsForPlotIndex plotIndex: Int) -> Int {
		return report?.count ?? 0
	}
	
	func graphChartView(_ graphChartView: ORKGraphChartView, dataPointForPointIndex pointIndex: Int, plotIndex: Int) -> ORKValueRange {
		if let report = report?[pointIndex] {
			if let durations = report.coreMotionActivities, durations.count > plotIndex {
				var daily = durations[plotIndex].duration.value?.decimal ?? Decimal(0)
				daily.divide(by: Decimal(report.numberOfDays ?? 1))
				return ORKValueRange(value: NSDecimalNumber(decimal: daily).doubleValue)
			}
		}
		return ORKValueRange(value: 0.0)
	}
	
	func graphChartView(_ graphChartView: ORKGraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String? {
		return report?[pointIndex]?.humanPeriod ?? "Unknown"
	}
	
	func graphChartView(_ graphChartView: ORKGraphChartView, colorForPlotIndex plotIndex: Int) -> UIColor {
		if let durations = report?.last?.coreMotionActivities, durations.count > plotIndex {
			return durations[plotIndex].preferredColorWithSaturation(0.7, brightness: 0.94)
		}
		return UIColor.lightGray
	}
	
	func minimumValue(for graphChartView: ORKGraphChartView) -> Double {
		return 0.0
	}
}

/**
Graph data source reporting HealthKit data.
*/
class HealthGraphDataSource: GraphDataSource {
	
	override init(report: ActivityReport?) {
		super.init(report: report)
	}
	
	
	// MARK: - Delegate
	
	override func numberOfPlots(in graphChartView: ORKGraphChartView) -> Int {
		return 3
	}
	
	override func graphChartView(_ graphChartView: ORKGraphChartView, dataPointForPointIndex pointIndex: Int, plotIndex: Int) -> ORKValueRange {
		if let samples = report?[pointIndex]?.healthKitSamples {
			let want: HKQuantityTypeIdentifier = (0 == plotIndex) ? .stepCount : ((1 == plotIndex) ? .flightsClimbed : .activeEnergyBurned)
			for sample in samples {
				if want.rawValue == sample.quantityType.identifier {
					let quantity = try? sample.c3_asFHIRQuantity()
					var daily = quantity?.value?.decimal ?? Decimal(0)
					daily.divide(by: Decimal(report?[pointIndex]?.numberOfDays ?? 1))
					return ORKValueRange(value: NSDecimalNumber(decimal: daily).doubleValue)
				}
			}
		}
		return super.graphChartView(graphChartView, dataPointForPointIndex: pointIndex, plotIndex: plotIndex)
	}
	
	override func graphChartView(_ graphChartView: ORKGraphChartView, colorForPlotIndex plotIndex: Int) -> UIColor {
		return (0 == plotIndex) ? UIColor.red : ((1 == plotIndex) ? UIColor.green : UIColor.blue)
	}
}

