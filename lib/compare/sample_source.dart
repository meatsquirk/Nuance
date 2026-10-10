import '../capture/capture_accuracy.dart';
import '../domain/color_coordinates.dart';
import '../domain/provenance.dart';
import '../domain/sample.dart';
import '../store/persistent_store.dart';

/// The saved samples the comparison picker lists (D-7).
///
/// A minimal read-only seam over the painter's saved colours: the picker (E3/E5
/// via E49) and every selection Given read the catalogue through this interface
/// rather than from a store, so bs-03 stays independent of persistence. bs-03
/// ships the in-memory [InMemorySampleSource]; **bs-06** (palette & projects)
/// later supplies a persistent catalogue behind this same interface without
/// touching the comparison code.
abstract interface class SampleSource {
  /// The saved samples available to compare, in listing order.
  List<Sample> savedSamples();
}

/// An in-memory [SampleSource] over a fixed list of samples.
///
/// The bs-03 default: an **empty** catalogue (`const InMemorySampleSource()`),
/// so the shell assembles with no saved samples. **COMPARE-3** constructs one
/// seeded with the named saved samples the picker offers; the list is exposed
/// read-only so callers cannot mutate the catalogue through [savedSamples].
class InMemorySampleSource implements SampleSource {
  /// Creates a catalogue over [samples] (empty by default).
  const InMemorySampleSource({this.samples = const []});

  /// The saved samples this catalogue holds.
  final List<Sample> samples;

  @override
  List<Sample> savedSamples() => List<Sample>.unmodifiable(samples);
}

/// A [SampleSource] persisted through the on-device [PersistentStore] (bs-06
/// D-1).
///
/// The write-side bs-06 adds behind the existing read-only seam: the painter's
/// saved samples (the ones projects are built from) are stored as JSON documents
/// keyed by a caller-chosen id in the store's [collection]. The comparison
/// picker still reads them synchronously through [savedSamples] (bs-03), so the
/// persisted catalogue is held in an in-memory cache that [load] populates from
/// the store once at startup; [saveSample] is the create/replace the PROJECT
/// behaviour phases drive (the PROJECT-2 enabler saves the samples a project
/// gathers). The sample↔JSON mapping ([sampleToJson] / [sampleFromJson]) is
/// reused by the persistent `ProjectSource` for the samples a project embeds, so
/// the store stays a generic document store that knows nothing of the schema.
class PersistentSampleSource implements SampleSource {
  /// Creates a source over [store]; call [load] before the catalogue is read.
  PersistentSampleSource(this._store);

  /// The store collection the saved-sample documents live in.
  static const String collection = 'samples';

  final PersistentStore _store;

  List<Sample> _cache = const [];

  /// Loads the stored samples into the in-memory cache [savedSamples] serves.
  ///
  /// Must be awaited before the (synchronous) [savedSamples] is read — the
  /// comparison picker reads the catalogue without awaiting. Safe to call again
  /// to refresh after a write.
  Future<void> load() async {
    final docs = await _store.list(collection);
    _cache = [for (final doc in docs) sampleFromJson(doc.data)];
  }

  @override
  List<Sample> savedSamples() => List<Sample>.unmodifiable(_cache);

  /// Persists [sample] under [id] (create or replace) and refreshes the cache so
  /// a later [savedSamples] read reflects the write.
  Future<void> saveSample(String id, Sample sample) async {
    await _store.put(collection, id, sampleToJson(sample));
    await load();
  }
}

/// Serialises [sample] to the JSON-shaped map the store persists.
///
/// Reused by the persistent `ProjectSource` for the samples a project embeds, so
/// a sample round-trips identically whether saved to the catalogue or inside a
/// project. Enums are stored as their names; coordinates as their three CIELAB
/// numbers; the append-ready [Sample.evidence] as a list of `{coordinates,
/// source}` maps (SI D9).
Map<String, Object?> sampleToJson(Sample sample) => {
      'coordinates': _coordsToJson(sample.coordinates),
      'provenance': {
        'tier': sample.provenance.tier.name,
        'note': sample.provenance.note,
      },
      'name': sample.name,
      'justCaptured': sample.justCaptured,
      'accuracy': sample.accuracy?.name,
      'evidence': [
        for (final point in sample.evidence)
          {
            'coordinates': _coordsToJson(point.coordinates),
            'source': point.source,
          },
      ],
    };

/// Reconstructs a [Sample] from a stored document [json].
Sample sampleFromJson(Map<String, Object?> json) {
  final provenance = (json['provenance'] as Map).cast<String, Object?>();
  final accuracy = json['accuracy'] as String?;
  return Sample(
    coordinates: _coordsFromJson((json['coordinates'] as Map).cast()),
    provenance: Provenance(
      ProvenanceTier.values.byName(provenance['tier'] as String),
      note: provenance['note'] as String?,
    ),
    name: json['name'] as String?,
    justCaptured: json['justCaptured'] as bool,
    accuracy:
        accuracy == null ? null : CaptureAccuracy.values.byName(accuracy),
    evidence: [
      for (final point in json['evidence'] as List)
        EvidencePoint(
          coordinates:
              _coordsFromJson((point as Map)['coordinates'] as Map),
          source: point['source'] as String,
        ),
    ],
  );
}

/// Serialises CIELAB [coords] to a `{l, a, b}` map.
Map<String, Object?> _coordsToJson(ColorCoordinates coords) => {
      'l': coords.lightness,
      'a': coords.a,
      'b': coords.b,
    };

/// Reconstructs [ColorCoordinates] from a `{l, a, b}` map.
ColorCoordinates _coordsFromJson(Map<Object?, Object?> json) => ColorCoordinates(
      lightness: (json['l'] as num).toDouble(),
      a: (json['a'] as num).toDouble(),
      b: (json['b'] as num).toDouble(),
    );
