//
//  AVAudioUnitMIDISynth.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 11.03.19.
//  Copyright © 2019 Peter Wunder. All rights reserved.
//

import Cocoa
import AVFoundation

class AVAudioUnitMIDISynth: AVAudioUnitMIDIInstrument {

	init(soundBankURL: URL?) throws {
		let description = AudioComponentDescription(
			componentType: kAudioUnitType_MusicDevice,
			componentSubType: kAudioUnitSubType_MIDISynth,
			componentManufacturer: kAudioUnitManufacturer_Apple,
			componentFlags: 0,
			componentFlagsMask: 0
		)

		super.init(audioComponentDescription: description)

		var soundfontURL = soundBankURL ?? URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")

		let status = AudioUnitSetProperty(
			self.audioUnit,
			AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
			AudioUnitScope(kAudioUnitScope_Global),
			0,
			&soundfontURL,
			UInt32(MemoryLayout<URL>.size))

		if status != OSStatus(noErr) {
			throw "\(status)"
		}
	}

	func setPreload(enabled: Bool) throws {
		guard let engine = self.engine else { throw "Synth must be connected to an engine." }
		if !engine.isRunning { throw "Engine must be running." }

		var enabledBit = enabled ? UInt32(1) : UInt32(0)

		let status = AudioUnitSetProperty(
			self.audioUnit,
			AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
			AudioUnitScope(kAudioUnitScope_Global),
			0,
			&enabledBit,
			UInt32(MemoryLayout<UInt32>.size))
		if status != noErr {
			throw "\(status)"
		}
	}
}
