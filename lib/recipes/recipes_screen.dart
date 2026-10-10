import 'package:flutter/material.dart';

import 'controls_region.dart';
import 'gamut_banner.dart';
import 'recipe_controller.dart';
import 'recipe_list_region.dart';
import 'target_region.dart';

/// The Recipes screen: the single surface the painter mixes a target colour
/// through (wireframe S1.R1, elements E22–E25, the recipe list and the gamut
/// banner).
///
/// A pure view over the [RecipeController] it is given (owned by
/// [RecipesHomeScreen], which also wraps this subtree in the `RecipeReadEndpoint`
/// the acceptance suite observes), mirroring bs-03's `ComparisonScreen`. It lays
/// out every region — the out-of-gamut banner, the target, the wet/dry controls
/// and the recipe list — so the acceptance finders and the behaviour phases have
/// stable anchors. This shell renders placeholders and disabled controls; each
/// region's real reading and each action land in their behaviour phase
/// (RECIPE-3/4, ENGINE-2..6). The "Recipes" app bar and the target render keep
/// bs-01's AC-11 handoff green.
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({required this.controller, super.key});

  /// The controller every region reads and (later) acts on.
  final RecipeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TargetRegion(controller: controller),
                const SizedBox(height: 12),
                ControlsRegion(controller: controller),
                const SizedBox(height: 12),
                // The out-of-gamut banner (ENGINE-5) sits just above the recipe
                // list it qualifies; hidden in this shell.
                GamutBanner(controller: controller),
                RecipeListRegion(controller: controller),
              ],
            );
          },
        ),
      ),
    );
  }
}
