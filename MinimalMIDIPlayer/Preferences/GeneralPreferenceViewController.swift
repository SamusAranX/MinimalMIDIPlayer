//
//  GeneralPreferenceViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 12.03.19.
//  Copyright © 2019 Peter Wunder. All rights reserved.
//

import Cocoa
import Preferences

class GeneralPreferenceViewController: NSViewController, Preferenceable {

	let toolbarItemTitle: String = "General"
	let toolbarItemIcon: NSImage = NSImage(named: "PreferencesMIDI")!
	
	override var nibName: NSNib.Name? {
		return "GeneralPreferenceViewController"
	}
	
	@IBOutlet weak var autoplayCheckbox: NSButton!
	@IBOutlet weak var looseSFMatchingCheckbox: NSButton!
	@IBOutlet weak var cacophonyModeCheckbox: NSButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.autoplayCheckbox.state = Settings.shared.autoplay ? .on : .off
		self.looseSFMatchingCheckbox.state = Settings.shared.looseSFMatching ? .on : .off
		self.cacophonyModeCheckbox.state = Settings.shared.cacophonyMode ? .on : .off
    }
    
	@IBAction func autoplayCheckboxToggled(_ sender: NSButton) {
		Settings.shared.autoplay = sender.state == .on
	}
	
	@IBAction func soundfontCheckboxToggled(_ sender: NSButton) {
		Settings.shared.looseSFMatching = sender.state == .on
	}
	
	@IBAction func cacophonyCheckboxToggled(_ sender: NSButton) {
		Settings.shared.cacophonyMode = sender.state == .on
		
		NSDocumentController.shared.closeAllDocuments(withDelegate: nil, didCloseAllSelector: nil, contextInfo: nil)
		
		if #available(OSX 10.12.2, *), Settings.shared.cacophonyMode {
			NowPlayingCentral.shared.playbackState = .unknown
			NowPlayingCentral.shared.resetNowPlayingInfo()
		}
	}
	
}
