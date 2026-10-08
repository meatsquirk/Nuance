import 'package:flutter/material.dart';

import '../app/router.dart';
import '../color_science/conversions.dart';
import '../domain/sample.dart';
import 'comparison_controller.dart';

/// The two sample slots and the controls that fill and reverse them (wireframe
/// S1.R1: Choose sample A [E3], Choose sample B [E5], Sample picker [E49], Swap A
/// and B [E4]).
///
/// Each slot shows its chosen sample's name (or `(empty)` until one is chosen)
/// on a `Slot A:` / `Slot B:` line, and — once a sample is placed — its reading
/// as `L n, C n, h n degrees` (the CIELCh of the sample, rounded, via bs-01's
/// [labToCielch]) read from [ComparisonController.state] (AC-1, AC-2).
///
/// Choose sample A / Choose sample B (E3 / E5) open the saved-sample picker
/// (E49) over [ComparisonController.savedSamples] and place the chosen sample
/// into its slot via [ComparisonController.selectA] / [ComparisonController.selectB]
/// (COMPARE-3). The standalone Sample picker affordance and Swap A and B (E4)
/// stay inert here; swap lands in COMPARE-5.
class SlotsRegion extends StatelessWidget {
  const SlotsRegion({required this.controller, super.key});

  /// Stable anchor for the slots region.
  static const Key regionKey = ValueKey('comparison-slots-region');

  /// The controller supplying the two slots and the saved-sample catalogue.
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slot('Slot A', state.slotA),
        TextButton(
          onPressed: () => _choose(context, ComparisonSlot.a),
          child: const Text('Choose sample A'),
        ),
        _slot('Slot B', state.slotB),
        TextButton(
          onPressed: () => _choose(context, ComparisonSlot.b),
          child: const Text('Choose sample B'),
        ),
        const TextButton(onPressed: null, child: Text('Sample picker')),
        // Inert in this phase; COMPARE-5 calls swap to re-express the comparison.
        const TextButton(onPressed: null, child: Text('Swap A and B')),
      ],
    );
  }

  /// One slot line: the name (or `(empty)`) and, when a sample is placed, its
  /// rounded CIELCh reading `L n, C n, h n degrees` (AC-1, AC-2).
  Widget _slot(String label, Sample? sample) {
    if (sample == null) {
      return Text('$label: (empty)');
    }
    final lch = labToCielch(sample.coordinates);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${sample.name ?? '(unnamed)'}'),
        Text('L ${lch.lightness.round()}, C ${lch.chroma.round()}, '
            'h ${lch.hue.round()} degrees'),
      ],
    );
  }

  /// Opens the saved-sample picker (E49) for [slot] and, if the painter chooses
  /// a sample, places it into that slot.
  Future<void> _choose(BuildContext context, ComparisonSlot slot) async {
    final chosen = await showDialog<Sample>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose a saved sample'),
        children: [
          for (final sample in controller.savedSamples)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(sample),
              child: Text(sample.name ?? '(unnamed)'),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    if (slot == ComparisonSlot.a) {
      controller.selectA(chosen);
    } else {
      controller.selectB(chosen);
    }
  }
}
