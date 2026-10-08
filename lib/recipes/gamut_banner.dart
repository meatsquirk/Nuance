import 'package:flutter/material.dart';

import 'recipe_controller.dart';

/// The out-of-gamut banner of the Recipes screen (wireframe S1.R1 — the "OUT OF
/// GAMUT" marker).
///
/// Shown above the recipe list when the target cannot be mixed from the selected
/// palette (AC-9), and hidden otherwise. This SCREEN-1 shell keeps it **hidden**:
/// ENGINE-5 adds the out-of-gamut signal to [RecipeController.state] and makes
/// this region render the banner from it. The region keeps its [regionKey] so
/// the acceptance finders and ENGINE-5 have a stable anchor either way.
class GamutBanner extends StatelessWidget {
  const GamutBanner({required this.controller, super.key});

  /// Stable anchor for the gamut banner.
  static const Key regionKey = ValueKey('recipes-gamut-banner');

  /// The controller that will supply the out-of-gamut signal (ENGINE-5).
  final RecipeController controller;

  @override
  Widget build(BuildContext context) {
    // ENGINE-5 renders "OUT OF GAMUT" here when the target is unreachable; the
    // shell keeps the banner hidden while the anchor stays in the tree.
    return const SizedBox.shrink(key: regionKey);
  }
}
