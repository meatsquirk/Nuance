import 'package:flutter/material.dart';

import 'comparison_controller.dart';

/// The relational-statement region of the Comparison screen (wireframe S1.R1 —
/// relational statement): the lightness / saturation / hue decomposition
/// (AC-5, AC-6), and, until a second sample is chosen, the invite to choose one
/// (AC-12).
///
/// With no reading yet (either slot empty ⇒ [ComparisonController.state]'s
/// [comparison] is null) this states no relational line and instead invites the
/// painter to choose a second sample (AC-12) — the enabled choose-sample-B
/// control lives in the slots region. Once both slots are set, DIFF-3 fills the
/// three decomposition lines from the derived [comparison]; this phase renders a
/// labelled placeholder for that case so the layout stays fixed.
class StatementRegion extends StatelessWidget {
  const StatementRegion({required this.controller, super.key});

  /// Stable anchor for the relational-statement region.
  static const Key regionKey = ValueKey('comparison-statement-region');

  /// The controller supplying the reading.
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    final comparison = controller.state.comparison;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Relational statement'),
        if (comparison == null)
          // No second sample yet: no relational statement, an invite instead
          // (AC-12). The choose-sample-B affordance is the slots region's.
          const Text('Choose a second sample to compare.')
        else
          // Both slots set; DIFF-3 fills the three decomposition lines here.
          const Text('—'),
      ],
    );
  }
}
