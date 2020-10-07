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

	// MARK: - UserDefaults plumbing

	private init() {
		UserDefaults.standard.register(defaults: [
			"autoplay": false,
			"looseSFMatching": false,
			"cacophonyMode": false,
			"bounceBetaWarningShown": false
		])
	}

	public static func clear() {
		for key in UserDefaults.standard.dictionaryRepresentation().keys {
			UserDefaults.standard.removeObject(forKey: key)
		}
		UserDefaults.standard.synchronize()
	}

	// MARK: - UserDefaults bindings

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

	var bounceBetaWarningShown: Bool {
		get {
			return UserDefaults.standard.bool(forKey: #function)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: #function)
			UserDefaults.standard.synchronize()
		}
	}

	// MARK: - Helper properties and methods

	let SAMPLE_RATE: Double = 44100
	let CHANNELS: AVAudioChannelCount = 2

	var processingFormat: AVAudioFormat {
		// processing happens at twice the sample rate
		guard let format = AVAudioFormat(standardFormatWithSampleRate: self.SAMPLE_RATE * 2, channels: self.CHANNELS) else {
			fatalError("processingFormat")
		}

		return format
	}

	func getConverter(from format: AVAudioFormat) -> AVAudioConverter {
		guard let destFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: self.SAMPLE_RATE, channels: self.CHANNELS, interleaved: true) else {
			fatalError("AVAudioFormat initialization error")
		}

		guard let conv = AVAudioConverter(from: format, to: destFormat) else {
			fatalError("Converter initialization failed")
		}

//		conv.bitRateStrategy = AVAudioBitRateStrategy_Constant
//		conv.bitRate = 320
		conv.downmix = true

		conv.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_MinimumPhase
		conv.sampleRateConverterQuality = .max

		return conv

	}

}
