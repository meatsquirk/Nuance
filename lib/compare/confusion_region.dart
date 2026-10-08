import 'package:flutter/material.dart';

import '../a11y/cvd/confusion_check.dart';
import 'comparison_controller.dart';

/// The confusion-warning region of the Comparison screen (wireframe S1.R1 —
/// confusion warning): the warning shown when the pair collides on the painter's
/// confusion line (AC-7), and nothing when it does not (AC-8).
///
/// Reads [ComparisonController.state]'s `confusable` flag (derived by the
/// controller from the injected [DichromatConfusionCheck]): when the pair is
/// confusable it states the canonical [confusionWarningMessage] — the two look
/// identical to the painter but are clearly different to others (AC-7); when it
/// is not, the region carries no warning at all (AC-8). The region keeps its
/// [regionKey] either way so the layout and the acceptance finders stay stable.
class ConfusionRegion extends StatelessWidget {
  const ConfusionRegion({required this.controller, super.key});

  /// Stable anchor for the confusion-warning region.
  static const Key regionKey = ValueKey('comparison-confusion-region');

  /// The controller supplying the confusable flag.
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    final confusable = controller.state.confusable;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AC-8: a distinct pair shows no warning — the region stays empty.
        if (confusable)
          Text(
            confusionWarningMessage,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
