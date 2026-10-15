import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/color_coordinates.dart';
import '../domain/paint.dart';
import 'seed_dataset.dart';
import 'validation_manifest.dart';

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
/// SEED-3 ships the asset (`assets/paints/winsor_newton_oil_seed.json`) — one
/// brand, one medium, ~15 reviewed optical entries (AC-1/AC-11) — and [load]
/// reads it through [rootBundle] and parses it with [parseSeedDataset]. The
/// asset path is held here so a later re-scope of the shipped seed does not
/// touch the assembly wiring. (The sibling `kReviewedPaints` catalogue mirrors a
/// CSV in a const; the seed instead parses its JSON asset directly, so the
/// shipped optical data has a single source of truth — AC-1's "solved, never
/// retrieved" rests on there being no second, divergent copy.)
class AssetSeedLoader implements SeedLoader {
  /// Creates a loader over the bundled seed asset at [assetPath].
  const AssetSeedLoader({this.assetPath = defaultAssetPath});

  /// The default shipped-seed asset path (`<brand>_<medium>_seed.json`, AC-11).
  static const String defaultAssetPath =
      'assets/paints/winsor_newton_oil_seed.json';

  /// The asset the loader reads the seed from.
  final String assetPath;

  @override
  Future<SeedDataset> load() async =>
      parseSeedDataset(await rootBundle.loadString(assetPath));
}

/// Parses the shipped-seed JSON [source] into a [SeedDataset] (read-only).
///
/// The dataset's `brand` and `medium` are the seed's single scope (AC-11); each
/// entry is stamped with them so a `SeedPaintEntry` carries the one brand and
/// medium the whole seed covers. An entry's `masstone` is the reviewed optical
/// CIELAB the solver mixes over (AC-1); `pigmentIndex`, `opacity` and
/// `lightfastness` are the LLM-trusted metadata (AC-4), and `origin` names the
/// provenance of the value. An unknown [PaintMedium] or [SeedOrigin] name throws
/// — the seed is a reviewed artifact, so a malformed record is a build error,
/// not a silent default (mirroring `parseReviewedPaints`).
///
/// SEED-3 parses the optical [entries] and the seed's scope only; the candidate
/// combinations (AC-2, SEED-4) and the held-out validation manifest (AC-5/AC-6,
/// SEED-5) are not part of the shipped asset yet, so the dataset carries an
/// empty mapping list and the non-shippable [ValidationManifest.empty]. Those
/// phases extend both the asset and this parser.
SeedDataset parseSeedDataset(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  final brand = json['brand'] as String;
  final medium = PaintMedium.values.byName(json['medium'] as String);
  final entries = <SeedPaintEntry>[
    for (final raw in (json['entries'] as List).cast<Map<String, dynamic>>())
      _entryFrom(raw, brand: brand, medium: medium),
  ];
  return SeedDataset(
    brand: brand,
    medium: medium,
    entries: entries,
    candidateMappings: const [],
    manifest: const ValidationManifest.empty(),
  );
}

/// Builds one [SeedPaintEntry] from its JSON [raw], stamping the seed-wide
/// [brand] and [medium] onto it (AC-11).
SeedPaintEntry _entryFrom(
  Map<String, dynamic> raw, {
  required String brand,
  required PaintMedium medium,
}) {
  final masstone = raw['masstone'] as Map<String, dynamic>;
  return SeedPaintEntry(
    id: raw['id'] as String,
    name: raw['name'] as String,
    brand: brand,
    medium: medium,
    masstone: ColorCoordinates(
      lightness: (masstone['l'] as num).toDouble(),
      a: (masstone['a'] as num).toDouble(),
      b: (masstone['b'] as num).toDouble(),
    ),
    pigmentIndex: raw['pigmentIndex'] as String,
    opacity: (raw['opacity'] as num).toDouble(),
    lightfastness: raw['lightfastness'] as String,
    origin: SeedOrigin.values.byName(raw['origin'] as String),
  );
}
