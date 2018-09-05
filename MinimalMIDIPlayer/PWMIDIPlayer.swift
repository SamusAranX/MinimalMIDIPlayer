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
    var currentSoundfont: URL?
    
    var nowPlayingInfo: MPNowPlayingInfoCenter?
    var commandCenter: MPRemoteCommandCenter?
    
    weak var delegate: PWMIDIPlayerDelegate?
    
    fileprivate var progressTimer: Timer?
    
    override var rate: Float {
        didSet {
            self.nowPlayingInfo?.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: self.rate)
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
    
    class func guessSoundfontPath(forMIDI midiFile: URL) -> URL? {
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
        
        for psf in potentialSoundFonts {
            if FileManager.default.fileExists(atPath: psf) {
                return URL(fileURLWithPath: psf)
            }
        }
        
        return nil
    }
	
    convenience init(withMIDI midiFile: URL, andSoundfont soundfontFile: URL? = nil) throws {
		try self.init(contentsOf: midiFile, soundBankURL: soundfontFile)
        
        self.nowPlayingInfo = MPNowPlayingInfoCenter.default()
        self.commandCenter = MPRemoteCommandCenter.shared()
		
		self.currentMIDI = midiFile
		self.currentSoundfont = soundfontFile
        
        let midiTitle = self.currentMIDI!.deletingPathExtension().lastPathComponent
        let midiAlbumTitle = self.currentSoundfont?.deletingPathExtension().lastPathComponent ?? self.currentMIDI!.deletingLastPathComponent().lastPathComponent
        let midiArtist = "MinimalMIDIPlayer" // heh
		
        var nowPlayingInfo: [String : Any] = [
            MPNowPlayingInfoPropertyMediaType: NSNumber(value: MPNowPlayingInfoMediaType.audio.rawValue),
            MPNowPlayingInfoPropertyIsLiveStream: NSNumber(booleanLiteral: false),
            
            MPNowPlayingInfoPropertyDefaultPlaybackRate: NSNumber(floatLiteral: 1.0),
            MPNowPlayingInfoPropertyPlaybackProgress: NSNumber(floatLiteral: 0.0),
            
            MPMediaItemPropertyTitle: midiTitle,
            MPMediaItemPropertyAlbumTitle: midiAlbumTitle,
            MPMediaItemPropertyArtist: midiArtist,
            
            MPMediaItemPropertyPlaybackDuration: NSNumber(value: self.duration)
        ]
        
        if #available(OSX 10.13.2, *) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 800, height: 800), requestHandler: {
                (size: CGSize) -> NSImage in
                
                return NSImage(named: "AlbumArt")!
            })
        }
        
        self.nowPlayingInfo?.nowPlayingInfo = nowPlayingInfo
        
        self.commandCenter?.playCommand.addTarget(self, action: #selector(playCommand(event:)))
        self.commandCenter?.pauseCommand.addTarget(self, action: #selector(pauseCommand(event:)))
        self.commandCenter?.togglePlayPauseCommand.addTarget(self, action: #selector(togglePlayPauseCommand(event:)))
        self.commandCenter?.changePlaybackPositionCommand.addTarget(self, action: #selector(changePlaybackPositionCommand(event:)))
        self.commandCenter?.previousTrackCommand.addTarget(self, action: #selector(previousTrackCommand(event:)))
        self.commandCenter?.nextTrackCommand.addTarget(self, action: #selector(nextTrackCommand(event:)))
	}
    
    deinit {
		Swift.print("deinit")
		
		self.progressTimer?.invalidate()
		self.progressTimer = nil
		
		self.nowPlayingInfo?.nowPlayingInfo = nil
		
		self.commandCenter?.playCommand.removeTarget(self)
		self.commandCenter?.pauseCommand.removeTarget(self)
		self.commandCenter?.togglePlayPauseCommand.removeTarget(self)
		self.commandCenter?.changePlaybackPositionCommand.removeTarget(self)
		self.commandCenter?.previousTrackCommand.removeTarget(self)
		self.commandCenter?.nextTrackCommand.removeTarget(self)
		
		self.delegate = nil
    }
    
    func timerDidFire(_ timer: Timer) {
        guard let _timer = self.progressTimer, _timer.isValid else {
            return
        }
        
        self.nowPlayingInfo?.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: self.currentPosition)
        self.delegate?.playbackPositionChanged(position: self.currentPosition, duration: self.duration)
    }
    
    ///
    /// COMMAND CENTER COMMANDS
    ///
    
    @objc func playCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        Swift.print("Play command")
        self.play()
        return .success
    }
    
    @objc func pauseCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        Swift.print("Pause command")
        self.pause()
        return .success
    }
    
    @objc func togglePlayPauseCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        Swift.print("Play/Pause command")
        self.togglePlayPause()
        return .success
    }
    
    @objc func changePlaybackPositionCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        let changePositionEvent = event as! MPChangePlaybackPositionCommandEvent
        self.currentPosition = changePositionEvent.positionTime
        return .success
    }
    
    @objc func previousTrackCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        Swift.print("Previous track command")
        self.stop()
        self.currentPosition = 0
        self.play()
        return .success
    }
    
    @objc func nextTrackCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        Swift.print("Next track command")
        self.stop()
        return .success
    }
    
    ///
    /// OVERRIDES AND CONVENIENCE METHODS
    ///
    
    override func prepareToPlay() {
        super.prepareToPlay()

        self.delegate?.filesLoaded(midi: self.currentMIDI!, soundFont: self.currentSoundfont)
    }
	
    override func play(_ completionHandler: AVMIDIPlayerCompletionHandler? = nil) {
		super.play() {
			DispatchQueue.main.async {
				if (self.currentPosition >= self.duration - 0.1) {
					self.progressTimer?.invalidate()
					self.nowPlayingInfo?.playbackState = .stopped
					self.delegate?.playbackEnded()
				}
			}
            
			completionHandler?()
		}
        
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.125, repeats: true, block: timerDidFire)
		self.progressTimer!.tolerance = 0.125 / 8
        
        self.nowPlayingInfo?.playbackState = .playing
        self.delegate?.playbackStarted(firstTime: self.currentPosition == 0)
    }
	
	// cheap, but it works. mostly
	func pause() {
		super.stop()
		
        self.progressTimer?.invalidate()
		
        self.nowPlayingInfo?.playbackState = .paused
		
		self.delegate?.playbackStopped(paused: true)
	}
    
    override func stop() {
		super.stop()
		
        self.progressTimer?.invalidate()
		
		self.currentPosition = 0
        self.nowPlayingInfo?.playbackState = .stopped
        
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
