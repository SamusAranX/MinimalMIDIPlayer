//
//  MIDIFileBouncer.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 11.03.19.
//  Copyright © 2019 Peter Wunder. All rights reserved.
//

import Cocoa
import AVFoundation

protocol MIDIFileBouncerDelegate: class {
	func bounceProgress(progress: Double)
	func bounceCompleted()
}

@available(OSX 10.13, *)
class MIDIFileOfflineBouncer {
	fileprivate var engine: AVAudioEngine!
	fileprivate var sampler: AVAudioUnitMIDISynth!
	fileprivate var sequencer: AVAudioSequencer!

	fileprivate var audioFormat: AVAudioFormat!

	fileprivate var cancelProcessing = false
	fileprivate var burnt = false

	var isCancelled: Bool {
		return self.cancelProcessing
	}

	weak var delegate: MIDIFileBouncerDelegate?

	deinit {
		self.engine.disconnectNodeInput(self.sampler, bus: 0)
		self.engine.detach(self.sampler)
		self.sequencer = nil
		self.sampler = nil
		self.engine = nil
	}

	init(midiFile: URL, soundfontFile: URL?) throws {
		self.engine = AVAudioEngine()

		self.sampler = try AVAudioUnitMIDISynth(soundBankURL: soundfontFile)

		self.engine.attach(self.sampler)

//		self.audioFormat = self.getUserFormat()
		self.audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
		print(self.audioFormat)

		let mixer = self.engine.mainMixerNode
		mixer.outputVolume = 0.0
		self.engine.connect(self.sampler, to: mixer, format: self.audioFormat)

		self.sequencer = AVAudioSequencer(audioEngine: self.engine)
		try self.sequencer.load(from: midiFile, options: [])
		self.sequencer.prepareToPlay()
	}

	func cancel() {
		self.cancelProcessing = true
	}

	fileprivate func getUserFormat() -> AVAudioFormat {
		var settings: [String: Any] = [:]

		settings[AVLinearPCMBitDepthKey] = Settings.shared.bitRate
		settings[AVLinearPCMIsFloatKey] = Settings.shared.bitRate == 32

		settings[AVSampleRateKey] = Settings.shared.sampleRate

		settings[AVNumberOfChannelsKey] = Settings.shared.channels
//		settings[AVLinearPCMIsNonInterleaved] = false

		guard let audioFormat = AVAudioFormat(settings: settings) else {
			fatalError("Invalid audio format")
		}

		return audioFormat
	}

	func bounceOffline(to fileURL: URL) throws {
		if self.burnt {
			fatalError("This instance is burnt. Please create a new instance instead of trying to render with this one a second time.")
		}

		self.burnt = true

		let duration = self.sequencer.tracks.map({ $0.lengthInSeconds + self.sequencer.seconds(forBeats: $0.offsetTime) }).max() ?? 0
		let outputFile = try AVAudioFile(forWriting: fileURL, settings: self.audioFormat.settings)

		try self.engine.enableManualRenderingMode(.offline, format: self.audioFormat, maximumFrameCount: 4096)

		print(self.engine.manualRenderingFormat)

		guard let buffer = AVAudioPCMBuffer(pcmFormat: self.engine.manualRenderingFormat, frameCapacity: self.engine.manualRenderingMaximumFrameCount) else {
			throw "Could not create buffer"
		}

		try self.engine.start()

		let targetSamples = AVAudioFramePosition(duration * self.audioFormat.sampleRate)
		while self.engine.manualRenderingSampleTime < targetSamples {
			do {
				if self.cancelProcessing {
					self.cancelProcessing = false
					break
				}

				let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(targetSamples - self.engine.manualRenderingSampleTime))
				let status = try self.engine.renderOffline(framesToRender, to: buffer)

				switch status {
				case .success:
					try outputFile.write(from: buffer)

					let progress = Double(self.engine.manualRenderingSampleTime) / Double(targetSamples) * 100
					self.delegate?.bounceProgress(progress: progress)
				case .cannotDoInCurrentContext:
					print("renderToFile cannotDoInCurrentContext")
					continue
				case .error, .insufficientDataFromInputNode:
					throw "renderToFile render error"
				@unknown default:
					fatalError("Unknown rendering status")
				}
			} catch {
				fatalError(error.localizedDescription)
			}
		}

		self.delegate?.bounceProgress(progress: 100)
		self.delegate?.bounceCompleted()

		self.engine.stop()
		self.engine.disableManualRenderingMode()
	}

//	@available(*, deprecated, message: "Use bounceOffline instead")
	func bounce(to fileURL: URL) throws {
		if self.burnt {
			fatalError("This instance is burnt. Please create a new instance instead of trying to render with this one a second time.")
		}

		self.burnt = true

		let outputNode = self.sampler!

		let sequenceLength = self.sequencer.tracks.map({ $0.lengthInSeconds + self.sequencer.seconds(forBeats: $0.offsetTime) }).max() ?? 0
		var writeError: NSError?
		let outputFile = try AVAudioFile(forWriting: fileURL, settings: outputNode.outputFormat(forBus: 0).settings)

		self.engine.prepare()
		try self.engine.start()

		// Get sequencer ready
		self.sequencer.currentPositionInSeconds = 0
		self.sequencer.prepareToPlay()

		// Start recording
		outputNode.installTap(onBus: 0, bufferSize: 4096, format: outputNode.outputFormat(forBus: 0)) { (buffer: AVAudioPCMBuffer, _) in
			do {
				try outputFile.write(from: buffer)
			} catch {
				writeError = error as NSError
			}
		}

		// Add silence to beginning
		usleep(200000)

		// Start playback.
		try self.sequencer.start()

		// Continuously check for track finished or error while looping.
		while self.sequencer.isPlaying && writeError == nil && self.sequencer.currentPositionInSeconds < sequenceLength {

			let progress = self.sequencer.currentPositionInSeconds / sequenceLength
			self.delegate?.bounceProgress(progress: progress * 100)

			usleep(100000)
		}

		// Ensure playback is stopped
		self.sequencer.stop()

		// Add 4 seconds of silence to end to ensure all notes have fully stopped playing
		usleep(4000000)

		// Stop recording.
		outputNode.removeTap(onBus: 0)
		self.engine.stop()

		self.delegate?.bounceCompleted()

		// Return error if there was any issue during recording.
		if let writeError = writeError {
			throw writeError
		}
	}
}
