import 'package:flutter/material.dart';

/// Inline style flags stored as a bitmask per character.
enum InlineStyle {
  /// Bold weight.
  bold,
  /// Italic style.
  italic,
  /// Underline decoration.
  underline,
  /// Strikethrough decoration.
  strikethrough,
}

/// A [TextEditingController] that supports per-character inline formatting.
///
/// Each character has an independent bitmask of [InlineStyle] flags.
/// Use [toggleStyle] to apply or remove a style on the current selection.
/// The controller's [buildTextSpan] renders mixed styles automatically
/// inside any [TextField] or [EditableText].
class StyledTextController extends TextEditingController {
  /// Per-character style bitmask. Length is always kept in sync with [text].
  List<int> _styles;

  StyledTextController({String text = ''})
      : _styles = List.filled(text.length, 0),
        super(text: text);

  // ── Value override to track insertions / deletions ─────────────────

  @override
  set value(TextEditingValue newValue) {
    final oldText = super.value.text;
    final newText = newValue.text;

    if (oldText.length != newText.length) {
      _adjustStyles(oldText.length, newText.length, newValue.selection);
    }

    super.value = newValue;
  }

  void _adjustStyles(int oldLen, int newLen, TextSelection newSel) {
    final delta = newLen - oldLen;

    if (delta > 0) {
      // Insertion — put empty style entries at the insertion point
      final insertAt = (newSel.baseOffset - delta).clamp(0, _styles.length);
      _styles.insertAll(insertAt, List.filled(delta, 0));
    } else if (delta < 0) {
      // Deletion — remove entries from the cursor position
      final deleteAt = newSel.baseOffset.clamp(0, _styles.length);
      final end = (deleteAt - delta).clamp(deleteAt, _styles.length);
      if (deleteAt < end) {
        _styles.removeRange(deleteAt, end);
      }
    }

    // Safety — always keep length in sync
    while (_styles.length < newLen) {
      _styles.add(0);
    }
    if (_styles.length > newLen) {
      _styles = _styles.sublist(0, newLen);
    }
  }

  // ── Public API ─────────────────────────────────────────────────────

  /// Toggle [style] on the current selection. If all characters in the
  /// selection already have the style, it is removed; otherwise it is added.
  ///
  /// Does nothing if the selection is collapsed (no text selected).
  void toggleStyle(InlineStyle style) {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) return;

    final start = sel.start;
    final end = sel.end;
    final bit = 1 << style.index;

    // Toggle: remove if all have it, add otherwise
    final allHave = _styles.sublist(start, end).every((s) => s & bit != 0);

    for (int i = start; i < end; i++) {
      if (allHave) {
        _styles[i] &= ~bit;
      } else {
        _styles[i] |= bit;
      }
    }
    notifyListeners();
  }

  /// Whether every character in the current selection has [style] applied.
  bool selectionHasStyle(InlineStyle style) {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) return false;
    final bit = 1 << style.index;
    return _styles.sublist(sel.start, sel.end).every((s) => s & bit != 0);
  }

  /// Whether any character in the current selection has [style] applied.
  bool selectionHasAnyStyle(InlineStyle style) {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) return false;
    final bit = 1 << style.index;
    return _styles.sublist(sel.start, sel.end).any((s) => s & bit != 0);
  }

  // ── buildTextSpan — renders mixed inline styles ────────────────────

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    if (text.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    // Group consecutive characters sharing the same bitmask into spans
    final spans = <TextSpan>[];
    int runStart = 0;
    int currentMask = _styles.isNotEmpty ? _styles[0] : 0;

    for (int i = 1; i <= text.length; i++) {
      final mask = i < _styles.length ? _styles[i] : 0;
      if (i == text.length || mask != currentMask) {
        spans.add(TextSpan(
          text: text.substring(runStart, i),
          style: _applyMask(currentMask, baseStyle),
        ));
        runStart = i;
        currentMask = mask;
      }
    }

    if (spans.length == 1) return spans.first;
    return TextSpan(children: spans, style: baseStyle);
  }

  TextStyle _applyMask(int mask, TextStyle base) {
    if (mask == 0) return base;

    final bold = mask & (1 << InlineStyle.bold.index) != 0;
    final italic = mask & (1 << InlineStyle.italic.index) != 0;
    final ul = mask & (1 << InlineStyle.underline.index) != 0;
    final st = mask & (1 << InlineStyle.strikethrough.index) != 0;

    final decs = <TextDecoration>[
      if (ul) TextDecoration.underline,
      if (st) TextDecoration.lineThrough,
    ];

    return base.copyWith(
      fontWeight: bold ? FontWeight.bold : null,
      fontStyle: italic ? FontStyle.italic : null,
      decoration: decs.isEmpty ? TextDecoration.none : TextDecoration.combine(decs),
    );
  }
}
