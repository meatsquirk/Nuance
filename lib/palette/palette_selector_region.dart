import 'package:flutter/material.dart';

import 'palette_controller.dart';

/// The palette-selection region of the Palette screen's My-paints view
/// (wireframe S1.R1 — the palette-selection body).
///
/// Lists the painter's named palettes and shows which one is active, read from
/// [PaletteController.palettes] / [PaletteController.selectedPalette]. Tapping a
/// palette makes it the active one via [PaletteController.selectPalette], which
/// re-points recipe search at it (AC-5, PALETTE-4). The active palette is marked
/// "(active)"; an empty catalogue shows a placeholder. The region keeps its
/// [regionKey] so the acceptance finder has a stable anchor.
class PaletteSelectorRegion extends StatelessWidget {
  const PaletteSelectorRegion({required this.controller, super.key});

  /// Stable anchor for the palette-selection region (AC-5).
  static const Key regionKey = ValueKey('palette-selector-region');

  /// The key of the tappable option for the palette named [name] (AC-5).
  static Key optionKeyFor(String name) => ValueKey('palette-option-$name');

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
            InkWell(
              key: optionKeyFor(palette.name),
              onTap: () => controller.selectPalette(palette),
              // A11Y-3 (AC-4): a bare-text option's tap target is only as tall
              // as the glyphs (~20dp); reserve the 48dp minimum interactive
              // height so the whole row is a conformant target.
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    palette.name == selected?.name
                        ? '${palette.name} (active)'
                        : palette.name,
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
