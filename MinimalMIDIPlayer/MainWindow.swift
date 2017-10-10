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
	
	var midiPlayer: AVMIDIPlayer!
	@IBOutlet var playPauseButton: NSButton!
	
	func loadFile(filename: String) {
		Swift.print("loadFile: \(filename)")
		
		let filenameOnly = (filename as NSString).lastPathComponent
		let midURL = URL(fileURLWithPath: filename)
		var soundFontURL: URL?
		
		do {
			let fileDirectory = midURL.deletingLastPathComponent()
			let nameWithoutExt = NSString(string: midURL.lastPathComponent).deletingPathExtension.removingPercentEncoding
			
			// Super cheap way of checking for accompanying soundfonts incoming
			let potentialSoundFonts = [
				"\(fileDirectory.path)/\(nameWithoutExt!).sf2", // Soundfonts with same name as the MIDI file
				"\(fileDirectory.path)/\(nameWithoutExt!).dls",
				"\(fileDirectory.path)/\(fileDirectory.lastPathComponent).sf2", // Soundfonts with same name as containing folder
				"\(fileDirectory.path)/\(fileDirectory.lastPathComponent).dls"
			]
//			Swift.print("potentialSoundFonts: \(potentialSoundFonts)")
			
			let fileManager = FileManager.default
			soundFontURL = nil
			for psf in potentialSoundFonts {
                if fileManager.fileExists(atPath: psf) {
					soundFontURL = URL(fileURLWithPath: psf)
					break
				}
			}
			Swift.print("soundFontURL: \(soundFontURL!)")
            
            try midiPlayer = AVMIDIPlayer(contentsOf: midURL, soundBankURL: soundFontURL)
			midiPlayer.prepareToPlay()
			midiPlayer.play() {
				Swift.print("Finished playing.")
				self.playPauseButton.state = NSControl.StateValue.off
			}
			playPauseButton.state = NSControl.StateValue.on
			playPauseButton.isEnabled = true
			self.title = filenameOnly
		} catch let error as NSError {
			playPauseButton.isEnabled = false
			Swift.print("Error playing MIDI file: \(error.localizedDescription)")
		}
	}
	
	func openDocument(sender: AnyObject?) {
		let panel = NSOpenPanel();
		let types = [ "mid", "midi" ]
		panel.allowedFileTypes = types;
		panel.allowsMultipleSelection = false;
		if panel.runModal() == NSApplication.ModalResponse.OK {
            self.loadFile(filename: panel.url!.path)
		}
	}

	@IBAction func buttonPressed(sender: AnyObject) {
		if midiPlayer != nil && midiPlayer.isPlaying {
			midiPlayer.stop()
			playPauseButton.state = NSControl.StateValue.off
			return
		} else if midiPlayer != nil && !midiPlayer.isPlaying {
			midiPlayer.prepareToPlay()
			midiPlayer.play() {
				Swift.print("Finished playing.")
				self.playPauseButton.state = NSControl.StateValue.off
			}
		}
	}
	
	
	
}
