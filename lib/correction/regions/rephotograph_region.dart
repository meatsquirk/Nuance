import 'package:flutter/material.dart';

import '../correction_controller.dart';

/// The re-photograph region of the Correction screen (wireframe element **E28** —
/// "Re-photograph swatch").
///
/// Carries the control that re-photographs the mixed swatch and re-checks it
/// against the target after the painter adjusts the mix (AC-8), so the loop can
/// run again without leaving the screen.
///
/// The "Re-photograph swatch" control is wired to
/// [CorrectionController.rephotograph] (LOOP-5, AC-8): re-driving the camera to a
/// fresh measured swatch and re-comparing it to the target. The region keeps its
/// [regionKey] as a stable anchor for the acceptance smoke test and the behaviour
/// phases.
class RephotographRegion extends StatelessWidget {
  const RephotographRegion({required this.controller, super.key});

  /// Stable anchor for the re-photograph region.
  static const Key regionKey = ValueKey('correction-rephotograph-region');

  /// The controller supplying the re-photograph action.
  final CorrectionController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // E28 Re-photograph swatch (AC-8): re-photographs the mixed swatch and
        // re-checks it against the target through the controller.
        TextButton(
          onPressed: () => controller.rephotograph(),
          child: const Text('Re-photograph swatch'),
        ),
      ],
    );
  }
}
