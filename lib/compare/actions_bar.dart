import 'package:flutter/material.dart';

import 'comparison_controller.dart';

/// The comparison actions bar (wireframe S1.R1: Speak whole comparison [E6],
/// Open readout for A [E7], Open readout for B [E8]). Swap [E4] lives with the
/// slots it reverses (`SlotsRegion`).
///
/// Named [ComparisonActionsBar] to stand apart from the readout's `ActionsBar`.
/// Every control is present but inert (disabled) in this shell; the behaviour
/// phases wire them: speak → the spoken comparison (CVD-3), and the two
/// open-readout controls → [ComparisonController.openReadout] (COMPARE-6, which
/// also adds the readout route they push).
class ComparisonActionsBar extends StatelessWidget {
  const ComparisonActionsBar({required this.controller, super.key});

  /// Stable anchor for the actions bar.
  static const Key regionKey = ValueKey('comparison-actions-bar');

  /// The controller whose actions these controls will invoke.
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      key: regionKey,
      spacing: 8,
      children: [
        // All inert in this shell; the behaviour phases enable them.
        TextButton(onPressed: null, child: Text('Speak whole comparison')),
        TextButton(onPressed: null, child: Text('Open readout for A')),
        TextButton(onPressed: null, child: Text('Open readout for B')),
      ],
    );
  }
}
