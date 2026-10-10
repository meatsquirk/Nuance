import 'package:flutter/material.dart';

/// The difference region of the Correction screen — how the checked mix differs
/// from the target.
///
/// Once the painter checks the mix this shows the perceptual distance (ΔE00),
/// the plain-language verdict and the value-leading decomposition (AC-2/AC-3,
/// filled by CORRECT-2), and the within-tolerance "very close" state when no
/// correction is needed (AC-6, CORRECT-4).
///
/// This is the SCREEN-1 **shell**: it renders only its pre-check placeholder and
/// keeps its [regionKey] as a stable anchor for the acceptance smoke test and
/// the behaviour phases, which read [CorrectionState.difference] here.
class DifferenceRegion extends StatelessWidget {
  const DifferenceRegion({super.key});

  /// Stable anchor for the difference region.
  static const Key regionKey = ValueKey('correction-difference-region');

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Check the mix to see how it differs from the target.'),
      ],
    );
  }
}
