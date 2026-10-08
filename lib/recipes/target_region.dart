import 'package:flutter/material.dart';

import 'recipe_controller.dart';

/// The target region of the Recipes screen (wireframe S1.R1 — the mixing target,
/// E22 Target selector, E23 Speak target).
///
/// Shows the current mixing target's name on a `Recipe target: <name>` line —
/// the same render the RECIPE-2 shell and the Readout → recipes handoff (bs-01
/// AC-11) rely on — read from [RecipeController.state]. Alongside it sit the two
/// target controls as **inert placeholders**: the target selector (E22) that
/// RECIPE-3 wires to choose a saved sample or enter a colour by hand (AC-1,
/// AC-2), and the speak-target control (E23) that RECIPE-4 wires to speak the
/// target (AC-11). The region keeps its [regionKey] so the acceptance finders
/// and the behaviour phases have a stable anchor.
class TargetRegion extends StatelessWidget {
  const TargetRegion({required this.controller, super.key});

  /// Stable anchor for the target region.
  static const Key regionKey = ValueKey('recipes-target-region');

  /// The controller supplying the current target (and, later, the target
  /// selection and speak actions).
  final RecipeController controller;

  @override
  Widget build(BuildContext context) {
    final target = controller.state.target;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recipe target: ${target.name ?? '(unnamed)'}'),
        // E22 Target selector — inert until RECIPE-3 (AC-1, AC-2).
        const TextButton(onPressed: null, child: Text('Choose target')),
        // E23 Speak target — inert until RECIPE-4 (AC-11).
        const TextButton(onPressed: null, child: Text('Speak target')),
      ],
    );
  }
}
