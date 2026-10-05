import 'package:flutter/material.dart';

import '../domain/sample.dart';

/// Thin stand-in for the comparison screen (the real screen arrives in bs-03).
///
/// Renders whichever of slot A / slot B carries a sample as findable text, so
/// the bs-01 acceptance tests can confirm the navigation handoff (AC-9, AC-10).
/// It is reached only through `AppRouter.toComparison`.
class ComparisonStubScreen extends StatelessWidget {
  const ComparisonStubScreen({this.sampleA, this.sampleB, super.key});

  /// The sample carried into comparison slot A, if any.
  final Sample? sampleA;

  /// The sample carried into comparison slot B, if any.
  final Sample? sampleB;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparison')),
      body: Column(
        children: [
          _SlotLine(label: 'Slot A', sample: sampleA),
          _SlotLine(label: 'Slot B', sample: sampleB),
        ],
      ),
    );
  }
}

class _SlotLine extends StatelessWidget {
  const _SlotLine({required this.label, required this.sample});

  final String label;
  final Sample? sample;

  @override
  Widget build(BuildContext context) {
    return Text('$label: ${sample?.name ?? '(empty)'}');
  }
}
