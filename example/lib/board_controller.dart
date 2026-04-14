import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fancy_sticky_notes/fancy_sticky_notes.dart';
import 'package:neuron/neuron.dart';

/// Available background presets for the board.
enum BoardBackground { corkboard, darkWood, whiteCanvas, chalkboard }

/// Controller managing the sticky note board state.
class BoardController extends NeuronController {
  // ── Signals ────────────────────────────────────────────────────────────

  late final notes = signal<List<StickyNoteModel>>([]);
  late final focusedNoteId = signal<String?>(null);
  late final background = signal(BoardBackground.corkboard);
  late final nextStyle = signal(StickyNoteStyle.classic);

  // ── Computed ───────────────────────────────────────────────────────────

  late final noteCount = computed(() => notes.val.length);

  // ── Palette ────────────────────────────────────────────────────────────

  static const _noteColors = [
    Color(0xFFFFFF99), // yellow
    Color(0xFFFFCDD2), // pink
    Color(0xFFE0F7FA), // cyan
    Color(0xFFF3E5F5), // lavender
    Color(0xFFC8E6C9), // green
    Color(0xFFFFE0B2), // orange
    Color(0xFFBBDEFB), // blue
    Color(0xFFFFF9C4), // light yellow
  ];

  static const _fontFamilies = [
    'Caveat',
    'Patrick Hand',
    'Indie Flower',
    'Shadows Into Light',
    'Kalam',
    'Architects Daughter',
    'Gloria Hallelujah',
    'Default',
  ];

  final _rng = math.Random();

  // ── Init ───────────────────────────────────────────────────────────────

  @override
  void onInit() {
    _seedNotes();
  }

  void _seedNotes() {
    final seeds = <StickyNoteModel>[
      _makeNote(
        id: 'note_1',
        position: const Offset(30, 60),
        rotation: -0.04,
        style: StickyNoteStyle.classic,
        color: const Color(0xFFFFFF99),
        text: 'Classic Note\n\nDouble-click to edit!',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        fontFamily: 'Caveat',
      ),
      _makeNote(
        id: 'note_2',
        position: const Offset(270, 40),
        rotation: 0.06,
        style: StickyNoteStyle.lined,
        color: const Color(0xFFFDE876),
        width: 240,
        height: 260,
        text: 'TODO:\n- Fix bugs\n- Drink coffee\n- Ship it!',
        fontSize: 18,
        fontFamily: 'Patrick Hand',
      ),
      _makeNote(
        id: 'note_3',
        position: const Offset(550, 60),
        rotation: -0.08,
        style: StickyNoteStyle.grid,
        color: const Color(0xFFE0F7FA),
        text: 'Engineering Grid\nPerfect for diagrams',
        fontSize: 16,
        fontFamily: 'Architects Daughter',
      ),
      _makeNote(
        id: 'note_4',
        position: const Offset(30, 330),
        rotation: 0.03,
        style: StickyNoteStyle.dotted,
        color: const Color(0xFFF3E5F5),
        width: 210,
        height: 210,
        text: 'Dotted paper!\nGreat for bullet journals',
        fontSize: 16,
        textColor: const Color(0xFF6A1B9A),
        fontFamily: 'Indie Flower',
      ),
      _makeNote(
        id: 'note_5',
        position: const Offset(280, 340),
        rotation: -0.05,
        style: StickyNoteStyle.crosshatch,
        color: const Color(0xFFFFF9C4),
        text: 'Crosshatch\nSketch paper feel',
        fontSize: 18,
        fontFamily: 'Shadows Into Light',
      ),
      _makeNote(
        id: 'note_6',
        position: const Offset(530, 340),
        rotation: 0.07,
        style: StickyNoteStyle.kraft,
        width: 220,
        height: 200,
        text: 'Kraft paper\nRecycled & organic',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        textColor: const Color(0xFF3E2723),
        fontFamily: 'Kalam',
      ),
      _makeNote(
        id: 'note_7',
        position: const Offset(30, 590),
        rotation: -0.02,
        style: StickyNoteStyle.blueprint,
        width: 230,
        height: 220,
        text: 'BLUEPRINT\nDark mode paper',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
        textAlign: TextAlign.center,
        fontFamily: 'Gloria Hallelujah',
      ),
      _makeNote(
        id: 'note_8',
        position: const Offset(300, 600),
        rotation: 0.04,
        style: StickyNoteStyle.cork,
        text: 'Cork texture\nLike a pinboard!',
        fontSize: 16,
        textColor: const Color(0xFFFFFFFF),
      ),
      _makeNote(
        id: 'note_9',
        position: const Offset(550, 590),
        rotation: -0.06,
        style: StickyNoteStyle.linen,
        color: const Color(0xFFF5F5DC),
        width: 210,
        height: 210,
        text: 'Linen canvas\nSubtle woven texture',
        fontSize: 18,
        textColor: const Color(0xFF424242),
        fontFamily: 'Caveat',
      ),
      _makeNote(
        id: 'note_10',
        position: const Offset(790, 100),
        rotation: 0.1,
        style: StickyNoteStyle.classic,
        color: const Color(0xFFFFCDD2),
        width: 180,
        height: 180,
        text: 'I am locked!\nUnlock me via toolbar',
        fontSize: 16,
        isLocked: true,
        textColor: const Color(0xFFC62828),
        fontFamily: 'Patrick Hand',
      ),
    ];

    notes.emit(seeds);
  }

  // ── Actions ────────────────────────────────────────────────────────────

  void addNote() {
    final id = 'note_${DateTime.now().millisecondsSinceEpoch}';
    final color = _noteColors[_rng.nextInt(_noteColors.length)];
    final font = _fontFamilies[_rng.nextInt(_fontFamilies.length)];
    final rotation = (_rng.nextDouble() - 0.5) * 0.15;
    final x = 100.0 + _rng.nextDouble() * 400;
    final y = 100.0 + _rng.nextDouble() * 300;

    final note = _makeNote(
      id: id,
      position: Offset(x, y),
      rotation: rotation,
      style: nextStyle.val,
      color: color,
      text: '',
      fontFamily: font,
      fontSize: 18,
    );

    notes.emit([...notes.val, note]);
    focusedNoteId.emit(id);
  }

  void removeNote(String id) {
    notes.emit(notes.val.where((n) => n.id != id).toList());
    if (focusedNoteId.val == id) focusedNoteId.emit(null);
  }

  void clearAll() {
    notes.emit([]);
    focusedNoteId.emit(null);
  }

  void cycleBackground() {
    final values = BoardBackground.values;
    final next = (background.val.index + 1) % values.length;
    background.emit(values[next]);
  }

  void setNextStyle(StickyNoteStyle style) => nextStyle.emit(style);

  // ── Helpers ────────────────────────────────────────────────────────────

  StickyNoteModel _makeNote({
    required String id,
    Offset position = Offset.zero,
    double rotation = 0.0,
    StickyNoteStyle style = StickyNoteStyle.classic,
    Color color = const Color(0xFFFFFF99),
    double width = 200,
    double height = 200,
    required String text,
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.normal,
    Color textColor = const Color(0xFF1A1A1A),
    TextAlign textAlign = TextAlign.left,
    String fontFamily = 'Default',
    bool isLocked = false,
  }) {
    return StickyNoteModel(
      id: id,
      position: position,
      rotation: rotation,
      style: style,
      color: color,
      width: width,
      height: height,
      textController: StyledTextController(text: text),
      fontSize: fontSize,
      fontWeight: fontWeight,
      textColor: textColor,
      textAlign: textAlign,
      fontFamily: fontFamily,
      isLocked: isLocked,
    );
  }

  // ── Singleton ──────────────────────────────────────────────────────────

  static BoardController get init => Neuron.ensure(() => BoardController());
}
