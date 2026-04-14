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
      : _styles = List.filled(text.length, 0, growable: true),
        super(text: text);

  // ── Value override to track insertions / deletions ─────────────────

  @override
  set value(TextEditingValue newValue) {
    final oldText = super.value.text;
    final newText = newValue.text;

    if (oldText != newText) {
      _adjustStyles(oldText, newText, newValue.selection);
    }

    super.value = newValue;
  }

  void _adjustStyles(String oldText, String newText, TextSelection newSel) {
    final oldLen = oldText.length;
    final newLen = newText.length;

    // Find common prefix and suffix to detect where the edit happened
    int prefixLen = 0;
    final minLen = oldLen < newLen ? oldLen : newLen;
    while (prefixLen < minLen && oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    int oldSuffixStart = oldLen;
    int newSuffixStart = newLen;
    while (oldSuffixStart > prefixLen &&
        newSuffixStart > prefixLen &&
        oldText[oldSuffixStart - 1] == newText[newSuffixStart - 1]) {
      oldSuffixStart--;
      newSuffixStart--;
    }

    // Remove deleted characters' styles
    if (oldSuffixStart > prefixLen) {
      _styles.removeRange(prefixLen, oldSuffixStart.clamp(0, _styles.length));
    }

    // Insert empty styles for new characters
    final insertCount = newSuffixStart - prefixLen;
    if (insertCount > 0) {
      _styles.insertAll(
        prefixLen.clamp(0, _styles.length),
        List.filled(insertCount, 0),
      );
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
