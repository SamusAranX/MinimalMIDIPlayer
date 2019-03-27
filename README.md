# MinimalMIDIPlayer
A very simple app that does what it says on the tin.

## Features

* Plays MIDI files
* Available in German 🇩🇪
* If there’s a soundfont with the same name as the MIDI file, MinimalMIDIPlayer will use that. Otherwise it’ll use the macOS standard soundfont.
	* This behavior can be overridden to load custom soundfonts
* Supports macOS Mojave's new Dark Mode
* Supports the Notification Center's Now Playing widget as well as the MacBook Pro's Touch Bar
* Keyboard shortcuts!
	* <kbd>Space</kbd> toggles playback
	* <kbd>↑</kbd> and <kbd>↓</kbd> adjust the playback speed
	* <kbd>←</kbd> and <kbd>→</kbd> respectively skip backwards or ahead by 10 seconds
		* or 5 seconds if you use <kbd>⇧</kbd><kbd>←</kbd> and <kbd>⇧</kbd><kbd>→</kbd>
	* Alternatively, use the standard media keys
* You can open files with ⌘O, drop files on the app icon and the dock icon, or set this app as the default for all MIDI files:

![MinimalMIDIPlayer as the default app](https://user-images.githubusercontent.com/676069/54680606-8daa1180-4b0a-11e9-8022-1304132ef143.png)

## Requirements

* macOS 10.12+
	* On macOS 10.12, media controls will not be available. They require macOS 10.13 or newer.

## Screenshots
![Playing e1m1.mid](https://user-images.githubusercontent.com/676069/50861150-24828100-1398-11e9-8c0d-af94397676b7.png)
![The Preferences window](https://user-images.githubusercontent.com/676069/55073593-60231200-508e-11e9-8c72-9458753bbfb3.png)
![The About window](https://user-images.githubusercontent.com/676069/55073568-513c5f80-508e-11e9-9a53-89dd95463f7d.png)
![The Now Playing widget in the Notification Center](https://user-images.githubusercontent.com/676069/45410936-40d51200-b673-11e8-84b4-085dde88cf44.png)

## Downloads
The latest download can be found in the Releases tab: https://github.com/SamusAranX/MinimalMIDIPlayer/releases/latest

## Known issues

* Because this is based on Apple’s own AVMIDIPlayer, customizability is basically non-existent. This app can play MIDI files with custom soundfonts and that’s it.
* Some soundfonts may cause **very** loud pops when starting playback. This is a bug in Apple's AVMIDIPlayer.
* When pausing and un-pausing playback, some sounds might be silent until they get played again. This is expected behavior and not a bug.
* When using the Touch Bar or the Now Playing widget to skip to another part of the track, the track might sound out of tune. This can happen if the MIDI you're listening to uses lots of Pitch Bends and is expected behavior.
* The Notification Center's Now Playing section sometimes gets out of sync with the currently playing track. This is because the Now Playing API is buggy and more or less expected behavior.
* ~~Currently, this app only checks for SF2 files in the same folder. DLS support will come later.~~ ***Added in v1.1***
* ~~This app will ignore all files that are dropped onto its dock icon. This, too, will be possible in a later version.~~ ***Added in v1.2***
* ~~Currently, the only way to use another soundfont is to rename it. Future versions will make the use of custom soundfonts easier.~~ ***Added in v1.5***

## Feedback and support
Just tweet at me [@SamusAranX](https://twitter.com/SamusAranX) or [drop me a mail](mailto:hallo@peterwunder.de).
Feel free to file an issue if you encounter any crashes, bugs, etc.: https://github.com/SamusAranX/MinimalMIDIPlayer/issues