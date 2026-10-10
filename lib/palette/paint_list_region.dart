import 'package:flutter/material.dart';

import 'palette_controller.dart';

/// The paint-list region of the Palette screen's My-paints view (wireframe
/// S1.R1 — the paint list body, element E32 Add paint).
///
/// Lists the paints in the painter's "My paints" palette, read from
/// [PaletteController.myPaints], and offers the E32 add-paint control. This
/// shell renders each paint by name with an empty-state placeholder, and the
/// add control is present but inert: the real rendering (brand/line/medium/
/// pigment index + a provenance **badge**, AC-2) lands in PALETTE-3, and the
/// add-from-dataset flow (AC-4) in PALETTE-2. The region keeps its [regionKey]
/// and the add control its [addPaintKey] so the acceptance finders and those
/// behaviour phases have stable anchors.
class PaintListRegion extends StatelessWidget {
  const PaintListRegion({required this.controller, super.key});

  /// Stable anchor for the paint-list region (AC-1 toggles its presence).
  static const Key regionKey = ValueKey('palette-paint-list-region');

  /// Stable anchor for the E32 add-paint control (wired by PALETTE-2, AC-4).
  static const Key addPaintKey = ValueKey('palette-add-paint-button');

  /// The controller supplying the painter's paints.
  final PaletteController controller;

  @override
  Widget build(BuildContext context) {
    final paints = controller.myPaints;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My paints', style: Theme.of(context).textTheme.titleMedium),
        if (paints.isEmpty)
          const Text('No paints yet')
        else
          for (final paint in paints) Text(paint.name),
        // E32 Add paint — wired by PALETTE-2 (AC-4): opens the reviewed-dataset
        // picker. Inert in this shell.
        TextButton(
          key: addPaintKey,
          onPressed: null,
          child: const Text('Add paint'),
        ),
      ],
    );
  }
}
