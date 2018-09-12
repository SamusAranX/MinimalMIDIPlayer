# MinimalMIDIPlayer

![About window header](https://user-images.githubusercontent.com/676069/45408048-8857a000-b66b-11e8-85de-f6381ecc2f81.png)
A very simple app that does what is says on the tin.

## Features
* Plays MIDI files
* If there’s a soundfont with the same name as the MIDI file, MinimalMIDIPlayer will use that. Otherwise it’ll just use the macOS standard soundfont.
* That behavior can be overridden to load custom soundfonts
* Supports macOS Mojave's new Dark Mode (by using it all the time like QuickTime Player)
* Supports the Notification Center's Now Playing widget as well as the newer MacBook Pro's Touch Bar
* Keyboard shortcuts!
	* <kbd>Space</kbd> toggles playback
	* <kbd>↑</kbd> and <kbd>↓</kbd> adjust the playback speed
	* <kbd>←</kbd> resets the playback position to the start of the track
	* <kbd>→</kbd> stops the playback
	* Alternatively, use the standard media keys
* You can open files with ⌘O, drop files on the app icon and the dock icon, or set this app as the default for all MIDI files:

![MinimalMIDIPlayer as default app](https://user-images.githubusercontent.com/676069/45409818-880dd380-b670-11e8-8ad6-49f6b97abcd3.png)

## Requirements
* OS X 10.13+

## Screenshots

![Playing e1m1.mid](https://user-images.githubusercontent.com/676069/45410932-3e72b800-b673-11e8-8df8-5de9a935094c.png)
![The Now Playing widget in the Notification Center](https://user-images.githubusercontent.com/676069/45410936-40d51200-b673-11e8-84b4-085dde88cf44.png)

## Downloads

The latest download can be found in the Releases tab: https://github.com/SamusAranX/MinimalMIDIPlayer/releases/latest

## Known issues
* Because this is based on Apple’s own AVMIDIPlayer, customizability is basically non-existent. This thing can play MIDI files with custom soundfonts and that’s it.
* ~~Currently, this app only checks for SF2 files in the same folder. DLS support will come later.~~ ***Added in v1.1***
* ~~This app will ignore all files that are dropped onto its dock icon. This, too, will be possible in a later version.~~ ***Added in v1.2***
* ~~Currently, the only way to use another soundfont is to rename it. Future versions will make the use of custom soundfonts easier.~~ ***Added in v1.5***
* When pausing and un-pausing playback, some sounds might be silent until they get played again. This is expected behavior and not a bug.
* When using the Touch Bar or the Now Playing widget to skip to another part of the track, the track might sound out of tune. This can happen if the MIDI you're listening to uses lots of Pitch Bends and is expected behavior.
* The Notification Center's Now Playing section sometimes gets out of sync with the currently playing track. This is because the Now Playing API is buggy and more or less expected behavior.

## Feedback and support
Just tweet at me [@SamusAranX](https://twitter.com/SamusAranX) or [drop me a mail](mailto:hallo@peterwunder.de).
Feel free to file an issue if you encounter any crashes, bugs, etc.: https://github.com/SamusAranX/MinimalMIDIPlayer/issues