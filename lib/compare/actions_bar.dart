import 'package:flutter/material.dart';

import '../app/router.dart';
import 'comparison_controller.dart';

/// The comparison actions bar (wireframe S1.R1: Speak whole comparison [E6],
/// Open readout for A [E7], Open readout for B [E8]). Swap [E4] lives with the
/// slots it reverses (`SlotsRegion`).
///
/// Named [ComparisonActionsBar] to stand apart from the readout's `ActionsBar`.
/// The two open-readout controls (E7/E8) are wired here (COMPARE-6): each pushes
/// [ComparisonController.openReadout] for its slot and is enabled only when that
/// slot holds a sample (AC-10, AC-11). Speak (E6) drives
/// [ComparisonController.speak] (CVD-3, AC-9) and is enabled only once both slots
/// are set — there is no comparison to speak until then.
class ComparisonActionsBar extends StatelessWidget {
  const ComparisonActionsBar({required this.controller, super.key});

  /// Stable anchor for the actions bar.
  static const Key regionKey = ValueKey('comparison-actions-bar');

  /// The controller whose actions these controls invoke.
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: regionKey,
      spacing: 8,
      children: [
        TextButton(
          onPressed: controller.state.comparison != null
              ? () => controller.speak()
              : null,
          child: const Text('Speak whole comparison'),
        ),
        TextButton(
          onPressed: controller.slotFilled(ComparisonSlot.a)
              ? () => Navigator.of(context)
                  .push(controller.openReadout(ComparisonSlot.a))
              : null,
          child: const Text('Open readout for A'),
        ),
        TextButton(
          onPressed: controller.slotFilled(ComparisonSlot.b)
              ? () => Navigator.of(context)
                  .push(controller.openReadout(ComparisonSlot.b))
              : null,
          child: const Text('Open readout for B'),
        ),
      ],
    );
  }
}
