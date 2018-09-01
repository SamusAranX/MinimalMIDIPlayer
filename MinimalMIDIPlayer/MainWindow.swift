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
	
    @IBOutlet weak var backgroundFXView: NSVisualEffectView!
    
    @IBOutlet weak var playPauseButton: NSButton!
	@IBOutlet weak var stopButton: NSButton!
	
	@IBOutlet weak var midiFileLabel: NSTextField!
	@IBOutlet weak var soundfontFileLabel: NSTextField!
	
	@IBOutlet weak var progressTimeLabel: NSTextField!
	@IBOutlet weak var durationTimeLabel: NSTextField!
	@IBOutlet weak var progressTimeBar: NSProgressIndicator!
	
	@IBOutlet weak var speedSlider: NSSlider!
	@IBOutlet weak var speedLabel: NSTextField!
	
	var midiPlayer: PWMIDIPlayer?
    
    var dcFormatter: DateComponentsFormatter?
    var durationCountDown = false;
    
    let speedValues: [Float] = [0.25, 1/3, 0.5, 2/3, 0.75, 0.8, 0.9, 1.0, 1.1, 1.2, 1.25, 1 + 1/3, 1.5, 1 + 2/3, 2.0]
    var playbackSpeed: Float = 1.0
    
    func windowOpened() {
        // make all numerical labels use tabular figures
        self.speedLabel.font = self.speedLabel.font?.monospacedNumbers?.openNumbers
        self.progressTimeLabel.font = self.progressTimeLabel.font?.monospacedNumbers?.openNumbers
        self.durationTimeLabel.font = self.durationTimeLabel.font?.monospacedNumbers?.openNumbers
        
        self.dcFormatter = DateComponentsFormatter()
        self.dcFormatter!.allowedUnits = [.minute, .second]
        self.dcFormatter!.unitsStyle = .positional
        self.dcFormatter!.zeroFormattingBehavior = .pad
        self.dcFormatter!.formattingContext = .standalone
    }
	
	///
	/// PWMIDIPlayer Delegate
	///
	
	func filesLoaded(midi: URL, soundFont: URL?) {
        Swift.print("filesLoaded")
        let midiName = midi.deletingPathExtension().lastPathComponent
        let soundFontName = soundFont?.lastPathComponent ?? ""
        
		self.midiFileLabel.stringValue = midiName
        self.soundfontFileLabel.stringValue = soundFontName
        
        NSDocumentController.shared.noteNewRecentDocumentURL(midi)
        
        self.midiPlayer!.rate = self.playbackSpeed
        
        self.playPauseButton.isEnabled = true
	}
	
	func playbackStarted(firstTime: Bool) {
        Swift.print("Playback started. First time: \(firstTime)")
        
        self.stopButton.isEnabled = true
        self.playPauseButton.state = .on
	}
	
	func playbackStopped(paused: Bool) {
        self.playPauseButton.state = .off
	}
	
	func playbackEnded() {
        Swift.print("Pretty sure the file just ended. Resetting playhead to the beginning")
        self.midiPlayer!.currentPosition = 0
        
        // This delegate method happens on a different thread
        DispatchQueue.main.async {
            self.playPauseButton.state = .off
        }
	}
    
    func playbackPositionChanged(position: TimeInterval, duration: TimeInterval) {
        DispatchQueue.main.async {
            let progress = position / duration
            
            self.progressTimeBar.doubleValue = progress * 100
            
            self.progressTimeLabel.stringValue = self.dcFormatter!.string(from: position)!
            
            if self.durationCountDown {
                self.durationTimeLabel.stringValue = "-" + self.dcFormatter!.string(from: duration - position)!
            } else {
                self.durationTimeLabel.stringValue = self.dcFormatter!.string(from: duration)!
            }
            
        }
    }
	
	func playbackSpeedChanged(speed: Float) {
        // empty
	}
    
    ///
    /// APP METHODS
    ///
    
    func openFile(midiFile: URL) {
        Swift.print("Window.openFile")
        do {
            self.midiPlayer?.stop()
            self.midiPlayer = nil
            
            self.midiPlayer = try PWMIDIPlayer(contentsOf: midiFile)
            self.midiPlayer!.delegate = self
            
            // required because .prepareToPlay() does additional stuff
            self.midiPlayer!.prepareToPlay()
            
            self.midiPlayer!.play()
        } catch let error as NSError {
            let alert = NSAlert()
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .critical
            alert.messageText = "Error opening file"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
	
    @IBAction func midiLabelClicked(_ sender: NSClickGestureRecognizer) {
        if let midiTitle = (sender.view as? NSTextField)?.stringValue, midiTitle.isEmpty {
            self.openDocument(nil)
        }
    }
    
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
        durationCountDown = !durationCountDown;
        
        if self.durationCountDown {
            self.durationTimeLabel.placeholderString = "-0:00"
        } else {
            self.durationTimeLabel.placeholderString = "0:00"
        }
    }
    
	@IBAction func playPauseButtonPressed(_ sender: NSButton) {
		// State off: "Play"
		// State on: "Pause"
        
        self.midiPlayer!.togglePlayPause()

        if self.midiPlayer!.isPlaying {
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
	
}
