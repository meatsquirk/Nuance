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
/// SEED-3 parsed the optical [entries] and the seed's scope only; SEED-4 adds
/// the LLM `candidateMappings` section (AC-2) and the ingest rule (AC-4); SEED-5
/// adds the held-out validation [ValidationManifest] (AC-5/AC-6). The `manifest`
/// section is optional — a seed without one yields the non-shippable
/// [ValidationManifest.empty], so a seed that records no held-out run can never
/// ship (AC-6).
///
/// The `candidateMappings` section is optional — a seed with no candidate
/// combinations yields an empty list — and the loader **stamps** every mapping
/// with [SeedOrigin.llmSeed] rather than trusting an origin from the asset: a
/// candidate combination is always an unverified LLM proposal of *which* paints
/// to mix (AC-2); the parts are the solver's, never the seed's (AC-3).
SeedDataset parseSeedDataset(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  final brand = json['brand'] as String;
  final medium = PaintMedium.values.byName(json['medium'] as String);
  final entries = <SeedPaintEntry>[
    for (final raw in (json['entries'] as List).cast<Map<String, dynamic>>())
      _entryFrom(raw, brand: brand, medium: medium),
  ];
  final candidateMappings = <CandidateMapping>[
    for (final raw in ((json['candidateMappings'] as List?) ?? const [])
        .cast<Map<String, dynamic>>())
      CandidateMapping(
        targetDescriptor: raw['targetDescriptor'] as String,
        candidatePaintIds: (raw['candidatePaintIds'] as List).cast<String>(),
        // Stamped, not read: a candidate combination is an LLM proposal (AC-2).
        origin: SeedOrigin.llmSeed,
      ),
  ];
  return SeedDataset(
    brand: brand,
    medium: medium,
    entries: entries,
    candidateMappings: candidateMappings,
    manifest: _manifestFrom(json['manifest'] as Map<String, dynamic>?),
  );
}

/// Parses the optional held-out validation `manifest` section (AC-5/AC-6).
///
/// A seed that records no held-out run (no `manifest` key) yields the
/// non-shippable [ValidationManifest.empty] — it can never ship (AC-6). When the
/// section is present, the recorded held-out count, the per-recipe ΔE00
/// [ValidationManifest.deltaE00Distribution], the hybrid and LLM-alone mean
/// errors and the usable threshold are read verbatim; the ship decision is the
/// manifest's own [ValidationManifest.shippable].
ValidationManifest _manifestFrom(Map<String, dynamic>? raw) {
  if (raw == null) return const ValidationManifest.empty();
  return ValidationManifest(
    heldOutCount: raw['heldOutCount'] as int,
    deltaE00Distribution: <double>[
      for (final value in (raw['deltaE00Distribution'] as List))
        (value as num).toDouble(),
    ],
    hybridMeanDeltaE00: (raw['hybridMeanDeltaE00'] as num).toDouble(),
    llmAloneMeanDeltaE00: (raw['llmAloneMeanDeltaE00'] as num).toDouble(),
    usableThreshold: (raw['usableThreshold'] as num).toDouble(),
  );
}

/// Input-record field names the ingest **rejects**: an LLM-*claimed* spectral
/// (reflectance) curve or mix ratio is never stored (bs-13 AC-4). Measured
/// optical data (the masstone) and the physics solver own these — a claimed
/// curve or ratio on an input record is stripped before the stored
/// [SeedPaintEntry] is built, so no LLM-asserted measured value can enter the
/// dataset through the asset. The accepted LLM metadata (pigment index, opacity,
/// lightfastness) is retained.
const Set<String> kRejectedClaimedFields = {
  'spectralCurve',
  'reflectanceCurve',
  'spectral',
  'ratio',
  'ratios',
  'parts',
  'partsFraction',
};

/// Applies the AC-4 ingest rule to an entry's JSON [raw]: returns a record
/// carrying only the non-claimed fields, dropping any [kRejectedClaimedFields]
/// key. The accepted metadata and the measured masstone survive; an LLM-claimed
/// spectral curve or ratio does not.
Map<String, dynamic> ingestEntryRecord(Map<String, dynamic> raw) => {
      for (final field in raw.entries)
        if (!kRejectedClaimedFields.contains(field.key)) field.key: field.value,
    };

/// Builds one [SeedPaintEntry] from its JSON [raw], stamping the seed-wide
/// [brand] and [medium] onto it (AC-11). The record first passes through the
/// [ingestEntryRecord] rule (AC-4) so any LLM-claimed spectral curve or ratio is
/// stripped before the entry is constructed from its accepted fields.
SeedPaintEntry _entryFrom(
  Map<String, dynamic> raw, {
  required String brand,
  required PaintMedium medium,
}) {
  final accepted = ingestEntryRecord(raw);
  final masstone = accepted['masstone'] as Map<String, dynamic>;
  return SeedPaintEntry(
    id: accepted['id'] as String,
    name: accepted['name'] as String,
    brand: brand,
    medium: medium,
    masstone: ColorCoordinates(
      lightness: (masstone['l'] as num).toDouble(),
      a: (masstone['a'] as num).toDouble(),
      b: (masstone['b'] as num).toDouble(),
    ),
    pigmentIndex: accepted['pigmentIndex'] as String,
    opacity: (accepted['opacity'] as num).toDouble(),
    lightfastness: accepted['lightfastness'] as String,
    origin: SeedOrigin.values.byName(accepted['origin'] as String),
  );
}
