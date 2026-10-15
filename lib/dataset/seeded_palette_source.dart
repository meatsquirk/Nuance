import '../recipes/palette.dart';
import '../recipes/palette_source.dart';
import 'seed_dataset.dart';

/// A [PaletteSource] over the shipped seed dataset (bs-13 SEED).
///
/// Exposes the seed's optical [SeedPaintEntry]s as a single named
/// [PaintPalette] the recipes solver can mix from (AC-1), behind the frozen
/// bs-04 [PaletteSource] seam so the Recipes feature stays unchanged. The
/// palette is named `"<brand> <medium>"` from the dataset's own scope (AC-11).
///
/// An **empty** dataset (the SEED-2 shell) lists **no** palette — [palettes]
/// returns `[]`, not a named empty palette — so composing it with the painter's
/// palettes is behaviour-neutral until SEED-3 ships the real asset.
class SeededPaletteSource implements PaletteSource {
  /// Creates a source over the loaded [dataset].
  const SeededPaletteSource(this.dataset);

  /// The shipped seed the palette is drawn from.
  final SeedDataset dataset;

  @override
  List<PaintPalette> palettes() {
    if (dataset.isEmpty) return const [];
    return [
      PaintPalette(
        name: '${dataset.brand} ${dataset.medium?.name ?? ''}'.trim(),
        paints: [for (final entry in dataset.entries) entry.toPaint()],
      ),
    ];
  }
}

/// A [PaletteSource] that concatenates several sources, in order (bs-13 SEED).
///
/// The seam `buildApp` composes so the always-available shipped seed and the
/// painter's own palettes coexist behind one [PaletteSource] (SEED interface
/// reconciliation): the seed is listed first, the painter's palettes add to it.
/// Composing with an empty [SeededPaletteSource] lists exactly the painter's
/// palettes, keeping the shell behaviour-neutral.
class CompositePaletteSource implements PaletteSource {
  /// Creates a source over [sources], listed in the given order.
  const CompositePaletteSource(this.sources);

  /// The composed sources, read front to back.
  final List<PaletteSource> sources;

  @override
  List<PaintPalette> palettes() =>
      [for (final source in sources) ...source.palettes()];
}
