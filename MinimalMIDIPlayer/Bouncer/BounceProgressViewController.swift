//
//  BounceProgressViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 29.03.19.
//  Copyright © 2019 Peter Wunder. All rights reserved.
//

import Cocoa

@available(OSX 10.13, *)
class BounceProgressViewController: NSViewController, MIDIFileBouncerDelegate {
	// TODO: do all the bouncing work in here
	// make the actual work happen in a background thread
	// and make it cancellable via the Cancel button

	@IBOutlet weak var primaryLabel: NSTextField!
	@IBOutlet weak var secondaryLabel: NSTextField!
	@IBOutlet weak var progressBar: NSProgressIndicator!

	fileprivate var sourceMIDI: URL?
	fileprivate var sourceSoundfont: URL?

	fileprivate var targetFile: URL?

	fileprivate var bouncer: MIDIFileBouncer?

	func prepare(sourceMIDI: URL, targetFile: URL, sourceSoundfont: URL? = nil) {
		guard self.sourceMIDI == nil, self.targetFile == nil else {
			return
		}

		self.sourceMIDI = sourceMIDI
		self.targetFile = targetFile

		self.sourceSoundfont = sourceSoundfont
	}

	func close() {
		if NSApp.modalWindow == self.view.window && NSApp.modalWindow?.isVisible ?? false {
			NSApp.stopModal(withCode: .cancel)
			self.view.window?.close()
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
	}

	override func viewWillAppear() {
		// prepare everything in viewWillAppear()

		guard let window = self.view.window, let sourceMIDI = self.sourceMIDI, let targetFile = self.targetFile else {
			fatalError("Requirements unfulfilled")
		}

		let primaryFormatString = NSLocalizedString("Bouncing {source.mid} to {target.wav}…", comment: "Primary label with source and target file")
		let secondaryFormatString = NSLocalizedString("Soundfont used: {source.sf2}", comment: "Secondary label, where {source.sf2} is optional")

		primaryLabel.stringValue = String(format: primaryFormatString, sourceMIDI.lastPathComponent, targetFile.lastPathComponent)
		if let sourceSoundfont = self.sourceSoundfont {
			secondaryLabel.stringValue = String(format: secondaryFormatString, sourceSoundfont.lastPathComponent)
		} else {
			secondaryLabel.stringValue = String(format: secondaryFormatString, NSLocalizedString("Default Soundfont", comment: "The translated string for 'Default Soundfont'"))
		}

		window.styleMask.remove(.closable)
		window.styleMask.remove(.miniaturizable)
		window.styleMask.remove(.resizable)
		window.title = self.title ?? "wat"
	}

	override func viewDidAppear() {
		// actually start rendering in viewDidAppear()

		guard let midiFile = self.sourceMIDI,
			  let targetFile = self.targetFile,
			  let bouncer = try? MIDIFileBouncer(midiFile: midiFile, soundfontFile: self.sourceSoundfont) else {
			fatalError("Couldn't initialize bouncer")
		}

		self.bouncer = bouncer
		self.bouncer?.delegate = self

		DispatchQueue.global(qos: .userInitiated).async {
			self.bouncer?.bounce(to: targetFile)
		}
	}

	func bounceProgress(progress: Double) {
		DispatchQueue.main.async {
			self.progressBar.doubleValue = progress
		}
	}

	func bounceCompleted() {
		DispatchQueue.main.async {
			NSAlert.runModal(title: "DONE", message: "Done!", style: .informational)
			self.close()
		}
	}

	func bounceError(error: Error) {
		DispatchQueue.main.async {
			NSAlert.runModal(title: "ERROR", message: error.localizedDescription, style: .critical)
			self.close()
		}
	}

	@IBAction func cancelButtonPressed(_ sender: NSButton) {
		self.bouncer?.cancel()
		self.close()
	}

}
