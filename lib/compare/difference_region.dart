import 'package:flutter/material.dart';

import 'comparison_controller.dart';

/// The overall-difference region of the Comparison screen (wireframe S1.R1 —
/// overall difference): the ΔE00 magnitude and its plain verdict (AC-4).
///
/// This shell renders only a labelled placeholder so the region is a findable
/// seam with the layout fixed; it shows no reading yet. DIFF-2 fills it from
/// [ComparisonController.state]'s [comparison] (the ΔE00 value and the
/// "clearly different" / … verdict) once both slots are set.
class DifferenceRegion extends StatelessWidget {
  const DifferenceRegion({required this.controller, super.key});

  /// Stable anchor for the overall-difference region.
  static const Key regionKey = ValueKey('comparison-difference-region');

  /// The controller supplying the reading (unused until DIFF-2).
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overall difference'),
        Text('—'),
      ],
    );
  }
}
