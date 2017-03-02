//
//  ProfileViewController.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 5/13/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import C3PRO
import SMART
import ResearchKit


let passcodeTaskId = "set-passcode-task"


class ProfileViewController : UITableViewController, UITextFieldDelegate, ORKPasscodeDelegate, ORKTaskViewControllerDelegate {
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	var willReloadTable = false
	
	var profileManager: ProfileManager!
	
	var user: User? {
		return profileManager.user
	}
	
	@IBOutlet var labelName: UILabel?
	
	@IBOutlet var labelStatus: UILabel?
	
	@IBOutlet var textfieldName: UITextField?
	
	@IBOutlet var buttonWithdraw: UIButton?
	
	@IBOutlet var editingView: UIView?
	
	var mainHeadHeight = CGFloat(1150.0)
	
	override func awakeFromNib() {
		registerForNotifications()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.rightBarButtonItem = editButtonItem
		
		// image as title view
		let img = UIImage(named: "yourprofile")
		let imgview = UIImageView(image: img)
		navigationItem.titleView = imgview
		
		// show version info in footer
		let foot = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 68))
		foot.translatesAutoresizingMaskIntoConstraints = true
		let footTxt = UILabel()
		footTxt.translatesAutoresizingMaskIntoConstraints = false
		footTxt.font = UIFont.preferredFont(forTextStyle: .footnote)
		footTxt.textColor = UIColor.lightGray
		footTxt.textAlignment = .center
		
		let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "~"
		let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
		footTxt.text = "Version \(version) (\(build))"
		
		foot.addSubview(footTxt)
		foot.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[lbl]-|", options: [], metrics: nil, views: ["lbl": footTxt]))
		foot.addConstraint(NSLayoutConstraint(item: footTxt, attribute: .centerY, relatedBy: .equal, toItem: foot, attribute: .centerY, multiplier: 1.0, constant: 0.0))
		tableView.tableFooterView = foot
	}
	
	override func viewWillAppear(_ animated: Bool) {
		updateUserVariables()
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		if editing {
			startEditingName()
		}
		else {
			endEditingName()
		}
	}
	
	
	// MARK: - Consent
	
	func showConsent(_ animated: Bool = true) {
		let pdfController = PDFViewController()
		if let url = ConsentController.signedConsentPDFURL(mustExist: true) ?? ConsentController.bundledConsentPDFURL() {
			if let navi = navigationController {
				pdfController.title = "Consent".sccs_loc
				pdfController.hidesBottomBarWhenPushed = true
				pdfController.startURL = url
				navi.pushViewController(pdfController, animated: true)
			}
			else {
				c3_logIfDebug("I must be embedded in a navigation controller to show the consent")
			}
		}
		else {
			c3_logIfDebug("FAILED to locate «consent.pdf»")
		}
	}
	
	
	// MARK: - Withdrawal
	
	var questionnaireController: QuestionnaireController?
	
	func startWithdrawalQuestionnaire(_ animated: Bool = true) {
		do {
			let questionnaire = try Bundle.main.fhir_bundledResource("c-tracker.survey-in-app.withdrawal", type: Questionnaire.self)
			let quest = QuestionnaireController(questionnaire: questionnaire)
			quest.whenCompleted = { viewController, answers in
				self.dismiss(animated: animated)
				self.doWithdraw(answers)
			}
			quest.whenCancelledOrFailed = { viewController, error in
				if let error = error {
					c3_logIfDebug("failed: \(error)")
				}
				self.dismiss(animated: animated)
			}
			
			quest.prepareQuestionnaireViewController() { viewController, error in
				if let vc = viewController {
					self.present(vc, animated: animated)
				}
				else {
					c3_logIfDebug("Error preparing withdrawal questionnaire: \(error)")
					self.doWithdraw()
				}
			}
			self.questionnaireController = quest
		}
		catch let error {
			c3_logIfDebug("Failed to read withdrawal questionnaire «c-tracker.survey-in-app.withdrawal»: \(error)")
			self.doWithdraw()
		}
	}
	
	func doWithdraw(_ answers: QuestionnaireResponse? = nil) {
		if let answers = answers, let server = profileManager?.dataServer {
			if let user = user {
				answers.subject = try? profileManager.patientResource(for: user).asRelativeReference()
			}
			answers.create(server) { error in }
		}
		self.questionnaireController = nil
		do {
			try profileManager.withdraw()
		}
		catch let error {
			c3_logIfDebug("ERROR withdrawing: \(error)")
		}
	}
	
	
	// MARK: - User Actions
	
	@IBAction func changeName(_ sender: UIGestureRecognizer?) {
		setEditing(true, animated: true)
	}
	
	@IBAction func withdraw(_ sender: UIButton?) {
		let alert = UIAlertController(title: "Leave Study?".sccs_loc,
			message: "Are you sure you wish to withdraw from the study?".sccs_loc,
			preferredStyle: UIAlertControllerStyle.alert)
		let withdraw = UIAlertAction(title: "Leave".sccs_loc, style: UIAlertActionStyle.destructive) { action in
			self.startWithdrawalQuestionnaire(true)
		}
		let abort = UIAlertAction(title: "Cancel".sccs_loc, style: UIAlertActionStyle.cancel, handler: nil)
		
		alert.addAction(abort)
		alert.addAction(withdraw)
		present(alert, animated: true, completion: nil)
	}
	
	func startEditingName() {
		if let edit = editingView, let head = tableView.tableHeaderView {
			textfieldName?.text = user?.name
			
			mainHeadHeight = head.frame.size.height
			head.addSubview(edit)
			edit.translatesAutoresizingMaskIntoConstraints = false
			head.addConstraint(NSLayoutConstraint(item: edit, attribute: .leading, relatedBy: .equal, toItem: head, attribute: .leading, multiplier: 1.0, constant: 0.0))
			head.addConstraint(NSLayoutConstraint(item: edit, attribute: .trailing, relatedBy: .equal, toItem: head, attribute: .trailing, multiplier: 1.0, constant: 0.0))
			head.addConstraint(NSLayoutConstraint(item: edit, attribute: .top, relatedBy: .equal, toItem: head, attribute: .top, multiplier: 1.0, constant: 0.0))
			
			tableView.tableHeaderView = nil
			head.frame = edit.bounds
			tableView.tableHeaderView = head
		}
	}
	
	func endEditingName(_ save: Bool = true) {
		if let edit = editingView {
			if let newName = textfieldName?.text, save {
				profileManager?.user?.name = newName
			}
			updateUserVariables()
			edit.removeFromSuperview()
			
			if let head = tableView.tableHeaderView {
				tableView.tableHeaderView = nil
				head.frame.size.height = mainHeadHeight
				tableView.tableHeaderView = head
			}
		}
	}
	
	func updateUserVariables(_ andTasks: Bool = false) {
		if !isViewLoaded {
			return
		}
		labelName?.text = user?.name
		if nil != user?.enrollmentDate {
			labelStatus?.text = "You are enrolled in {{study}}".sccs_loc.replacingOccurrences(of: "{{study}}", with: cStudyName)
			buttonWithdraw?.isEnabled = true
		}
		else {
			labelStatus?.text = "Join {{study}}!".sccs_loc.replacingOccurrences(of: "{{study}}", with: cStudyName)
			buttonWithdraw?.isEnabled = false
		}
		
		self.tableView.reloadData()
	}
	
	func userDidSomething(_ notification: Notification?) {
		updateUserVariables(true)
	}
	
	func userDidWithdraw(_ notification: Notification?) {
		userDidSomething(notification)
	}
	
	
	// MARK: - Table View Data Source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 4
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if 2 == section {
		#if DEBUG
			return 4
		#else
			return 3
		#endif
		}
		if 3 == section {
			return 2
		}
		return 1
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if 0 == section {
			return "Your Medical Data".sccs_loc
		}
		if 1 == section {
			return (nil == user?.enrollmentDate) ? nil : "Consent".sccs_loc
		}
		if 2 == section {
			return "App Settings".sccs_loc
		}
		return "Legal".sccs_loc
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if 0 == indexPath.section {
			let cell = tableView.dequeueReusableCell(withIdentifier: "C3MoreCell", for: indexPath) 
			cell.textLabel?.text = user?.humanSummary
			return cell
		}
		
		// Consent
		if 1 == indexPath.section {
			let cell = tableView.dequeueReusableCell(withIdentifier: "C3MoreCell", for: indexPath) 
			cell.textLabel?.text = "Review Consent".sccs_loc
			return cell
		}
		
		// App Settings
		if 2 == indexPath.section {
			let cell = tableView.dequeueReusableCell(withIdentifier: "C3BasicCell", for: indexPath) 
			cell.detailTextLabel?.text = nil
			cell.accessoryType = .none
			if 0 == indexPath.row {
				cell.textLabel?.text = "Change Passcode".sccs_loc
			}
			else if 1 == indexPath.row {
				cell.textLabel?.text = "Reminders".sccs_loc
				cell.detailTextLabel?.text = (UserDefaults.standard.surveyRemindersEnable ? "ON" : "OFF").sccs_loc
				cell.accessoryType = .disclosureIndicator
			}
			else if 2 == indexPath.row {
				cell.textLabel?.text = "Verify App Permissions".sccs_loc
			}
			else if 3 == indexPath.row {
				cell.textLabel?.text = "App Credentials".sccs_loc
				cell.accessoryType = .disclosureIndicator
			}
			return cell
		}
		
		// Legal
		let cell = tableView.dequeueReusableCell(withIdentifier: "C3MoreCell", for: indexPath) 
		if 0 == indexPath.row {
			cell.textLabel?.text = "Privacy Policy".sccs_loc
		}
		else if 1 == indexPath.row {
			cell.textLabel?.text = "Software Licenses".sccs_loc
		}
		return cell
	}
	
	
	// MARK: - Table View Delegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if 0 == indexPath.section {
			showMedicalInfoVC(true)
		}
		else if 1 == indexPath.section {
			showConsent(true)
		}
		else if 2 == indexPath.section {
			if 0 == indexPath.row {
				showChangePasscodeVC()
			}
			else if 1 == indexPath.row {
				showNotificationsVC()
			}
			else if 2 == indexPath.row {
				showPermissionsVC()
			}
			else if 3 == indexPath.row {
				showClientDebugVC()
			}
			tableView.deselectRow(at: indexPath, animated: true)
		}
		else if 3 == indexPath.section {
			if 0 == indexPath.row {
				showPrivacyPolicyVC()
			}
			else if 1 == indexPath.row {
				showLicensesVC()
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	
	// MARK: - Text Field Delegate
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		setEditing(false, animated: true)
		return true
	}
	
	
	// MARK: - User Data & Settings
	
	func showMedicalInfoVC(_ animated: Bool = true) {
		if let info = storyboard?.instantiateViewController(withIdentifier: "C3MedicalInfo") as? MedicalInfoViewController {
			info.profileManager = profileManager
			if let navi = navigationController {
				navi.pushViewController(info, animated: animated)
			}
			else {
				c3_logIfDebug("I need to be in a navigation controller in order to show medical info")
			}
		}
		else {
			c3_logIfDebug("Failed to instantiate C3MedicalInfo view controller")
		}
	}
	
	func showChangePasscodeVC(_ animated: Bool = true) {
		if ORKPasscodeViewController.isPasscodeStoredInKeychain() {
			let vc = ORKPasscodeViewController.passcodeEditingViewController(withText: nil, delegate: self, passcodeType: .type4Digit)
			present(vc, animated: animated, completion: nil)
		}
		// in the event that the passcode disappeared (in case of beta testers)
		else {
			let step = ORKPasscodeStep(identifier: "set-passcode")
			let task = ORKOrderedTask(identifier: passcodeTaskId, steps: [step])
			let vc = ORKTaskViewController(task: task, taskRun: UUID())
			vc.delegate = self
			present(vc, animated: animated, completion: nil)
		}
	}
	
	func showNotificationsVC(_ animated: Bool = true) {
		if let navi = navigationController {
			let vc = NotificationsViewController()
			navi.pushViewController(vc, animated: animated)
		}
		else {
			c3_logIfDebug("I need to be in a navigation controller in order to show reminder settings")
		}
	}
	
	func showPermissionsVC(_ animated: Bool = true) {
		let vc = SystemPermissionTableViewController(style: .plain)
		vc.services = profileManager.systemServicesNeeded
		vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ProfileViewController.dismissPresentedViewController))
		
		let navi = UINavigationController(rootViewController: vc)
		present(navi, animated: animated, completion: nil)
	}
	
	func showClientDebugVC(_ animated: Bool = true) {
		#if DEBUG
		let debug = ClientDebugViewController()
//		debug.smart = profileManager.dataServer
		navigationController?.pushViewController(debug, animated: animated)
		#endif
	}
	
	func showPrivacyPolicyVC(_ animated: Bool = true) {
		let privacy = WebViewController()
		privacy.startURL = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "html")
		navigationController?.pushViewController(privacy, animated: animated)
	}
	
	func showLicensesVC(_ animated: Bool = true) {
		let licenses = LicenseViewController()
		navigationController?.pushViewController(licenses, animated: animated)
	}
	
	func dismissPresentedViewController() {
		dismiss(animated: true, completion: nil)
	}
	
	
	// MARK: - Notifications
	
	func registerForNotifications() {
		let center = NotificationCenter.default
		center.addObserver(self, selector: #selector(ProfileViewController.userDidWithdraw(_:)), name: ProfileManager.userDidWithdrawFromStudyNotification, object: nil)
	}
    
    
    // MARK: - ORKPasscodeDelegate
    
    func passcodeViewControllerDidFinish(withSuccess viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func passcodeViewControllerDidFailAuthentication(_ viewController: UIViewController) {
    }
    
    func passcodeViewControllerDidCancel(_ viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
	}
	
	// MARK: - ORKTaskViewControllerDelegate
	
	func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
		if passcodeTaskId == taskViewController.task?.identifier {
			dismiss(animated: true, completion: nil)
		}
	}
}


// MARK: -

class ProfileMedicalTableViewCell : UITableViewCell {
}

