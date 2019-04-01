//
//  MIDIFileBouncer.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 11.03.19.
//  Copyright © 2019 Peter Wunder. All rights reserved.
//

import Cocoa
import AVFoundation

class MIDIFileBouncer {
	fileprivate var engine: AVAudioEngine!
	fileprivate var sampler: AVAudioUnitMIDISynth!
	fileprivate var sequencer: AVAudioSequencer!

	deinit {
		self.engine.disconnectNodeInput(self.sampler, bus: 0)
		self.engine.detach(self.sampler)
		self.sequencer = nil
		self.sampler = nil
		self.engine = nil
	}

	init(midiFileData: Data, soundBankURL: URL) throws {
		self.engine = AVAudioEngine()
		self.sampler = try AVAudioUnitMIDISynth(soundBankURL: soundBankURL)

		self.engine.attach(self.sampler)

		// We'll tap the sampler output directly for recording
		// and mute the mixer output so that bouncing is silent to the user.
		let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
		let mixer = self.engine.mainMixerNode
		mixer.outputVolume = 1.0
		self.engine.connect(self.sampler, to: mixer, format: audioFormat)

		self.sequencer = AVAudioSequencer(audioEngine: self.engine)
		try self.sequencer.load(from: midiFileData, options: [])
		self.sequencer.prepareToPlay()
	}

	func bounce(toFileURL fileURL: URL) throws {
		let outputNode = self.sampler!

		let sequenceLength = self.sequencer.tracks.map({ $0.lengthInSeconds }).max() ?? 0
		var writeError: NSError?
		let outputFile = try AVAudioFile(forWriting: fileURL, settings: outputNode.outputFormat(forBus: 0).settings)

		self.engine.prepare()
		try self.engine.start()

		// Load the patches by playing the sequence through in preload mode.
		//		self.sequencer.rate = 100.0
		//		self.sequencer.currentPositionInSeconds = 0
		//		self.sequencer.prepareToPlay()
		//
		//		try self.sampler.setPreload(enabled: true)
		//		try self.sequencer.start()
		//		while (self.sequencer.isPlaying
		//			&& self.sequencer.currentPositionInSeconds < sequenceLength) {
		//				usleep(100000)
		//		}
		//		self.sequencer.stop()
		//		usleep(2000000) // ensure all notes have rung out
		//		try self.sampler.setPreload(enabled: false)
		//		self.sequencer.rate = 1.0

		// Get sequencer ready again.
		self.sequencer.currentPositionInSeconds = 0
		self.sequencer.prepareToPlay()

		// Start recording.
		outputNode.installTap(onBus: 0, bufferSize: 4096, format: outputNode.outputFormat(forBus: 0)) { (buffer: AVAudioPCMBuffer, _) in
			do {
				try outputFile.write(from: buffer)
			} catch {
				writeError = error as NSError
			}
		}

		// Add silence to beginning.
		usleep(200000)

		// Start playback.
		try self.sequencer.start()

		// Continuously check for track finished or error while looping.
		while self.sequencer.isPlaying && writeError == nil && self.sequencer.currentPositionInSeconds < sequenceLength {
				usleep(100000)
		}

		// Ensure playback is stopped.
		self.sequencer.stop()

		// Add silence to end.
		usleep(2500000)

		// Stop recording.
		outputNode.removeTap(onBus: 0)
		self.engine.stop()

		// Return error if there was any issue during recording.
		if let writeError = writeError {
			throw writeError
		}
	}
}
