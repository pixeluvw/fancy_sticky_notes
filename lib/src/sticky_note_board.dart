import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sticky_note_style.dart';
import 'styled_text_controller.dart';
import 'sticky_note.dart';

/// Preset text colors for the color picker.
const List<Color> _kTextColors = [
  Color(0xFF1A1A1A),
  Color(0xFF424242),
  Color(0xFFFFFFFF),
  Color(0xFFC62828),
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFE65100),
  Color(0xFF6A1B9A),
  Color(0xFF00838F),
  Color(0xFFF9A825),
];

/// Preset note background colors.
const List<Color> _kNoteColors = [
  Color(0xFFFFFF99), // yellow
  Color(0xFFFFCDD2), // pink
  Color(0xFFE0F7FA), // cyan
  Color(0xFFF3E5F5), // lavender
  Color(0xFFC8E6C9), // green
  Color(0xFFFFE0B2), // orange
  Color(0xFFBBDEFB), // blue
  Color(0xFFFFF9C4), // light yellow
  Color(0xFFD7CCC8), // brown
  Color(0xFFFFFFFF), // white
];

/// Available handwriting font families.
const List<String> _kFontFamilies = [
  'Default',
  'Caveat',
  'Patrick Hand',
  'Indie Flower',
  'Shadows Into Light',
  'Kalam',
  'Architects Daughter',
  'Gloria Hallelujah',
];

/// Returns a [TextStyle] for the given font family name using Google Fonts.
TextStyle fontStyleFor(String family, {double? fontSize, FontWeight? fontWeight, Color? color}) {
  final base = TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
  switch (family) {
    case 'Caveat':
      return GoogleFonts.caveat(textStyle: base);
    case 'Patrick Hand':
      return GoogleFonts.patrickHand(textStyle: base);
    case 'Indie Flower':
      return GoogleFonts.indieFlower(textStyle: base);
    case 'Shadows Into Light':
      return GoogleFonts.shadowsIntoLight(textStyle: base);
    case 'Kalam':
      return GoogleFonts.kalam(textStyle: base);
    case 'Architects Daughter':
      return GoogleFonts.architectsDaughter(textStyle: base);
    case 'Gloria Hallelujah':
      return GoogleFonts.gloriaHallelujah(textStyle: base);
    default:
      return base;
  }
}

/// Mutable data model representing a single sticky note on the board.
///
/// Use with [StickyNoteBoard] or pass individual fields to a [StickyNote].
/// For per-character inline formatting, supply a [StyledTextController]
/// as the [textController].
class StickyNoteModel {
  /// Unique identifier for the note.
  final String id;

  /// Position of the note's top-left corner on the board.
  Offset position;

  /// Rotation angle in radians.
  double rotation;

  /// Note width in logical pixels.
  double width;

  /// Note height in logical pixels.
  double height;

  /// Optional custom child widget (displayed instead of the text field).
  final Widget? child;

  /// Controller for editable text. Use [StyledTextController] for
  /// per-selection inline formatting (bold, italic, underline, strikethrough).
  final TextEditingController? textController;

  /// Focus node managed internally by the board.
  final FocusNode focusNode = FocusNode();

  /// Whether the note is currently in text-editing mode.
  bool isEditing;

  /// Base font size in logical pixels.
  double fontSize;

  /// Base font weight for all text.
  FontWeight fontWeight;

  /// Text color.
  Color textColor;

  /// Text alignment within the note.
  TextAlign textAlign;

  /// Font family name (Google Fonts or `'Default'`).
  String fontFamily;

  /// Note-level strikethrough flag (plain controller only).
  bool strikethrough;

  /// Note-level underline flag (plain controller only).
  bool underline;

  /// Note-level italic flag (plain controller only).
  bool italic;

  /// Whether the note is locked (prevents move, resize, rotate).
  bool isLocked;

  /// Whether to use fully rounded corners.
  bool roundCorners;

  /// Whether bullet-list prefixes are active.
  bool bulletList;

  /// Visual style preset for the note background.
  final StickyNoteStyle style;

  /// Background color of the note (mutable via the toolbar).
  Color color;

  /// Optional texture image for the [StickyNoteStyle.textured] style.
  final ImageProvider? texture;

  StickyNoteModel({
    required this.id,
    this.position = Offset.zero,
    this.rotation = 0.0,
    this.width = 200,
    this.height = 200,
    this.child,
    this.textController,
    this.isEditing = false,
    this.isLocked = false,
    this.roundCorners = false,
    this.bulletList = false,
    this.strikethrough = false,
    this.underline = false,
    this.italic = false,
    this.fontSize = 18.0,
    this.fontWeight = FontWeight.normal,
    this.textColor = const Color(0xFF1A1A1A),
    this.textAlign = TextAlign.left,
    this.fontFamily = 'Default',
    this.style = StickyNoteStyle.classic,
    this.color = const Color(0xFFFFFF99),
    this.texture,
  });
}

/// A board that manages multiple sticky notes with dragging, resizing,
/// rotation, locking, font switching, and a floating text formatting toolbar.
class StickyNoteBoard extends StatefulWidget {
  /// The initial list of notes to display on the board.
  final List<StickyNoteModel> initialNotes;

  /// Optional background widget rendered behind all notes.
  final Widget? background;

  /// Called when a note is deleted via the toolbar. Receives the note [id].
  final ValueChanged<String>? onNoteDeleted;

  const StickyNoteBoard({
    super.key,
    required this.initialNotes,
    this.background,
    this.onNoteDeleted,
  });

  @override
  State<StickyNoteBoard> createState() => _StickyNoteBoardState();
}

class _StickyNoteBoardState extends State<StickyNoteBoard> {
  late List<StickyNoteModel> _notes;
  StickyNoteModel? _focusedNote;

  @override
  void initState() {
    super.initState();
    _notes = List.of(widget.initialNotes);
  }

  void _bringToFrontAndFocus(StickyNoteModel note) {
    setState(() {
      _notes.remove(note);
      _notes.add(note);
      _focusedNote = note;
    });
  }

  void _unfocus() {
    if (_focusedNote != null) {
      FocusScope.of(context).unfocus();
      setState(() {
        _focusedNote!.isEditing = false;
        _focusedNote = null;
      });
    }
  }

  void _deleteNote(StickyNoteModel note) {
    setState(() {
      _notes.remove(note);
      _focusedNote = null;
    });
    widget.onNoteDeleted?.call(note.id);
  }

  // ── Bullet list helpers ──────────────────────────────────────────────

  /// Toggles bullet prefixes on the selected lines (or the current line
  /// if no selection). Lines outside the selection are left unchanged,
  /// so you can mix regular text with bullet items in the same note.
  void _toggleBulletList(StickyNoteModel note) {
    final ctrl = note.textController;
    if (ctrl == null) return;

    final sel = ctrl.selection;
    final text = ctrl.text;

    // Find line range that overlaps the selection / cursor
    final selStart = sel.isValid ? sel.start : text.length;
    final selEnd = sel.isValid ? sel.end : text.length;

    // Walk back to the start of the first affected line
    int lineStart = text.lastIndexOf('\n', selStart > 0 ? selStart - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;

    // Walk forward to the end of the last affected line
    int lineEnd = text.indexOf('\n', selEnd);
    if (lineEnd == -1) lineEnd = text.length;

    final before = text.substring(0, lineStart);
    final affected = text.substring(lineStart, lineEnd);
    final after = text.substring(lineEnd);

    // Check if ALL affected lines already have bullets → remove; otherwise add
    final lines = affected.split('\n');
    final allBulleted = lines.every((l) => l.trimLeft().startsWith('• '));

    final transformed = lines.map((l) {
      final trimmed = l.trimLeft();
      if (allBulleted) {
        // Remove bullet
        return trimmed.startsWith('• ') ? trimmed.substring(2) : trimmed;
      } else {
        // Add bullet
        return trimmed.startsWith('• ') ? l : '• $trimmed';
      }
    }).join('\n');

    final newText = before + transformed + after;
    final cursorPos = (before.length + transformed.length).clamp(0, newText.length);

    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPos),
    );

    setState(() {
      // Update the pill state based on whether any line in the note has bullets
      note.bulletList = newText.split('\n').any((l) => l.trimLeft().startsWith('• '));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _unfocus,
          behavior: HitTestBehavior.opaque,
          child: widget.background ?? Container(color: Colors.transparent),
        ),

        ..._notes.map((note) {
          final isFocused = _focusedNote == note;
          return Positioned(
            left: note.position.dx,
            top: note.position.dy,
            child: Listener(
              onPointerDown: (_) => _bringToFrontAndFocus(note),
              behavior: HitTestBehavior.translucent,
              child: StickyNote(
                style: note.style,
                color: note.color,
                rotation: note.rotation,
                width: note.width,
                height: note.height,
                roundCorners: note.roundCorners,
                texture: note.texture,
                textController: note.textController,
                focusNode: note.focusNode,
                isEditing: note.isEditing,
                fontSize: note.fontSize,
                fontWeight: note.fontWeight,
                textColor: note.textColor,
                textAlign: note.textAlign,
                fontFamily: note.fontFamily,
                strikethrough: note.strikethrough,
                underline: note.underline,
                italic: note.italic,
                isFocused: isFocused,
                isLocked: note.isLocked,
                onDoubleTap: () {
                  setState(() { note.isEditing = true; });
                  note.focusNode.requestFocus();
                },
                onDrag: (delta) {
                  setState(() { note.position += delta; });
                },
                onResize: note.isLocked
                    ? null
                    : (delta) {
                        setState(() {
                          note.width = (note.width + delta.dx).clamp(120.0, 800.0);
                          note.height = (note.height + delta.dy).clamp(120.0, 800.0);
                        });
                      },
                onRotate: note.isLocked
                    ? null
                    : (delta) {
                        setState(() { note.rotation += delta; });
                      },
                child: note.child,
              ),
            ),
          );
        }),

        // ── Floating Toolbar ─────────────────────────────────────────────
        if (_focusedNote != null && _focusedNote!.textController != null && _focusedNote!.isEditing)
          Builder(builder: (context) {
            final note = _focusedNote!;
            return Positioned(
              left: note.position.dx,
              top: note.position.dy - 108,
              child: _FloatingToolbar(
                note: note,
                onChanged: () => setState(() {}),
                onToggleBulletList: () => _toggleBulletList(note),
                onDelete: () => _deleteNote(note),
              ),
            );
          }),

        // ── Hint bar below focused note ──────────────────────────────────
        if (_focusedNote != null && _focusedNote!.isEditing)
          Builder(builder: (context) {
            final note = _focusedNote!;
            return Positioned(
              left: note.position.dx,
              top: note.position.dy + note.height + 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mouse, size: 13, color: Colors.white70),
                    SizedBox(width: 5),
                    Text(
                      'Drag to move  |  Bottom edge to resize  |  Space + drag to rotate',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Floating Toolbar — two-row, touch-friendly
// ═══════════════════════════════════════════════════════════════════════════

const Color _kActive = Color(0xFF1565C0);

class _FloatingToolbar extends StatefulWidget {
  final StickyNoteModel note;
  final VoidCallback onChanged;
  final VoidCallback onToggleBulletList;
  final VoidCallback onDelete;

  const _FloatingToolbar({
    required this.note,
    required this.onChanged,
    required this.onToggleBulletList,
    required this.onDelete,
  });

  @override
  State<_FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<_FloatingToolbar> {
  StyledTextController? _styledCtrl;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant _FloatingToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.textController != widget.note.textController) {
      _unbindController();
      _bindController();
    }
  }

  void _bindController() {
    final ctrl = widget.note.textController;
    if (ctrl is StyledTextController) {
      _styledCtrl = ctrl;
      _styledCtrl!.addListener(_onControllerChanged);
    }
  }

  void _unbindController() {
    _styledCtrl?.removeListener(_onControllerChanged);
    _styledCtrl = null;
  }

  void _onControllerChanged() {
    // Rebuild to update B/I/U/S active states when selection moves
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _unbindController();
    super.dispose();
  }

  // ── Inline style helpers ───────────────────────────────────────────

  bool _isStyleActive(InlineStyle style) {
    return _styledCtrl?.selectionHasStyle(style) ?? false;
  }

  void _toggle(InlineStyle style) {
    _styledCtrl?.toggleStyle(style);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final onChanged = widget.onChanged;
    final hasSelection = _styledCtrl != null &&
        _styledCtrl!.selection.isValid &&
        !_styledCtrl!.selection.isCollapsed;

    // Derive toolbar background from note color — lighten and desaturate
    final noteHsl = HSLColor.fromColor(note.color);
    final toolbarBg = noteHsl
        .withLightness((noteHsl.lightness * 0.3 + 0.7).clamp(0.0, 0.97))
        .withSaturation((noteHsl.saturation * 0.4).clamp(0.0, 1.0))
        .toColor();
    final borderColor = noteHsl
        .withLightness((noteHsl.lightness * 0.5 + 0.3).clamp(0.0, 0.85))
        .withSaturation((noteHsl.saturation * 0.3).clamp(0.0, 1.0))
        .toColor();

    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: toolbarBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ══════════ Row 1 — Font, size & text style ══════════
              Row(
                children: [
                  _FontPicker(note: note, onChanged: onChanged),
                  const SizedBox(width: 6),
                  // Size
                  _tapIcon(Icons.remove_circle_outline, 'Smaller', null, () {
                    note.fontSize = (note.fontSize - 2).clamp(10.0, 72.0);
                    onChanged();
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '${note.fontSize.toInt()}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  _tapIcon(Icons.add_circle_outline, 'Larger', null, () {
                    note.fontSize = (note.fontSize + 2).clamp(10.0, 72.0);
                    onChanged();
                  }),
                  const SizedBox(width: 4),
                  _hDiv(),
                  const SizedBox(width: 4),
                  // Bold / Italic / Underline / Strikethrough — per selection
                  _toggleIcon(Icons.format_bold,
                    hasSelection ? 'Bold selection' : 'Select text first',
                    _isStyleActive(InlineStyle.bold),
                    hasSelection ? () => _toggle(InlineStyle.bold) : null),
                  _toggleIcon(Icons.format_italic,
                    hasSelection ? 'Italic selection' : 'Select text first',
                    _isStyleActive(InlineStyle.italic),
                    hasSelection ? () => _toggle(InlineStyle.italic) : null),
                  _toggleIcon(Icons.format_underlined,
                    hasSelection ? 'Underline selection' : 'Select text first',
                    _isStyleActive(InlineStyle.underline),
                    hasSelection ? () => _toggle(InlineStyle.underline) : null),
                  _toggleIcon(Icons.format_strikethrough,
                    hasSelection ? 'Strikethrough selection' : 'Select text first',
                    _isStyleActive(InlineStyle.strikethrough),
                    hasSelection ? () => _toggle(InlineStyle.strikethrough) : null),
                  const SizedBox(width: 4),
                  _hDiv(),
                  const SizedBox(width: 4),
                  // Text color · Note color
                  _ColorPickerBtn(
                    tooltip: 'Text Color',
                    currentColor: note.textColor,
                    colors: _kTextColors,
                    onSelected: (c) { note.textColor = c; onChanged(); },
                  ),
                  const SizedBox(width: 2),
                  _ColorPickerBtn(
                    tooltip: 'Note Color',
                    currentColor: note.color,
                    colors: _kNoteColors,
                    icon: Icons.palette,
                    onSelected: (c) { note.color = c; onChanged(); },
                  ),
                ],
              ),

              // Divider between rows
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(height: 1, color: borderColor),
              ),

              // ══════════ Row 2 — Alignment, pills, rotation, lock ══════════
              Row(
                children: [
                  // Alignment
                  _toggleIcon(Icons.format_align_left, 'Left',
                    note.textAlign == TextAlign.left,
                    () { note.textAlign = TextAlign.left; onChanged(); }),
                  _toggleIcon(Icons.format_align_center, 'Center',
                    note.textAlign == TextAlign.center,
                    () { note.textAlign = TextAlign.center; onChanged(); }),
                  _toggleIcon(Icons.format_align_right, 'Right',
                    note.textAlign == TextAlign.right,
                    () { note.textAlign = TextAlign.right; onChanged(); }),
                  const SizedBox(width: 4),
                  _hDiv(),
                  const SizedBox(width: 4),
                  // Pills
                  _pill(Icons.format_list_bulleted, 'List', note.bulletList, widget.onToggleBulletList),
                  const SizedBox(width: 6),
                  _pill(Icons.rounded_corner, 'Round', note.roundCorners, () {
                    note.roundCorners = !note.roundCorners; onChanged();
                  }),
                  const SizedBox(width: 4),
                  _hDiv(),
                  const SizedBox(width: 4),
                  // Rotation
                  _tapIcon(Icons.rotate_left, 'Rotate left', null, () {
                    note.rotation -= 0.05; onChanged();
                  }),
                  _tapIcon(Icons.restart_alt, 'Reset',
                    note.rotation != 0.0 ? const Color(0xFFE65100) : null, () {
                    note.rotation = 0.0; onChanged();
                  }),
                  _tapIcon(Icons.rotate_right, 'Rotate right', null, () {
                    note.rotation += 0.05; onChanged();
                  }),
                  const SizedBox(width: 4),
                  _hDiv(),
                  const SizedBox(width: 4),
                  // Lock
                  _pill(
                    note.isLocked ? Icons.lock : Icons.lock_open,
                    note.isLocked ? 'Unlock' : 'Lock',
                    note.isLocked,
                    () { note.isLocked = !note.isLocked; onChanged(); },
                    activeColor: const Color(0xFFC62828),
                  ),
                  const SizedBox(width: 4),
                  _hDiv(),
                  const SizedBox(width: 4),
                  // Delete
                  _tapIcon(Icons.delete_outline, 'Delete note',
                    const Color(0xFFC62828), widget.onDelete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Building Blocks ────────────────────────────────────────────────────

  static Widget _tapIcon(IconData icon, String tooltip, Color? tint, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: tint ?? Colors.grey.shade700),
        ),
      ),
    );
  }

  static Widget _toggleIcon(IconData icon, String tooltip, bool active, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active ? _kActive.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20,
            color: !enabled
                ? Colors.grey.shade400
                : active ? _kActive : Colors.grey.shade700),
        ),
      ),
    );
  }

  static Widget _hDiv() {
    return Container(width: 1, height: 24, color: Colors.grey.shade300);
  }

  static Widget _pill(
    IconData icon, String label, bool active, VoidCallback onTap, {
    Color activeColor = _kActive,
  }) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active ? activeColor.withValues(alpha: 0.12) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: active ? activeColor : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? activeColor : Colors.grey.shade700),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? activeColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Font Picker
// ═══════════════════════════════════════════════════════════════════════════

class _FontPicker extends StatelessWidget {
  final StickyNoteModel note;
  final VoidCallback onChanged;

  const _FontPicker({required this.note, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Font',
      constraints: const BoxConstraints(maxWidth: 200),
      offset: const Offset(0, -200),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade100,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 60),
              child: Text(
                note.fontFamily == 'Default' ? 'Font' : note.fontFamily,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 14),
          ],
        ),
      ),
      onSelected: (family) {
        note.fontFamily = family;
        onChanged();
      },
      itemBuilder: (context) {
        return _kFontFamilies.map((family) {
          final isSelected = note.fontFamily == family;
          final style = family == 'Default'
              ? const TextStyle(fontSize: 14)
              : fontStyleFor(family, fontSize: 14);
          return PopupMenuItem<String>(
            value: family,
            child: Row(
              children: [
                Expanded(child: Text(family, style: style)),
                if (isSelected)
                  const Icon(Icons.check, size: 16, color: Color(0xFF1565C0)),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Color Picker Button
// ═══════════════════════════════════════════════════════════════════════════

class _ColorPickerBtn extends StatelessWidget {
  final String tooltip;
  final Color currentColor;
  final List<Color> colors;
  final IconData? icon;
  final ValueChanged<Color> onSelected;

  const _ColorPickerBtn({
    required this.tooltip,
    required this.currentColor,
    required this.colors,
    this.icon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Color>(
      tooltip: tooltip,
      offset: const Offset(0, -120),
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          PopupMenuItem<Color>(
            enabled: false,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((c) {
                final isSelected = currentColor == c;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade400,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ];
      },
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: icon != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, size: 16, color: Colors.grey.shade700),
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 3,
                        decoration: BoxDecoration(
                          color: currentColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  ),
                ),
        ),
      ),
    );
  }
}
