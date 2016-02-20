# MinimalMIDIPlayer
A very simple app that does what is says on the tin. Also it has the worst name ever.

## Features
* Has a very minimal interface
* Plays MIDI files
* If there’s an SF2 file with the same name as the MIDI file, MinimalMIDIPlayer will use that as the soundfont. Otherwise it’ll just use the OS X standard soundfont.
* You can open files with ⌘O, drop files on the app icon, or set this app as the default for all MIDI files: ![MinimalMIDIPlayer as default app](https://cloud.githubusercontent.com/assets/676069/13197115/1fb342b0-d7e4-11e5-95ae-7f825b58cfd2.png)

## Requirements
* OS X 10.11

## Screenshots

![The main interface. Incredible, isn’t it?](https://cloud.githubusercontent.com/assets/676069/13197091/643d8e3c-d7e3-11e5-91a2-c2c5528ead68.png)

## Known issues
* Because this is based on Apple’s own AVMIDIPlayer, customizability is basically non-existent. This thing can play MIDI files with custom soundfonts and that’s it.
* Currently, this app only checks for SF2 files in the same folder. DLS support will come later.

## Feedback and support
Just tweet at me [@SamusAranX](https://twitter.com/SamusAranX) or [drop me a mail](mailto:hallo@peterwunder.de).
Feel free to file an issue if you encounter any crashes, bugs, etc.: https://github.com/SamusAranX/MinimalMIDIPlayer/issues