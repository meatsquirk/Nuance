import 'package:flutter/material.dart';

import 'recipe_controller.dart';
import 'recipe_state.dart';

/// The controls region of the Recipes screen (wireframe S1.R1.E24 — the wet or
/// dry toggle).
///
/// Shows which prediction the recipes are for — wet or dry — read from
/// [RecipeController.state]'s [MixMode], as a segmented toggle. Switching the
/// toggle drives [RecipeController.setMode], re-rendering the recipes for the
/// chosen mode so the painter can see the predicted dry colour (AC-10). The
/// region keeps its [regionKey] so the acceptance finders have a stable anchor.
class ControlsRegion extends StatelessWidget {
  const ControlsRegion({required this.controller, super.key});

  /// Stable anchor for the controls region.
  static const Key regionKey = ValueKey('recipes-controls-region');

  /// The controller supplying the current wet/dry mode (and, later, the toggle
  /// action).
  final RecipeController controller;

  @override
  Widget build(BuildContext context) {
    final mode = controller.state.mode;
    return Row(
      key: regionKey,
      children: [
        // Bold so the field label meets the AA contrast floor (AC-5): at 14px
        // regular the contrast guideline samples anti-aliased edges of the thin
        // glyphs and under-reads the true onSurface contrast; a bold weight
        // gives the label solid-coloured glyphs (and the legible-text 3:1
        // threshold).
        const Text('Wet or dry:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        // E24 Wet or dry toggle — reflects the current mode and switches the
        // prediction between wet and dry (AC-10 / ENGINE-6). Single-select, so
        // the callback's set holds exactly the chosen mode.
        SegmentedButton<MixMode>(
          segments: const [
            ButtonSegment(value: MixMode.wet, label: Text('Wet')),
            ButtonSegment(value: MixMode.dry, label: Text('Dry')),
          ],
          selected: {mode},
          onSelectionChanged: (selection) =>
              controller.setMode(selection.first),
        ),
      ],
    );
  }
}
