//
//  SettingsViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 07.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController {

	@IBOutlet weak var autoplayCheckbox: NSButton!
	@IBOutlet weak var cacophonyModeCheckbox: NSButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.autoplayCheckbox.state = Settings.shared.autoplay ? .on : .off
		self.cacophonyModeCheckbox.state = Settings.shared.cacophonyMode ? .on : .off
        // Do view setup here.
    }
    
	@IBAction func autoplayCheckboxToggled(_ sender: NSButton) {
		Settings.shared.autoplay = sender.state == .on
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
