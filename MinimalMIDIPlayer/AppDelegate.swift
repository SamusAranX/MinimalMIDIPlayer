//
//  AppDelegate.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 30.12.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var updaterController: SPUStandardUpdaterController!

	@IBOutlet weak var loopMenuItem: NSMenuItem!

	func applicationDidFinishLaunching(_ notification: Notification) {
		self.updaterController.updater.automaticallyChecksForUpdates = Settings.shared.automaticUpdates
	}

}
