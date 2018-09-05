//
//  MainWindow.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 30.12.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa
import AVFoundation
import MediaPlayer

class MainWindow: NSWindow, PWMIDIPlayerDelegate {
    
    enum SoundfontMenuType: Int {
        case macdef = 0
        case recent = 1
        case custom = 2
    }
	
    @IBOutlet weak var backgroundFXView: NSVisualEffectView!
    
	@IBOutlet weak var previousButton: NSButton!
	@IBOutlet weak var playPauseButton: NSButton!
	@IBOutlet weak var nextButton: NSButton!
	
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
	
	override func awakeFromNib() {
		// On 10.14 (and presumably above), the system handles system theme changes for us. Below 10.14, we'll have to do it ourselves
		let osVersion = ProcessInfo().operatingSystemVersion
		if osVersion.majorVersion == 10 && osVersion.minorVersion <= 13 {
			DistributedNotificationCenter.default().addObserver(self, selector: #selector(systemThemeChanged), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
			self.appearance = self.getSystemAppearance()
		}
		
		let newFrame = NSRect(x: self.frame.origin.x, y: self.frame.origin.x, width: self.minSize.width, height: self.minSize.height)
		self.setFrame(newFrame, display: true)
        
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
        
        self.populateSoundfontMenu()
        
        // make all numerical labels use tabular figures
        // also do it here because windowOpened() is executed when the window is already visible
        self.speedLabel.font = self.speedLabel.font?.monospacedNumbers
        self.progressTimeLabel.font = self.progressTimeLabel.font?.monospacedNumbers
        self.durationTimeLabel.font = self.durationTimeLabel.font?.monospacedNumbers
        
        self.overrideSFToggled(self.overrideSFCheckbox)
	}
	
	@objc func systemThemeChanged(_ notification: Notification) {
		self.appearance = getSystemAppearance()
	}
	
	func getSystemAppearance() -> NSAppearance {
		let systemAppearanceName = (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light").lowercased()
		let systemAppearance = systemAppearanceName == "dark" ? NSAppearance(named: NSAppearance.Name.vibrantDark) : NSAppearance(named: NSAppearance.Name.vibrantLight)
		
		return systemAppearance!
	}
    
    func showAlert(title: String, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.runModal()
    }
	
	///
	/// PWMIDIPlayer Delegate
	///
	
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
		
		self.populateSoundfontMenu()
		
		self.setTitleWithRepresentedFilename(midi.path)
		if let documentIconButton = self.standardWindowButton(.documentIconButton) {
			documentIconButton.image = NSImage(named: "DocIcon")
		}
		
        NSDocumentController.shared.noteNewRecentDocumentURL(midi)
        
        self.midiPlayer!.rate = self.playbackSpeed
        
        self.playPauseButton.isEnabled = true
	}
	
	func playbackStarted(firstTime: Bool) {
        Swift.print("Playback started. First time: \(firstTime)")
		
		self.previousButton.isEnabled = true
        self.nextButton.isEnabled = true
        self.playPauseButton.state = .on
	}
	
	func playbackStopped(paused: Bool) {
        self.playPauseButton.state = .off
	}
	
	func playbackEnded() {
        Swift.print("Pretty sure the file just ended. Resetting playhead to the beginning")
		
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
	
	///
	/// NSWINDOW OVERRIDES
	///
	
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
			super.keyDown(with: event)
		}
	}
    
    ///
    /// APP METHODS
    ///
	
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
	
    @IBAction func overrideSFToggled(_ sender: NSButton) {
        let overrideEnabled = sender.state == .on
        
        self.soundfontMenu.isHidden = !overrideEnabled
        self.fauxSoundfontMenu.isHidden = overrideEnabled
        
        if !overrideEnabled, let midi = self.midiPlayer?.currentMIDI {
			self.openFile(midiFile: midi, autoplay: self.midiPlayer?.isPlaying ?? false)
        }
    }
    
    @IBAction func soundfontItemSelected(_ sender: NSPopUpButton) {
        // all soundfont selection logic is in openFile()
        if let midi = self.midiPlayer?.currentMIDI {
            self.openFile(midiFile: midi)
        }
	}
    
	func openFile(midiFile: URL, autoplay: Bool = true) {
        do {
            let newGuessedSoundfont = PWMIDIPlayer.guessSoundfontPath(forMIDI: midiFile)
            var newActiveSoundfont = newGuessedSoundfont
            
            if self.overrideSFCheckbox.state == .on,
                let selectedItem = self.soundfontMenu.selectedItem,
                let selectedType = SoundfontMenuType(rawValue: selectedItem.tag) {
                switch (selectedType) {
                case .macdef:
                    newActiveSoundfont = nil
                case .recent:
                    let recentIndex = self.soundfontMenu.indexOfSelectedItem - SOUNDFONTS_RECENT_START
                    let recentSoundfont = self.recentSoundfonts[recentIndex]
                    Swift.print(recentSoundfont)
                    newActiveSoundfont = recentSoundfont
                case .custom:
                    let panel = NSOpenPanel()
                    panel.allowedFileTypes = [ "sf2", "dls" ]
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == NSApplication.ModalResponse.OK {
                        newActiveSoundfont = URL(fileURLWithPath: panel.url!.path)
                    } else {
                        // open panel was cancelled, resetting soundfont selection to default
                        self.soundfontMenu.selectItem(at: 0)
                    }
                }
			}
            
            if !FileManager.default.fileExists(atPath: midiFile.path) {
                self.showAlert(title: "Error opening file", message: "Couldn't open MIDI file", style: .critical)
                return
            }
            if let sf = newActiveSoundfont, !FileManager.default.fileExists(atPath: sf.path) {
                self.showAlert(title: "Error opening file", message: "Couldn't open Soundfont file", style: .critical)
                return
            }
            
            let newMidiPlayer = try PWMIDIPlayer(withMIDI: midiFile, andSoundfont: newActiveSoundfont)
			
			self.guessedSoundfont = newGuessedSoundfont
			self.activeSoundfont = newActiveSoundfont
			
			self.midiPlayer?.stop()
			self.midiPlayer = nil
			
			self.midiPlayer = newMidiPlayer
            self.midiPlayer!.delegate = self
			
            // required, because .prepareToPlay triggers a callback that we need
            self.midiPlayer!.prepareToPlay()
			
			if autoplay {
				self.midiPlayer!.play()
			}
        } catch let error as NSError {
            self.showAlert(title: "Error opening file", message: error.localizedDescription, style: .critical)
        }
    }
    
    @IBAction func openDocument(_ sender: AnyObject?) {
		let panel = NSOpenPanel()
		panel.allowedFileTypes = [ kUTTypeMIDIAudio as String ]
		panel.allowsMultipleSelection = false
		if panel.runModal() == NSApplication.ModalResponse.OK {
			let midiFile = URL(fileURLWithPath: panel.url!.path)
			self.openFile(midiFile: midiFile)
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
	
	@IBAction func nextButtonPressed(_ sender: NSButton) {
        self.midiPlayer?.stop()
	}
	
	@IBAction func speedSliderMoved(_ sender: NSSlider) {
        let currentSliderPos = sender.integerValue
        let speedValue = self.speedValues[currentSliderPos]
        
        self.playbackSpeed = speedValue
        self.speedLabel.stringValue = String(format: "%.2f×", speedValue)
        
        self.midiPlayer?.rate = self.playbackSpeed
	}
	
}
