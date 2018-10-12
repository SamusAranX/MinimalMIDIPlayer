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
	
	@IBOutlet weak var previousButton: NSButton!
	@IBOutlet weak var playPauseButton: NSButton!
	@IBOutlet weak var stopButton: NSButton!
	@IBOutlet weak var cacophonyIconView: NSView!
	
	@IBOutlet weak var soundfontMenu: NSPopUpButton!
	@IBOutlet weak var fauxSoundfontMenu: NSTextField!
	@IBOutlet weak var overrideSFCheckbox: NSButton!
	
	@IBOutlet weak var progressTimeLabel: NSTextField!
	@IBOutlet weak var durationTimeLabel: NSTextField!
	@IBOutlet weak var progressTimeBar: NSProgressIndicator!
	
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
	
	let speedValues: [Float] = [0.25, 1/3, 0.5, 2/3, 0.75, 0.8, 0.9, 1.0, 1.1, 1.2, 1.25, 1 + 1/3, 1.5, 1 + 2/3, 2.0]
	var playbackSpeed: Float = 1.0
	
	enum SoundfontMenuType: Int {
		case macdef = 0
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
		
		// make all numerical labels use tabular figures
		// also do it here because windowOpened() is executed when the window is already visible
		self.speedLabel.font = self.speedLabel.font?.monospacedNumbers
		self.progressTimeLabel.font = self.progressTimeLabel.font?.monospacedNumbers
		self.durationTimeLabel.font = self.durationTimeLabel.font?.monospacedNumbers
		
		self.overrideSFToggled(self.overrideSFCheckbox)
		
		self.cacophonyIconView.toolTip = "Cacophony Mode enabled"
	}
	
	func windowWillClose(_ notification: Notification) {
		if #available(OSX 10.12.2, *) {
			NowPlayingCentral.shared.removeFromPlayers(player: self.midiPlayer)
		}
		
		self.midiPlayer?.stop()
		self.midiPlayer = nil
	}
	
	// MARK: - IBActions
	
	@IBAction func overrideSFToggled(_ sender: NSButton) {
		let overrideEnabled = sender.state == .on
		
		self.soundfontMenu.isHidden = !overrideEnabled
		self.fauxSoundfontMenu.isHidden = overrideEnabled
		
		if !overrideEnabled, let midiURL = self.midiPlayer?.currentMIDI {
			// only restart playback if soundfont actually changed
			let selectedSoundfont = self.getSelectedSoundfont()
			
			if (self.guessedSoundfont == nil && selectedSoundfont.soundfontType == .macdef) ||
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
	
	@IBAction func durationLabelClicked(_ sender: NSClickGestureRecognizer) {
		durationCountDown = !durationCountDown
		
		if self.durationCountDown {
			self.durationTimeLabel.placeholderString = "-0:00"
		} else {
			self.durationTimeLabel.placeholderString = "0:00"
		}
	}
	
	@IBAction func previousButtonPressed(_ sender: NSButton) {
		let playerWasRunning = self.midiPlayer?.isPlaying
		
		self.midiPlayer?.stop()
		self.midiPlayer?.currentPosition = 0
		
		if let pwr = playerWasRunning, pwr {
			self.midiPlayer?.play()
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
	
	@IBAction func stopButtonPressed(_ sender: NSButton) {
		self.midiPlayer?.stop()
	}
	
	@IBAction func speedSliderMoved(_ sender: NSSlider) {
		let currentSliderPos = sender.integerValue
		let speedValue = self.speedValues[currentSliderPos]
		
		self.playbackSpeed = speedValue
		self.speedLabel.stringValue = String(format: "%.2f×", speedValue)
		
		self.midiPlayer?.rate = self.playbackSpeed
	}
	
	// MARK: - App logic
	
	func openFile(midiURL: URL) {
		do {
			let newGuessedSoundfont = PWMIDIPlayer.guessSoundfontPath(forMIDI: midiURL)
			var newActiveSoundfont = newGuessedSoundfont
			
			if self.overrideSFCheckbox.state == .on {
				newActiveSoundfont = self.getSelectedSoundfont().soundfont
			}
			
			if !FileManager.default.fileExists(atPath: midiURL.path) {
				NSAlert.runModal(title: "Error opening file", message: "Couldn't open MIDI file.\nSearch path: \(midiURL.path)", style: .critical)
				return
			}
			if let sf = newActiveSoundfont, !FileManager.default.fileExists(atPath: sf.path) {
				NSAlert.runModal(title: "Error opening file", message: "Couldn't open Soundfont file", style: .critical)
				return
			}
			
			let newMidiPlayer = try PWMIDIPlayer(withMIDI: midiURL, andSoundfont: newActiveSoundfont)
			
			self.guessedSoundfont = newGuessedSoundfont
			self.activeSoundfont = newActiveSoundfont
			
			self.midiPlayer?.stop()
			self.midiPlayer = nil
			
			self.midiPlayer = newMidiPlayer
			self.midiPlayer!.delegate = self
			
			// required, because .prepareToPlay triggers a callback that we need
			self.midiPlayer!.prepareToPlay()
			
			self.previousButton.isEnabled = true
			self.stopButton.isEnabled = true
			
			self.playbackPositionChanged(position: 0, duration: self.midiPlayer!.duration)
		} catch let error as NSError {
			NSAlert.runModal(title: "Error opening file", message: error.localizedDescription, style: .critical)
		}
	}
	
	func openDocument(midiDoc: MIDIDocument) {
		guard let midiURL = midiDoc.fileURL else {
			Swift.print("Document fileURL is nil")
			return
		}
		
		self.openFile(midiURL: midiURL)
	}
	
	func getSelectedSoundfont() -> (soundfont: URL?, soundfontType: SoundfontMenuType) {
		if let selectedItem = self.soundfontMenu.selectedItem,
		   let selectedType = SoundfontMenuType(rawValue: selectedItem.tag) {
			switch (selectedType) {
			case .macdef:
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
		defaultSFItem.tag = SoundfontMenuType.macdef.rawValue
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
	
	// MARK: - WindowControllerDelegate
	
	override func keyDown(with event: NSEvent) {
		switch (event.keyCode) {
		case 0x31: // space
			self.midiPlayer?.togglePlayPause()
		case 0x7B: // arrow left
			self.midiPlayer?.currentPosition = 0
		case 0x7C: // arrow right
			self.midiPlayer?.stop()
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
		Swift.print("Playback will start from the beginning: \(firstTime)")
	}
	
	func playbackStarted(firstTime: Bool) {
		Swift.print("Playback started from the beginning: \(firstTime)")
		self.playPauseButton.state = .on
	}
	
	func playbackStopped(paused: Bool) {
		self.playPauseButton.state = .off
	}
	
	func playbackEnded() {
		Swift.print("Playback ended, resetting position to the beginning")
		
		self.midiPlayer?.currentPosition = 0
		self.playPauseButton.state = .off
	}
	
	func playbackPositionChanged(position: TimeInterval, duration: TimeInterval) {
		DispatchQueue.main.async {
			let progress = position / duration
			
			self.progressTimeBar.doubleValue = progress * 100
			
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
