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
		viewControllers: [
			GeneralPreferenceViewController(),
			BouncePreferenceViewController()
		]
	)

	func applicationDidFinishLaunching(_ notification: Notification) {
		NSUserNotificationCenter.default.delegate = self
	}

	@IBAction func closeAllWindows(_ sender: NSMenuItem) {
		NSDocumentController.shared.closeAllDocuments(withDelegate: nil, didCloseAllSelector: nil, contextInfo: nil)
	}

	@IBAction func showPreferencesWindow(_ sender: NSMenuItem) {
		preferencesWindowController.showWindow()
	}

	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}

}
