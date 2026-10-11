import 'package:flutter/material.dart';

import '../domain/paint.dart';
import 'palette_controller.dart';

/// The paint-list region of the Palette screen's My-paints view (wireframe
/// S1.R1 — the paint list body, element E32 Add paint).
///
/// Lists the paints in the painter's "My paints" palette, read from
/// [PaletteController.myPaints], and offers the E32 add-paint control. This
/// region renders each paint by name with an empty-state placeholder; the real
/// row rendering (brand/line/medium/pigment index + a provenance **badge**,
/// AC-2) lands in PALETTE-3. PALETTE-2 (AC-4) wires the add control to open the
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
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My paints', style: Theme.of(context).textTheme.titleMedium),
        if (paints.isEmpty)
          const Text('No paints yet')
        else
          for (final paint in paints) Text(paint.name),
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
}
