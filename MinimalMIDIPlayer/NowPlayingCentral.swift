//
//  NowPlayingCentral.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 07.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa
import MediaPlayer

class NowPlayingCentral: NSObject {

	static let shared = NowPlayingCentral()

	var playbackState: MPNowPlayingPlaybackState {
		get {
			return MPNowPlayingInfoCenter.default().playbackState
		}
		set {
			if !Settings.shared.cacophonyMode {
				MPNowPlayingInfoCenter.default().playbackState = newValue
			}
		}
	}

	private var players: [PWMIDIPlayer] = []
	private var activePlayer: PWMIDIPlayer? {
		return self.players.last
	}

	override init() {
		super.init()

		MPRemoteCommandCenter.shared().playCommand.addTarget(self, action: #selector(playCommand(event:)))
		MPRemoteCommandCenter.shared().pauseCommand.addTarget(self, action: #selector(pauseCommand(event:)))
//		MPRemoteCommandCenter.shared().stopCommand.addTarget(self, action: #selector(stopCommand(event:)))
		MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget(self, action: #selector(togglePlayPauseCommand(event:)))
		MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget(self, action: #selector(changePlaybackPositionCommand(event:)))
//		MPRemoteCommandCenter.shared().previousTrackCommand.addTarget(self, action: #selector(previousTrackCommand(event:)))
		MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = false
		MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = false

		MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget(self, action: #selector(skipBackwardCommand(event:)))
		MPRemoteCommandCenter.shared().skipForwardCommand.addTarget(self, action: #selector(skipForwardCommand(event:)))
		MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [NSNumber(value: 10)]
		MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [NSNumber(value: 10)]
		MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
		MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
	}

	// MARK: - Player Management

	/// Adds a player to the internal list of players if it isn't there already
	/// and then promotes it to be the active player, pausing all others.
	/// - Parameters:
	///     - player: The player to be added
	func makeActive(player: PWMIDIPlayer) {
		if self.players.contains(player), let playerIdx = self.players.firstIndex(of: player) {
			self.players.remove(at: playerIdx)
		}

		self.players.append(player)

		// Pause every PWMIDIPlayer instance except this one
		// but only if Cacophony Mode isn't enabled
		if !Settings.shared.cacophonyMode {
			for player in self.players.dropLast() {
				if player.isPlaying {
					player.pause()
				}
			}
		}
	}

	/// Removes a player from the internal list of players and sets the Now Playing
	/// data to that of the next player in the list, if present
	/// - Parameters:
	///     - player: The player to be removed
	func removeFromPlayers(player: PWMIDIPlayer?) {
		if let player = player, let playerIdx = self.players.firstIndex(of: player) {
			// Reset Now Playing info going in
			if player == self.activePlayer {
				self.resetNowPlayingInfo()
			}

			// Actually remove the player
			self.players.remove(at: playerIdx)

			// If there is a next player in the list, load its Now Playing data
			if let lastPlayer = self.players.last {
				self.initNowPlayingInfo(for: lastPlayer)
			}
		}
	}

	// MARK: - Now Playing Control

	/// Resets the Now Playing info dictionary to nil and sets the playback state to unknown
	func resetNowPlayingInfo() {
		MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
		self.playbackState = .unknown
	}

	func initNowPlayingInfo(for midiPlayer: PWMIDIPlayer) {
		guard midiPlayer == self.activePlayer else {
			return
		}

		let midiTitle = midiPlayer.currentMIDI!.deletingPathExtension().lastPathComponent
		let midiAlbumTitle = midiPlayer.currentSoundfont?.deletingPathExtension().lastPathComponent ?? midiPlayer.currentMIDI!.deletingLastPathComponent().lastPathComponent
		let midiArtist = "MinimalMIDIPlayer" // shameless advertising

		var nowPlayingInfo: [String: Any] = [
			MPNowPlayingInfoPropertyMediaType: NSNumber(value: MPNowPlayingInfoMediaType.audio.rawValue),
			MPNowPlayingInfoPropertyIsLiveStream: NSNumber(value: false),

			MPNowPlayingInfoPropertyDefaultPlaybackRate: NSNumber(value: Double(midiPlayer.rate)),
			MPNowPlayingInfoPropertyPlaybackProgress: NSNumber(value: midiPlayer.currentPosition),

			MPMediaItemPropertyTitle: midiTitle,
			MPMediaItemPropertyAlbumTitle: midiAlbumTitle,
			MPMediaItemPropertyArtist: midiArtist,

			MPMediaItemPropertyPlaybackDuration: NSNumber(value: midiPlayer.duration),
			MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: midiPlayer.currentPosition)
		]

		if #available(OSX 10.13.2, *) {
			nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 800, height: 800), requestHandler: { (_) -> NSImage in
				return NSImage(named: "AlbumArt")!
			})
		}

		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

		if midiPlayer.isPlaying {
			self.playbackState = .playing
		} else if midiPlayer.isPaused {
			self.playbackState = .paused
		} else if midiPlayer.isAtEndOfTrack {
			self.playbackState = .stopped
		}
	}

	func updateNowPlayingInfo(for midiPlayer: PWMIDIPlayer, with updatedDict: [String: Any]) {
		guard MPNowPlayingInfoCenter.default().nowPlayingInfo != nil, !Settings.shared.cacophonyMode else {
			return
		}

		for key in updatedDict.keys {
			MPNowPlayingInfoCenter.default().nowPlayingInfo![key] = updatedDict[key]
		}
	}

	// MARK: - MPRemoteCommandEvent Handlers

	@objc func playCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
		print("Play command")
		if let activePlayer = self.activePlayer, !Settings.shared.cacophonyMode {
			activePlayer.play()
			return .success
		}

		return .noActionableNowPlayingItem
	}

	@objc func pauseCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
		print("Pause command")
		if let activePlayer = self.activePlayer, !Settings.shared.cacophonyMode {
			activePlayer.pause()
			return .success
		}
		return .noActionableNowPlayingItem
	}

	@objc func stopCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
		print("Stop command")
		if let activePlayer = self.activePlayer, !Settings.shared.cacophonyMode {
			activePlayer.stop()
			return .success
		}
		return .noActionableNowPlayingItem
	}

	@objc func togglePlayPauseCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
		print("Play/Pause command")

		if let activePlayer = self.activePlayer, !Settings.shared.cacophonyMode {
			activePlayer.togglePlayPause()
			return .success
		}
		return .noActionableNowPlayingItem
	}

	@objc func changePlaybackPositionCommand(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
		if let activePlayer = self.activePlayer, !Settings.shared.cacophonyMode {
			activePlayer.currentPosition = event.positionTime
			return .success
		}

		return .noActionableNowPlayingItem
	}

	@objc func skipBackwardCommand(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
		if let activePlayer = self.activePlayer, !Settings.shared.cacophonyMode {
			activePlayer.rewind(secs: event.interval)
			return .success
		}
		return .noActionableNowPlayingItem
	}

	@objc func skipForwardCommand(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
		if let activePlayer = self.activePlayer, !Settings.shared.cacophonyMode {
			activePlayer.fastForward(secs: event.interval)
			return .success
		}
		return .noActionableNowPlayingItem
	}

}
