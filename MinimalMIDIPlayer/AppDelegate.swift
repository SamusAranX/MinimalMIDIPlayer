//
//  AppDelegate.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 30.12.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa
import Preferences

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

	let preferencesWindowController = PreferencesWindowController(
		preferencePanes: [
			GeneralPreferenceViewController(),
			BouncePreferenceViewController()
		], style: .segmentedControl, animated: true
	)

	func applicationDidFinishLaunching(_ notification: Notification) {
		NSUserNotificationCenter.default.delegate = self
	}

	@IBAction func closeAllWindows(_ sender: NSMenuItem) {
		NSDocumentController.shared.closeAllDocuments(withDelegate: nil, didCloseAllSelector: nil, contextInfo: nil)
	}

	@IBAction func showPreferencesWindow(_ sender: NSMenuItem) {
		print("Showing Preferences")
		preferencesWindowController.show(preferencePane: .general)
	}

	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}

}
