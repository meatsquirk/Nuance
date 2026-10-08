import 'package:flutter/material.dart';

import 'recipe_controller.dart';

/// The recipe-list region of the Recipes screen (wireframe S1.R1 — the recipe
/// list body, E25 Speak recipe).
///
/// This is the SCREEN-1 **placeholder**: it shows an empty-state line in place
/// of the solved recipes and an inert speak-recipe control (E25). The real list
/// — a card per recipe with its paints and parts, predicted colour, ΔE00,
/// verdict, the "a touch of" trace and the muddying flag — is built by the
/// ENGINE behaviour phases (ENGINE-2..6) reading [RecipeController.state]'s
/// recipes; RECIPE-4 wires the per-recipe speak control (E25, AC-12). The region
/// keeps its [regionKey] so the acceptance finders and those phases have a stable
/// anchor.
class RecipeListRegion extends StatelessWidget {
  const RecipeListRegion({required this.controller, super.key});

  /// Stable anchor for the recipe-list region.
  static const Key regionKey = ValueKey('recipes-list-region');

  /// The controller supplying the solved recipes (empty in this shell; filled by
  /// ENGINE-2).
  final RecipeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        // ENGINE-2 replaces this with a card per solved recipe; until then the
        // list is an empty-state placeholder.
        Text('No recipes yet'),
        // E25 Speak recipe — inert until RECIPE-4 (AC-12).
        TextButton(onPressed: null, child: Text('Speak recipe')),
      ],
    );
  }
}
