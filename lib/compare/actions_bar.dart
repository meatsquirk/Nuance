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
/// are set — there is no comparison to speak until then. The speak action itself
/// is the Compare screen's always-visible floating [SpeakButton] (bs-18 AC-6),
/// rendered by [ComparisonScreen] as the screen's `floatingActionButton`, not in
/// this bar — but [speakKey] stays here as the shared anchor its siblings tap.
class ComparisonActionsBar extends StatelessWidget {
  const ComparisonActionsBar({required this.controller, super.key});

  /// Stable anchor for the actions bar.
  static const Key regionKey = ValueKey('comparison-actions-bar');

  /// Stable anchor for the "speak whole comparison" action (E6, AC-9).
  ///
  /// The control is the Compare screen's floating [SpeakButton] (bs-18 AC-6),
  /// rendered by [ComparisonScreen] outside this bar; the key stays here as the
  /// shared anchor every sibling (the spoken-output flow) taps.
  static const Key speakKey = ValueKey('comparison-action-speak');

  /// The controller whose actions these controls invoke.
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: regionKey,
      spacing: 8,
      children: [
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
