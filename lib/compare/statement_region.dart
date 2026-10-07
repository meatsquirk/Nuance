import 'package:flutter/material.dart';

import 'comparison_controller.dart';

/// The relational-statement region of the Comparison screen (wireframe S1.R1 —
/// relational statement): the lightness / saturation / hue decomposition
/// (AC-5, AC-6), and, until a second sample is chosen, the invite to choose one
/// (AC-12).
///
/// This shell renders only a labelled placeholder so the region is a findable
/// seam with the layout fixed; it states nothing and invites nothing yet.
/// DIFF-3 fills the three decomposition lines from [ComparisonController.state]'s
/// [comparison]; COMPARE-3 adds the "choose sample B" invite shown while a slot
/// is empty.
class StatementRegion extends StatelessWidget {
  const StatementRegion({required this.controller, super.key});

  /// Stable anchor for the relational-statement region.
  static const Key regionKey = ValueKey('comparison-statement-region');

  /// The controller supplying the reading (unused until DIFF-3 / COMPARE-3).
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Relational statement'),
        Text('—'),
      ],
    );
  }
}
