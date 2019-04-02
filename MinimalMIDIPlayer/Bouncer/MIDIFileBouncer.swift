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
	func bounceError(error: Error)
	func bounceCompleted()
}

@available(OSX 10.13, *)
class MIDIFileBouncer {
	fileprivate var engine: AVAudioEngine!
	fileprivate var sampler: AVAudioUnitMIDISynth!
	fileprivate var sequencer: AVAudioSequencer!

	fileprivate let audioFormat: AVAudioFormat

	fileprivate var cancelProcessing = false

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

		//		self.audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(Settings.shared.sampleRate), channels: AVAudioChannelCount(Settings.shared.channels))
		//		self.audioFormat = Settings.shared.destinationFormat
		self.audioFormat = Settings.shared.processingFormat

		let mixer = self.engine.mainMixerNode
		mixer.outputVolume = 0.0
		self.engine.connect(self.sampler, to: mixer, format: Settings.shared.processingFormat)

		self.sequencer = AVAudioSequencer(audioEngine: self.engine)
		try self.sequencer.load(from: midiFile, options: [])
		self.sequencer.prepareToPlay()
	}

	func cancel() {
		self.cancelProcessing = true
	}

	func bounce(to fileURL: URL) {
		var writeError: NSError?

		let recordLeading = 0.2
		let recordTrailing = 2.0

		let outputNode = self.sampler!
		let outputFormat = outputNode.outputFormat(forBus: 0)

		guard let sequenceLength = self.sequencer.tracks.map({ $0.lengthInSeconds + self.sequencer.seconds(forBeats: $0.offsetTime) }).max() else {
			fatalError()
		}

		let converter = Settings.shared.getConverter(from: outputFormat)

		let outputFile: AVAudioFile
		do {
//			outputFile = try AVAudioFile(forWriting: fileURL, settings: outputFormat.settings)
			outputFile = try AVAudioFile(forWriting: fileURL, settings: converter.outputFormat.settings, commonFormat: .pcmFormatInt16, interleaved: true)
//			outputFile = try AVAudioFile(forWriting: fileURL, settings: converter.outputFormat.settings)
		} catch {
			self.delegate?.bounceError(error: error)
			return
		}

		// Install tap
		outputNode.installTap(onBus: 0, bufferSize: 8192, format: nil) { (buffer: AVAudioPCMBuffer, _) in
			do {
				let sampleRateRatio = outputFormat.sampleRate / converter.outputFormat.sampleRate
				let capacity = UInt32(Double(buffer.frameCapacity) / sampleRateRatio)

				let convertedBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: capacity)!
				convertedBuffer.frameLength = convertedBuffer.frameCapacity

				let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
					outStatus.pointee = AVAudioConverterInputStatus.haveData
					return buffer
				}
				let _ = converter.convert(to: convertedBuffer, error: &writeError, withInputFrom: inputBlock)
				print(writeError == nil)

				print(outputFile.processingFormat)
				print(converter.outputFormat)

				try outputFile.write(from: convertedBuffer)
			} catch {
				writeError = error as NSError
			}
		}

		// Get sequencer ready
		self.sequencer.currentPositionInSeconds = 0
		self.sequencer.prepareToPlay()

		self.engine.prepare()

		do {
			try self.engine.start()
		} catch {
			self.delegate?.bounceError(error: error)
			return
		}

		// Add silence to beginning
		usleep(useconds_t(recordLeading * 1000 * 1000))

		// Start playback.
		do {
			try self.sequencer.start()
		} catch {
			self.delegate?.bounceError(error: error)
			return
		}

		// Continuously check for track finished or error while looping.
		while self.sequencer.isPlaying && !self.cancelProcessing && writeError == nil && self.sequencer.currentPositionInSeconds < sequenceLength {

			let progress = self.sequencer.currentPositionInSeconds / sequenceLength
			self.delegate?.bounceProgress(progress: progress * 100)

			usleep(10000)
		}

		// Ensure playback is stopped
		self.sequencer.stop()

		if writeError == nil {
			// Add x seconds of silence to end to ensure all notes have fully stopped playing
			usleep(useconds_t(recordTrailing * 1000 * 1000))
			self.delegate?.bounceProgress(progress: 100)
		}

		// Stop recording.
		outputNode.removeTap(onBus: 0)
		self.engine.stop()


		// Return error if there was any issue during recording.
		if let writeError = writeError {
			self.delegate?.bounceError(error: writeError)
		} else {
			self.delegate?.bounceCompleted()
		}
	}
}
