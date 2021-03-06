//
//  MIDIDocument.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 05.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa
import AVFoundation

class MIDIFilePresenter: NSObject, NSFilePresenter {
	private var midiPath: URL!
	private var soundfontPath: URL?

	convenience init(path: URL, sfPath: URL?) {
		self.init()

		self.midiPath = path
		self.soundfontPath = sfPath
	}

	var files: [URL] {
		var temp: [URL] = [self.midiPath]
		if let sfURL = self.presentedItemURL {
			temp.append(sfURL)
		}
		return temp
	}

	var primaryPresentedItemURL: URL? {
		return self.midiPath
	}

	var presentedItemURL: URL? {
		return self.soundfontPath
	}

	var presentedItemOperationQueue: OperationQueue {
		return OperationQueue.main
	}
}

class MIDIDocument: NSDocument {

	var midiPresenter: MIDIFilePresenter!

	private var midiPath: URL!
	private var soundfontPath: URL?

	var viewController: DocumentViewController? {
		return self.windowControllers[0].contentViewController as? DocumentViewController
	}

	override var isInViewingMode: Bool {
		return true
	}

	override var keepBackupFile: Bool {
		return false
	}

	override func makeWindowControllers() {
		let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
		guard let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("DocumentWindowController")) as? DocumentWindowController else {
			fatalError("Couldn't instantiate window controller")
		}
		self.addWindowController(windowController)

		if let documentURL = self.midiPath {
			(windowController.contentViewController as? DocumentViewController)?.openFile(midiURL: documentURL)
		}
	}

	// MARK: - NSDocument

	override func read(from url: URL, ofType typeName: String) throws {
		// this will throw if the MIDI isn't valid, aborting the document opening process
		_ = try AVMIDIPlayer(contentsOf: url, soundBankURL: nil)

		self.midiPath = url
		self.soundfontPath = PWMIDIPlayer.guessSoundfontPath(forMIDI: url)

		self.midiPresenter = MIDIFilePresenter(path: url, sfPath: self.soundfontPath)
		NSFileCoordinator.addFilePresenter(self.midiPresenter)
	}

	override func close() {
		NSFileCoordinator.removeFilePresenter(self.midiPresenter)
		super.close()
	}
}
