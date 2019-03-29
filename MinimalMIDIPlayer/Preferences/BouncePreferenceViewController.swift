//
//  BouncePreferenceViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 29.03.19.
//  Copyright © 2019 Peter Wunder. All rights reserved.
//

import Cocoa
import Preferences

class BouncePreferenceViewController: NSViewController, Preferenceable {

	let toolbarItemTitle: String = NSLocalizedString("Bounce", comment: "Preference Tab Title")
	let toolbarItemIcon: NSImage = NSImage(named: "PreferencesWaveform")!

	override var nibName: NSNib.Name? {
		return "BouncePreferenceViewController"
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

}
