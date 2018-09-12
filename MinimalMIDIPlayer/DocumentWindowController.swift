//
//  MainWindowController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 05.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa

protocol WindowControllerDelegate {
	func keyDown(with event: NSEvent)
}

class DocumentWindowController: NSWindowController {
	
	var delegate: WindowControllerDelegate?
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		self.shouldCascadeWindows = true
		self.shouldCloseDocument = true
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		if let documentViewController = self.window?.contentViewController as? DocumentViewController {
			self.delegate = documentViewController
			
			if #available(OSX 10.14, *) {
				// Since Interface Builder doesn't "know" Dark Aqua yet with the 10.13 SDK, this has to be done in code
				Swift.print("Dark Aqua")
				self.window!.appearance = NSAppearance(named: NSAppearance.Name.darkAqua)
			} else {
				// Pseudo-"dark mode" on 10.13
				Swift.print("Vibrant Dark")
				self.window!.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
			}
		}
	}
	
	override func keyDown(with event: NSEvent) {
		super.keyDown(with: event)
		
		self.delegate?.keyDown(with: event)
	}
	
	
}
