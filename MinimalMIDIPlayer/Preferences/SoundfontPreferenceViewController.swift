//
//  GeneralPreferenceViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 18.11.20.
//  Copyright © 2020 Peter Wunder. All rights reserved.
//

import Foundation

class SoundfontPreferenceViewController: NSViewController {

    @IBOutlet weak var approximateSFMatchingCheckbox: NSButton!
    @IBOutlet weak var customSoundfontCheckbox: NSButton!
    @IBOutlet weak var soundfontPathLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.prepareUIElements()
    }

    func prepareUIElements() {
        self.approximateSFMatchingCheckbox.state = Settings.shared.looseSFMatching ? .on : .off
        self.customSoundfontCheckbox.state = Settings.shared.enableCustomSoundfont ? .on : .off

        self.soundfontPathLabel.stringValue = Settings.shared.customSoundfontPath?.lastPathComponent ?? ""
    }

    @IBAction func approximateMatchingCheckboxToggled(_ sender: NSButton) {
        Settings.shared.looseSFMatching = sender.state == .on
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

}
