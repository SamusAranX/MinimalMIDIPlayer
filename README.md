# MinimalMIDIPlayer
A very simple app that does what is says on the tin. Also it has the worst name ever.

## Features
* Plays MIDI files
* If there’s a soundfont with the same name as the MIDI file, MinimalMIDIPlayer will use that. Otherwise it’ll just use the macOS standard soundfont.
* Supports macOS Mojave's new Dark Mode
* Supports the Notification Center's Now Playing widget as well as the newer MacBook Pro's Touch Bar
* Keyboard shortcuts!
	* <kbd>Space</kbd> toggles playback
	* <kbd>↑</kbd> and <kbd>↓</kbd> adjust the playback speed
	* <kbd>←</kbd> resets the playback position to the start of the track
	* <kbd>→</kbd> stops the playback
* You can open files with ⌘O, drop files on the app icon and the dock icon, or set this app as the default for all MIDI files: 

![MinimalMIDIPlayer as default app](https://user-images.githubusercontent.com/676069/44947578-21d2b680-ae0f-11e8-93d5-596cce9c3f91.png)

## Requirements
* OS X 10.13+

## Screenshots

![Light Mode](https://user-images.githubusercontent.com/676069/44947559-da4c2a80-ae0e-11e8-9a2f-357b6bb50ce1.png)
![Dark Mode](https://user-images.githubusercontent.com/676069/44947558-d91afd80-ae0e-11e8-8c28-c0dc4df701a5.png)

## Downloads

The latest download can be found in the Releases tab: https://github.com/SamusAranX/MinimalMIDIPlayer/releases/latest

## Known issues
* Because this is based on Apple’s own AVMIDIPlayer, customizability is basically non-existent. This thing can play MIDI files with custom soundfonts and that’s it.
* ~~Currently, this app only checks for SF2 files in the same folder. DLS support will come later.~~ *Added in v1.1*
* ~~This app will ignore all files that are dropped onto its dock icon. This, too, will be possible in a later version.~~ *Added in v1.2*
* Currently, the only way to use another soundfont is to rename it. Future versions will make the use of custom soundfonts easier.
* When pausing and un-pausing playback, some sounds might be silent until they get played again. This is not expected behavior and not a bug.
* When using the Touch Bar or the Now Playing widget to skip to another part of the track, the track might sound out of tune. This can happen if the MIDI you're listening to uses lots of Pitch Bends and is expected behavior.

## Feedback and support
Just tweet at me [@SamusAranX](https://twitter.com/SamusAranX) or [drop me a mail](mailto:hallo@peterwunder.de).
Feel free to file an issue if you encounter any crashes, bugs, etc.: https://github.com/SamusAranX/MinimalMIDIPlayer/issues