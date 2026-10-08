import 'package:flutter/material.dart';

import 'comparison_controller.dart';

/// The overall-difference region of the Comparison screen (wireframe S1.R1 —
/// overall difference): the ΔE00 magnitude and its plain verdict (AC-4).
///
/// Once both slots are set the region reads the derived comparison from
/// [ComparisonController.state]: the overall difference as `delta-E00 N` (the
/// CIEDE2000 ΔE00 to one decimal) and its plain-language verdict band (e.g.
/// "clearly different"). Until there is a reading — either slot still empty —
/// it shows the labelled placeholder so the region stays a findable seam.
class DifferenceRegion extends StatelessWidget {
  const DifferenceRegion({required this.controller, super.key});

  /// Stable anchor for the overall-difference region.
  static const Key regionKey = ValueKey('comparison-difference-region');

  /// The controller supplying the derived reading.
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    final comparison = controller.state.comparison;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overall difference'),
        if (comparison == null)
          const Text('—')
        else ...[
          Text('delta-E00 ${comparison.deltaE00.toStringAsFixed(1)}'),
          Text(comparison.verdict),
        ],
      ],
    );
  }
}
