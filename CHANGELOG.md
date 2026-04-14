## 0.2.1

* Fixed text editing — TextField now receives all input when in editing mode
* Fixed StyledTextController crash on text input (growable list)
* Fixed style array sync using prefix/suffix diff algorithm
* Bullet list now works per-selection (mix regular text with bullet items)
* Toolbar inherits parent note color

## 0.2.0

* Added `StyledTextController` for per-selection inline formatting (bold, italic, underline, strikethrough)
* Toolbar formatting now applies to selected text only, not the entire note
* Added dartdoc comments to all public API members
* Toolbar B/I/U/S buttons show disabled state when no text is selected

## 0.1.0

* Initial release
* 10 visual styles: classic, lined, grid, textured, dotted, crosshatch, kraft, blueprint, cork, linen
* Draggable, resizable sticky notes with bottom-edge resize handle
* Rotation via Space + left-drag or toolbar buttons
* Floating two-row text formatting toolbar with font picker, size, bold, italic, underline, strikethrough
* Text and note background color pickers
* Alignment controls, bullet list toggle, round corners toggle
* Lock/unlock notes
* StickyNoteBoard widget for multi-note management with z-ordering
* Google Fonts integration for handwriting font families
