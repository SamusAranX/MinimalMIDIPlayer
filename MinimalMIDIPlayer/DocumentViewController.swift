//
//  MainViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 05.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa

class DocumentViewController: NSViewController, WindowControllerDelegate, PWMIDIPlayerDelegate {
	@IBOutlet weak var backgroundFXView: NSVisualEffectView!
	
	@IBOutlet weak var rewindButton: NSButton!
	@IBOutlet weak var playPauseButton: NSButton!
	@IBOutlet weak var fastForwardButton: NSButton!
	@IBOutlet weak var cacophonyIconView: NSView!
	
	@IBOutlet weak var soundfontMenu: NSPopUpButton!
	@IBOutlet weak var fauxSoundfontMenu: NSTextField!
	@IBOutlet weak var overrideSFCheckbox: NSButton!
	
	@IBOutlet weak var progressTimeLabel: NSTextField!
	@IBOutlet weak var durationTimeLabel: NSTextField!
	@IBOutlet weak var progressTimeSlider: NSSlider!
	
	@IBOutlet weak var speedSlider: NSSlider!
	@IBOutlet weak var speedLabel: NSTextField!
	
	var midiPlayer: PWMIDIPlayer?
	
	var dcFormatter: DateComponentsFormatter!
	var durationCountDown = false
	
	let USERDEFAULTS_SOUNDFONTS_KEY = "recentSoundfonts"
	var recentSoundfonts: [URL] = []
	var guessedSoundfont: URL?
	var activeSoundfont: URL?
	
	let SOUNDFONTS_RECENT_START = 3
	
	let speedValues: [Float] = [0.25, 1/3, 0.5, 2/3, 0.75, 0.8, 0.9, 1.0, 1.1, 1.2, 1.25, 4/3, 1.5, 5/3, 2.0]
	var playbackSpeed: Float = 1.0
	
	var pausedDueToDraggingKnob: Bool = false
	var shiftPressed: Bool = false
	
	enum SoundfontMenuType: Int {
		case macdefault = 0
		case recent = 1
		case custom = 2
		case unknown = 1000
	}
	
	// MARK: - Initialization
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// initialize the formatter used for the duration labels
		self.dcFormatter = DateComponentsFormatter()
		self.dcFormatter.allowedUnits = [.minute, .second]
		self.dcFormatter.unitsStyle = .positional
		self.dcFormatter.zeroFormattingBehavior = .pad
		self.dcFormatter.formattingContext = .standalone
		
		// load recently used soundfonts
		if let storedRecentSFArr = UserDefaults.standard.array(forKey: USERDEFAULTS_SOUNDFONTS_KEY) as? [String] {
			self.recentSoundfonts = storedRecentSFArr.map { return URL(string: $0)! }
		}
		
		// make all numerical labels use nice fonts
		// also do it here because windowOpened() is executed when the window is already visible
		if let readableSF = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize).monospacedNumbers?.verticallyCenteredColon {
			self.speedLabel.font = readableSF
			self.progressTimeLabel.font = readableSF
			self.durationTimeLabel.font = readableSF
		}
		
		self.overrideSFToggled(self.overrideSFCheckbox)
		self.cacophonyIconView.toolTip = "Cacophony Mode enabled"
	}
	
	// MARK: - IBActions
	
	@IBAction func overrideSFToggled(_ sender: NSButton) {
		let overrideEnabled = sender.state == .on
		
		self.soundfontMenu.isHidden = !overrideEnabled
		self.fauxSoundfontMenu.isHidden = overrideEnabled
		
		if !overrideEnabled, let midiURL = self.midiPlayer?.currentMIDI {
			// only restart playback if soundfont actually changed
			let selectedSoundfont = self.getSelectedSoundfont()
			
			if (self.guessedSoundfont == nil && selectedSoundfont.soundfontType == .macdefault) ||
			   (self.guessedSoundfont == selectedSoundfont.soundfont) {
				return
			}
			
			self.populateSoundfontMenu()
			
			self.openFile(midiURL: midiURL)
		}
	}
	
	@IBAction func soundfontItemSelected(_ sender: NSPopUpButton) {
		// all soundfont selection logic is in openFile()
		if let midiURL = self.midiPlayer?.currentMIDI {
			self.openFile(midiURL: midiURL)
		}
	}
	
	@IBAction func clickRecognizerTriggered(_ sender: NSClickGestureRecognizer) {
		print("click recognized!")
		let mousePoint = sender.location(in: self.progressTimeSlider)
		
		let progFactor = mousePoint.x / self.progressTimeSlider.bounds.width
		let newProgress = self.progressTimeSlider.maxValue * Double(progFactor)
		
		self.progressTimeSlider.doubleValue = newProgress
		self.positionSliderMoved(progressTimeSlider)
	}
	
	@IBAction func durationLabelClicked(_ sender: NSClickGestureRecognizer) {
		durationCountDown = !durationCountDown
		
		if self.durationCountDown {
			self.durationTimeLabel.placeholderString = "-0:00"
		} else {
			self.durationTimeLabel.placeholderString = "0:00"
		}
	}
	
	@IBAction func positionSliderMoved(_ sender: NSSlider) {
		let positionPercent = sender.doubleValue / 100
		
		guard let midiPlayer = self.midiPlayer else {
			return
		}
		
		if let currentEvent = sender.window?.currentEvent {
			switch (currentEvent.type) {
			case .leftMouseDown:
				if midiPlayer.isPlaying {
					midiPlayer.pause()
					self.pausedDueToDraggingKnob = true
				}
			case .leftMouseDragged:
				self.playbackPositionChanged(position: positionPercent * midiPlayer.duration, duration: midiPlayer.duration)
			case .leftMouseUp:
				// this has to occur before resuming playback
				// if .currentPosition is set after resuming playback
				// you risk being deafened by *extremely* loud pops
				midiPlayer.currentPosition = midiPlayer.duration * positionPercent
				
				if self.pausedDueToDraggingKnob && !midiPlayer.isAtEndOfTrack {
					midiPlayer.play()
					self.pausedDueToDraggingKnob = false
				}
				
			default:
				print("Unknown type \(currentEvent.type.rawValue)")
			}
		}
	}

	@IBAction func skipButtonPressed(_ sender: NSButton) {
		if sender.tag < 0 {
			self.rewind()
		} else {
			self.fastForward()
		}
	}
	
	@IBAction func playPauseButtonPressed(_ sender: NSButton) {
		// State off: "Play"
		// State on: "Pause"
		
		guard self.midiPlayer != nil else {
			return
		}
		
		self.midiPlayer?.togglePlayPause()
		
		if self.midiPlayer?.isPlaying ?? false {
			// Player is now playing
			self.playPauseButton.state = .on
		} else {
			// Player is now paused
			self.playPauseButton.state = .off
		}
	}
	
	@IBAction func speedSliderMoved(_ sender: NSSlider) {
		self.shiftPressed = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
		
		if self.shiftPressed {
			sender.allowsTickMarkValuesOnly = false
			
			let lowerCap = self.speedValues[Int(floor(sender.floatValue))]
			let upperCap = self.speedValues[Int(ceil(sender.floatValue))]
			let valueDiff = upperCap - lowerCap
			let betweenFactor = sender.floatValue - floor(sender.floatValue)
			let newValue = lowerCap + valueDiff * betweenFactor
			
			self.playbackSpeed = newValue.rounded(toDecimalPlaces: 2)
		} else {
			sender.allowsTickMarkValuesOnly = true
			
			let currentSliderPos = sender.integerValue
			let speedValue = self.speedValues[currentSliderPos]
			
			self.playbackSpeed = speedValue
		}
		
		self.speedLabel.stringValue = String(format: "%.2f×", self.playbackSpeed)
		self.midiPlayer?.rate = self.playbackSpeed
	}
	
	// MARK: - App logic
	
	func openFile(midiURL: URL) {
		guard let window = self.view.window, let document = NSDocumentController.shared.document(for: window) as? MIDIDocument else {
			// this might happen if another soundfont is selected after a file that's being played is renamed
			NSAlert.runModal(title: "Error loading file", message: "Something went wrong. Please try reopening the file.", style: .critical)
			
			// attempt to close anyway
			self.view.window?.close()
			return
		}
		
		let newGuessedSoundfont = document.midiPresenter.presentedItemURL
		var newActiveSoundfont = newGuessedSoundfont
		
		if self.overrideSFCheckbox.state == .on {
			newActiveSoundfont = self.getSelectedSoundfont().soundfont
		}
		
		if !FileManager.default.fileExists(atPath: midiURL.path) {
			NSAlert.runModal(title: "Error opening file", message: "Couldn't open MIDI file.\nSearch path: \(midiURL.path)", style: .critical)
			NSDocumentController.shared.document(for: window)?.close()
			return
		}
		if let sf = newActiveSoundfont, !FileManager.default.fileExists(atPath: sf.path) {
			NSAlert.runModal(title: "Error opening file", message: "Couldn't open Soundfont file", style: .critical)
			NSDocumentController.shared.document(for: window)?.close()
			return
		}
		
		let coordinator = NSFileCoordinator(filePresenter: document.midiPresenter)
		coordinator.coordinate(readingItemAt: document.midiPresenter.primaryPresentedItemURL!, options: [], error: nil) {
			url in
			
			do {
				let newMidiPlayer = try PWMIDIPlayer(withMIDI: url, andSoundfont: newActiveSoundfont)
				
				self.guessedSoundfont = newGuessedSoundfont
				self.activeSoundfont = newActiveSoundfont
				
				// TODO: Check if this is still needed
				self.midiPlayer?.stop()
				if #available(OSX 10.12.2, *) {
					// remove old player from Now Playing Central to get rid of "phantom" players
					NowPlayingCentral.shared.removeFromPlayers(player: self.midiPlayer)
				}
				self.midiPlayer = nil
				
				self.midiPlayer = newMidiPlayer
				self.midiPlayer!.delegate = self
				
				// required, because .prepareToPlay triggers a callback that we need
				self.midiPlayer!.prepareToPlay()
				
				DispatchQueue.main.async {
					self.rewindButton.isEnabled = true
					self.fastForwardButton.isEnabled = true
					
					self.playbackPositionChanged(position: 0, duration: self.midiPlayer!.duration)
				}
			} catch let error as NSError {
				NSAlert.runModal(title: "Error opening file", message: error.localizedDescription, style: .critical)
				NSDocumentController.shared.document(for: window)?.close()
			}
		}
	}
	
	func openDocument(midiDoc: MIDIDocument) {
		print("openDocument!")
		
		guard let midiURL = midiDoc.fileURL else {
			print("Document fileURL is nil")
			return
		}
		
		self.openFile(midiURL: midiURL)
	}
	
	func getSelectedSoundfont() -> (soundfont: URL?, soundfontType: SoundfontMenuType) {
		if let selectedItem = self.soundfontMenu.selectedItem,
		   let selectedType = SoundfontMenuType(rawValue: selectedItem.tag) {
			switch (selectedType) {
			case .macdefault:
				return (nil, selectedType)
			case .recent:
				let recentIndex = self.soundfontMenu.indexOfSelectedItem - SOUNDFONTS_RECENT_START
				let recentSoundfont = self.recentSoundfonts[recentIndex]
				return (recentSoundfont, selectedType)
			case .custom:
				let panel = NSOpenPanel()
				panel.allowedFileTypes = [ "sf2", "dls" ]
				panel.allowsMultipleSelection = false
				if panel.runModal() == NSApplication.ModalResponse.OK {
					return (URL(fileURLWithPath: panel.url!.path), selectedType)
				} else {
					// open panel was cancelled, resetting soundfont selection to default
					return (nil, selectedType)
				}
			default:
				return (nil, .unknown)
			}
		}
		
		return (nil, .unknown)
	}
	
	func populateSoundfontMenu() {
		// don't do anything if the menu contains two or fewer items for some reason
		guard self.soundfontMenu.numberOfItems > 2 else {
			return
		}
		
		// clear menu
		self.soundfontMenu.removeAllItems()
		
		let defaultSFItem = NSMenuItem()
		defaultSFItem.title = "Default Soundfont"
		defaultSFItem.tag = SoundfontMenuType.macdefault.rawValue
		self.soundfontMenu.menu!.addItem(defaultSFItem)
		self.soundfontMenu.select(defaultSFItem)
		
		if !self.recentSoundfonts.isEmpty {
			self.soundfontMenu.menu!.addItem(NSMenuItem.separator())
			
			let recentSFHeaderItem = NSMenuItem()
			recentSFHeaderItem.title = "Recent Soundfonts"
			recentSFHeaderItem.tag = SoundfontMenuType.recent.rawValue
			recentSFHeaderItem.isEnabled = false
			self.soundfontMenu.menu!.addItem(recentSFHeaderItem)
			
			for recentSF in self.recentSoundfonts {
				if !FileManager.default.fileExists(atPath: recentSF.path) {
					continue
				}
				
				let recentSFTitle = recentSF.lastPathComponent
				
				let recentSFItem = NSMenuItem()
				recentSFItem.title = recentSFTitle
				recentSFItem.tag = SoundfontMenuType.recent.rawValue
				self.soundfontMenu.menu!.addItem(recentSFItem)
				
				if self.activeSoundfont == recentSF {
					self.soundfontMenu.select(recentSFItem)
				}
			}
		}
		
		if let selectedTitle = self.soundfontMenu.titleOfSelectedItem {
			self.fauxSoundfontMenu.stringValue = selectedTitle
		}
		
		self.soundfontMenu.menu?.addItem(NSMenuItem.separator())
		let customSFItem = NSMenuItem()
		customSFItem.title = "Load Custom Soundfont…"
		customSFItem.tag = SoundfontMenuType.custom.rawValue
		self.soundfontMenu.menu!.addItem(customSFItem)
	}

	func rewind() {
		let skipAmount: TimeInterval = self.shiftPressed ? 5 : 10
		self.midiPlayer?.rewind(secs: skipAmount)
		print("rewind \(skipAmount) seconds")
	}

	func fastForward() {
		let skipAmount: TimeInterval = self.shiftPressed ? 5 : 10
		self.midiPlayer?.fastForward(secs: skipAmount)
		print("fast forward \(skipAmount) seconds")
	}
	
	// MARK: - Prevent error beeps when the space bar is pressed
	
	override var acceptsFirstResponder: Bool {
		return true
	}
	
	// MARK: - WindowControllerDelegate

	func flagsChangedEvent(with event: NSEvent) {
		self.shiftPressed = event.modifierFlags.contains(.shift)

		let skipAmount = self.shiftPressed ? 5 : 10
		self.rewindButton.title = String(skipAmount)
		self.fastForwardButton.title = String(skipAmount)
	}

	func keyDownEvent(with event: NSEvent) {
		switch (event.keyCode) {
		case 0x31: // space
			self.midiPlayer?.togglePlayPause()
		case 0x7B: // arrow left
			self.rewind()
		case 0x7C: // arrow right
			self.fastForward()
		case 0x7D: // arrow down
			if self.speedSlider.integerValue > Int(self.speedSlider.minValue) {
				self.speedSlider.integerValue -= 1
			}
			self.speedSliderMoved(speedSlider)
		case 0x7E: // arrow up
			if self.speedSlider.integerValue < Int(self.speedSlider.maxValue) {
				self.speedSlider.integerValue += 1
			}
			self.speedSliderMoved(speedSlider)
		default:
			break
		}
	}

	func windowWillClose(_ notification: Notification) {
		if #available(OSX 10.12.2, *) {
			NowPlayingCentral.shared.removeFromPlayers(player: self.midiPlayer)
			print("Removed from NPC")
		}

		self.midiPlayer?.stop()
		self.midiPlayer = nil
	}

	// MARK: - PWMIDIPlayerDelegate
	
	func filesLoaded(midi: URL, soundFont: URL?) {
		if let sf = soundFont {
			if self.recentSoundfonts.contains(sf) {
				let sfElement = self.recentSoundfonts.remove(at: self.recentSoundfonts.firstIndex(of: sf)!)
				self.recentSoundfonts.insert(sfElement, at: 0)
			} else {
				self.recentSoundfonts.insert(sf, at: 0)
			}
			
			self.recentSoundfonts = Array(self.recentSoundfonts.dropLast(max(0, self.recentSoundfonts.count - 5)))
			UserDefaults.standard.set(self.recentSoundfonts.map { $0.absoluteString }, forKey: USERDEFAULTS_SOUNDFONTS_KEY)
		}
		
		if Settings.shared.cacophonyMode {
			let accVC: NSTitlebarAccessoryViewController = NSTitlebarAccessoryViewController()
			accVC.view = self.cacophonyIconView
			accVC.layoutAttribute = .right
			
			self.view.window?.addTitlebarAccessoryViewController(accVC)
		}
		
		self.populateSoundfontMenu()
		
		self.midiPlayer?.rate = self.playbackSpeed
		
		self.playPauseButton.isEnabled = true
		
		if Settings.shared.autoplay {
			self.midiPlayer?.play()
		}
	}
	
	func playbackWillStart(firstTime: Bool) {
		
	}
	
	func playbackStarted(firstTime: Bool) {
		self.playPauseButton.state = .on
	}
	
	func playbackStopped(paused: Bool) {
		self.playPauseButton.state = .off
	}
	
	func playbackEnded() {
		self.playPauseButton.state = .off
	}
	
	func playbackPositionChanged(position: TimeInterval, duration: TimeInterval) {
		DispatchQueue.main.async {
			let progress = position / duration
			
			self.progressTimeSlider.doubleValue = progress * 100
			
			self.progressTimeLabel.stringValue = self.dcFormatter.string(from: position)!
			
			if self.durationCountDown {
				self.durationTimeLabel.stringValue = "-" + self.dcFormatter.string(from: duration - position)!
			} else {
				self.durationTimeLabel.stringValue = self.dcFormatter.string(from: duration)!
			}
			
		}
	}
	
	func playbackSpeedChanged(speed: Float) {
		// empty because optional protocol methods aren't a thing yet in Swift
	}
	
}
