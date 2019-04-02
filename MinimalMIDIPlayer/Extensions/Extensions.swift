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
		return NSRange(location: 0, length: NSString(string: self).length)
	}

	func hyperlink(with url: URL) -> NSAttributedString {
		let stringRange = self.fullRange()
		let attrString = NSMutableAttributedString(string: self)

		attrString.addAttribute(NSAttributedString.Key.link, value: url, range: stringRange)

		return attrString
	}
}

extension String: LocalizedError {
	public var errorDescription: String? { return self }
}

extension NSMutableAttributedString {
	func setFontFace(font: NSFont, color: NSColor? = nil) {
		beginEditing()
		self.enumerateAttribute(.font, in: self.string.fullRange()) { (value, range, _) in
			if let f = value as? NSFont, let familyName = font.familyName {
				let newFontDescriptor = f.fontDescriptor.withFamily(familyName).withSymbolicTraits(f.fontDescriptor.symbolicTraits).withSize(f.pointSize)
				guard let newFont = NSFont(descriptor: newFontDescriptor, size: font.pointSize) else {
					fatalError("Could not create new font object")
				}
				removeAttribute(.font, range: range)
				addAttribute(.font, value: newFont, range: range)
				if let color = color {
					removeAttribute(.foregroundColor, range: range)
					addAttribute(.foregroundColor, value: color, range: range)
				}
			}
		}
		endEditing()
	}
}

extension Float {
	func rounded(toDecimalPlaces places: Int) -> Float {
		let divisor = pow(10.0, Float(places))
		return (self * divisor).rounded() / divisor
	}
}

extension NSWindow {
	var titlebarHeight: CGFloat {
		let contentHeight = self.contentRect(forFrameRect: self.frame).height
		return self.frame.height - contentHeight
	}
}

extension BinaryInteger {
	private func toBytes() -> [UInt8] {
		let loopNum = self.bitWidth / 8
		var bytes: [UInt8] = []

		for i in 0..<loopNum {
			let value = UInt8(UInt(self >> (i*8)) & 0xff)

			bytes.append(value)
		}

		return bytes.reversed()
	}

	func toASCII() -> String {
		let bytes = self.toBytes()
		var string = ""

		for byte in bytes {
			let us = UnicodeScalar(byte)
			string.append(Character(us))
		}

		return string
	}
}
