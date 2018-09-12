//
//  MIDIDocument.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 05.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa
import AVFoundation

enum MIDIDocumentError: Error {
	case noAutosavesAllowed
}

class MIDIDocument: NSDocument {
	
	var viewController: DocumentViewController? {
		return self.windowControllers[0].contentViewController as? DocumentViewController
	}
	
	override var isInViewingMode: Bool {
		return true
	}
	
	override var keepBackupFile: Bool {
		return false
	}
	
	override init() {
		Swift.print("init")
	}
	
	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("DocumentWindowController")) as! DocumentWindowController
		self.addWindowController(windowController)
		
		if let documentURL = self.fileURL {
			(windowController.contentViewController as? DocumentViewController)?.openFile(midiURL: documentURL)
		}
	}
	
	override func read(from url: URL, ofType typeName: String) throws {
		// this will throw if the MIDI isn't valid, aborting the document opening process
		// good thing AVMIDIPlayer is so lightweight or having to do this would really suck
		let _ = try AVMIDIPlayer(contentsOf: url, soundBankURL: nil)
	}
}
