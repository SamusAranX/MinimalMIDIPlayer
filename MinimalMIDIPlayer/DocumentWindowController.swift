//
//  MainWindowController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 05.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa

protocol WindowControllerDelegate: AnyObject {
	func keyDownEvent(with event: NSEvent)
	func windowWillClose(_ notification: Notification)
}

class DocumentWindowController: NSWindowController, NSWindowDelegate {

	weak var delegate: WindowControllerDelegate?

	required init?(coder: NSCoder) {
		super.init(coder: coder)

		self.shouldCascadeWindows = true
		self.shouldCloseDocument = true
	}

	override func windowDidLoad() {
		super.windowDidLoad()

		guard let documentViewController = self.window?.contentViewController as? DocumentViewController else {
			fatalError("Couldn't access DocumentViewController instance")
		}

		self.delegate = documentViewController
	}

	func windowDidBecomeMain(_ notification: Notification) {
		guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
			fatalError("Couldn't access AppDelegate")
		}

		guard let documentViewController = self.window?.contentViewController as? DocumentViewController else {
			fatalError("Couldn't access DocumentViewController instance")
		}

		print("Loop menu item updated: \(documentViewController.playbackLoop)")
		appDelegate.loopMenuItem.state = documentViewController.playbackLoop ? .on : .off
	}

	func windowWillClose(_ notification: Notification) {
		self.delegate?.windowWillClose(notification)
	}

	// Key codes: Space, Arrow keys
	let forwardedKeyCodes: [UInt16] = [0x31, 0x7B, 0x7C, 0x7D, 0x7E]
	override func keyDown(with event: NSEvent) {
		if !forwardedKeyCodes.contains(event.keyCode) {
			super.keyDown(with: event)
		}

		self.delegate?.keyDownEvent(with: event)
	}
}
