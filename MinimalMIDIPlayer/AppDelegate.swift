//
//  AppDelegate.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 30.12.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: MainWindow!

	func applicationDidFinishLaunching(aNotification: NSNotification) {
//		NSNotificationCenter.defaultCenter().addObserver(self, selector: "windowClosed:", name: NSWindowWillCloseNotification, object: window)
	}
	
//	func windowClosed(aNotification: NSNotification) {
//		window.setFrameAutosaveName(window.representedFilename)
//		print("Window closed")
//	}
	
	func application(sender: NSApplication, openFile filename: String) -> Bool {
		Swift.print("openFile: \(filename)")
		
		// Check if OS X think that this file is a MIDI file
		do {
			let fileUTI = try NSWorkspace.sharedWorkspace().typeOfFile(filename)
			if UTTypeConformsTo(fileUTI, kUTTypeMIDIAudio) {
				window.loadFile(filename)
				return true // It is, load the file
			}
		} catch let error as NSError {
			Swift.print("Error checking file: \(error.localizedDescription)")
			return false // There was an error
		}
		
		Swift.print("Not a valid file")
		return false // It's not, abort
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
		return true
	}


}

