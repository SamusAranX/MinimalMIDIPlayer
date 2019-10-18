//
//  BouncePreferenceViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 29.03.19.
//  Copyright © 2019 Peter Wunder. All rights reserved.
//

import Cocoa
import Preferences

class BouncePreferenceViewController: NSViewController, PreferencePane {

	let preferencePaneIdentifier = PreferencePaneIdentifier.bouncing
	let preferencePaneTitle: String = NSLocalizedString("Bouncing", comment: "Preference Tab Title")
	let toolbarItemIcon: NSImage = NSImage(named: "PreferencesWaveform")!

	override var nibName: NSNib.Name? {
		return "BouncePreferenceViewController"
	}

	@IBOutlet weak var sampleRateMenu: NSPopUpButton!
	@IBOutlet weak var channelsMenu: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

		self.sampleRateMenu.selectItem(withTag: Settings.shared.sampleRate)
		self.channelsMenu.selectItem(withTag: Settings.shared.channels)
    }

	@IBAction func sampleRateSelectionChanged(_ sender: NSPopUpButton) {
		guard let selectedItem = sender.selectedItem else {
			Swift.print("Somehow, no item was selected")
			return
		}

		Settings.shared.sampleRate = selectedItem.tag
	}

	@IBAction func channelsSelectionChanged(_ sender: NSPopUpButton) {
		guard let selectedItem = sender.selectedItem else {
			Swift.print("Somehow, no item was selected")
			return
		}

		Settings.shared.channels = selectedItem.tag
	}

}
