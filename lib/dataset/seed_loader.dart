import 'seed_dataset.dart';

/// Loads the shipped seed dataset at app assembly (bs-13 SEED).
///
/// A minimal read-only seam, mirroring bs-06's `PersistentPaletteSource.load()`:
/// production loads the shipped asset once before [buildApp] assembles the app
/// and passes the result as `AppDependencies.seedDataset`, while the acceptance
/// suite injects a dataset directly. The load is asynchronous because the real
/// implementation reads a bundled asset; the recipes solve path reads the loaded
/// dataset synchronously thereafter.
abstract interface class SeedLoader {
  /// Loads and parses the shipped seed into a [SeedDataset].
  Future<SeedDataset> load();
}

/// A [SeedLoader] that reads the shipped seed JSON from the asset bundle.
///
/// **Shell (SEED-2):** [load] returns the empty placeholder
/// [SeedDataset.empty] so assembly is behaviour-neutral — no seed palette is
/// listed and no manifest ships. **SEED-3** authors the asset
/// (`assets/paints/<brand>_<medium>_seed.json`) and makes [load] read and parse
/// it into the real dataset; the asset path is held here so that change does not
/// touch the assembly wiring.
class AssetSeedLoader implements SeedLoader {
  /// Creates a loader over the bundled seed asset at [assetPath].
  const AssetSeedLoader({this.assetPath = defaultAssetPath});

  /// The default shipped-seed asset path (populated in SEED-3).
  static const String defaultAssetPath = 'assets/paints/seed.json';

  /// The asset the loader reads the seed from.
  final String assetPath;

  @override
  Future<SeedDataset> load() async => const SeedDataset.empty();
}
