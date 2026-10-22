import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'source/frame.dart';

/// The live preview surface: paints the active capture source's latest [Frame],
/// falling back to a flat placeholder when no frame is available.
///
/// bs-19 VIEW-1 seam — this is the frame-render widget the live view routes
/// through. Until a source actually streams frames (VIEW-2 wires the camera
/// feed in), [frame] is null and the original flat [placeholderColor] surface
/// shows, so the software-source and no-camera paths render exactly as the
/// SCREEN-1 shell did. The widget carries [CaptureLiveView.liveViewKey] as its
/// stable anchor, so every existing assertion over that key (the eyedropper
/// over the feed, the value-only grayscale filter) holds unchanged.
class LiveFrameView extends StatelessWidget {
  const LiveFrameView({required this.frame, super.key});

  /// The latest frame to paint, or null when no source is streaming — then the
  /// flat [placeholderColor] surface shows (behaviour unchanged from the shell).
  final Frame? frame;

  /// The flat placeholder colour shown when [frame] is null — sourced from the
  /// theme authority ([AppTheme.cameraPlaceholderSurface]) so this screen holds
  /// no hardcoded palette literal (bs-17 AC-14 / D-8, VIEW-4). The value is the
  /// original SCREEN-1 feed-surface grey, kept so the un-wired paths look
  /// identical; the harness/unit test read this member, so both still track the
  /// placeholder without depending on a hardcoded literal.
  static Color get placeholderColor => AppTheme.cameraPlaceholderSurface;

  @override
  Widget build(BuildContext context) {
    final frame = this.frame;
    if (frame == null) {
      return ColoredBox(color: placeholderColor);
    }
    // Paint the frame's pixels directly; the real camera feed is downsampled
    // (D-4) before it reaches here, so a per-pixel paint is cheap enough for
    // the preview. VIEW-2 feeds the live source's frames into [frame].
    return CustomPaint(
      painter: _FramePainter(frame),
      child: const SizedBox.expand(),
    );
  }
}

/// Paints a [Frame]'s row-major RGB pixels onto the canvas, scaling the buffer
/// to fill the available [Size].
class _FramePainter extends CustomPainter {
  const _FramePainter(this.frame);

  final Frame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / frame.width;
    final cellHeight = size.height / frame.height;
    final paint = Paint();
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        final pixel = frame.pixelAt(x, y);
        paint.color = Color.fromARGB(255, pixel.r, pixel.g, pixel.b);
        canvas.drawRect(
          Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => oldDelegate.frame != frame;
}
