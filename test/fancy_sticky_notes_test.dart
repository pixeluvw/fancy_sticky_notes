import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:fancy_sticky_notes/fancy_sticky_notes.dart';

void main() {
  test('StickyNoteStyle has 10 values', () {
    expect(StickyNoteStyle.values.length, 10);
  });

  test('StickyNotePainter.paperPath returns a non-empty path', () {
    final path = StickyNotePainter.paperPath(const Size(200, 200));
    expect(path.getBounds().isEmpty, isFalse);
  });

  test('StickyNotePainter.paperPath with roundCorners returns a non-empty path', () {
    final path = StickyNotePainter.paperPath(const Size(200, 200), roundCorners: true);
    expect(path.getBounds().isEmpty, isFalse);
  });
}
