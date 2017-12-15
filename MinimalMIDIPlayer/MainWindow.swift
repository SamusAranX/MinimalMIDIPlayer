//
//  MainWindow.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 30.12.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa
import AVFoundation

class MainWindow: NSWindow {
	
	@IBOutlet weak var playPauseButton: NSButton!
	@IBOutlet weak var stopButton: NSButton!
	
	@IBOutlet weak var midiFileLabel: NSTextField!
	@IBOutlet weak var soundfontFileLabel: NSTextField!
	
	@IBOutlet weak var progressTimeLabel: NSTextField!
	@IBOutlet weak var durationTimeLabel: NSTextField!
	@IBOutlet weak var progressTimeBar: NSProgressIndicator!
	
	@IBOutlet weak var speedSlider: NSSlider!
	@IBOutlet weak var speedLabel: NSTextField!
	
	var midiPlayer: AVMIDIPlayer?
	var progressTimer: Timer?
	var dateComponentsFormatter: DateComponentsFormatter?
	
	var currentMidiFile: URL? {
		didSet {
			self.midiFileLabel.stringValue = currentMidiFile?.lastPathComponent ?? ""
		}
	}
	var currentSoundFontFile: URL? {
		didSet {
			self.soundfontFileLabel.stringValue = currentSoundFontFile?.lastPathComponent ?? ""
		}
	}
	
	let speedValues = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
	var playbackSpeed: Float {
		let currentSliderPos = self.speedSlider.integerValue
		let speedValue = self.speedValues[currentSliderPos]
		
		return Float(speedValue)
	}
	var playbackSpeedString: String {
		return String(format: "%.2f", self.playbackSpeed)
	}
	
	func loadFiles(_ filename: String) -> (midi: URL, sf: URL?) {
		Swift.print("loadFile: \(filename)")
		
		if self.dateComponentsFormatter == nil {
			self.dateComponentsFormatter = DateComponentsFormatter()
			self.dateComponentsFormatter!.allowedUnits = [.minute, .second]
			self.dateComponentsFormatter!.unitsStyle = .positional
			self.dateComponentsFormatter!.zeroFormattingBehavior = .pad
		}
		
		let midiURL = URL(fileURLWithPath: filename)
		
		let fileDirectory = midiURL.deletingLastPathComponent()
		let nameWithoutExt = NSString(string: midiURL.lastPathComponent).deletingPathExtension.removingPercentEncoding
		
		// Super cheap way of checking for accompanying soundfonts incoming
		let potentialSoundFonts = [
			// Soundfonts with same name as the MIDI file
			"\(fileDirectory.path)/\(nameWithoutExt!).sf2",
			"\(fileDirectory.path)/\(nameWithoutExt!).dls",
			
			// Soundfonts with same name as containing folder
			"\(fileDirectory.path)/\(fileDirectory.lastPathComponent).sf2",
			"\(fileDirectory.path)/\(fileDirectory.lastPathComponent).dls"
		]
		
		let fileManager = FileManager.default
		var soundFontURL: URL? = nil
		for psf in potentialSoundFonts {
			if fileManager.fileExists(atPath: psf) {
				soundFontURL = URL(fileURLWithPath: psf)
				break
			}
		}
		
		return (midiURL, soundFontURL)
	}
	
	func playFiles(midiFile: URL, soundFontFile: URL? = nil) {
		do {
			self.midiPlayer = try AVMIDIPlayer(contentsOf: midiFile, soundBankURL: soundFontFile)
			
			guard self.midiPlayer != nil else {
				Swift.print("midiPlayer is somehow still nil")
				return
			}
			
			self.currentMidiFile = midiFile
			self.currentSoundFontFile = soundFontFile
			
			self.midiPlayer!.rate = self.playbackSpeed
			
			self.midiPlayer!.prepareToPlay()
			self.midiPlayer!.play(playbackCompleted)
			self.playPauseButton.state = .on
			self.playPauseButton.isEnabled = true
			self.stopButton.isEnabled = true
			
			self.startTimer()
		} catch let error as NSError {
			let alert = NSAlert()
			alert.addButton(withTitle: "OK")
			alert.alertStyle = .critical
			alert.messageText = "Error opening file"
			alert.informativeText = error.localizedDescription
			alert.runModal()
		}
	}
	
	func startTimer() {
		self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: playbackProgress)
	}
	
	func stopTimer() {
		self.progressTimer?.invalidate()
		self.progressTimer = nil
	}
	
	func playbackProgress(_ sender: Timer) {
		guard self.midiPlayer != nil else {
			Swift.print("midiPlayer is nil")
			self.stopTimer()
			return
		}
		
		let progress = self.midiPlayer!.currentPosition / self.midiPlayer!.duration
		self.progressTimeBar.doubleValue = progress * 100
		
		self.progressTimeLabel.stringValue = self.dateComponentsFormatter!.string(from: self.midiPlayer!.currentPosition)!
		self.durationTimeLabel.stringValue = self.dateComponentsFormatter!.string(from: self.midiPlayer!.duration)!
	}
	
	func playbackCompleted() {
		Swift.print("Playback completed")
		
		self.stopTimer()
		
		if self.midiPlayer!.currentPosition >= self.midiPlayer!.duration - 0.1 {
			self.midiPlayer!.currentPosition = 0
			DispatchQueue.main.async {
				self.progressTimeBar.doubleValue = 100 // completely fill progress bar
			}
			Swift.print("Pretty sure the file just ended. Resetting playhead to the beginning")
		}
		
		DispatchQueue.main.async {
			self.playPauseButton.state = .off
		}
	}
	
	@IBAction func openDocument(_ sender: AnyObject?) {
		let panel = NSOpenPanel()
		panel.allowedFileTypes = [ kUTTypeMIDIAudio as String ]
		panel.allowsMultipleSelection = false
		if panel.runModal() == NSApplication.ModalResponse.OK {
            let files = self.loadFiles(panel.url!.path)
			self.playFiles(midiFile: files.midi, soundFontFile: files.sf)
		}
	}

	@IBAction func playPauseButtonPressed(_ sender: NSButton) {
		// State off: "Play"
		// State on: "Pause"
		
		guard self.midiPlayer != nil else {
			Swift.print("midiPlayer is nil")
			sender.state = .off
			return
		}

		if self.midiPlayer!.isPlaying {
//			self.pausePosition = self.midiPlayer!.currentPosition
			
			self.midiPlayer!.stop()
			self.playPauseButton.state = NSControl.StateValue.off
			return
		} else {
			self.midiPlayer!.prepareToPlay()
			self.midiPlayer!.play(playbackCompleted)
			self.startTimer()
		}
	}
	
	@IBAction func stopButtonPressed(_ sender: NSButton) {
		guard self.midiPlayer != nil else {
			Swift.print("midiPlayer is nil")
			self.playPauseButton.state = .off
			return
		}
		
		self.midiPlayer!.stop()
		self.midiPlayer!.currentPosition = 0
	}
	
	@IBAction func speedSliderMoved(_ sender: NSSlider) {
		self.midiPlayer?.rate = self.playbackSpeed
		self.speedLabel.stringValue = self.playbackSpeedString
	}
	
}
