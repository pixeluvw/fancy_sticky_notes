import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'sticky_note_style.dart';

/// Corner radius for rounded sticky notes.
const double kNoteCornerRadius = 8.0;

/// Fully rounded corner radius.
const double kNoteRoundRadius = 20.0;

/// Paints the sticky note background, shadow, and decorative style overlay.
class StickyNotePainter extends CustomPainter {
  /// The visual style preset that determines the decorative overlay.
  final StickyNoteStyle style;

  /// Background color of the note.
  final Color color;

  /// Current rotation angle in radians (affects shadow offset).
  final double rotation;

  /// Whether to use a fully rounded rectangle instead of the paper-curl shape.
  final bool roundCorners;

  StickyNotePainter({
    required this.style,
    required this.color,
    required this.rotation,
    this.roundCorners = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = paperPath(size, roundCorners: roundCorners);

    // Shadow
    final shadowOffset = Offset(
      3.0 + (rotation * 8.0),
      5.0 + (rotation * 3.0).abs(),
    );
    canvas.save();
    canvas.translate(shadowOffset.dx, shadowOffset.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0),
    );
    canvas.restore();

    // Background
    final bgPaint = Paint();
    if (style == StickyNoteStyle.classic) {
      bgPaint.shader = ui.Gradient.linear(
        Offset.zero, Offset(0, size.height),
        [color, _darken(color, 0.1)],
      );
    } else if (style == StickyNoteStyle.blueprint) {
      bgPaint.color = const Color(0xFF1A3A5C);
    } else if (style == StickyNoteStyle.cork) {
      bgPaint.color = const Color(0xFFBF9B6E);
    } else if (style == StickyNoteStyle.kraft) {
      bgPaint.color = const Color(0xFFC4A77D);
    } else {
      bgPaint.color = color;
    }
    canvas.drawPath(path, bgPaint);

    // Decorative overlay
    canvas.save();
    canvas.clipPath(path);
    switch (style) {
      case StickyNoteStyle.lined:
        _paintLined(canvas, size);
        break;
      case StickyNoteStyle.grid:
        _paintGrid(canvas, size, Colors.grey.withValues(alpha: 0.35));
        break;
      case StickyNoteStyle.dotted:
        _paintDotted(canvas, size);
        break;
      case StickyNoteStyle.crosshatch:
        _paintCrosshatch(canvas, size);
        break;
      case StickyNoteStyle.kraft:
        _paintKraft(canvas, size);
        break;
      case StickyNoteStyle.blueprint:
        _paintBlueprint(canvas, size);
        break;
      case StickyNoteStyle.cork:
        _paintCork(canvas, size);
        break;
      case StickyNoteStyle.linen:
        _paintLinen(canvas, size);
        break;
      default:
        break;
    }
    canvas.restore();
  }

  // ── Styles ─────────────────────────────────────────────────────────────

  void _paintLined(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    const double topMargin = 40.0, spacing = 22.0;
    for (double y = topMargin; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final marginPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(30, 0), Offset(30, size.height), marginPaint);
    canvas.drawLine(const Offset(34, 0), Offset(34, size.height), marginPaint);
  }

  void _paintGrid(Canvas canvas, Size size, Color lineColor) {
    final p = Paint()..color = lineColor..strokeWidth = 1.0;
    const double s = 15.0;
    for (double y = 0; y < size.height; y += s) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    for (double x = 0; x < size.width; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  void _paintDotted(Canvas canvas, Size size) {
    final p = Paint()..color = _darken(color, 0.15).withValues(alpha: 0.4);
    const double s = 18.0, r = 2.0;
    for (double y = s; y < size.height; y += s) {
      for (double x = s; x < size.width; x += s) {
        canvas.drawCircle(Offset(x, y), r, p);
      }
    }
  }

  void _paintCrosshatch(Canvas canvas, Size size) {
    final p = Paint()..color = _darken(color, 0.1).withValues(alpha: 0.25)..strokeWidth = 0.8;
    const double s = 12.0;
    final m = size.width + size.height;
    for (double d = -m; d < m; d += s) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), p);
      canvas.drawLine(Offset(size.width + d, 0), Offset(d, size.height), p);
    }
  }

  void _paintKraft(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final sp = Paint();
    for (int i = 0; i < 300; i++) {
      sp.color = Colors.brown.shade900.withValues(alpha: 0.05 + rng.nextDouble() * 0.15);
      canvas.drawCircle(Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          0.5 + rng.nextDouble() * 2.0, sp);
    }
    final fp = Paint()..color = Colors.brown.shade800.withValues(alpha: 0.06)..strokeWidth = 0.5;
    for (int i = 0; i < 40; i++) {
      final y = rng.nextDouble() * size.height;
      final x1 = rng.nextDouble() * size.width * 0.3;
      canvas.drawLine(Offset(x1, y), Offset(x1 + 20 + rng.nextDouble() * size.width * 0.4, y), fp);
    }
  }

  void _paintBlueprint(Canvas canvas, Size size) {
    final major = Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeWidth = 1.0;
    final minor = Paint()..color = Colors.white.withValues(alpha: 0.06)..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), major);
    }
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), major);
    }
    for (double y = 0; y < size.height; y += 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
    }
  }

  void _paintCork(Canvas canvas, Size size) {
    final rng = math.Random(77);
    final sp = Paint();
    for (int i = 0; i < 500; i++) {
      final dark = rng.nextBool();
      final op = 0.05 + rng.nextDouble() * 0.12;
      sp.color = dark
          ? Colors.brown.shade900.withValues(alpha: op)
          : Colors.orange.shade100.withValues(alpha: op * 0.5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          width: 1.0 + rng.nextDouble() * 4.0,
          height: 1.0 + rng.nextDouble() * 3.0,
        ), sp);
    }
  }

  void _paintLinen(Canvas canvas, Size size) {
    final h = Paint()..color = _darken(color, 0.06).withValues(alpha: 0.3)..strokeWidth = 0.5;
    final v = Paint()..color = _darken(color, 0.04).withValues(alpha: 0.2)..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), h);
    }
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), v);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Public so both painter and clipper share the same shape.
  static Path paperPath(Size size, {bool roundCorners = false}) {
    if (roundCorners) {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(kNoteRoundRadius),
        ));
    }

    const r = kNoteCornerRadius;
    final path = Path();
    path.moveTo(r, 0);
    path.lineTo(size.width - r, 0);
    path.arcToPoint(Offset(size.width, r), radius: const Radius.circular(r));
    path.lineTo(size.width, size.height - 5);
    path.quadraticBezierTo(size.width * 0.75, size.height, size.width * 0.5, size.height - 3);
    path.quadraticBezierTo(size.width * 0.25, size.height - 6, 0, size.height);
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: const Radius.circular(r));
    path.close();
    return path;
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant StickyNotePainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.color != color ||
      oldDelegate.rotation != rotation ||
      oldDelegate.roundCorners != roundCorners;
}

/// Clips the note content to the [StickyNotePainter.paperPath] shape.
class StickyNoteClipper extends CustomClipper<Path> {
  /// Whether to clip to a fully rounded rectangle.
  final bool roundCorners;

  /// Creates a clipper matching the note's paper shape.
  StickyNoteClipper({this.roundCorners = false});

  @override
  Path getClip(Size size) => StickyNotePainter.paperPath(size, roundCorners: roundCorners);

  @override
  bool shouldReclip(covariant StickyNoteClipper oldClipper) =>
      oldClipper.roundCorners != roundCorners;
}
