import 'package:flutter/material.dart';

import 'comparison_controller.dart';

/// The two sample slots and the controls that fill and reverse them (wireframe
/// S1.R1: Choose sample A [E3], Choose sample B [E5], Sample picker [E49], Swap A
/// and B [E4]).
///
/// Each slot shows its chosen sample's name (or `(empty)` until one is chosen)
/// on a `Slot A:` / `Slot B:` line read from [ComparisonController.state].
/// The Readout → compare handoff pre-places a sample here, so the slot lines are
/// the one piece of real rendering this shell carries (the existing bs-01 handoff
/// tests read them). The Choose A / Choose B / Sample picker / Swap controls are
/// present but inert (disabled): selection behaviour lands in COMPARE-3, which
/// drives the picker over [ComparisonController.savedSamples] and calls
/// [ComparisonController.selectA] / [ComparisonController.selectB]; swap lands in
/// COMPARE-5, which calls [ComparisonController.swap].
class SlotsRegion extends StatelessWidget {
  const SlotsRegion({required this.controller, super.key});

  /// Stable anchor for the slots region.
  static const Key regionKey = ValueKey('comparison-slots-region');

  /// The controller supplying the two slots.
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Slot A: ${state.slotA?.name ?? '(empty)'}'),
        // Inert in this shell; COMPARE-3 opens the picker and calls selectA.
        const TextButton(onPressed: null, child: Text('Choose sample A')),
        Text('Slot B: ${state.slotB?.name ?? '(empty)'}'),
        // Inert in this shell; COMPARE-3 opens the picker and calls selectB.
        const TextButton(onPressed: null, child: Text('Choose sample B')),
        const TextButton(onPressed: null, child: Text('Sample picker')),
        // Inert in this shell; COMPARE-5 calls swap to re-express the comparison.
        const TextButton(onPressed: null, child: Text('Swap A and B')),
      ],
    );
  }
}
