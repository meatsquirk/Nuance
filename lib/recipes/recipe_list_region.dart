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

  /// A per-card anchor (keyed by the recipe's position in the solved list) the
  /// acceptance suite scopes its trace / muddying assertions to.
  static Key cardKey(int index) => ValueKey('recipe-card-$index');

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
              for (var i = 0; i < recipes.length; i++)
                _RecipeCard(
                  recipe: recipes[i],
                  index: i,
                  controller: controller,
                ),
            ],
    );
  }
}

/// One solved recipe (ENGINE-2): its paints as parts by volume and the mix's
/// predicted colour. A trace component (under ~2% by volume) is expressed as
/// "a touch of" plus its technique note rather than a measured part (ENGINE-4,
/// AC-7), and a mix liable to muddy carries a flag (ENGINE-4, AC-8). The
/// per-recipe "Speak recipe" control (E25) is wired by RECIPE-4 to speak the
/// recipe's paints and parts through the controller (AC-12).
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.index,
    required this.controller,
  });

  final Recipe recipe;

  /// The recipe's position in the solved list — a stable per-card anchor the
  /// acceptance finders scope their trace / muddying assertions to.
  final int index;

  /// The controller the per-card "Speak recipe" control (E25) drives (AC-12).
  final RecipeController controller;

  @override
  Widget build(BuildContext context) {
    final predicted = recipe.predictedColor;
    return Card(
      key: RecipeListRegion.cardKey(index),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final component in recipe.components)
              if (component.isTrace)
                _TraceComponent(component: component)
              else
                Text('${component.paint.name} — '
                    '${(component.partsFraction * 100).round()}%'),
            Text('Predicted colour: L ${predicted.lightness.round()}, '
                'a ${predicted.a.round()}, b ${predicted.b.round()}'),
            // The mix's distance from the target and its plain verdict (AC-5 /
            // D-7). The verdict is null only on a recipe built without one (the
            // model default); the engine always fills it, so it reads here.
            Text('ΔE00 ${recipe.deltaE00.toStringAsFixed(1)}'
                '${recipe.verdict == null ? '' : ' — ${recipe.verdict}'}'),
            if (recipe.muddying) const Text('Liable to muddy'),
            // E25 Speak recipe — wired by RECIPE-4 (AC-12): speaks this recipe's
            // paints and their parts through the controller's speech seam.
            TextButton(
              onPressed: () => controller.speakRecipe(recipe),
              child: const Text('Speak recipe'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A trace component (AC-7 / D-12): the paint expressed as "a touch of" with its
/// static technique note, rather than an unrealistic measured fraction.
class _TraceComponent extends StatelessWidget {
  const _TraceComponent({required this.component});

  final RecipeComponent component;

  @override
  Widget build(BuildContext context) {
    // The engine always pairs a trace with its static technique note (D-12);
    // the fallback is pure defence so the card never asserts on a null note.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${component.paint.name} — a touch of'),
        Text(component.techniqueNote ?? ''),
      ],
    );
  }
}
