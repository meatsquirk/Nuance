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
/// the bs-04 `RecipeController.selectPalette` via [onPaletteSelected] so recipes
/// re-solve against the selected palette (AC-5, D-5). No mixing or recipe code
/// is reopened here — only the frozen `selectPalette` API is reused.
class PaletteController extends ChangeNotifier {
  /// Creates the controller over [source], offering [reviewedDataset] as the
  /// paints that may be added (the shipped [kReviewedPaints] by default).
  ///
  /// The initially selected palette is the first the source lists, or null when
  /// the catalogue is empty (the shell's default state).
  PaletteController({
    required PaletteSource source,
    this.reviewedDataset = kReviewedPaints,
    this.onPaletteSelected,
  }) : _source = source {
    _palettes = source.palettes();
    _selectedPalette = _palettes.isEmpty ? null : _palettes.first;
  }

  /// The canonical name of the painter's default palette (spec: "My paints").
  static const String myPaintsName = 'My paints';

  /// The reviewed paints the painter may add from (AC-4; no free-hand values).
  final List<Paint> reviewedDataset;

  /// Re-points recipe search when the painter selects a palette (AC-5, D-5).
  ///
  /// Invoked from [selectPalette] with the newly-active palette so the Palette
  /// screen can call the bs-04 `RecipeController.selectPalette` (wired by
  /// `PaletteHomeScreen`), which re-solves recipes against only that palette.
  /// Null in the shell and unit contexts that have no recipe surface; the
  /// callback — not a direct `RecipeController` reference — keeps this controller
  /// decoupled from the recipes feature (the screen owns the wiring). It fires
  /// only on an actual change (the no-op guard in [selectPalette] returns first).
  final void Function(PaintPalette palette)? onPaletteSelected;

  /// The palette catalogue seam. Read in the constructor to seed [palettes];
  /// when it can persist (a [PersistentPaletteSource]), [addPaintFromDataset]
  /// saves the updated "My paints" palette through it so the add survives a
  /// restart.
  final PaletteSource _source;

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

  /// Makes [palette] the active palette, notifies listeners and re-points recipe
  /// search at it (AC-5).
  ///
  /// A no-op when [palette] is already selected (so recipes are not needlessly
  /// re-solved). Otherwise the screen's active palette moves and, through
  /// [onPaletteSelected], the bs-04 `RecipeController` re-solves recipes against
  /// only the selected palette (D-5) — the solve code itself is untouched.
  void selectPalette(PaintPalette palette) {
    if (palette == _selectedPalette) return;
    _selectedPalette = palette;
    notifyListeners();
    onPaletteSelected?.call(palette);
  }

  /// Adds [paint] — chosen from the reviewed [reviewedDataset] — to the "My
  /// paints" palette and persists the palette (AC-4).
  ///
  /// The paint is appended to "My paints" exactly as the dataset holds it, so
  /// its provenance tier, pigment index and masstone are preserved (no
  /// free-hand or blanked value). If there is no "My paints" palette yet, one is
  /// created to hold it. When [_source] can persist (a [PersistentPaletteSource]
  /// — the production and acceptance wiring), the updated palette is saved
  /// through it so the add survives a restart; an in-memory source (the shell
  /// and unit tests) keeps the add in memory only. Listeners are notified so the
  /// paint list re-renders.
  Future<void> addPaintFromDataset(Paint paint) async {
    final current = _myPaintsPalette();
    final updated = PaintPalette(
      name: myPaintsName,
      paints: [...?current?.paints, paint],
    );
    _replaceMyPaints(updated);
    final source = _source;
    if (source is PersistentPaletteSource) {
      await source.savePalette(updated);
    }
    notifyListeners();
  }

  /// The painter's "My paints" palette, or null when there is none yet.
  PaintPalette? _myPaintsPalette() {
    for (final palette in _palettes) {
      if (palette.name == myPaintsName) return palette;
    }
    return null;
  }

  /// Replaces the "My paints" palette with [updated] (appending it when there is
  /// none yet), keeping the active palette pointed at it when it was selected.
  void _replaceMyPaints(PaintPalette updated) {
    final next = <PaintPalette>[];
    var replaced = false;
    for (final palette in _palettes) {
      if (palette.name == myPaintsName) {
        next.add(updated);
        replaced = true;
      } else {
        next.add(palette);
      }
    }
    if (!replaced) next.add(updated);
    _palettes = next;
    if (_selectedPalette == null || _selectedPalette!.name == myPaintsName) {
      _selectedPalette = updated;
    }
  }
}
