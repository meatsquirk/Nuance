import 'package:flutter/material.dart';

import '../widgets/mono_label.dart';
import '../widgets/speak_button.dart';
import '../widgets/surface_card.dart';
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

  /// Stable anchor for the "ranked by" note (AC-7): the design-system mono
  /// eyebrow above the solved list telling the painter the recipes are ordered
  /// closest-first.
  static const Key rankedNoteKey = ValueKey('recipes-ranked-note');

  /// The "ranked by" note's text (AC-7), rendered through [MonoLabel] in the
  /// design-system mono micro-label style: the recipes below are ordered by
  /// their distance from the target, the closest first.
  static const String rankedNoteText = 'Ranked by closeness';

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
              // AC-7: the "ranked by" note — a design-system mono eyebrow
              // telling the painter the recipes below are ordered closest-first.
              const MonoLabel(rankedNoteText, key: rankedNoteKey),
              const SizedBox(height: 8),
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
/// AC-7), and a mix liable to muddy carries a flag (ENGINE-4, AC-8). When the
/// target is out of gamut the card marks the mix the nearest possible, not a
/// match (ENGINE-5, AC-9). The
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
    // AC-7 (presentation only, D-2): each recipe sits in a design-system
    // [SurfaceCard] rather than a Material `Card`, and the inter-card gap keeps
    // the list's vertical rhythm. [cardKey] moves to the inner content so the
    // `SurfaceCard` is its ancestor — the acceptance finder reads a `SurfaceCard`
    // *above* `cardKey(index)` — while the trace / muddying finders the bs-04
    // suite scopes to `cardKey(index)` still see the same content beneath it.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SurfaceCard(
        child: Padding(
          key: RecipeListRegion.cardKey(index),
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
              // When the target is out of gamut (AC-9) the mix is the nearest
              // possible, not a match — the card says so plainly so the verdict's
              // distance band is never read as a claimed match.
              if (recipe.outOfGamut)
                const Text('Nearest possible — not an exact match'),
              if (recipe.muddying) const Text('Liable to muddy'),
              // E25 Speak recipe — the design-system round speak affordance
              // (AC-7 recipe action, superseding the ad-hoc TextButton): speaks
              // this recipe's paints and their parts through the controller's
              // speech seam (AC-12).
              SpeakButton(
                onPressed: () => controller.speakRecipe(recipe),
                semanticLabel: 'Speak recipe',
                size: SpeakButtonSize.compact,
              ),
            ],
          ),
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
