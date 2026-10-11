import 'package:flutter/material.dart';

import '../correction_controller.dart';

/// The difference region of the Correction screen — how the checked mix differs
/// from the target.
///
/// Before a check it shows its placeholder; once the painter checks the mix it
/// reads [CorrectionState.difference] from the [controller] and shows the
/// perceptual distance (ΔE00) with its plain verdict, then the value-leading
/// decomposition — value first, hue second (AC-2/AC-3, D-5). The within-tolerance
/// "very close" state (AC-6, CORRECT-4) rides the same verdict line.
///
/// Keeps its [regionKey] as a stable anchor for the acceptance smoke test and
/// the behaviour phases.
class DifferenceRegion extends StatelessWidget {
  const DifferenceRegion({required this.controller, super.key});

  /// Stable anchor for the difference region.
  static const Key regionKey = ValueKey('correction-difference-region');

  /// The controller supplying the checked mix's [CorrectionState.difference].
  final CorrectionController controller;

  @override
  Widget build(BuildContext context) {
    final difference = controller.state.difference;
    final List<Widget> children;
    if (difference == null) {
      children = const [
        Text('Check the mix to see how it differs from the target.'),
      ];
    } else {
      children = [
        // The perceptual distance and its plain verdict (AC-2).
        Text('ΔE00 ${difference.deltaE00.toStringAsFixed(1)} — '
            '${difference.verdict}'),
        // The value-leading decomposition (AC-3): value first for a CVD painter,
        // hue second.
        Text(difference.valueReading),
        Text(difference.hueReading),
      ];
    }
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
