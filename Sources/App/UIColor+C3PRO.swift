//
//  UIColor+C3PRO.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 8/11/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit


public extension UIColor {
	
	/**
	Color that fades to grey the closer it gets to `maxSpanDays`.
	*/
	public class func timeFadedColor(_ date: Date, maxSpanDays: Int = 14) -> UIColor {
		let maxSpan = Double(maxSpanDays) * 24 * 3600.0
		let diff = date.timeIntervalSinceNow + maxSpan
		let sat = CGFloat((diff < 0.0) ? 0.0 : (diff / maxSpan))
		return UIColor(hue: 0.558, saturation: sat, brightness: 0.666, alpha: 1.0)
	}
	
	public class func appPrimaryColor() -> UIColor {
		return UIColor(red:57.0/255, green:99.0/255, blue:159.0/255, alpha:1.0)
	}
}

