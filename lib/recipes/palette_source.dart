import 'palette.dart';

/// The owned paint palettes the mixing solver may draw from (bs-04 D-5).
///
/// A minimal read-only seam over the painter's palettes, mirroring bs-03's
/// `SampleSource`: the target region and the solver read the available palettes
/// through this interface rather than from a store, so the Recipes feature stays
/// independent of persistence. bs-04 ships the in-memory
/// [InMemoryPaletteSource]; **bs-06** (palette & projects) later supplies a
/// persistent catalogue behind this same interface without touching the recipes
/// code. The *selected* palette is not held here — it is state on the
/// `RecipeController`; this seam only lists what is available.
abstract interface class PaletteSource {
  /// The palettes available to mix from, in listing order.
  List<PaintPalette> palettes();
}

/// An in-memory [PaletteSource] over a fixed list of palettes.
///
/// The bs-04 default: an **empty** catalogue (`const InMemoryPaletteSource()`),
/// so the shell assembles with no palettes. The acceptance harness (ITEST) and
/// the behaviour phases construct one seeded with named palettes of owned
/// `Paint`s; the list is exposed read-only so callers cannot mutate the
/// catalogue through [palettes].
class InMemoryPaletteSource implements PaletteSource {
  /// Creates a catalogue over [catalogue] (empty by default).
  const InMemoryPaletteSource({this.catalogue = const []});

  /// The palettes this catalogue holds, in listing order.
  final List<PaintPalette> catalogue;

  @override
  List<PaintPalette> palettes() => List<PaintPalette>.unmodifiable(catalogue);
}
