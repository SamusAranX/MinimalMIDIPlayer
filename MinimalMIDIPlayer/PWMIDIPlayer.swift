//
//  AVMIDIWrapperDelegate.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 09.01.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa
import AVFoundation
import MediaPlayer

protocol PWMIDIPlayerDelegate: class {
	
    func filesLoaded(midi: URL, soundFont: URL?)
    
    func playbackStarted(firstTime: Bool)
    
    func playbackPositionChanged(position: TimeInterval, duration: TimeInterval)
    
    func playbackStopped(paused: Bool)
    func playbackEnded()
    
    func playbackSpeedChanged(speed: Float)
    
}

class PWMIDIPlayer: AVMIDIPlayer {
    
    var currentMIDI: URL?
    var currentSoundFont: URL?
    
    var nowPlayingInfo: MPNowPlayingInfoCenter!
    var commandCenter: MPRemoteCommandCenter!
    
    weak var delegate: PWMIDIPlayerDelegate?
    
    fileprivate var progressTimer: Timer?
    
    override var rate: Float {
        didSet {
            self.nowPlayingInfo.nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: self.rate)
            self.delegate?.playbackSpeedChanged(speed: self.rate)
        }
    }
    
    override var currentPosition: TimeInterval {
        didSet {
            self.delegate?.playbackPositionChanged(position: self.currentPosition, duration: self.duration)
        }
    }
    
    var isPaused: Bool {
        get {
            return !self.isPlaying && !self.isStopped
        }
    }
	
	var isStopped: Bool {
		get {
			return !self.isPlaying && self.currentPosition >= self.duration - 0.1
		}
	}
	
    convenience init(contentsOf midiFile: URL) throws {
		let fileDirectory = midiFile.deletingLastPathComponent()
		let nameWithoutExt = NSString(string: midiFile.lastPathComponent).deletingPathExtension.removingPercentEncoding
		
		// Super cheap way of checking for accompanying soundfonts
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
		
		try self.init(contentsOf: midiFile, soundBankURL: soundFontURL)
        
        self.nowPlayingInfo = MPNowPlayingInfoCenter.default()
        self.commandCenter = MPRemoteCommandCenter.shared()
		
		self.currentMIDI = midiFile
		self.currentSoundFont = soundFontURL
        
        let midiTitle = self.currentMIDI!.deletingPathExtension().lastPathComponent
        let midiAlbumTitle = self.currentSoundFont?.deletingPathExtension().lastPathComponent ?? self.currentMIDI!.deletingLastPathComponent().lastPathComponent
        let midiArtist = "MinimalMIDIPlayer" // heh
        
        var nowPlayingInfo: [String : Any] = [
            MPNowPlayingInfoPropertyMediaType: NSNumber(value: MPNowPlayingInfoMediaType.audio.rawValue),
            MPNowPlayingInfoPropertyIsLiveStream: NSNumber(booleanLiteral: false),
            
            MPNowPlayingInfoPropertyDefaultPlaybackRate: NSNumber(floatLiteral: 1.0),
            
            MPMediaItemPropertyTitle: midiTitle,
            MPMediaItemPropertyAlbumTitle: midiAlbumTitle,
            MPMediaItemPropertyArtist: midiArtist,
            
            MPMediaItemPropertyPlaybackDuration: NSNumber(value: self.duration)
        ]
        
        if #available(OSX 10.13.2, *) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 800, height: 800), requestHandler: {
                (size: CGSize) -> NSImage in
                
                return NSImage(named: NSImage.Name("AlbumArt"))!
            })
        }
        
        self.nowPlayingInfo.nowPlayingInfo = nowPlayingInfo
        
        let npDuration: NSNumber = self.nowPlayingInfo.nowPlayingInfo![MPMediaItemPropertyPlaybackDuration] as! NSNumber
        Swift.print("MIDI Duration: \(self.duration)")
        Swift.print("Now Playing Info updated. New Duration: \(npDuration)")
        
        self.commandCenter.playCommand.addTarget {
            (event) -> MPRemoteCommandHandlerStatus in
            Swift.print("Play command")
            
            self.play()
            return .success
        }
        
        self.commandCenter.pauseCommand.addTarget {
            (event) -> MPRemoteCommandHandlerStatus in
            
            self.pause()
            return .success
        }
        
        self.commandCenter.togglePlayPauseCommand.addTarget {
            (event) -> MPRemoteCommandHandlerStatus in
            
            self.togglePlayPause()
            return .success
        }
        
        self.commandCenter.changePlaybackPositionCommand.addTarget {
            (event) -> MPRemoteCommandHandlerStatus in
            
            let changePositionEvent = event as! MPChangePlaybackPositionCommandEvent
            self.currentPosition = changePositionEvent.positionTime
            
            return .success
        }
	}
    
    deinit {
        Swift.print("deinit")
        self.progressTimer?.invalidate()
        self.progressTimer = nil
        
        self.nowPlayingInfo.nowPlayingInfo = nil
        
        self.delegate = nil
    }
	
    func timerDidFire(_ timer: Timer) {
        self.nowPlayingInfo.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: self.currentPosition)
        self.delegate?.playbackPositionChanged(position: self.currentPosition, duration: self.duration)
    }
    
    override func prepareToPlay() {
        super.prepareToPlay()

        self.delegate?.filesLoaded(midi: self.currentMIDI!, soundFont: self.currentSoundFont)
    }
	
    override func play(_ completionHandler: AVMIDIPlayerCompletionHandler? = nil) {
		super.play() {
            if (self.currentPosition >= self.duration - 0.1) {
                self.delegate?.playbackEnded()
            }
            
			completionHandler?()
		}
        
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.125, repeats: true, block: timerDidFire)
        
        self.nowPlayingInfo.playbackState = .playing
        self.delegate?.playbackStarted(firstTime: self.currentPosition == 0)
    }
	
	// cheap, but it works. mostly
	func pause() {
        self.progressTimer?.invalidate()
        
		super.stop()
        self.nowPlayingInfo.playbackState = .paused
        
		self.delegate?.playbackStopped(paused: true)
	}
    
    override func stop() {
        self.progressTimer?.invalidate()
        
        super.stop()
		self.currentPosition = 0
        self.nowPlayingInfo.playbackState = .stopped
        
		self.delegate?.playbackStopped(paused: false)
    }
    
    func togglePlayPause() {
        if (self.isPaused) {
            self.play()
        } else if (self.isPlaying) {
            self.pause()
        } else {
            print("Play/pause misfire?")
        }
    }
}
