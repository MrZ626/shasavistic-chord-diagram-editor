# Shasavistic Chord Diagram Editor

> An editor for creating and editing chord diagrams

Original Theory & Design from **LΛMPLIGHT**:
[YouTube](https://www.youtube.com/@L4MPLIGHT)
[Website](https://lamplight0.sakura.ne.jp/a/)

Diagram Code (experimental) made by MrZ_26

## Installation

### Windows

1. Clone/Download this repository
2. Download love2d engine from https://love2d.org/
3. Drag the project folder onto `love.exe`

### Linux

1. Clone/Download this repository
2. Get love2d engine from your package manager
3. Run `love .` in the project folder

## Manual

### Edit

`Number 1~7`: add new note at current position  
Hold `Shift` to add downwards  
Hold `Ctrl` to delete note

`.`: set/unset selected note as skipped note

`/`: set/unset selected note as base note

`Backspace`: remove selected note

### Navigation

`Space`: play selected note

`Arrow Up/Down`: move cursor up/down (to next note)  
Hold `Ctrl` to scroll vertically  
Hold `Alt` to move current chord up/down, (default to 2d move, hold 1~7 to change move distance)

`Arrow Left/Right`: move cursor to previous/next chord  
Hold `Ctrl` to scroll horizontally  
Hold `Alt` to move selected note to left/right side

`Enter`: add a new chord to the right of the current chord

`Delete`: delete current chord

`Mouse Wheel Up/Down`: scroll the view  
Hold `Shift` to scroll horizontally  
Or use mouse drag to scroll

### Copy & Paste

`Ctrl+C`: copy all chord codes to clipboard

`Ctrl+V`: paste chord codes from clipboard
