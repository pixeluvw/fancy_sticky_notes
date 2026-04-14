import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sticky_note_style.dart';
import 'sticky_note_painter.dart';
import 'sticky_note_board.dart' show fontStyleFor;

/// Height of the resize edge strip along the bottom of the note.
const double _kResizeEdgeHeight = 14.0;

/// A single Sticky Note widget.
///
/// Gesture model (all handled internally — no arena conflicts):
/// - Left-drag on body → move the note
/// - Left-drag on bottom edge → resize (height via dy, width via dx)
/// - Space + left-drag on body → rotate
/// - Double-tap → edit
class StickyNote extends StatefulWidget {
  final Widget? child;
  final TextEditingController? textController;
  final FocusNode? focusNode;
  final bool isEditing;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final TextAlign textAlign;
  final String fontFamily;
  final bool strikethrough;
  final bool underline;
  final bool italic;
  final bool isFocused;
  final bool isLocked;
  final bool isPinned;
  final bool isMinimized;
  final bool roundCorners;
  final double opacity;
  final ValueChanged<Offset>? onResize;
  final ValueChanged<double>? onRotate;
  final ValueChanged<Offset>? onDrag;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final StickyNoteStyle style;
  final Color color;
  final double width;
  final double height;
  final double rotation;
  final ImageProvider? texture;

  const StickyNote({
    super.key,
    this.child,
    this.textController,
    this.focusNode,
    this.isEditing = false,
    this.fontSize = 18.0,
    this.fontWeight = FontWeight.normal,
    this.textColor = const Color(0xFF1A1A1A),
    this.textAlign = TextAlign.left,
    this.fontFamily = 'Default',
    this.strikethrough = false,
    this.underline = false,
    this.italic = false,
    this.isFocused = false,
    this.isLocked = false,
    this.isPinned = false,
    this.isMinimized = false,
    this.roundCorners = false,
    this.opacity = 1.0,
    this.onResize,
    this.onRotate,
    this.onDrag,
    this.onTap,
    this.onDoubleTap,
    this.style = StickyNoteStyle.classic,
    this.color = const Color(0xFFFFFF99),
    this.width = 200,
    this.height = 200,
    this.rotation = 0.0,
    this.texture,
  });

  @override
  State<StickyNote> createState() => _StickyNoteState();
}

class _StickyNoteState extends State<StickyNote> {
  // Space+drag rotation tracking
  double? _prevAngle;
  bool _spaceRotating = false;

  bool get _isSpaceDown =>
      HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.space);

  Offset get _noteCenter =>
      Offset(widget.width / 2, (widget.isMinimized ? 36.0 : widget.height) / 2);

  double _angleFrom(Offset localPos) =>
      math.atan2(localPos.dy - _noteCenter.dy, localPos.dx - _noteCenter.dx);

  // ── Body pan (move or rotate depending on Space key) ───────────────

  void _onBodyPanStart(DragStartDetails d) {
    if (_isSpaceDown && !widget.isLocked && widget.onRotate != null) {
      _spaceRotating = true;
      _prevAngle = _angleFrom(d.localPosition);
    } else {
      _spaceRotating = false;
    }
  }

  void _onBodyPanUpdate(DragUpdateDetails d) {
    if (widget.isLocked) return;
    if (_spaceRotating && widget.onRotate != null) {
      final cur = _angleFrom(d.localPosition);
      if (_prevAngle != null) {
        var delta = cur - _prevAngle!;
        if (delta > math.pi) delta -= 2 * math.pi;
        if (delta < -math.pi) delta += 2 * math.pi;
        widget.onRotate!(delta);
      }
      _prevAngle = cur;
    } else {
      widget.onDrag?.call(d.delta);
    }
  }

  void _onBodyPanEnd(DragEndDetails d) {
    _spaceRotating = false;
    _prevAngle = null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.isMinimized ? 36.0 : widget.height;

    // ── Text style ───────────────────────────────────────────────────
    var textStyle = fontStyleFor(
      widget.fontFamily,
      fontSize: widget.fontSize,
      fontWeight: widget.fontWeight,
      color: widget.textColor,
    );
    if (widget.italic) {
      textStyle = textStyle.copyWith(fontStyle: FontStyle.italic);
    }
    final decs = <TextDecoration>[
      if (widget.strikethrough) TextDecoration.lineThrough,
      if (widget.underline) TextDecoration.underline,
    ];
    if (decs.isNotEmpty) {
      textStyle = textStyle.copyWith(decoration: TextDecoration.combine(decs));
    }

    // ── Content ──────────────────────────────────────────────────────
    final Widget contentWidget = widget.textController != null && !widget.isMinimized
        ? IgnorePointer(
            ignoring: !widget.isEditing,
            child: TextField(
              controller: widget.textController,
              focusNode: widget.focusNode,
              maxLines: null,
              expands: true,
              textAlign: widget.textAlign,
              style: textStyle,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              cursorColor: widget.textColor.withValues(alpha: 0.5),
            ),
          )
        : widget.isMinimized
            ? Text(
                widget.textController?.text.split('\n').first ?? '',
                style: textStyle.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : (widget.child ?? const SizedBox());

    // ── Should we show the resize edge? ──────────────────────────────
    final bool showResize =
        widget.isFocused && widget.onResize != null && !widget.isLocked && !widget.isMinimized;

    // ── Painted note body (clipped) ──────────────────────────────────
    final Widget paintedBody = CustomPaint(
      size: Size(widget.width, effectiveHeight),
      painter: StickyNotePainter(
        style: widget.style,
        color: widget.color,
        rotation: widget.rotation,
        roundCorners: widget.roundCorners,
      ),
      child: SizedBox(
        width: widget.width,
        height: effectiveHeight,
        child: ClipPath(
          clipper: StickyNoteClipper(roundCorners: widget.roundCorners),
          child: Stack(
            children: [
              if (widget.style == StickyNoteStyle.textured &&
                  widget.texture != null &&
                  !widget.isMinimized)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.35,
                    child: Image(image: widget.texture!, fit: BoxFit.cover),
                  ),
                ),
              Positioned.fill(
                child: Padding(
                  padding: widget.isMinimized
                      ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                      : const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: contentWidget,
                ),
              ),
              if (widget.isLocked)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Icon(Icons.lock, size: 12, color: Colors.black.withValues(alpha: 0.3)),
                ),
              if (widget.isPinned)
                Positioned(
                  left: 6,
                  top: 4,
                  child: Icon(Icons.push_pin, size: 12, color: Colors.red.withValues(alpha: 0.5)),
                ),
            ],
          ),
        ),
      ),
    );

    // ── Assemble: body (drag/rotate) + resize edge ───────────────────
    // The body GestureDetector and the resize GestureDetector are siblings
    // in a Stack — they never compete in the gesture arena.
    final Widget noteWidget = SizedBox(
      width: widget.width,
      height: effectiveHeight,
      child: Stack(
        children: [
          // Note body — handles drag (or Space+drag rotate) + double-tap
          Positioned.fill(
            // Leave room for the resize edge at the bottom so the two
            // GestureDetectors don't overlap.
            bottom: showResize ? _kResizeEdgeHeight : 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: widget.onDoubleTap,
              onPanStart: widget.isLocked ? null : _onBodyPanStart,
              onPanUpdate: widget.isLocked ? null : _onBodyPanUpdate,
              onPanEnd: widget.isLocked ? null : _onBodyPanEnd,
              child: paintedBody,
            ),
          ),
          // Resize edge — full width strip at the bottom, OUTSIDE ClipPath
          if (showResize)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _kResizeEdgeHeight,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (d) => widget.onResize!(d.delta),
                  child: CustomPaint(
                    painter: _ResizeEdgePainter(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Opacity(
      opacity: widget.opacity,
      child: Transform.rotate(angle: widget.rotation, child: noteWidget),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Resize edge painter — subtle dots along the bottom
// ═══════════════════════════════════════════════════════════════════════════

class _ResizeEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeCap = StrokeCap.round;

    // Three small dots centered horizontally
    final cy = size.height / 2;
    final cx = size.width / 2;
    const r = 2.0;
    const spacing = 8.0;
    for (int i = -1; i <= 1; i++) {
      canvas.drawCircle(Offset(cx + i * spacing, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
