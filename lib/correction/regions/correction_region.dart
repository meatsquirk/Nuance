import 'package:flutter/material.dart';

/// The correction region of the Correction screen — the paint(s) to add to close
/// the gap.
///
/// Once the painter checks the mix this shows the concrete correction: the paint
/// and amount to add, with "a touch of" for a trace (AC-4/AC-5, filled by
/// CORRECT-3), and the **no-correction** state when the mix is already within
/// tolerance (AC-6, CORRECT-4).
///
/// This is the SCREEN-1 **shell**: it renders only its pre-check placeholder and
/// keeps its [regionKey] as a stable anchor for the acceptance smoke test and
/// the behaviour phases, which read [CorrectionState.correction] here.
class CorrectionRegion extends StatelessWidget {
  const CorrectionRegion({super.key});

  /// Stable anchor for the correction region.
  static const Key regionKey = ValueKey('correction-correction-region');

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Check the mix to see the paints to add.'),
      ],
    );
  }
}
