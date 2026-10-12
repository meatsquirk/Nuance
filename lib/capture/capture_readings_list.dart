import 'package:flutter/material.dart';

import '../widgets/color_chip.dart';
import 'capture_state.dart';

/// The multi-point readings region of the Capture screen (bs-09 AC-3, AC-4).
///
/// Renders one row per [MultiPointReading] the controller has produced, each
/// showing the frame position it was sampled from alongside its own colour
/// value as text. Every row is a [ColorChip], so a reading is never a bare
/// swatch — the value always carries a label (SI Accessibility). SCREEN-1 shell:
/// the list is empty until [CaptureState.markedReadings] is filled by
/// `CaptureController.sampleMarkedPoints` (CAPTURE-4); the rendering that keeps
/// each point's position beside its own value is what AC-4's behaviour phase
/// (SCREEN-3) exercises. It reads a plain list so it renders any state without
/// driving the controller.
class CaptureReadingsList extends StatelessWidget {
  const CaptureReadingsList({required this.readings, super.key});

  /// Stable anchor for the readings region.
  static const Key readingsListKey = ValueKey('capture-readings-list');

  /// Stable anchor for the reading at [index] within the region.
  static Key readingKey(int index) => ValueKey('capture-reading-$index');

  /// The readings to show, one per marked point; empty before any is sampled.
  final List<MultiPointReading> readings;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: readingsListKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < readings.length; index++)
          ColorChip(
            key: readingKey(index),
            label: _labelFor(readings[index]),
          ),
      ],
    );
  }

  /// The row text for [reading]: the marked position kept beside its own CIELAB
  /// value, so each point shows a distinct position and a distinct value (AC-4).
  static String _labelFor(MultiPointReading reading) {
    final p = reading.position;
    final c = reading.coordinates;
    return 'Point (${p.x}, ${p.y}): L ${c.lightness} a ${c.a} b ${c.b}';
  }
}
