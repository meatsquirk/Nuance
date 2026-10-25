import 'package:flutter/material.dart';

/// The 0–10 Munsell value scale: an 11-step strip (0..10) with the sample's
/// Munsell value marked on it (AC-2).
///
/// READOUT-2 shell — introduces the findable [scaleKey] anchor so the harness
/// and the AC-2 acceptance test can anchor on the scale, without yet rendering
/// the strip (behaviour unchanged; the bare "Munsell value N" the [ValueRegion]
/// already shows stays). READOUT-5 renders the 11 labelled steps 0..10 and marks
/// the sample's step; it adds the sample's Munsell value as a constructor input
/// then.
class ValueScale extends StatelessWidget {
  const ValueScale({super.key});

  /// Stable anchor for the 0–10 value scale (AC-2).
  static const Key scaleKey = ValueKey('readout-value-scale');

  @override
  Widget build(BuildContext context) {
    // Shell placeholder: the anchor is present and findable; the 11-step scale
    // and the sample's marked step land in READOUT-5.
    return const SizedBox.shrink(key: scaleKey);
  }
}
