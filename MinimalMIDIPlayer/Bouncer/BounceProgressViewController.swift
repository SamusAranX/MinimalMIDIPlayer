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
	@IBOutlet weak var primaryLabel: NSTextField!
	@IBOutlet weak var secondaryLabel: NSTextField!
	@IBOutlet weak var progressBar: NSProgressIndicator!
	@IBOutlet weak var timeRemainingLabel: NSTextField!

	fileprivate var sourceMIDI: URL?
	fileprivate var sourceSoundfont: URL?

	fileprivate var targetFile: URL?

	fileprivate var bouncer: MIDIFileBouncer?
	fileprivate var bouncerRate: Float = 1.0
	fileprivate var bouncerDuration: TimeInterval = 0

	fileprivate var timeFormatter: DateComponentsFormatter!

	func prepare(sourceMIDIPlayer: PWMIDIPlayer, targetFile: URL) {
		guard self.sourceMIDI == nil, self.targetFile == nil else {
			return
		}

		self.sourceMIDI = sourceMIDIPlayer.currentMIDI!
		self.targetFile = targetFile

		self.sourceSoundfont = sourceMIDIPlayer.currentSoundfont

		self.bouncerRate = sourceMIDIPlayer.rate
		self.bouncerDuration = sourceMIDIPlayer.duration / Double(self.bouncerRate)
	}

	func close(with code: NSApplication.ModalResponse) {
		if NSApp.modalWindow == self.view.window && NSApp.modalWindow?.isVisible ?? false {
			NSApp.stopModal(withCode: code)
			self.view.window?.close()
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		self.timeFormatter = DateComponentsFormatter()
		self.timeFormatter.allowedUnits = [.hour, .minute, .second]
		self.timeFormatter.formattingContext = .beginningOfSentence
		self.timeFormatter.includesApproximationPhrase = true
		self.timeFormatter.includesTimeRemainingPhrase = true
		self.timeFormatter.maximumUnitCount = 2
		self.timeFormatter.unitsStyle = .short
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
		self.bouncer?.rate = self.bouncerRate
		self.bouncer?.delegate = self

		DispatchQueue.global(qos: .userInitiated).async {
			self.bouncer?.bounce(to: targetFile)
		}
	}

	func bounceProgress(progress: Double, currentTime: TimeInterval) {
		DispatchQueue.main.async {
			self.progressBar.doubleValue = progress

			let currentTime = currentTime / Double(self.bouncerRate)
			let timeRemaining = max(0, self.bouncerDuration - currentTime)

			if let timeRemainingString = self.timeFormatter.string(from: timeRemaining) {
				self.timeRemainingLabel.stringValue = timeRemainingString
			} else {
				self.timeRemainingLabel.stringValue = "N/A"
			}
		}
	}

	func bounceCompleted() {
		DispatchQueue.main.async {
			self.close(with: .OK)
		}
	}

	func bounceError(error: Error) {
		DispatchQueue.main.async {
			let errorTitle = NSLocalizedString("An error occurred", comment: "Generic error title string")
			NSAlert.runModal(title: errorTitle, message: error.localizedDescription, style: .critical)
			self.close(with: .abort)
		}
	}

	@IBAction func cancelButtonPressed(_ sender: NSButton) {
		self.bouncer?.cancel()
		self.close(with: .cancel)
	}
}
