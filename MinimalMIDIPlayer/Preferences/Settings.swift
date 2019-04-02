//
//  Settings.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 06.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa
import AVFoundation

class Settings {

	static let shared = Settings()

	var autoplay: Bool {
		get {
			return UserDefaults.standard.bool(forKey: #function)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: #function)
			UserDefaults.standard.synchronize()
		}
	}

	var looseSFMatching: Bool {
		get {
			return UserDefaults.standard.bool(forKey: #function)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: #function)
			UserDefaults.standard.synchronize()
		}
	}

	var cacophonyMode: Bool {
		get {
			return UserDefaults.standard.bool(forKey: #function)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: #function)
			UserDefaults.standard.synchronize()
		}
	}

	var sampleRate: Int {
		get {
			return UserDefaults.standard.integer(forKey: #function)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: #function)
			UserDefaults.standard.synchronize()
		}
	}

	var bitDepth: Int {
		get {
			return UserDefaults.standard.integer(forKey: #function)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: #function)
			UserDefaults.standard.synchronize()
		}
	}

	var channels: Int {
		get {
			return UserDefaults.standard.integer(forKey: #function)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: #function)
			UserDefaults.standard.synchronize()
		}
	}

	var processingFormat: AVAudioFormat {
		guard let format = AVAudioFormat(standardFormatWithSampleRate: 96000, channels: 2) else {
			fatalError("processingFormat")
		}

		return format
	}

	var destinationFormat: AVAudioFormat {
		guard let referenceIntFormat = AVAudioFormat(commonFormat: .pcmFormatInt32, sampleRate: Double(self.sampleRate), channels: AVAudioChannelCount(self.channels), interleaved: true),
			let referenceFloatFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(self.sampleRate), channels: AVAudioChannelCount(self.channels), interleaved: true) else {
				fatalError()
		}

		var outDesc: AudioStreamBasicDescription
		if self.bitDepth == 1616 || self.bitDepth == 32 {
			outDesc = referenceFloatFormat.streamDescription.pointee
		} else {
			outDesc = referenceIntFormat.streamDescription.pointee
		}

		switch self.bitDepth {
		case 8:
			outDesc.mBitsPerChannel = 8
		case 16, 1616:
			outDesc.mBitsPerChannel = 16
		case 32:
			outDesc.mBitsPerChannel = 32
		default:
			fatalError("Unexpected bit depth \(self.bitDepth)")
		}

		outDesc.mBytesPerFrame = outDesc.mBitsPerChannel * outDesc.mChannelsPerFrame / 8
		outDesc.mBytesPerPacket = outDesc.mBytesPerFrame * outDesc.mFramesPerPacket

		guard let audioFormat = AVAudioFormat(streamDescription: &outDesc) else {
			fatalError("AVAudioFormat initialization error")
		}

		return audioFormat
	}

	func getConverter(from format: AVAudioFormat, to destFormat: AVAudioFormat? = nil) -> AVAudioConverter {
		let destFormat = destFormat ?? self.destinationFormat
		guard let conv = AVAudioConverter(from: format, to: destFormat) else {
			fatalError("Converter initialization failed")
		}

		if destinationFormat.channelCount < format.channelCount {
			conv.downmix = true
		}

//		conv.bitRateStrategy = AVAudioBitRateStrategy_Constant

		conv.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_MinimumPhase
		conv.sampleRateConverterQuality = .max

		return conv

	}

	private init() {
		UserDefaults.standard.register(defaults: [
			"autoplay": false,
			"looseSFMatching": false,
			"cacophonyMode": false,
			"sampleRate": 44100,
			"bitDepth": 16,
			"channels": 2
		])
	}

	public static func clear() {
		for key in UserDefaults.standard.dictionaryRepresentation().keys {
			UserDefaults.standard.removeObject(forKey: key)
		}
		UserDefaults.standard.synchronize()
	}

}
