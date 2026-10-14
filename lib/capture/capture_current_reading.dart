import 'package:flutter/material.dart';

import '../app/build_app.dart';
import '../color_science/color_science.dart';
import '../domain/sample.dart';
import '../widgets/color_chip.dart';

/// The Capture screen's live colour reading, shown as a decorative swatch beside
/// its value label (bs-10 AC-9).
///
/// The capture live view surfaces the reading under the reticle
/// ([CaptureState.currentSample]); this renders that colour through the shared
/// [ColorChip] display chokepoint, so a CVD simulation or the daltonization
/// remap transforms it exactly as it does the Readout's and Palette's swatches —
/// daltonization reaches *every* screen through the one chokepoint (D-1/D-6).
/// The swatch never stands alone: the reading's CIELAB value is the label
/// [ColorChip] requires (SI §5.1).
///
/// It renders nothing before a colour has been sampled ([sample] is null) or
/// when there is no enclosing `AppScope` to read the colour science from (a
/// standalone capture screen in a unit context) — so the pre-bs-10 capture
/// layout is unchanged until a reading exists in the assembled app.
class CaptureCurrentReading extends StatelessWidget {
  const CaptureCurrentReading({required this.sample, super.key});

  /// Stable anchor for the live-reading swatch chip.
  static const Key readingKey = ValueKey('capture-current-reading');

  /// The colour sampled under the reticle right now, or null before any sample.
  final Sample? sample;

  @override
  Widget build(BuildContext context) {
    final current = sample;
    final science = AppScope.maybeOf(context)?.colorScience;
    if (current == null || science == null) return const SizedBox.shrink();
    final SRGBColor rgb = science.toSRGB(current.coordinates);
    final c = current.coordinates;
    return ColorChip(
      key: readingKey,
      label: 'Current reading: '
          'L ${c.lightness} a ${c.a} b ${c.b}',
      color: Color.fromARGB(255, rgb.red, rgb.green, rgb.blue),
    );
  }
}
