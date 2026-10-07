import 'package:flutter/material.dart';

import 'capture_eyedropper.dart';
import 'capture_state.dart';

/// The live camera viewport: the feed surface, the centre eyedropper, and the
/// text readings laid over it (stability, accuracy, low-light warning).
///
/// SCREEN-1 shell — it renders a placeholder feed surface (a flat colour; the
/// real frame render and the value-only grayscale toggle land in SOURCE-2 /
/// SCREEN-3) with the [CaptureEyedropper] centred over it, and surfaces the
/// observable [CaptureState] as text so no reading rests on colour alone (the
/// bs-01 label contract): the stability indicator, the accuracy tier and the
/// low-light warning are words, not bare colour. It reads a plain [CaptureState]
/// so it renders any state without driving the controller.
class CaptureLiveView extends StatelessWidget {
  const CaptureLiveView({required this.state, super.key});

  /// Stable anchor for the feed surface.
  static const Key liveViewKey = ValueKey('capture-live-view');

  /// Stable anchor for the "SETTLING n/12" / "STABLE 12/12" indicator.
  static const Key stabilityKey = ValueKey('capture-stability-indicator');

  /// Stable anchor for the stated-accuracy label.
  static const Key accuracyKey = ValueKey('capture-accuracy-label');

  /// Stable anchor for the low-light warning (E15's subject).
  static const Key warningKey = ValueKey('capture-low-light-warning');

  /// The capture state this viewport reflects.
  final CaptureState state;

  @override
  Widget build(BuildContext context) {
    // Fills the space its parent gives it (the Capture screen hands it the area
    // above the controls); the readings are laid over the feed.
    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder feed surface; SOURCE-2 renders real frames here and
        // SCREEN-3 adds the value-only grayscale filter.
        const ColoredBox(key: liveViewKey, color: Color(0xFF3A3A3A)),
        // The eyedropper carries [CaptureEyedropper.eyedropperKey] itself.
        const CaptureEyedropper(),
        // The text readings, laid over the feed so none rests on colour alone.
        Positioned(
          left: 8,
          top: 8,
          child: Text(
            state.stabilityText,
            key: stabilityKey,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Text(
            state.accuracy.label,
            key: accuracyKey,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Visibility(
            visible: state.lowLightWarning,
            child: const Text(
              'Low light — reading may be approximate',
              key: warningKey,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
