//
//  GeneralPreferenceViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 18.11.20.
//  Copyright © 2020 Peter Wunder. All rights reserved.
//

import Foundation

class UpdatePreferenceViewController: NSViewController {

    @IBOutlet weak var autoUpdateCheckbox: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.prepareUIElements()
    }

    func prepareUIElements() {
        self.autoUpdateCheckbox.state = Settings.shared.automaticUpdates ? .on : .off
    }

    @IBAction func autoUpdateCheckboxToggled(_ sender: NSButton) {
        Settings.shared.automaticUpdates = sender.state == .on

        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.updater.updater?.automaticallyChecksForUpdates = Settings.shared.automaticUpdates
        }
    }

}
