import 'package:flutter/material.dart';

import 'actions_bar.dart';
import 'comparison_controller.dart';
import 'confusion_region.dart';
import 'difference_region.dart';
import 'slots_region.dart';
import 'statement_region.dart';

/// The Comparison screen: the single surface the painter compares two samples
/// through (wireframe S1.R1, elements E3–E8 and the sample picker E49).
///
/// A pure view over the [ComparisonController] it is given (owned by
/// [ComparisonHomeScreen], which also wraps this subtree in the
/// `ComparisonReadEndpoint` the acceptance suite observes). It lays out every
/// region — the two slots, the overall difference, the relational statement, the
/// confusion warning and the actions bar — so the acceptance finders and the
/// behaviour phases have stable anchors. This shell renders placeholders and
/// disabled controls; each region's real reading and each action land in their
/// behaviour phase.
class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({required this.controller, super.key});

  /// The controller every region reads and (later) acts on.
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparison')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SlotsRegion(controller: controller),
                const SizedBox(height: 12),
                DifferenceRegion(controller: controller),
                const SizedBox(height: 12),
                StatementRegion(controller: controller),
                const SizedBox(height: 12),
                ConfusionRegion(controller: controller),
                const SizedBox(height: 16),
                ComparisonActionsBar(controller: controller),
              ],
            );
          },
        ),
      ),
    );
  }
}
