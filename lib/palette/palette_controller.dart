import 'package:flutter/foundation.dart';

import '../domain/paint.dart';
import '../recipes/palette.dart';
import '../recipes/palette_source.dart';
import 'paint_dataset.dart';

/// The Palette screen's state: the painter's palettes, the active (selected)
/// palette and the reviewed dataset they may add from (bs-06 PALETTE-1).
///
/// A [ChangeNotifier] skeleton over a [PaletteSource], mirroring the bs-04
/// `RecipeController` pattern. PALETTE-1 ships the state and reads only:
/// [palettes] and [myPaints] come from the injected source, and [selectPalette]
/// tracks which palette is active on this screen. The AC behaviour lands in the
/// behaviour phases: PALETTE-2 adds `addPaintFromDataset` (persisting through
/// [PersistentPaletteSource.savePalette]); PALETTE-4 wires [selectPalette] on to
/// the bs-04 `RecipeController.selectPalette` so recipes re-solve against the
/// selected palette (AC-5, D-5). No mixing or recipe code is reopened here.
class PaletteController extends ChangeNotifier {
  /// Creates the controller over [source], offering [reviewedDataset] as the
  /// paints that may be added (the shipped [kReviewedPaints] by default).
  ///
  /// The initially selected palette is the first the source lists, or null when
  /// the catalogue is empty (the shell's default state).
  PaletteController({
    required PaletteSource source,
    this.reviewedDataset = kReviewedPaints,
  }) {
    _palettes = source.palettes();
    _selectedPalette = _palettes.isEmpty ? null : _palettes.first;
  }

  /// The canonical name of the painter's default palette (spec: "My paints").
  static const String myPaintsName = 'My paints';

  /// The reviewed paints the painter may add from (AC-4; no free-hand values).
  final List<Paint> reviewedDataset;

  late List<PaintPalette> _palettes;
  PaintPalette? _selectedPalette;

  /// The painter's palettes, in listing order (read-only).
  List<PaintPalette> get palettes => List<PaintPalette>.unmodifiable(_palettes);

  /// The active palette recipes solve against (AC-5), or null when none.
  PaintPalette? get selectedPalette => _selectedPalette;

  /// The paints in the "My paints" palette the list view shows (AC-2), or an
  /// empty list when there is no such palette yet.
  List<Paint> get myPaints {
    for (final palette in _palettes) {
      if (palette.name == myPaintsName) {
        return List<Paint>.unmodifiable(palette.paints);
      }
    }
    return const [];
  }

  /// Makes [palette] the active palette and notifies listeners.
  ///
  /// A no-op when [palette] is already selected. PALETTE-4 extends this to also
  /// re-point the bs-04 `RecipeController` so recipe search re-solves against
  /// the selection (AC-5); here it only tracks the screen's active palette.
  void selectPalette(PaintPalette palette) {
    if (palette == _selectedPalette) return;
    _selectedPalette = palette;
    notifyListeners();
  }
}
