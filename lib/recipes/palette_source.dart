import '../domain/color_coordinates.dart';
import '../domain/paint.dart';
import '../domain/provenance.dart';
import '../store/persistent_store.dart';
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

/// A [PaletteSource] persisted through the on-device [PersistentStore] (bs-06
/// D-1).
///
/// The write-side bs-06 adds behind the existing read-only seam: palettes are
/// stored as JSON documents (one per palette, keyed by name) in the store's
/// [collection]. Because the recipes solve path reads [palettes] *synchronously*
/// (bs-04), the persistent catalogue is held in an in-memory cache that [load]
/// populates from the store once at startup; [savePalette] is the create/replace
/// the PALETTE behaviour phases drive (AC-4 adds a reviewed paint to a palette
/// and re-saves it). The paint↔JSON mapping lives here so the store stays a
/// generic document store (DATA-2) that knows nothing of the paint schema.
class PersistentPaletteSource implements PaletteSource {
  /// Creates a source over [store]; call [load] before the catalogue is read.
  PersistentPaletteSource(this._store);

  /// The store collection the palette documents live in.
  static const String collection = 'palettes';

  final PersistentStore _store;

  List<PaintPalette> _cache = const [];

  /// Loads the stored palettes into the in-memory cache [palettes] serves.
  ///
  /// Must be awaited before the (synchronous) [palettes] is read — the recipes
  /// solve path reads the catalogue without awaiting. Safe to call again to
  /// refresh after a write.
  Future<void> load() async {
    final docs = await _store.list(collection);
    _cache = [for (final doc in docs) _paletteFromJson(doc.data)];
  }

  @override
  List<PaintPalette> palettes() => List<PaintPalette>.unmodifiable(_cache);

  /// Persists [palette] (create or replace, keyed by its name) and refreshes the
  /// cache so a later [palettes] read reflects the write.
  Future<void> savePalette(PaintPalette palette) async {
    await _store.put(collection, palette.name, _paletteToJson(palette));
    await load();
  }
}

/// Serialises [palette] to the JSON-shaped map the store persists.
Map<String, Object?> _paletteToJson(PaintPalette palette) => {
      'name': palette.name,
      'paints': [for (final paint in palette.paints) _paintToJson(paint)],
    };

/// Reconstructs a [PaintPalette] from a stored document [json].
PaintPalette _paletteFromJson(Map<String, Object?> json) => PaintPalette(
      name: json['name'] as String,
      paints: [
        for (final paint in json['paints'] as List)
          _paintFromJson((paint as Map).cast<String, Object?>()),
      ],
    );

/// Serialises [paint] to a JSON-shaped map (enums as their names; the masstone
/// as its three CIELAB coordinates).
Map<String, Object?> _paintToJson(Paint paint) => {
      'id': paint.id,
      'name': paint.name,
      'medium': paint.medium.name,
      'masstone': {
        'l': paint.masstone.lightness,
        'a': paint.masstone.a,
        'b': paint.masstone.b,
      },
      'pigmentIndex': paint.pigmentIndex,
      'opacity': paint.opacity,
      'brand': paint.brand,
      'line': paint.line,
      'provenance': paint.provenance.name,
    };

/// Reconstructs a [Paint] from a stored document [json].
Paint _paintFromJson(Map<String, Object?> json) {
  final masstone = (json['masstone'] as Map).cast<String, Object?>();
  return Paint(
    id: json['id'] as String,
    name: json['name'] as String,
    medium: PaintMedium.values.byName(json['medium'] as String),
    masstone: ColorCoordinates(
      lightness: (masstone['l'] as num).toDouble(),
      a: (masstone['a'] as num).toDouble(),
      b: (masstone['b'] as num).toDouble(),
    ),
    pigmentIndex: json['pigmentIndex'] as String?,
    opacity: (json['opacity'] as num?)?.toDouble(),
    brand: json['brand'] as String?,
    line: json['line'] as String?,
    provenance: ProvenanceTier.values.byName(json['provenance'] as String),
  );
}
