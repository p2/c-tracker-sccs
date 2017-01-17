//
//  EstablishViewController.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 17.01.17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import UIKit


open class EstablishViewController: UIViewController {
	
	@IBOutlet var spinner: UIActivityIndicatorView?
	
	@IBOutlet var label: UILabel?
	
	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		spinner?.startAnimating()
	}
	
	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		spinner?.stopAnimating()
	}
	
	
	// MARK: - Action
	
	public func processDone(status: String?) {
		spinner?.stopAnimating()
		label?.text = status
	}
}
