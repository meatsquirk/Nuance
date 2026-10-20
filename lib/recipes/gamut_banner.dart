import 'package:flutter/material.dart';

import '../widgets/mono_label.dart';
import '../widgets/surface_card.dart';
import 'recipe_controller.dart';

/// The out-of-gamut banner of the Recipes screen (wireframe S1.R1 — the "OUT OF
/// GAMUT" marker).
///
/// Shown above the recipe list when the target cannot be mixed from the selected
/// palette (AC-9), and hidden otherwise. ENGINE-5 wires it to the out-of-gamut
/// signal on [RecipeController.state]: the banner reads "OUT OF GAMUT" when the
/// target is unreachable and collapses to nothing when it is in gamut. The
/// region keeps its [regionKey] as a stable anchor in either state, so the
/// screen (wrapped in a `ListenableBuilder` over the controller) rebuilds it as
/// the solve result moves.
class GamutBanner extends StatelessWidget {
  const GamutBanner({required this.controller, super.key});

  /// Stable anchor for the gamut banner.
  static const Key regionKey = ValueKey('recipes-gamut-banner');

  /// The marker shown when the target is out of gamut (AC-9).
  static const String markerText = 'OUT OF GAMUT';

  /// The controller supplying the out-of-gamut signal (ENGINE-5).
  final RecipeController controller;

  @override
  Widget build(BuildContext context) {
    // In gamut (or before any solve): the anchor stays in the tree, collapsed.
    if (!controller.state.outOfGamut) {
      return const SizedBox.shrink(key: regionKey);
    }

    // Out of gamut: mark the target plainly in the design-system banner — a
    // [SurfaceCard] (the READ-2 warning-banner treatment) carrying the marker as
    // a [MonoLabel] in the mono micro-label style (AC-7), superseding the ad-hoc
    // error-red container. The recipes below are the nearest possible, never a
    // claimed match (each is flagged `outOfGamut`); the Semantics label spells
    // that out for a screen reader while the visible marker stays the short mono
    // micro-label (`excludeSemantics` folds the raw "OUT OF GAMUT" into it).
    return Padding(
      key: regionKey,
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Semantics(
            label: 'Out of gamut: this colour cannot be mixed from the '
                'selected palette. The recipes below are the nearest possible, '
                'not exact matches.',
            excludeSemantics: true,
            child: const MonoLabel(markerText),
          ),
        ),
      ),
    );
  }
}
