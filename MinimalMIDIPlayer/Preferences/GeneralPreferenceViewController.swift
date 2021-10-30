//
//  GeneralPreferenceViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 18.11.20.
//  Copyright © 2020 Peter Wunder. All rights reserved.
//

import Foundation

class GeneralPreferenceViewController: NSViewController {

	@IBOutlet weak var autoplayCheckbox: NSButton!
	@IBOutlet weak var cacophonyModeCheckbox: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		self.prepareUIElements()
	}

	func prepareUIElements() {
		self.autoplayCheckbox.state = Settings.shared.autoplay ? .on : .off
		self.cacophonyModeCheckbox.state = Settings.shared.cacophonyMode ? .on : .off
	}

	@IBAction func autoplayCheckboxToggled(_ sender: NSButton) {
		Settings.shared.autoplay = sender.state == .on
	}

	@IBAction func cacophonyCheckboxToggled(_ sender: NSButton) {
		Settings.shared.cacophonyMode = sender.state == .on

		NSDocumentController.shared.closeAllDocuments(withDelegate: nil, didCloseAllSelector: nil, contextInfo: nil)

		if Settings.shared.cacophonyMode {
			NowPlayingCentral.shared.playbackState = .unknown
			NowPlayingCentral.shared.resetNowPlayingInfo()
		}
	}

	@IBAction func resetWarningsAction(_ sender: NSButton) {
		Settings.shared.bounceBetaWarningShown = false
	}

}
