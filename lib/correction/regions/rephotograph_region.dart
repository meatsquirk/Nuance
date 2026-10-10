import 'package:flutter/material.dart';

/// The re-photograph region of the Correction screen (wireframe element **E28** —
/// "Re-photograph swatch").
///
/// Carries the control that re-photographs the mixed swatch and re-checks it
/// against the target after the painter adjusts the mix (AC-8), so the loop can
/// run again without leaving the screen.
///
/// This is the SCREEN-1 **shell**: the control is disabled until LOOP-5 wires
/// [CorrectionController.rephotograph] to it. The region keeps its [regionKey] as
/// a stable anchor for the acceptance smoke test and the behaviour phases.
class RephotographRegion extends StatelessWidget {
  const RephotographRegion({super.key});

  /// Stable anchor for the re-photograph region.
  static const Key regionKey = ValueKey('correction-rephotograph-region');

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // E28 Re-photograph swatch — wired by LOOP-5 (AC-8). Disabled in this
        // shell.
        TextButton(
          onPressed: null,
          child: Text('Re-photograph swatch'),
        ),
      ],
    );
  }
}
