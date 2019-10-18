//
//  AudioFormats.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 02.04.19.
//  Copyright © 2019 Peter Wunder. All rights reserved.
//

import Foundation
import AVFoundation

enum AudioFormats: AudioFormatID {
	case LinearPCM = 1819304813 // kAudioFormatLinearPCM
	case MPEG4AAC = 1633772320 // kAudioFormatMPEG4AAC
	case MPEGLayer3 = 778924083 // kAudioFormatMPEGLayer3
	case FLAC = 1718378851 // kAudioFormatFLAC
	case AppleLossless = 1634492771 // kAudioFormatAppleLossless
}
