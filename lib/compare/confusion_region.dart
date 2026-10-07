import 'package:flutter/material.dart';

import 'comparison_controller.dart';

/// The confusion-warning region of the Comparison screen (wireframe S1.R1 —
/// confusion warning): the warning shown when the pair collides on the painter's
/// confusion line (AC-7), and nothing when it does not (AC-8).
///
/// This shell renders only a labelled placeholder so the region is a findable
/// seam with the layout fixed; it shows no warning yet. CVD-2 reads
/// [ComparisonController.state]'s [confusable] flag and replaces the placeholder
/// with the real warning (or an empty region when the pair is distinct).
class ConfusionRegion extends StatelessWidget {
  const ConfusionRegion({required this.controller, super.key});

  /// Stable anchor for the confusion-warning region.
  static const Key regionKey = ValueKey('comparison-confusion-region');

  /// The controller supplying the confusable flag (unused until CVD-2).
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confusion warning'),
        Text('—'),
      ],
    );
  }
}
