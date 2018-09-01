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

	func applicationDidFinishLaunching(_ notification: Notification) {
		Swift.print("applicationDidFinishLaunching")
        Swift.print(kUTTypeMIDIAudio)
        
        self.window!.windowOpened()
//		NSNotificationCenter.defaultCenter().addObserver(self, selector: "windowClosed:", name: NSWindowWillCloseNotification, object: window)
	}
	
//	func windowClosed(aNotification: NSNotification) {
//		window.setFrameAutosaveName(window.representedFilename)
//		print("Window closed")
//	}
	
	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		Swift.print("openFile: \(filename)")
		
		let alert = NSAlert()
		alert.addButton(withTitle: "OK")
        
		alert.alertStyle = .critical
		
		// Check if macOS thinks that this file is a MIDI file
		do {
			let fileUTI = try NSWorkspace.shared.type(ofFile: filename)
			
			if UTTypeConformsTo(fileUTI as CFString, kUTTypeMIDIAudio) {
                let midiFile = URL(fileURLWithPath: filename)
				window.openFile(midiFile: midiFile)
				return true // It is, load and play the files
			}
		} catch let error as NSError {
			alert.messageText = "Error checking file"
			alert.informativeText = error.localizedDescription
			alert.runModal()
			return false // There was an error
		}
		
		alert.messageText = "Error checking file"
		alert.informativeText = "This is not a valid MIDI file."
		alert.runModal()
		
		return false // It's not, abort
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }


}

