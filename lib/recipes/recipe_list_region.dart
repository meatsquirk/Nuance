import 'package:flutter/material.dart';

import 'engine/mixing_engine.dart';
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
    final recipes = controller.state.recipes;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recipes.isEmpty
          ? const [Text('No recipes yet')]
          : [
              for (final recipe in recipes) _RecipeCard(recipe: recipe),
            ],
    );
  }
}

/// One solved recipe (ENGINE-2): its paints as parts by volume and the mix's
/// predicted colour. The per-recipe "Speak recipe" control (E25) is inert until
/// RECIPE-4 wires it to the controller (AC-12).
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final predicted = recipe.predictedColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final component in recipe.components)
              Text('${component.paint.name} — '
                  '${(component.partsFraction * 100).round()}%'),
            Text('Predicted colour: L ${predicted.lightness.round()}, '
                'a ${predicted.a.round()}, b ${predicted.b.round()}'),
            // E25 Speak recipe — inert until RECIPE-4 (AC-12).
            const TextButton(onPressed: null, child: Text('Speak recipe')),
          ],
        ),
      ),
    );
  }
}
