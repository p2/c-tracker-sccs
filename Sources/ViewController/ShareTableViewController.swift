//
//  ShareTableViewController.swift
//  CTracker
//
//  Created by Pascal Pfiffner on 8/21/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import MessageUI
import Social


enum ShareServiceType {
	case unknown
	case twitter
	case facebook
	case email
	case sms
	
	var localizedName: String {
		switch self {
		case .twitter:
			return "Twitter".sccs_loc
		case .facebook:
			return "Facebook".sccs_loc
		case .email:
			return "Email".sccs_loc
		case .sms:
			return "SMS".sccs_loc
		default:
			return "Unknown".sccs_loc
		}
	}
	
	var shareImage: UIImage? {
		switch self {
		case .twitter:
			return UIImage(named: "share_twitter")?.withRenderingMode(.alwaysTemplate)
		case .facebook:
			return UIImage(named: "share_facebook")?.withRenderingMode(.alwaysTemplate)
		case .email:
			return UIImage(named: "share_email")?.withRenderingMode(.alwaysTemplate)
		case .sms:
			return UIImage(named: "share_sms")?.withRenderingMode(.alwaysTemplate)
		default:
			return nil
		}
	}
}


class ShareService: NSObject, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {
	
	var type = ShareServiceType.unknown
	
	var presentedOnViewController: UIViewController?
	
	var localizedName: String {
		switch type {
		case .twitter:
			return "Share on".sccs_loc + " " + type.localizedName
		case .facebook:
			return "Share on".sccs_loc + " " + type.localizedName
		default:
			return "Share via".sccs_loc + " " + type.localizedName
		}
	}
	
	var localizedSharingMessage: String {
		return "I think you'd like “C Tracker”, a research study app for iPhone:".sccs_loc + " " + cStudyWebsiteURL
	}
	
	init(type: ShareServiceType) {
		self.type = type
	}
	
	
	// MARK: - View Controllers
	
	func createViewController(_ message: String) -> UIViewController? {
		switch type {
		case .twitter:
			let controller = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
			controller?.setInitialText(message)
			return controller
		case .facebook:
			let controller = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
			controller?.setInitialText(message)
			return controller
		case .email:
			if MFMailComposeViewController.canSendMail() {
				let controller = MFMailComposeViewController()
				controller.mailComposeDelegate = self
				controller.setMessageBody(message, isHTML: false)
				return controller
			}
		case .sms:
			if MFMessageComposeViewController.canSendText() {
				let controller = MFMessageComposeViewController()
				controller.messageComposeDelegate = self
				controller.body = message
				return controller
			}
		default:
			return nil
		}
		return nil
	}
	
	func executeFrom(_ viewController: UIViewController, animated: Bool) {
		if let vc = createViewController(localizedSharingMessage) {
			presentedOnViewController = viewController
			viewController.present(vc, animated: animated, completion: nil)
		}
		else {
			let message = "Looks like your device is not set up to share via {{service}}".sccs_loc.replacingOccurrences(of: "{{service}}", with: type.localizedName)
			viewController.show(message: message, title: "No {{service}}".sccs_loc.replacingOccurrences(of: "{{service}}", with: type.localizedName))
		}
	}
	
	
	// MARK: - Sharing Delegates
	
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		presentedOnViewController?.dismiss(animated: true, completion: nil)
	}
	
	func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
		presentedOnViewController?.dismiss(animated: true, completion: nil)
	}
}


class ShareTableViewController: UITableViewController {
	
	var services = [
		ShareService(type: .twitter),
		ShareService(type: .facebook),
		ShareService(type: .email),
		ShareService(type: .sms),
	]
	
	
	// MARK: - View Tasks
	
	override func viewDidLoad() {
		self.title = "Share".sccs_loc
		super.viewDidLoad()
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ShareCell")
		
		// header
		let head = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 140))
		head.backgroundColor = UIColor.clear
		let logo = UIImageView(image: UIImage(named: "logo_disease"))
		logo.translatesAutoresizingMaskIntoConstraints = false
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = UIFont.preferredFont(forTextStyle: .footnote)
		label.textColor = UIColor.gray
		label.textAlignment = .center
		label.numberOfLines = 2
		label.minimumScaleFactor = 0.7
		label.text = "You can help us find study participants by telling others about the study!".sccs_loc
		
		head.addSubview(logo)
		head.addSubview(label)
		let views = ["logo": logo, "label": label]
		head.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(30)-[logo]-(16)-[label]", options: [], metrics: nil, views: views))
		head.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]-|", options: [], metrics: nil, views: views))
		head.addConstraint(NSLayoutConstraint(item: logo, attribute: .centerX, relatedBy: .equal, toItem: head, attribute: .centerX, multiplier: 1.0, constant: 0.0))
		tableView.tableHeaderView = head
		
		// footer
		let foot = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 80))
		foot.backgroundColor = UIColor.clear
		let link = UILabel()
		link.isUserInteractionEnabled = true
		link.translatesAutoresizingMaskIntoConstraints = false
		link.font = UIFont.preferredFont(forTextStyle: .body)
		link.textAlignment = .center
		link.numberOfLines = 1
		link.minimumScaleFactor = 0.5
		let tap = UITapGestureRecognizer(target: self, action: #selector(ShareTableViewController.didTapFooter(_:)))
		link.addGestureRecognizer(tap)
		
		let str = NSMutableAttributedString(string: "Or share this link:".sccs_loc + " ")
		let lnk = NSAttributedString(string: cStudyWebsiteURL, attributes: [NSLinkAttributeName: cStudyWebsiteURL])
		str.append(lnk)
		link.attributedText = str
		
		foot.addSubview(link)
		let links = ["link": link]
		foot.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(12)-[link]", options: [], metrics: nil, views: links))
		foot.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[link]-|", options: [], metrics: nil, views: links))
		tableView.tableFooterView = foot
	}
	
	
	// MARK: - Table View Data Source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return services.count
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 68.0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ShareCell", for: indexPath) 
		if indexPath.row < services.count {
			let service = services[indexPath.row]
			cell.imageView?.image = service.type.shareImage
			cell.textLabel?.text = service.localizedName
		}
		return cell
	}
	
	
	// MARK: - Table View Delegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row < services.count {
			services[indexPath.row].executeFrom(self, animated: true)
		}
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	
	// MARK: - Tap Gesture Recognizer
	
	func didTapFooter(_ recognizer: UITapGestureRecognizer) {
		switch recognizer.state {
		case .ended:
			shareLink(true)
		default:
			break
		}
	}
	
	func shareLink(_ animated: Bool) {
		let action = UIAlertController(title: "Share".sccs_loc, message: nil, preferredStyle: .actionSheet)
		action.addAction(UIAlertAction(title: "Cancel".sccs_loc, style: .cancel, handler: nil))
		action.addAction(UIAlertAction(title: "Open Website".sccs_loc, style: .default, handler: { action in
			if let url = URL(string: cStudyWebsiteURL) {
				UIApplication.shared.openURL(url)
			}
			else {
				self.dismiss(animated: true) {
					self.show(message: "Failed to open \(cStudyWebsiteURL)", title: "Error".sccs_loc)
				}
			}
		}))
		action.addAction(UIAlertAction(title: "Copy Link".sccs_loc, style: .default, handler: { action in
			UIPasteboard.general.url = URL(string: cStudyWebsiteURL)
		}))
		present(action, animated: animated, completion: nil)
	}
}

