//
//  Settings.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 06.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa

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
	
	private init() {
		UserDefaults.standard.register(defaults: [
			"autoplay": false,
			"looseSFMatching": false,
			"cacophonyMode": false
		])
	}
	
	public static func clear() {
		for key in UserDefaults.standard.dictionaryRepresentation().keys {
			UserDefaults.standard.removeObject(forKey: key)
		}
		UserDefaults.standard.synchronize()
	}

}
