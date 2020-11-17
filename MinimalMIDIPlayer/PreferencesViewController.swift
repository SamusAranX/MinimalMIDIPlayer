//
//  PreferencesViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 03.04.20.
//  Copyright © 2020 Peter Wunder. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

	@IBOutlet weak var autoplayCheckbox: NSButton!
	@IBOutlet weak var looseSFMatchingCheckbox: NSButton!
	@IBOutlet weak var cacophonyModeCheckbox: NSButton!
	@IBOutlet weak var customSoundfontCheckbox: NSButton!
	@IBOutlet weak var soundfontSelectionButton: NSButton!
	@IBOutlet weak var soundfontPathLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

		self.prepareUIElements()
	}

	func prepareUIElements() {
		self.autoplayCheckbox.state = Settings.shared.autoplay ? .on : .off
		self.looseSFMatchingCheckbox.state = Settings.shared.looseSFMatching ? .on : .off
		self.cacophonyModeCheckbox.state = Settings.shared.cacophonyMode ? .on : .off
		self.customSoundfontCheckbox.state = Settings.shared.enableCustomSoundfont ? .on : .off

		self.soundfontPathLabel.stringValue = Settings.shared.customSoundfontPath?.lastPathComponent ?? ""
	}

	@IBAction func autoplayCheckboxToggled(_ sender: NSButton) {
		Settings.shared.autoplay = sender.state == .on
	}

	@IBAction func looseMatchingCheckboxToggled(_ sender: NSButton) {
		Settings.shared.looseSFMatching = sender.state == .on
	}

	@IBAction func cacophonyCheckboxToggled(_ sender: NSButton) {
		Settings.shared.cacophonyMode = sender.state == .on

		NSDocumentController.shared.closeAllDocuments(withDelegate: nil, didCloseAllSelector: nil, contextInfo: nil)

		if Settings.shared.cacophonyMode {
			NowPlayingCentral.shared.playbackState = .unknown
			NowPlayingCentral.shared.resetNowPlayingInfo()
		}
	}

	@IBAction func soundfontCheckboxToggled(_ sender: NSButton) {
		Settings.shared.enableCustomSoundfont = sender.state == .on
	}

	@IBAction func chooseSoundfontAction(_ sender: NSButton) {
		let panel = NSOpenPanel()
		panel.allowedFileTypes = [ "sf2", "dls" ]
		panel.allowsMultipleSelection = false
		if panel.runModal() == NSApplication.ModalResponse.OK {
			let selectedFileURL = URL(fileURLWithPath: panel.url!.path)
			Settings.shared.customSoundfontPath = selectedFileURL
			self.soundfontPathLabel.stringValue = selectedFileURL.lastPathComponent
		}
	}
    
    @IBAction func resetWarningsAction(_ sender: NSButton) {
        Settings.shared.bounceBetaWarningShown = false
    }
    
}
