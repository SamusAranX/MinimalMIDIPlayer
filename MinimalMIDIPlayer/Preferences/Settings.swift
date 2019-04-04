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
			"sampleRate": 44100,
			"channels": 2
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

	var sampleRate: Int {
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

	// MARK: - Helper properties and methods

	var processingFormat: AVAudioFormat {
		guard let format = AVAudioFormat(standardFormatWithSampleRate: 96000, channels: 2) else {
			fatalError("processingFormat")
		}

		return format
	}

	var destinationFormat: AVAudioFormat {
		let cf = AVAudioCommonFormat.pcmFormatFloat32
		let sr = Double(self.sampleRate)
		let cc = AVAudioChannelCount(self.channels)

		guard let af = AVAudioFormat(commonFormat: cf, sampleRate: sr, channels: cc, interleaved: true) else {
			fatalError("AVAudioFormat initialization error")
		}

		return af
	}

	func getConverter(from format: AVAudioFormat, to destFormat: AVAudioFormat? = nil) -> AVAudioConverter {
		let destFormat = destFormat ?? self.destinationFormat
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
