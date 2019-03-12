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
	
	func playbackWillStart(firstTime: Bool)
    func playbackStarted(firstTime: Bool)
	
    func playbackPositionChanged(position: TimeInterval, duration: TimeInterval)
	
    func playbackStopped(paused: Bool)
    func playbackEnded()
	
    func playbackSpeedChanged(speed: Float)
    
}

class PWMIDIPlayer: AVMIDIPlayer {
    
    var currentMIDI: URL?
    var currentSoundfont: URL?
    
    weak var delegate: PWMIDIPlayerDelegate?
    
    private var progressTimer: Timer?
	
	private let endOfTrackTolerance = 0.1
    
    override var rate: Float {
        didSet {
			if #available(OSX 10.12.2, *) {
				NowPlayingCentral.shared.updateNowPlayingInfo(for: self, with: [MPNowPlayingInfoPropertyPlaybackRate : NSNumber(value: self.rate)])
			}
            self.delegate?.playbackSpeedChanged(speed: self.rate)
        }
    }
    
    override var currentPosition: TimeInterval {
        didSet {
            self.delegate?.playbackPositionChanged(position: self.currentPosition, duration: self.duration)
        }
    }
	
	/// A Boolean value that indicates whether the sequence is paused.
    var isPaused: Bool {
        get {
            return !self.isPlaying && !self.isAtEndOfTrack
        }
    }
	
	/// A Boolean value that indicates whether the sequence is stopped.
	var isAtEndOfTrack: Bool {
		get {
			return !self.isPlaying && self.currentPosition >= self.duration - self.endOfTrackTolerance
		}
	}
    
    class func guessSoundfontPath(forMIDI midiFile: URL) -> URL? {
        let midiDirectory = midiFile.deletingLastPathComponent()
		let midiDirParent = midiDirectory.deletingLastPathComponent()
		
		guard let fileNameWithoutExt = NSString(string: midiFile.lastPathComponent).deletingPathExtension.removingPercentEncoding else {
			return nil
		}
        
		// Super cheap way of checking for accompanying soundfonts:
		// Just check for soundfonts that have the same name as the MIDI file
		// or the containing directory
        let potentialSoundFonts = [
            // Soundfonts with same name as the MIDI file
            "\(midiDirectory.path)/\(fileNameWithoutExt).sf2",
            "\(midiDirectory.path)/\(fileNameWithoutExt).dls",
            
            // Soundfonts with same name as containing directory
            "\(midiDirectory.path)/\(midiDirectory.lastPathComponent).sf2",
            "\(midiDirectory.path)/\(midiDirectory.lastPathComponent).dls",
			
			// Soundfonts with same name as the parent directory
			"\(midiDirParent.path)/\(midiDirParent.lastPathComponent).sf2",
			"\(midiDirParent.path)/\(midiDirParent.lastPathComponent).dls"
        ]
        
        for psf in potentialSoundFonts {
            if FileManager.default.fileExists(atPath: psf) {
				Swift.print("Soundfont found: \(psf)")
                return URL(fileURLWithPath: psf)
			} else {
//				Swift.print("\(psf) does not exist")
			}
        }
		
		if Settings.shared.looseSFMatching {
			// Busting out the old Levenshtein string distance
			// as a "looser" soundfont detection method
			Swift.print("starting loose soundfont search")
			do {
				let directoryContents = try FileManager.default.contentsOfDirectory(at: midiDirectory, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
				
				let soundFontURLs = directoryContents.filter {
					$0.pathExtension.lowercased() == "dls" || $0.pathExtension.lowercased() == "sf2"
				}
				
				return soundFontURLs.min {
					let fileA = $0.lastPathComponent
					let fileB = $1.lastPathComponent
					
					return Levenshtein.distanceBetween(aStr: fileA, and: fileNameWithoutExt) <
					Levenshtein.distanceBetween(aStr: fileB, and: fileNameWithoutExt)
				}
			} catch {
				Swift.print(error.localizedDescription)
			}
		}
		
		Swift.print("no soundfont found")
        return nil
    }
	
    convenience init(withMIDI midiFile: URL, andSoundfont soundfontFile: URL? = nil) throws {
		try self.init(contentsOf: midiFile, soundBankURL: soundfontFile)
		
		self.currentMIDI = midiFile
		self.currentSoundfont = soundfontFile
	}
    
    deinit {
		Swift.print("PWMIDIPlayer: deinit")
		
		self.progressTimer?.invalidate()
		self.progressTimer = nil
		
		self.currentSoundfont?.stopAccessingSecurityScopedResource()
		
		self.delegate = nil
    }
    
    func timerDidFire(_ timer: Timer) {
        guard let _timer = self.progressTimer, _timer.isValid else {
            return
        }
		
		if #available(OSX 10.12.2, *) {
			// Updating the entire Now Playing dictionary here because macOS's caching(?) really fucks with us here
			// If I rely on the OS to keep track of song names, durations and whatnot, we'll desync in about 0.02 seconds
			NowPlayingCentral.shared.initNowPlayingInfo(for: self)
			NowPlayingCentral.shared.updateNowPlayingInfo(for: self, with: [MPNowPlayingInfoPropertyElapsedPlaybackTime : NSNumber(value: self.currentPosition)])
		}
		
        self.delegate?.playbackPositionChanged(position: self.currentPosition, duration: self.duration)
    }
	
	// MARK: - Overrides and convenience methods
    
    override func prepareToPlay() {
        super.prepareToPlay()

        self.delegate?.filesLoaded(midi: self.currentMIDI!, soundFont: self.currentSoundfont)
    }
	
    override func play(_ completionHandler: AVMIDIPlayerCompletionHandler? = nil) {
		if #available(OSX 10.12.2, *) {
			NowPlayingCentral.shared.makeActive(player: self)
		}
		
		if (self.currentPosition >= self.duration - self.endOfTrackTolerance) {
			self.currentPosition = 0
		}
		
		self.delegate?.playbackWillStart(firstTime: self.currentPosition == 0)
		
		super.play() {
			DispatchQueue.main.async {
				if (self.currentPosition >= self.duration - self.endOfTrackTolerance) {
					self.progressTimer?.invalidate()
					
					if #available(OSX 10.12.2, *) {
						NowPlayingCentral.shared.playbackState = .stopped
					}
					self.delegate?.playbackEnded()
				}
			}
            
			completionHandler?()
		}
        
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.125, repeats: true, block: timerDidFire)
		self.progressTimer!.tolerance = 0.125 / 8
		
		if #available(OSX 10.12.2, *), !Settings.shared.cacophonyMode {
			NowPlayingCentral.shared.initNowPlayingInfo(for: self)
			NowPlayingCentral.shared.playbackState = .playing
		}
		
        self.delegate?.playbackStarted(firstTime: self.currentPosition == 0)
    }
	
	// cheap, but it works. mostly
	func pause() {
		super.stop()
		
        self.progressTimer?.invalidate()
		
		if #available(OSX 10.12.2, *) {
        	NowPlayingCentral.shared.playbackState = .paused
		}
		
		self.delegate?.playbackStopped(paused: true)
	}
    
    override func stop() {
		super.stop()
		
        self.progressTimer?.invalidate()
		
		self.currentPosition = 0
		
		if #available(OSX 10.12.2, *) {
        	NowPlayingCentral.shared.playbackState = .stopped
		}
        
		self.delegate?.playbackStopped(paused: false)
    }
	
	func rewind(secs: TimeInterval) {
		let newPos = max(0, self.currentPosition - secs)
		self.currentPosition = newPos
	}
	
	func fastForward(secs: TimeInterval) {
		let newPos = min(self.currentPosition + secs, self.duration)
		self.currentPosition = newPos
	}
    
    func togglePlayPause() {
        if (self.isPaused || self.isAtEndOfTrack) {
            self.play()
        } else if (self.isPlaying) {
            self.pause()
        } else {
			self.stop()
        }
    }
	
}
