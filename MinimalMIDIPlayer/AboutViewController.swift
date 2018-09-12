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
	@IBOutlet weak var buildLabel: NSTextField!
	@IBOutlet weak var copyrightLabel: NSTextField!
	@IBOutlet weak var aboutTextLabel: HyperlinkTextField!
	
	@IBOutlet weak var githubLabel: HyperlinkTextField!
	@IBOutlet weak var bugsLabel: HyperlinkTextField!
	@IBOutlet weak var twitterLabel: HyperlinkTextField!
	
	let hyperlinksInText: [String: URL] = [:]
	
	let hyperlinksForLabels = [
		URL(string: "https://github.com/SamusAranX/MinimalMIDIPlayer")!,
		URL(string: "https://github.com/SamusAranX/MinimalMIDIPlayer/issues")!,
		URL(string: "https://twitter.com/SamusAranX")!
	]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Fill in the version number
		if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
			let buildNum = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
			
			var versionString = "v\(version)"
			let startIndex = versionString.endIndex
			versionString += buildNum
			let endIndex = versionString.endIndex
			
			let range = startIndex..<endIndex
			let nsRange = NSRange(range, in: versionString)
			
			let versionAttrString = NSMutableAttributedString(string: versionString)
			versionAttrString.addAttributes([
				NSAttributedString.Key.superscript : NSNumber(booleanLiteral: true)
			], range: nsRange)
			versionLabel.attributedStringValue = versionAttrString
		}
		
		if let regex = try? NSRegularExpression(pattern: "(\\d{4})−(\\d{4}) (.*?)\\.", options: []),
		   let copyrightString = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String{
			
			let matches = regex.matches(in: copyrightString, options: [], range: copyrightString.fullRange())
			let matchStrings: [String] = (1..<matches.first!.numberOfRanges).map {
				return String(copyrightString[Range(matches.first!.range(at: $0), in: copyrightString)!])
			}
			
			copyrightLabel.stringValue = "A project by \(matchStrings[2]), \(matchStrings[0]) – \(matchStrings[1])"
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
		
		// Configure hyperlinks in smaller labels
		let githubAttrString = githubLabel.stringValue.hyperlink(with: hyperlinksForLabels[0])
		githubLabel.attributedStringValue = githubAttrString
		
		let bugsAttrString = bugsLabel.stringValue.hyperlink(with: hyperlinksForLabels[1])
		bugsLabel.attributedStringValue = bugsAttrString
		
		let twitterAttrString = twitterLabel.stringValue.hyperlink(with: hyperlinksForLabels[2])
		twitterLabel.attributedStringValue = twitterAttrString
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		
		if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
			self.view.window?.title = "About \(appName)"
		}
	}
	
}
