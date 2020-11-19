//
//  MainViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 05.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa

class DocumentViewController: NSViewController, WindowControllerDelegate, PWMIDIPlayerDelegate, MIDIFileBouncerDelegate {
	@IBOutlet weak var backgroundFXView: NSVisualEffectView!

	@IBOutlet weak var rewindButton: NSButton!
	@IBOutlet weak var playPauseButton: NSButton!
	@IBOutlet weak var fastForwardButton: NSButton!
	@IBOutlet weak var cacophonyIconView: NSView!

	@IBOutlet weak var soundfontMenu: NSPopUpButton!

	@IBOutlet weak var progressTimeLabel: NSTextField!
	@IBOutlet weak var durationTimeLabel: NSTextField!
	@IBOutlet weak var progressTimeSlider: NSSlider!
	@IBOutlet weak var bounceProgressBar: NSProgressIndicator!

	@IBOutlet weak var speedSlider: NSSlider!
	@IBOutlet weak var speedLabel: NSTextField!

	private var midiPlayer: PWMIDIPlayer?

	private var dcFormatter: DateComponentsFormatter!
	private var durationCountDown = false

	private let USERDEFAULTS_SOUNDFONTS_KEY = "recentSoundfonts"
	private var recentSoundfonts: [URL] = []
	private var guessedSoundfont: URL?
	private var activeSoundfont: URL?
	private var firstLoad = true

	private var playbackSpeed: Float = 1.0

    public var supportedPlaybackRates: [NSNumber] {
        return PWMIDIPlayer.speedValues.map { float in
            NSNumber(value: float)
        }
    }

	private var pausedDueToDraggingKnob = false
	@objc dynamic var isBouncing = false

	private var bouncer: MIDIFileBouncer?

	private var shiftPressed: Bool {
		return NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
	}

	private enum SoundfontMenuType: Int {
		case macDefault = 0
		case recent = 1
		case custom = 2
		case customDefault = 3
		case reset = 4
		case header = 999
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

        // set speed slider's maximum based on the number of speed settings in PWMIDIPlayer.speedValue
        self.speedSlider.maxValue = Double(PWMIDIPlayer.speedValues.count - 1)
        self.speedSlider.numberOfTickMarks = PWMIDIPlayer.speedValues.count
        self.speedSlider.intValue = Int32(PWMIDIPlayer.speedValues.firstIndex(of: 1.0)!) // will crash if 1.0 isn't a supported playback rate

		self.cacophonyIconView.toolTip = NSLocalizedString("Cacophony Mode enabled", comment: "Tooltip for the 📣 icon")
	}

	// MARK: - WindowControllerDelegate

	func keyDownEvent(with event: NSEvent) {
		switch event.keyCode {
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
		if self.isBouncing {
			self.bouncer?.cancel()
		}

		NowPlayingCentral.shared.removeFromPlayers(player: self.midiPlayer)

		self.midiPlayer?.stop()

		// wait until the bouncer has finished
		while self.bouncer != nil {
			RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))
		}

		self.midiPlayer = nil
	}

	// MARK: - IBActions

	@IBAction func soundfontItemSelected(_ sender: NSPopUpButton) {
		// all soundfont selection logic is in openFile()
		if let midiURL = self.midiPlayer?.currentMIDI {
			self.openFile(midiURL: midiURL)
		}
	}

	@IBAction func clickRecognizerTriggered(_ sender: NSClickGestureRecognizer) {
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

		if !self.isBouncing, let player = self.midiPlayer {
			self.updatePlayerControls(position: player.currentPosition, duration: player.duration)
		}
	}

	@IBAction func positionSliderMoved(_ sender: NSSlider) {
		let positionPercent = sender.doubleValue / 100

		guard let midiPlayer = self.midiPlayer else {
			return
		}

		if let currentEvent = sender.window?.currentEvent {
			switch currentEvent.type {
			case .leftMouseDown:
				if midiPlayer.isPlaying {
					midiPlayer.pause()
					self.pausedDueToDraggingKnob = true
				}
			case .leftMouseDragged:
				self.playbackPositionChanged(position: positionPercent * midiPlayer.duration, duration: midiPlayer.duration)
			case .leftMouseUp:
				// this has to occur before resuming playback
				// if .currentPosition is set after resuming playback you risk being deafened by *extremely* loud pops
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

		guard let player = self.midiPlayer else {
			return
		}

		player.togglePlayPause()
		self.playPauseButton.state = player.isPlaying ? .on : .off
	}

	@IBAction func speedSliderMoved(_ sender: NSSlider) {
		if self.shiftPressed {
			sender.allowsTickMarkValuesOnly = false

			let lowerCap = PWMIDIPlayer.speedValues[Int(floor(sender.floatValue))]
			let upperCap = PWMIDIPlayer.speedValues[Int(ceil(sender.floatValue))]
			let valueDiff = upperCap - lowerCap
			let betweenFactor = sender.floatValue - floor(sender.floatValue)
			let newValue = lowerCap + valueDiff * betweenFactor

			self.playbackSpeed = newValue.rounded(toDecimalPlaces: 2)
		} else {
			sender.allowsTickMarkValuesOnly = true

			let currentSliderPos = sender.integerValue
			let speedValue = PWMIDIPlayer.speedValues[currentSliderPos]

			self.playbackSpeed = speedValue
		}

		self.speedLabel.stringValue = String(format: "%.2f×", self.playbackSpeed)
		self.midiPlayer?.rate = self.playbackSpeed
	}

	@IBAction func cancelBounceButtonPressed(_ sender: NSButton) {
		self.bouncer?.cancel()
	}

	// MARK: - App logic

	func openFile(midiURL: URL) {
		let errorTitle    = NSLocalizedString("Error loading file", comment: "Alert popup title")
		let unknownError  = NSLocalizedString("Something went wrong. Please try reopening the file.", comment: "Message for unknown error")
		let openMIDIError = NSLocalizedString("Couldn't open MIDI file.", comment: "Message in case MIDI file can't be opened")

		guard let window = self.view.window, let document = NSDocumentController.shared.document(for: window) as? MIDIDocument else {
			// this might happen if another soundfont is selected after a file that's being played is renamed
			NSAlert.runModal(title: errorTitle, message: unknownError, style: .critical)

			// attempt to close anyway
			self.view.window?.close()
			return
		}

		if !FileManager.default.fileExists(atPath: midiURL.path) {
			NSAlert.runModal(title: errorTitle, message: openMIDIError, style: .critical)
			NSDocumentController.shared.document(for: window)?.close()
			return
		}

		let selectedSoundfont = self.getSelectedSoundfont()
		var newActiveSoundfont: URL?
        var resetSoundfontToPrevious = false

		self.guessedSoundfont = document.midiPresenter.presentedItemURL
		if self.guessedSoundfont != nil && firstLoad {
			// First load: A guessed soundfont was found and custom default soundfonts are either not set or not enabled
			newActiveSoundfont = self.guessedSoundfont
		} else if firstLoad, Settings.shared.enableCustomSoundfont, let customDefaultSF = Settings.shared.customSoundfontPath {
			// First load: No guessed soundfont could be found and a custom default soundfont is set and enabled
			newActiveSoundfont = customDefaultSF
		} else if selectedSoundfont.soundfontType == .customDefault, let customDefaultSF = Settings.shared.customSoundfontPath {
			// Not first load: The custom default soundfont is manually selected
			newActiveSoundfont = customDefaultSF
		} else if selectedSoundfont.soundfont != nil {
			// A soundfont was already selected
			newActiveSoundfont = selectedSoundfont.soundfont
        } else if selectedSoundfont.soundfontType == .custom && selectedSoundfont.soundfont == nil {
            resetSoundfontToPrevious = true
        }

		if let sf = newActiveSoundfont, !FileManager.default.fileExists(atPath: sf.path) {
			let openSoundfontErrorFormat = NSLocalizedString("Couldn't open Soundfont file \"%@\".", comment: "Message in case Soundfont file can't be opened")
			let openSoundfontError = String(format: openSoundfontErrorFormat, arguments: [sf.lastPathComponent])

			NSAlert.runModal(title: errorTitle, message: openSoundfontError, style: .critical)
			NSDocumentController.shared.document(for: window)?.close()
			return
		}

		let coordinator = NSFileCoordinator(filePresenter: document.midiPresenter)
		coordinator.coordinate(readingItemAt: document.midiPresenter.primaryPresentedItemURL!, options: [], error: nil) { url in
			do {
                if resetSoundfontToPrevious {
                    self.activeSoundfont = self.midiPlayer?.currentSoundfont
                } else {
                    self.activeSoundfont = newActiveSoundfont
                }

				let newMidiPlayer = try PWMIDIPlayer(withMIDI: url, andSoundfont: self.activeSoundfont)

				self.midiPlayer?.stop()

				// remove old player from Now Playing Central to get rid of "phantom" players
				NowPlayingCentral.shared.removeFromPlayers(player: self.midiPlayer)
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
				NSAlert.runModal(title: errorTitle, message: error.localizedDescription, style: .critical)
				NSDocumentController.shared.document(for: window)?.close()
			}
		}
	}

	func openDocument(midiDoc: MIDIDocument) {
		guard let midiURL = midiDoc.fileURL else {
			return
		}

		self.openFile(midiURL: midiURL)
	}

	private func getSelectedSoundfont() -> (soundfont: URL?, soundfontType: SoundfontMenuType) {
		if let selectedItem = self.soundfontMenu.selectedItem,
		   let selectedType = SoundfontMenuType(rawValue: selectedItem.tag) {
			switch selectedType {
			case .macDefault:
				return (nil, selectedType)
			case .customDefault:
				// Force-unwrapping customSoundfontPath because we can only hit this code path once a custom default soundfont has been selected
				return (Settings.shared.customSoundfontPath!, selectedType)
			case .recent:
				// we'll assume the index is always valid since we can't get here if no recent soundfont menu items exist
				let recentSoundfontsFirstIndex = self.soundfontMenu.indexOfItem(withTag: SoundfontMenuType.recent.rawValue)

				let recentIndex = self.soundfontMenu.indexOfSelectedItem - recentSoundfontsFirstIndex
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
			case .reset:
				if self.guessedSoundfont == nil, Settings.shared.enableCustomSoundfont, let customSFPath = Settings.shared.customSoundfontPath {
					return (customSFPath, selectedType)
				} else {
					return (self.guessedSoundfont, selectedType)
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

		let defaultSFHeaderTitle = NSLocalizedString("Default Soundfonts", comment: "'Default Soundfonts' menu header item")
		let defaultSFTitle       = NSLocalizedString("Default Soundfont", comment: "'Default Soundfont' menu item")
		let recentSFHeaderTitle  = NSLocalizedString("Recent Soundfonts", comment: "'Recent Soundfonts' menu header item")
		let resetSFTitle         = NSLocalizedString("Reset Soundfont", comment: "'Reset Soundfont' menu item")
		let customSFTitle        = NSLocalizedString("Load Custom Soundfont…", comment: "'Load Custom Soundfont' menu item")

		// clear menu
		self.soundfontMenu.menu!.removeAllItems()

		let defaultSFHeaderItem = NSMenuItem()
		defaultSFHeaderItem.title = defaultSFHeaderTitle
		defaultSFHeaderItem.tag = SoundfontMenuType.header.rawValue
		defaultSFHeaderItem.isEnabled = false
		self.soundfontMenu.menu!.addItem(defaultSFHeaderItem)

		let defaultSFItem = NSMenuItem()
		defaultSFItem.title = defaultSFTitle
		defaultSFItem.tag = SoundfontMenuType.macDefault.rawValue
		defaultSFItem.indentationLevel = 1
		self.soundfontMenu.menu!.addItem(defaultSFItem)
		self.soundfontMenu.select(defaultSFItem)

		if let customDefaultSFName = Settings.shared.customSoundfontPath?.lastPathComponent {
			let customDefaultSFItem = NSMenuItem()
			customDefaultSFItem.attributedTitle = customDefaultSFName.addColor(in: customDefaultSFName.fullRange(), color: NSColor.systemYellow)
			customDefaultSFItem.tag = SoundfontMenuType.customDefault.rawValue
			customDefaultSFItem.indentationLevel = 1
			self.soundfontMenu.menu!.addItem(customDefaultSFItem)

			if self.activeSoundfont == Settings.shared.customSoundfontPath {
				self.soundfontMenu.select(customDefaultSFItem)
			}
		}

		if !self.recentSoundfonts.isEmpty {
			self.soundfontMenu.menu!.addItem(NSMenuItem.separator())

			let recentSFHeaderItem = NSMenuItem()
			recentSFHeaderItem.title = recentSFHeaderTitle
			recentSFHeaderItem.tag = SoundfontMenuType.header.rawValue
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
				recentSFItem.indentationLevel = 1
				self.soundfontMenu.menu!.addItem(recentSFItem)

				if self.activeSoundfont != Settings.shared.customSoundfontPath && self.activeSoundfont == recentSF {
					self.soundfontMenu.select(recentSFItem)
				}
			}
		}

		self.soundfontMenu.menu?.addItem(NSMenuItem.separator())

		let resetSFItem = NSMenuItem()
		resetSFItem.title = resetSFTitle
		resetSFItem.tag = SoundfontMenuType.reset.rawValue
		self.soundfontMenu.menu!.addItem(resetSFItem)

		let loadCustomSFItem = NSMenuItem()
		loadCustomSFItem.title = customSFTitle
		loadCustomSFItem.tag = SoundfontMenuType.custom.rawValue
		self.soundfontMenu.menu!.addItem(loadCustomSFItem)

		self.soundfontMenu.synchronizeTitleAndSelectedItem()
	}

	func rewind() {
		let skipAmount: TimeInterval = self.shiftPressed ? 5 : 10
		self.midiPlayer?.rewind(secs: skipAmount)
	}

	func fastForward() {
		let skipAmount: TimeInterval = self.shiftPressed ? 5 : 10
		self.midiPlayer?.fastForward(secs: skipAmount)
	}

	func updatePlayerControls(position: TimeInterval, duration: TimeInterval) {
		let progress = position / duration

		if self.isBouncing {
			self.bounceProgressBar.doubleValue = progress * 100
		} else {
			self.progressTimeSlider.doubleValue = progress * 100
		}

		self.progressTimeLabel.stringValue = self.dcFormatter.string(from: position)!

		if self.durationCountDown {
			self.durationTimeLabel.stringValue = "-" + self.dcFormatter.string(from: duration - position)!
		} else {
			self.durationTimeLabel.stringValue = self.dcFormatter.string(from: duration)!
		}
	}

	// MARK: - Prevent error beeps when the space bar is pressed

	override var acceptsFirstResponder: Bool {
		return true
	}

	// MARK: - IBAction for the Bounce to File menu item

	@IBAction func bounceToFile(_ sender: NSMenuItem) {
		guard !self.isBouncing, self.bouncer == nil, let midiPlayer = self.midiPlayer, let sourceMIDI = midiPlayer.currentMIDI else {
			print("bounceToFile unsatisfied conditions")
			return
		}

		if !Settings.shared.bounceBetaWarningShown {
			let alertTitle = NSLocalizedString("BouncingBetaWarningTitle", comment: "Warning title")
			let alertMessage = NSLocalizedString("BouncingBetaWarningMessage", comment: "Warning message")
			NSAlert.runModal(title: alertTitle, message: alertMessage, style: .informational)
			Settings.shared.bounceBetaWarningShown = true
		}

		midiPlayer.pause()
		midiPlayer.acceptsMediaKeys = false

		let savePanel = NSSavePanel()

		let savePanelTitleFormat = NSLocalizedString("Bouncing %@ to file", comment: "title")
		savePanel.title = String(format: savePanelTitleFormat, sourceMIDI.lastPathComponent)

		savePanel.prompt = NSLocalizedString("Bounce", comment: "save button label")
		savePanel.nameFieldLabel = NSLocalizedString("Export As:", comment: "name field label")
		savePanel.nameFieldStringValue = sourceMIDI.deletingPathExtension().lastPathComponent
		savePanel.allowedFileTypes = ["wav"]

		guard savePanel.runModal() == .OK, let saveURL = savePanel.url else {
			midiPlayer.acceptsMediaKeys = true
			return
		}

		self.isBouncing = true

		DispatchQueue.global(qos: .userInitiated).async {
			guard let bouncer = try? MIDIFileBouncer(midiFile: sourceMIDI, soundfontFile: midiPlayer.currentSoundfont) else {
				DispatchQueue.main.async {
					self.bounceError(error: MIDIBounceError(kind: .initializationFailure, message: "Bouncer can't be initialized."))
				}
				return
			}

			self.bouncer = bouncer

			self.bouncer!.rate = midiPlayer.rate
			self.bouncer!.delegate = self
			self.bouncer!.bounce(to: saveURL)
		}
	}

	// MARK: - PWMIDIPlayerDelegate

	func filesLoaded(midi: URL, soundFont: URL?) {
		if let sf = soundFont {
			if self.recentSoundfonts.contains(sf) {
				let sfElement = self.recentSoundfonts.remove(at: self.recentSoundfonts.firstIndex(of: sf)!)
				self.recentSoundfonts.insert(sfElement, at: 0)
			} else if sf != Settings.shared.customSoundfontPath {
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

		if Settings.shared.autoplay && self.firstLoad {
			self.midiPlayer?.play()
		}

		self.firstLoad = false
	}

	func playbackWillStart(firstTime: Bool) {
		// empty because optional protocol methods aren't a thing yet in Swift
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
			self.updatePlayerControls(position: position, duration: duration)
		}
	}

	func playbackSpeedChanged(speed: Float) {
		// empty because optional protocol methods aren't a thing yet in Swift
	}

	// MARK: - MIDIFileBouncerDelegate

	func bounceProgress(progress: Double, currentTime: TimeInterval) {
		guard self.isBouncing else {
			return
		}

		guard let player = self.midiPlayer else {
			fatalError("player?")
		}

		self.updatePlayerControls(position: currentTime, duration: player.realDuration)
	}

	func bounceCompleted() {
		guard let bouncer = self.bouncer, let player = self.midiPlayer else {
			fatalError("player?")
		}

		if !bouncer.isCancelled {
			NSApplication.shared.requestUserAttention(.informationalRequest)
			let popupTitle = NSLocalizedString("Bounce completed", comment: "Popup title when bounce ended successfully")

			if let midiFile = bouncer.midiFile, let outFile = bouncer.outFile {
				let popupTextFormat = NSLocalizedString("%@ was successfully bounced to %@.", comment: "Popup text when bounce ended successfully")
				let popupText = String(format: popupTextFormat, midiFile.lastPathComponent, outFile.lastPathComponent)
				NSAlert.runModal(title: popupTitle, message: popupText, style: .informational)
			} else {
				// Tempting fate: fallback that should never happen
				NSAlert.runModal(title: popupTitle, message: popupTitle, style: .informational)
			}
		}

		// reset labels
		self.updatePlayerControls(position: player.currentPosition, duration: player.duration)

		// clean up behind us
		self.isBouncing = false
		self.bouncer = nil
		player.acceptsMediaKeys = true
	}

	func bounceError(error: MIDIBounceError) {
		let errorTitle = NSLocalizedString("An error occurred while bouncing", comment: "Generic error title string")
		var errorMessage = error.localizedMessage

		if let innerError = error.innerError {
			errorMessage += "\n\n"
			errorMessage += NSLocalizedString("More details: ", comment: "Prefix for detailed inner error message with trailing space")
			errorMessage += innerError.localizedDescription
		}

		NSAlert.runModal(title: errorTitle, message: errorMessage, style: .critical)

		guard let player = self.midiPlayer else {
			fatalError("player?")
		}

		// clean up this mess
		self.isBouncing = false
		self.bouncer = nil
		player.acceptsMediaKeys = true
	}

}
