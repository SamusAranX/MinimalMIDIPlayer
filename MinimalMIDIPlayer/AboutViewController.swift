//
//  AboutViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 06.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController {

	@IBOutlet weak var appNameLabel: NSTextField!
	@IBOutlet weak var versionLabel: NSTextField!
	@IBOutlet weak var copyrightLabel: NSTextField!
	@IBOutlet weak var appIconView: NSImageView!

	@IBOutlet weak var aboutTextLabel: HyperlinkTextField!

	@IBOutlet weak var githubLabel: HyperlinkTextField!
	@IBOutlet weak var bugsLabel: HyperlinkTextField!
	@IBOutlet weak var twitterLabel: HyperlinkTextField!

	@IBOutlet weak var disclosureTriangleButton: NSButton!

	@IBOutlet var acknowledgementTextView: NSTextView!

	let hyperlinksInText: [String: URL] = [:]

	let hyperlinksForLabels = [
		URL(string: "https://github.com/SamusAranX/MinimalMIDIPlayer")!,
		URL(string: "https://github.com/SamusAranX/MinimalMIDIPlayer/issues")!,
		URL(string: "https://twitter.com/SamusAranX")!
	]

	override func viewDidLoad() {
		super.viewDidLoad()

		// Fill in the app name
		if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
			appNameLabel.stringValue = appName
		}

		// Fill in the version number
		if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
			let buildNum = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
			let versionString = NSLocalizedString("VersionString", comment: "Format string for the version subtitle")
			versionLabel.stringValue = String(format: versionString, version, buildNum)
		}

		// Fill in the copyright label below the app name label
		if let regex = try? NSRegularExpression(pattern: "(\\d{4})−(\\d{4}) (.*?)\\.", options: []),
		   let copyrightString = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String {

			let matches = regex.matches(in: copyrightString, options: [], range: copyrightString.fullRange())
			let matchStrings: [String] = (1..<matches.first!.numberOfRanges).map {
				return String(copyrightString[Range(matches.first!.range(at: $0), in: copyrightString)!])
			}

			let copyrightOwner = matchStrings[2]
			let copyrightYear1 = matchStrings[0]
			let copyrightYear2 = matchStrings[1]

			let copyrightFormatString = NSLocalizedString("AProjectBy", comment: "A project by %@, %@ – %@")
			let copyrightString = String(format: copyrightFormatString, copyrightOwner, copyrightYear1, copyrightYear2)

			copyrightLabel.stringValue = copyrightString
		}

		// Select Beta icon if this is a Beta build
		if let identifier = Bundle.main.bundleIdentifier, identifier.hasSuffix(".beta") {
			appIconView.image = NSImage(named: "AboutIconBeta")
		}

		// Configure hyperlinks in multi-line label
		if !hyperlinksInText.isEmpty {
			let aboutString = NSString(string: aboutTextLabel.stringValue)
			let aboutAttrString = NSMutableAttributedString(string: aboutTextLabel.stringValue)
			for hyperlink in hyperlinksInText {
				let range = aboutString.range(of: hyperlink.key)
				aboutAttrString.addAttribute(NSAttributedString.Key.link, value: hyperlink.value, range: range)
			}
			aboutTextLabel.attributedStringValue = aboutAttrString
		}

		guard let ackFilePath = Bundle.main.path(forResource: "Acknowledgements", ofType: "rtf") else {
			fatalError("Couldn't read acknowledgements file")
		}

		do {
			let ackAttrStr = try NSMutableAttributedString(url: URL(fileURLWithPath: ackFilePath), options: [:], documentAttributes: nil)
			ackAttrStr.setFontFace(font: aboutTextLabel.font!, color: NSColor.controlTextColor)
			acknowledgementTextView.textStorage?.setAttributedString(ackAttrStr)
		} catch {
			fatalError("Couldn't apply font to acknowledgements file")
		}

		// Configure hyperlinks in smaller labels
		let githubAttrString = githubLabel.stringValue.hyperlink(with: hyperlinksForLabels[0])
		githubLabel.attributedStringValue = githubAttrString

		let bugsAttrString = bugsLabel.stringValue.hyperlink(with: hyperlinksForLabels[1])
		bugsLabel.attributedStringValue = bugsAttrString

		let twitterAttrString = twitterLabel.stringValue.hyperlink(with: hyperlinksForLabels[2])
		twitterLabel.attributedStringValue = twitterAttrString
	}

	override func viewWillAppear() {
		super.viewWillAppear()
	}

	@IBAction func disclosureTriangleToggled(_ sender: NSButton) {
		guard let window = self.view.window else {
			print("Couldn't get window")
			return
		}

		let willExpand = sender.state == .on
		let newHeight: CGFloat = (willExpand ? 383 : 263) + window.titlebarHeight
		var newFrame = window.frame

		if willExpand {
			newFrame.origin.y -= abs(newFrame.height - newHeight)
		} else {
			newFrame.origin.y += abs(newFrame.height - newHeight)
		}

		newFrame.size.height = newHeight

		NSAnimationContext.beginGrouping()

		NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
		NSAnimationContext.current.duration = 0.2
		NSAnimationContext.current.allowsImplicitAnimation = true

		window.animator().setFrame(newFrame, display: false)

		NSAnimationContext.endGrouping()
	}

	@IBAction func disclosureHelperPressed(_ sender: NSButton) {
		self.disclosureTriangleButton.performClick(sender)
	}

}
