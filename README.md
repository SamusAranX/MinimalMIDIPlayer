# MinimalMIDIPlayer
A very simple app that does what is says on the tin. Also it has the worst name ever.

## Features
* Has a very minimal interface
* Plays MIDI files
* If there’s a soundfont with the same name as the MIDI file, MinimalMIDIPlayer will use that. Otherwise it’ll just use the macOS standard soundfont.
* You can open files with ⌘O, drop files on the app icon and the dock icon, or set this app as the default for all MIDI files: 

![MinimalMIDIPlayer as default app](https://cloud.githubusercontent.com/assets/676069/13197115/1fb342b0-d7e4-11e5-95ae-7f825b58cfd2.png)

## Requirements
* OS X 10.12+

## Screenshots

![The main interface. Finally, a real one.](https://user-images.githubusercontent.com/676069/34043994-98049e42-e1a3-11e7-895d-d1b2b0ea731a.png)
![The same interface, but with a file loaded and playing.](https://user-images.githubusercontent.com/676069/34043663-4c9c8006-e1a2-11e7-86b1-7642b07d34b1.png)

*Finally, a real interface that's not just a button.*

## Downloads

The latest download can be found in the Releases tab: https://github.com/SamusAranX/MinimalMIDIPlayer/releases/latest

## Known issues
* Because this is based on Apple’s own AVMIDIPlayer, customizability is basically non-existent. This thing can play MIDI files with custom soundfonts and that’s it.
* ~~Currently, this app only checks for SF2 files in the same folder. DLS support will come later.~~ *Added in v1.1*
* ~~This app will ignore all files that are dropped onto its dock icon. This, too, will be possible in a later version.~~ *Added in v1.2*
* Currently, the only way to use another soundfont is to rename it. Future versions will make the use of custom soundfonts easier.
* When pausing and un-pausing playback, some sounds might be silent until they get played again. This is normal behavior.
* The Notification Center's Now Playing section sometimes displays the wrong track duration. This is because the Now Playing API is shit and sadly, completely out of my control.

## Feedback and support
Just tweet at me [@SamusAranX](https://twitter.com/SamusAranX) or [drop me a mail](mailto:hallo@peterwunder.de).
Feel free to file an issue if you encounter any crashes, bugs, etc.: https://github.com/SamusAranX/MinimalMIDIPlayer/issues