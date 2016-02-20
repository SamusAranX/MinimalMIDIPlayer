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
		let midURL = NSURL(fileURLWithPath: filename)
		var sf2URL: NSURL?
		
		do {
			let fileDirectory = midURL.URLByDeletingLastPathComponent
			let nameWithoutExt = NSString(string: midURL.lastPathComponent!).stringByDeletingPathExtension.stringByRemovingPercentEncoding!
			Swift.print(nameWithoutExt)
			let potentialSF2 = fileDirectory!.path! + "/" +  nameWithoutExt + ".sf2"
			Swift.print(potentialSF2)
			
			let fileManager = NSFileManager.defaultManager()
			if fileManager.fileExistsAtPath(potentialSF2) {
				sf2URL = NSURL(fileURLWithPath: potentialSF2)
			} else {
				sf2URL = nil
			}
			Swift.print(sf2URL)
			
			try midiPlayer = AVMIDIPlayer(contentsOfURL: midURL, soundBankURL: sf2URL)
			midiPlayer.prepareToPlay()
			midiPlayer.play() {
				Swift.print("Finished playing.")
				self.playPauseButton.state = NSOffState
			}
			playPauseButton.state = NSOnState
			playPauseButton.enabled = true
			self.title = filenameOnly
		} catch let error as NSError {
			playPauseButton.enabled = false
			Swift.print("Error playing MIDI file: \(error.localizedDescription)")
		}
	}
	
	func openDocument(sender: AnyObject?) {
		let panel = NSOpenPanel();
		let types = [ "mid", "midi" ]
		panel.allowedFileTypes = types;
		panel.allowsMultipleSelection = false;
		if panel.runModal() == NSFileHandlingPanelOKButton {
			self.loadFile(panel.URL!.path!)
		}
	}

	@IBAction func buttonPressed(sender: AnyObject) {
		if midiPlayer != nil && midiPlayer.playing {
			midiPlayer.stop()
			playPauseButton.state = NSOffState
			return
		} else if midiPlayer != nil && !midiPlayer.playing {
			midiPlayer.prepareToPlay()
			midiPlayer.play() {
				Swift.print("Finished playing.")
				self.playPauseButton.state = NSOffState
			}
		}
	}
	
	
	
}
