import 'package:flutter/material.dart';

import '../correction_controller.dart';

/// The check region of the Correction screen (wireframe element **E26** — "Check
/// my mix").
///
/// Shows the colour the painter is correcting toward on a
/// `Correction target: <name>` line — the same render the Recipes → correction
/// handoff (`AppRouter.toCorrection`) and the `correctionEntry` launch rely on —
/// read from [CorrectionController.state], and the "Check my mix" control (E26)
/// that photographs the mixed swatch and compares it to that target (AC-1).
///
/// This is the SCREEN-1 **shell**: the target line is bound to the controller,
/// but the control is disabled until LOOP-3 wires [CorrectionController.checkMix]
/// to it. The region keeps its [regionKey] so the acceptance smoke test and the
/// behaviour phases have a stable anchor.
class CheckRegion extends StatelessWidget {
  const CheckRegion({required this.controller, super.key});

  /// Stable anchor for the check region.
  static const Key regionKey = ValueKey('correction-check-region');

  /// The controller supplying the correction target and (later) the check
  /// action.
  final CorrectionController controller;

  @override
  Widget build(BuildContext context) {
    final target = controller.state.target;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Correction target: ${target.name ?? '(unnamed)'}'),
        // E26 Check my mix — wired by LOOP-3 (AC-1): photographs the swatch and
        // compares it to the target. Disabled in this shell.
        const ElevatedButton(
          onPressed: null,
          child: Text('Check my mix'),
        ),
      ],
    );
  }
}
