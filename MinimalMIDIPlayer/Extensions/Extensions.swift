//
//  Extensions.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 06.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa

extension NSAlert {
	
	class func runModal(title: String, message: String, style: NSAlert.Style) {
		let alert = NSAlert()
		alert.addButton(withTitle: "OK")
		alert.messageText = title
		alert.informativeText = message
		alert.alertStyle = style
		alert.runModal()
	}
	
}

extension String {
	func fullRange() -> NSRange {
		return NSMakeRange(0, NSString(string: self).length)
	}
	
	func hyperlink(with url: URL) -> NSAttributedString {
		let stringRange = self.fullRange()
		let attrString = NSMutableAttributedString(string: self)
		
		attrString.addAttribute(NSAttributedString.Key.link, value: url, range: stringRange)
		
		return attrString
	}
}

extension NSViewController {
	static func load<T>(from bundle: Bundle? = nil) -> T where T: NSViewController {
		return T(nibName: T.className(), bundle: bundle)
	}
}
