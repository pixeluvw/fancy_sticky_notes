# Fancy Sticky Notes

A fully-featured sticky note widget package for Flutter. Create beautiful, interactive sticky notes with 10 visual styles, rich text formatting, drag-to-move, resize, rotation, and a floating toolbar — all out of the box.

## Features

- **10 visual styles** — classic, lined, grid, textured, dotted, crosshatch, kraft, blueprint, cork, linen
- **Rich text formatting** — bold, italic, underline, strikethrough, font size, text color
- **8 handwriting fonts** via Google Fonts — Caveat, Patrick Hand, Indie Flower, Shadows Into Light, Kalam, Architects Daughter, Gloria Hallelujah
- **Drag to move** — left-click and drag any note
- **Resize** — drag the bottom edge of a focused note
- **Rotate** — hold Space + left-drag, or use toolbar rotation buttons
- **Floating toolbar** — two-row, touch-friendly formatting bar appears on double-tap
- **Note background colors** — 10 preset colors, changeable per note
- **Text alignment** — left, center, right
- **Bullet list toggle** — auto-prefixes lines with bullet points
- **Round corners toggle** — switch between paper-curl and rounded rectangle shapes
- **Lock/unlock** — prevent accidental edits or movement
- **Z-ordering** — tap a note to bring it to front
- **Custom textures** — overlay an `ImageProvider` on the `textured` style
- **Minimized mode** — collapse a note to a single-line strip

## Getting Started

Add the dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  fancy_sticky_notes: ^0.1.0
  neuron: ^1.6.1
```

Then import the packages:

```dart
import 'package:fancy_sticky_notes/fancy_sticky_notes.dart';
import 'package:neuron/neuron.dart';
```

## Usage

### Quick Start with Neuron

The recommended way to use this package is with [Neuron](https://pub.dev/packages/neuron) state management. Create a controller to manage your board state, then use `Slot` widgets for reactive UI.

#### 1. Define a controller

```dart
class BoardController extends NeuronController {
  late final notes = signal<List<StickyNoteModel>>([]);
  late final background = signal(BoardBackground.corkboard);
  late final nextStyle = signal(StickyNoteStyle.classic);
  late final noteCount = computed(() => notes.val.length);

  @override
  void onInit() {
    notes.emit([
      StickyNoteModel(
        id: 'note_1',
        position: const Offset(50, 80),
        textController: TextEditingController(text: 'Hello!'),
        style: StickyNoteStyle.classic,
        color: const Color(0xFFFFFF99),
        fontFamily: 'Caveat',
        fontSize: 22,
      ),
      StickyNoteModel(
        id: 'note_2',
        position: const Offset(300, 120),
        rotation: 0.05,
        textController: TextEditingController(text: 'Second note'),
        style: StickyNoteStyle.lined,
        color: const Color(0xFFE0F7FA),
      ),
    ]);
  }

  void addNote() {
    final note = StickyNoteModel(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      position: Offset(100 + Random().nextDouble() * 400, 100 + Random().nextDouble() * 300),
      style: nextStyle.val,
      textController: TextEditingController(),
    );
    notes.emit([...notes.val, note]);
  }

  void removeNote(String id) {
    notes.emit(notes.val.where((n) => n.id != id).toList());
  }

  void clearAll() => notes.emit([]);
  void cycleBackground() { /* cycle through BoardBackground values */ }
  void setNextStyle(StickyNoteStyle style) => nextStyle.emit(style);

  static BoardController get init => Neuron.ensure(() => BoardController());
}
```

#### 2. Bootstrap with NeuronApp

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BoardController.init;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NeuronApp(
      title: 'Fancy Sticky Notes Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}
```

#### 3. Build the UI with Slot

```dart
class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = BoardController.init;

    return Scaffold(
      appBar: AppBar(
        title: Slot<int>(
          connect: ctrl.noteCount,
          to: (_, count) => Text('Sticky Notes ($count)'),
        ),
      ),
      body: Slot<List<StickyNoteModel>>(
        connect: ctrl.notes,
        to: (_, noteList) => StickyNoteBoard(
          initialNotes: noteList,
          background: Container(color: Colors.brown.shade100),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ctrl.addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Why Neuron?

| Feature | StatefulWidget | Neuron |
|---|---|---|
| State declaration | `setState(() { ... })` | `signal<T>(value)` / `computed(() => ...)` |
| Rebuild scope | Entire widget | Only the `Slot` wrapping the signal |
| Boilerplate | `initState`, `dispose`, `setState` | `onInit`, auto-dispose via `register()` |
| Multi-signal | Manual rebuild coordination | `MultiSlot.t2`...`t6` |
| Async data | `FutureBuilder` / `StreamBuilder` | `asyncSignal` + `AsyncSlot` |
| Singleton access | Provider / InheritedWidget | `Neuron.ensure(() => Controller())` |

### Interactions

| Action | Gesture |
|---|---|
| Move a note | Left-click drag on the note body |
| Edit text | Double-tap the note |
| Resize | Drag the bottom edge (visible when focused) |
| Rotate | Hold **Space** + left-drag on the note body |
| Rotate (toolbar) | Use the rotate-left / rotate-right buttons |
| Bring to front | Tap any note |
| Unfocus | Tap the background |

### Standalone StickyNote Widget

Use `StickyNote` directly for full control over state and gestures. With Neuron, you can drive it with signals:

```dart
class NoteController extends NeuronController {
  late final position = signal(const Offset(100, 100));
  late final width = signal(220.0);
  late final height = signal(220.0);
  late final rotation = signal(0.0);
  late final isEditing = signal(false);

  static NoteController get init => Neuron.ensure(() => NoteController());
}

// In your widget:
final ctrl = NoteController.init;

MultiSlot.t5(
  connect: (ctrl.position, ctrl.width, ctrl.height, ctrl.rotation, ctrl.isEditing),
  to: (_, pos, w, h, rot, editing) => StickyNote(
    width: w,
    height: h,
    rotation: rot,
    isEditing: editing,
    isFocused: true,
    style: StickyNoteStyle.grid,
    color: const Color(0xFFF3E5F5),
    fontFamily: 'Indie Flower',
    textController: myTextController,
    onDrag: (delta) => ctrl.position.emit(pos + delta),
    onResize: (delta) {
      ctrl.width.emit((w + delta.dx).clamp(120.0, 800.0));
      ctrl.height.emit((h + delta.dy).clamp(120.0, 800.0));
    },
    onRotate: (delta) => ctrl.rotation.emit(rot + delta),
    onDoubleTap: () => ctrl.isEditing.emit(true),
  ),
);
```

## API Reference

### StickyNoteStyle

An enum defining the visual style of the note background.

| Value | Description |
|---|---|
| `classic` | Solid color with a subtle vertical gradient |
| `lined` | Yellow legal pad with horizontal blue lines and a red margin |
| `grid` | Light gray grid of squares |
| `textured` | Custom `ImageProvider` overlay (crinkled paper, etc.) |
| `dotted` | Scattered small dots pattern |
| `crosshatch` | Diagonal cross-hatched pencil lines |
| `kraft` | Kraft/recycled brown paper with speckled noise |
| `blueprint` | Dark blue background with white grid lines |
| `cork` | Warm brown with darker fiber-like speckles |
| `linen` | Subtle woven horizontal and vertical threads |

### StickyNoteModel

Mutable data model representing one note on a `StickyNoteBoard`.

```dart
StickyNoteModel(
  // Required
  id: 'unique_id',

  // Position & size
  position: const Offset(100, 100), // default: Offset.zero
  width: 200,                       // default: 200
  height: 200,                      // default: 200
  rotation: 0.0,                    // radians, default: 0.0

  // Text
  textController: TextEditingController(text: 'My note'),
  fontSize: 18.0,                   // default: 18.0
  fontWeight: FontWeight.normal,    // default: FontWeight.normal
  fontFamily: 'Caveat',            // default: 'Default'
  textColor: const Color(0xFF1A1A1A),
  textAlign: TextAlign.left,

  // Text decoration
  italic: false,
  underline: false,
  strikethrough: false,

  // Visual
  style: StickyNoteStyle.classic,
  color: const Color(0xFFFFFF99),   // note background color
  texture: null,                     // ImageProvider for textured style
  roundCorners: false,
  bulletList: false,

  // State
  isEditing: false,
  isLocked: false,

  // Custom content (used instead of textController if provided)
  child: null,
);
```

### StickyNote

The core widget rendering a single sticky note. All gestures (drag, resize, rotate) are handled internally to avoid gesture arena conflicts.

#### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `style` | `StickyNoteStyle` | `classic` | Visual style preset |
| `color` | `Color` | `0xFFFFFF99` | Note background color |
| `width` | `double` | `200` | Note width in logical pixels |
| `height` | `double` | `200` | Note height in logical pixels |
| `rotation` | `double` | `0.0` | Rotation angle in radians |
| `roundCorners` | `bool` | `false` | Use rounded rectangle instead of paper-curl shape |
| `texture` | `ImageProvider?` | `null` | Texture overlay for `textured` style |
| `opacity` | `double` | `1.0` | Note opacity (0.0 to 1.0) |
| `textController` | `TextEditingController?` | `null` | Text content controller |
| `focusNode` | `FocusNode?` | `null` | Focus node for text editing |
| `isEditing` | `bool` | `false` | Whether the text field is editable |
| `isFocused` | `bool` | `false` | Whether the note shows resize handles |
| `isLocked` | `bool` | `false` | Prevents drag, resize, rotate |
| `isPinned` | `bool` | `false` | Shows a pin indicator |
| `isMinimized` | `bool` | `false` | Collapses note to a single-line strip |
| `fontSize` | `double` | `18.0` | Text font size |
| `fontWeight` | `FontWeight` | `normal` | Text font weight |
| `fontFamily` | `String` | `'Default'` | Font family name (Google Fonts or system) |
| `textColor` | `Color` | `0xFF1A1A1A` | Text color |
| `textAlign` | `TextAlign` | `left` | Text alignment |
| `italic` | `bool` | `false` | Italic text |
| `underline` | `bool` | `false` | Underlined text |
| `strikethrough` | `bool` | `false` | Strikethrough text |
| `child` | `Widget?` | `null` | Custom content (replaces text field) |

#### Callbacks

| Callback | Type | Description |
|---|---|---|
| `onDrag` | `ValueChanged<Offset>?` | Called with delta offset during left-drag |
| `onResize` | `ValueChanged<Offset>?` | Called with delta offset during bottom-edge drag |
| `onRotate` | `ValueChanged<double>?` | Called with delta angle during Space+drag |
| `onDoubleTap` | `VoidCallback?` | Called on double-tap (typically enters edit mode) |
| `onTap` | `VoidCallback?` | Called on single tap |

### StickyNoteBoard

A ready-to-use board widget that manages multiple `StickyNoteModel` instances. Provides drag-to-move, resize, rotation, z-ordering, and a floating text formatting toolbar.

```dart
// With Neuron — reactive rebuild when notes change
Slot<List<StickyNoteModel>>(
  connect: ctrl.notes,
  to: (_, noteList) => StickyNoteBoard(
    initialNotes: noteList,
    background: Container(color: Colors.brown.shade100),
  ),
);
```

#### Floating Toolbar

The toolbar appears automatically when a note with a `textController` is double-tapped. It has two rows:

**Row 1 — Text formatting:**
- Font family picker (8 handwriting fonts)
- Font size controls (+/-)
- Bold, italic, underline, strikethrough toggles
- Text color picker (10 presets)
- Note background color picker (10 presets)

**Row 2 — Layout & controls:**
- Text alignment (left, center, right)
- Bullet list toggle pill
- Round corners toggle pill
- Rotation buttons (left, reset, right)
- Lock/unlock pill

### StickyNotePainter

The `CustomPainter` responsible for rendering the note background, shadow, and decorative overlays. Exposed for advanced use cases.

```dart
// Access the paper shape path (useful for custom clipping)
final path = StickyNotePainter.paperPath(
  const Size(200, 200),
  roundCorners: false,
);
```

### fontStyleFor

Helper function that returns a `TextStyle` for a given font family name using Google Fonts.

```dart
final style = fontStyleFor(
  'Caveat',
  fontSize: 22,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);
```

#### Available font families

| Name | Style |
|---|---|
| `'Default'` | System font |
| `'Caveat'` | Casual handwriting |
| `'Patrick Hand'` | Clean handwriting |
| `'Indie Flower'` | Playful handwriting |
| `'Shadows Into Light'` | Light, airy handwriting |
| `'Kalam'` | Informal handwriting |
| `'Architects Daughter'` | Technical handwriting |
| `'Gloria Hallelujah'` | Bold, expressive handwriting |

## Examples

### Full example with Neuron controller

The `example/` directory contains a complete app with a `BoardController` that manages:

| Signal | Type | Purpose |
|---|---|---|
| `notes` | `Signal<List<StickyNoteModel>>` | All notes on the board |
| `focusedNoteId` | `Signal<String?>` | Currently focused note |
| `background` | `Signal<BoardBackground>` | Board background preset |
| `nextStyle` | `Signal<StickyNoteStyle>` | Style for newly added notes |
| `noteCount` | `computed` | Derived count for the app bar |

Actions: `addNote()`, `removeNote(id)`, `clearAll()`, `cycleBackground()`, `setNextStyle()`

### Locked note

```dart
StickyNoteModel(
  id: 'locked',
  position: const Offset(400, 100),
  textController: TextEditingController(text: 'Cannot move or edit me'),
  isLocked: true,
  style: StickyNoteStyle.classic,
  color: const Color(0xFFFFCDD2),
  textColor: const Color(0xFFC62828),
);
```

### Blueprint style with centered white text

```dart
StickyNoteModel(
  id: 'blueprint',
  position: const Offset(50, 300),
  width: 240,
  height: 220,
  textController: TextEditingController(text: 'BLUEPRINT\nDark mode paper'),
  style: StickyNoteStyle.blueprint,
  fontSize: 20,
  fontWeight: FontWeight.bold,
  textColor: Colors.white,
  textAlign: TextAlign.center,
  fontFamily: 'Gloria Hallelujah',
);
```

### Custom child widget instead of text

```dart
StickyNoteModel(
  id: 'custom',
  position: const Offset(200, 200),
  style: StickyNoteStyle.dotted,
  color: const Color(0xFFC8E6C9),
  child: Column(
    children: [
      const Icon(Icons.check_circle, color: Colors.green, size: 48),
      const SizedBox(height: 8),
      const Text('All done!', style: TextStyle(fontSize: 18)),
    ],
  ),
);
```

### Textured note with image overlay

```dart
StickyNoteModel(
  id: 'textured',
  position: const Offset(100, 100),
  style: StickyNoteStyle.textured,
  texture: const AssetImage('assets/crinkled_paper.jpg'),
  textController: TextEditingController(text: 'Paper texture!'),
);
```

## Architecture

```
lib/
  fancy_sticky_notes.dart          # Barrel export
  src/
    sticky_note_style.dart         # StickyNoteStyle enum (10 styles)
    sticky_note_painter.dart       # CustomPainter + CustomClipper
    sticky_note.dart               # StickyNote widget (StatefulWidget)
    sticky_note_board.dart         # StickyNoteBoard + StickyNoteModel + toolbar

example/
  lib/
    board_controller.dart          # Neuron controller with signals & actions
    main.dart                      # App bootstrap & Slot-based UI
```

| File | Responsibility |
|---|---|
| `sticky_note_style.dart` | The `StickyNoteStyle` enum |
| `sticky_note_painter.dart` | `StickyNotePainter` (shadow, background, style overlays), `StickyNoteClipper`, and `paperPath()` |
| `sticky_note.dart` | `StickyNote` widget with internal gesture handling (drag, resize, rotate) |
| `sticky_note_board.dart` | `StickyNoteBoard`, `StickyNoteModel`, `fontStyleFor()`, floating toolbar and its sub-widgets |
| `board_controller.dart` | `BoardController` — Neuron controller managing notes, background, and style signals |
| `main.dart` | App entry point — bootstraps controller, uses `Slot` for reactive rendering |

## Dependencies

- [flutter](https://flutter.dev) (SDK)
- [google_fonts](https://pub.dev/packages/google_fonts) — handwriting font families
- [neuron](https://pub.dev/packages/neuron) — state management (example app)

## License

MIT License. See [LICENSE](LICENSE) for details.
