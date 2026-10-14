import 'package:flutter/material.dart';

import '../app/build_app.dart';
import '../color_science/color_science.dart';
import '../domain/paint.dart';
import '../widgets/paint_row.dart';
import 'palette_controller.dart';

/// The paint-list region of the Palette screen's My-paints view (wireframe
/// S1.R1 — the paint list body, element E32 Add paint).
///
/// Lists the paints in the painter's "My paints" palette, read from
/// [PaletteController.myPaints], and offers the E32 add-paint control. Each
/// paint renders as a [PaintRow] — its identity (brand/line/medium/pigment
/// index) with a provenance **badge**, never colour alone (AC-2, PALETTE-3) —
/// or an empty-state placeholder. PALETTE-2 (AC-4) wires the add control to open the
/// reviewed-dataset picker: choosing a paint adds it to "My paints" through
/// [PaletteController.addPaintFromDataset]. The region keeps its [regionKey] and
/// the add control its [addPaintKey] so the acceptance finders and the later
/// behaviour phases have stable anchors.
class PaintListRegion extends StatelessWidget {
  const PaintListRegion({required this.controller, super.key});

  /// Stable anchor for the paint-list region (AC-1 toggles its presence).
  static const Key regionKey = ValueKey('palette-paint-list-region');

  /// Stable anchor for the E32 add-paint control (wired by PALETTE-2, AC-4).
  static const Key addPaintKey = ValueKey('palette-add-paint-button');

  /// Stable anchor for the reviewed-dataset picker the add control opens (AC-4).
  static const Key datasetPickerKey = ValueKey('palette-dataset-picker');

  /// The controller supplying the painter's paints.
  final PaletteController controller;

  @override
  Widget build(BuildContext context) {
    final paints = controller.myPaints;
    // The colour science that renders a paint's masstone to its display sRGB
    // swatch (bs-10 AC-9), from the enclosing AppScope. Null in a standalone
    // context (no scope); then each row renders its name as plain text and no
    // swatch — exactly the pre-bs-10 layout.
    final science = AppScope.maybeOf(context)?.colorScience;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My paints', style: Theme.of(context).textTheme.titleMedium),
        if (paints.isEmpty)
          const Text('No paints yet')
        else
          // Each paint renders its identity (brand/line/medium/pigment index)
          // and a provenance badge — never colour alone (AC-2) — plus a
          // decorative masstone swatch routed through the shared display
          // chokepoint, so daltonization remaps it on this screen too (AC-9).
          for (final paint in paints)
            PaintRow(
              paint: paint,
              swatchColor: science == null
                  ? null
                  : _masstoneSwatch(science, paint),
            ),
        // E32 Add paint (AC-4): opens the reviewed-dataset picker; choosing a
        // paint adds it to "My paints" with its dataset provenance preserved.
        TextButton(
          key: addPaintKey,
          onPressed: () => _openDatasetPicker(context),
          child: const Text('Add paint'),
        ),
      ],
    );
  }

  /// Opens the reviewed-dataset picker and adds the chosen paint (AC-4).
  ///
  /// The painter may add only from the reviewed [PaletteController.reviewedDataset]
  /// (no free-hand values, D-3). The picker returns the exact dataset [Paint]
  /// the painter taps, which [PaletteController.addPaintFromDataset] appends to
  /// "My paints" with its provenance preserved; dismissing the picker adds
  /// nothing.
  Future<void> _openDatasetPicker(BuildContext context) async {
    final chosen = await showModalBottomSheet<Paint>(
      context: context,
      builder: (context) => ListView(
        key: datasetPickerKey,
        children: [
          for (final paint in controller.reviewedDataset)
            ListTile(
              title: Text(paint.name),
              onTap: () => Navigator.of(context).pop(paint),
            ),
        ],
      ),
    );
    if (chosen != null) {
      await controller.addPaintFromDataset(chosen);
    }
  }

  /// The true display sRGB colour of [paint]'s masstone, via [science] — the
  /// colour [PaintRow] hands to its [ColorChip] for the decorative swatch, which
  /// the shared chokepoint then remaps under daltonization (bs-10 AC-9). The
  /// swatch is the paint's own masstone; the remap is applied at render time at
  /// the chokepoint, never written back (AC-8).
  static Color _masstoneSwatch(ColorScience science, Paint paint) {
    final SRGBColor s = science.toSRGB(paint.masstone);
    return Color.fromARGB(255, s.red, s.green, s.blue);
  }
}
