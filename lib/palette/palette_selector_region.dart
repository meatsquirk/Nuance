import 'package:flutter/material.dart';

import 'palette_controller.dart';

/// The palette-selection region of the Palette screen's My-paints view
/// (wireframe S1.R1 — the palette-selection body).
///
/// Lists the painter's named palettes and shows which one is active, read from
/// [PaletteController.palettes] / [PaletteController.selectedPalette]. Selecting
/// a palette re-points recipe search at it (AC-5); that wiring lands in
/// PALETTE-4, so this shell renders each palette name (with the active one
/// marked) and an empty-state placeholder, with no selection action yet. The
/// region keeps its [regionKey] so the acceptance finder and PALETTE-4 have a
/// stable anchor.
class PaletteSelectorRegion extends StatelessWidget {
  const PaletteSelectorRegion({required this.controller, super.key});

  /// Stable anchor for the palette-selection region (AC-5).
  static const Key regionKey = ValueKey('palette-selector-region');

  /// The controller supplying the painter's palettes and the active one.
  final PaletteController controller;

  @override
  Widget build(BuildContext context) {
    final palettes = controller.palettes;
    final selected = controller.selectedPalette;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Palettes', style: Theme.of(context).textTheme.titleMedium),
        if (palettes.isEmpty)
          const Text('No palettes yet')
        else
          for (final palette in palettes)
            Text(
              palette.name == selected?.name
                  ? '${palette.name} (active)'
                  : palette.name,
            ),
      ],
    );
  }
}
