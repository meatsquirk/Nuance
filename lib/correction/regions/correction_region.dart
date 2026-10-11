import 'package:flutter/material.dart';

import '../correction_controller.dart';
import '../engine/correction_engine.dart';

/// The correction region of the Correction screen — the paint(s) to add to close
/// the gap.
///
/// Before a check it shows its placeholder; once the painter checks the mix it
/// reads [CorrectionState.correction] from the [controller] and shows the
/// concrete correction: each paint to add with its amount, rendered as
/// `a touch of <paint>` plus a technique note for a trace (AC-5) or
/// `add about N parts of <paint>` for a measured amount (AC-4). An empty
/// [Correction] — the mix needs
/// no change — shows the no-correction state (AC-6; CORRECT-4 gives it the "very
/// close" wording).
///
/// Keeps its [regionKey] as a stable anchor for the acceptance smoke test and
/// the behaviour phases.
class CorrectionRegion extends StatelessWidget {
  const CorrectionRegion({required this.controller, super.key});

  /// Stable anchor for the correction region.
  static const Key regionKey = ValueKey('correction-correction-region');

  /// The controller supplying the checked mix's [CorrectionState.correction].
  final CorrectionController controller;

  @override
  Widget build(BuildContext context) {
    final correction = controller.state.correction;
    final List<Widget> children;
    if (correction == null) {
      children = const [
        Text('Check the mix to see the paints to add.'),
      ];
    } else if (correction.isEmpty) {
      children = const [
        Text('No paints to add.'),
      ];
    } else {
      children = [
        const Text('Add to your mix:'),
        for (final addition in correction.additions)
          _AdditionLine(addition: addition),
      ];
    }
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// One paint to add: "a touch of" + a technique note for a trace (AC-5), or the
/// paint and its measured amount otherwise (AC-4).
class _AdditionLine extends StatelessWidget {
  const _AdditionLine({required this.addition});

  final CorrectionAddition addition;

  @override
  Widget build(BuildContext context) {
    if (addition.isTrace) {
      // A trace renders "a touch of" + its static technique note, not an
      // unmeasurable measured part (D-7), reusing bs-04's idiom.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('a touch of ${addition.paint.name}'),
          Text(addition.techniqueNote ?? ''),
        ],
      );
    }
    return Text('Add about ${_parts(addition.parts)} of ${addition.paint.name}');
  }

  /// The addition amount as painter-facing parts by volume (illustrative,
  /// G-4(a)): one decimal place, pluralised.
  static String _parts(double parts) {
    final text = parts.toStringAsFixed(1);
    return text == '1.0' ? '1 part' : '$text parts';
  }
}
