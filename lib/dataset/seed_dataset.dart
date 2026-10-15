import 'package:flutter/foundation.dart';

import '../domain/color_coordinates.dart';
import '../domain/paint.dart';
import 'validation_manifest.dart';

/// Where a seed record's value came from (bs-13 D-9 provenance, shell seam).
///
/// A **local placeholder** introduced by SEED-2 so the seed schema can stamp an
/// origin before PROV-1 lands. It is reconciled to the runtime `EvidenceKind`
/// (`lib/domain/sample.dart`, PROV module) at SEED-4; only the two origins the
/// seed itself produces are modelled here:
///
/// - [reviewedOptical] — the reviewed measured optical data of a paint (its
///   masstone), the solver's trusted input.
/// - [llmSeed] — a value the LLM proposed (the candidate paint combinations,
///   AC-2), unverified until physical evidence promotes it.
enum SeedOrigin {
  /// Reviewed measured optical data (a paint's masstone).
  reviewedOptical,

  /// Proposed by the LLM and not yet verified (candidate combinations).
  llmSeed,
}

/// One paint in the shipped seed dataset: the solver's optical atom plus the
/// LLM-trusted metadata and its provenance [origin] (bs-13 SEED).
///
/// Carries the masstone CIELAB (the optical data the physics solver mixes over,
/// never an RGB-to-recipe answer — AC-1) and the LLM-supplied metadata the
/// ingest rule accepts (pigment index, opacity, lightfastness — AC-4). It maps
/// to the frozen bs-04 [Paint] via [toPaint]; [lightfastness] is seed-only
/// metadata that does not appear on [Paint]. Value-equal and `const`.
@immutable
class SeedPaintEntry {
  /// Creates a seed entry; [id], [name], [brand], [medium] and [masstone] are
  /// required, the metadata fields optional, and [origin] defaults to the
  /// reviewed optical data the entry represents.
  const SeedPaintEntry({
    required this.id,
    required this.name,
    required this.brand,
    required this.medium,
    required this.masstone,
    this.pigmentIndex,
    this.opacity,
    this.lightfastness,
    this.origin = SeedOrigin.reviewedOptical,
  });

  /// Stable identity of the paint within the seed (keys candidate mappings).
  final String id;

  /// The painter-facing name (e.g. "Titanium White").
  final String name;

  /// The manufacturer the seed covers (one brand in v1, AC-11).
  final String brand;

  /// The binder the paint is ground in (one medium in v1, AC-11).
  final PaintMedium medium;

  /// The paint's masstone — its CIELAB colour at full strength (the optical
  /// data the solver mixes over, AC-1).
  final ColorCoordinates masstone;

  /// The Colour Index pigment code (e.g. "PW6"), or null when unknown — accepted
  /// LLM metadata (AC-4).
  final String? pigmentIndex;

  /// Hiding power on 0 (transparent) … 1 (opaque), or null — accepted metadata.
  final double? opacity;

  /// The lightfastness rating (e.g. "I"), or null — accepted seed-only metadata
  /// (AC-4); not carried on [Paint].
  final String? lightfastness;

  /// The provenance of this entry's optical value (defaults to reviewed data).
  final SeedOrigin origin;

  /// Maps this entry to the frozen bs-04 [Paint] the solver mixes over.
  ///
  /// Copies the optical data and the metadata [Paint] carries ([pigmentIndex],
  /// [opacity], [brand]); [lightfastness] is seed-only and dropped. The paint's
  /// `provenance` is left at [Paint]'s default — the runtime tier is derived by
  /// the PROV model (reconciled at SEED-4), not by the seed schema.
  Paint toPaint() => Paint(
        id: id,
        name: name,
        medium: medium,
        masstone: masstone,
        pigmentIndex: pigmentIndex,
        opacity: opacity,
        brand: brand,
      );

  @override
  bool operator ==(Object other) =>
      other is SeedPaintEntry &&
      other.id == id &&
      other.name == name &&
      other.brand == brand &&
      other.medium == medium &&
      other.masstone == masstone &&
      other.pigmentIndex == pigmentIndex &&
      other.opacity == opacity &&
      other.lightfastness == lightfastness &&
      other.origin == origin;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        brand,
        medium,
        masstone,
        pigmentIndex,
        opacity,
        lightfastness,
        origin,
      );

  @override
  String toString() => 'SeedPaintEntry($id, $name, ${medium.name})';
}

/// An LLM-proposed set of candidate paints for a target descriptor (bs-13 AC-2).
///
/// The LLM proposes *which* paints might mix toward a described target; the
/// physics solver (not this mapping) produces the ratios (AC-3). The [origin] is
/// therefore [SeedOrigin.llmSeed] — the mapping is an unverified proposal, never
/// a shipped answer. Value-equal and `const`.
@immutable
class CandidateMapping {
  /// Creates a mapping of [targetDescriptor] to [candidatePaintIds]; [origin]
  /// defaults to [SeedOrigin.llmSeed] (the LLM proposed it).
  const CandidateMapping({
    required this.targetDescriptor,
    required this.candidatePaintIds,
    this.origin = SeedOrigin.llmSeed,
  });

  /// The qualitative target the candidates are proposed for (e.g. "warm grey").
  final String targetDescriptor;

  /// The ids of the [SeedPaintEntry]s the LLM proposes for the target.
  final List<String> candidatePaintIds;

  /// The provenance of the proposal (the LLM seeded it).
  final SeedOrigin origin;

  @override
  bool operator ==(Object other) =>
      other is CandidateMapping &&
      other.targetDescriptor == targetDescriptor &&
      listEquals(other.candidatePaintIds, candidatePaintIds) &&
      other.origin == origin;

  @override
  int get hashCode => Object.hash(
        targetDescriptor,
        Object.hashAll(candidatePaintIds),
        origin,
      );

  @override
  String toString() =>
      'CandidateMapping("$targetDescriptor", ${candidatePaintIds.length} ids)';
}

/// The shipped seed dataset: optical [entries], the LLM [candidateMappings] and
/// the [manifest] that gates shipping (bs-13 SEED).
///
/// One [brand] and one [medium] in v1 (AC-11). The dataset stores optical data
/// and candidate proposals — never RGB-to-recipe answers (AC-1) and never
/// LLM-claimed spectral curves or ratios (AC-4). Value-equal and `const`.
@immutable
class SeedDataset {
  /// Creates a dataset over [entries], [candidateMappings] and a [manifest].
  const SeedDataset({
    required this.brand,
    required this.medium,
    required this.entries,
    required this.candidateMappings,
    required this.manifest,
  });

  /// The empty placeholder dataset the SEED-2 shell loads.
  ///
  /// No brand or medium, no entries or candidate mappings, and an empty,
  /// non-shippable [ValidationManifest] — so wiring it into the app is
  /// behaviour-neutral until SEED-3 ships the real asset.
  const SeedDataset.empty()
      : brand = '',
        medium = null,
        entries = const [],
        candidateMappings = const [],
        manifest = const ValidationManifest.empty();

  /// The one manufacturer the seed covers (AC-11); empty in the shell.
  final String brand;

  /// The one medium the seed covers (AC-11); null in the empty shell dataset.
  final PaintMedium? medium;

  /// The optical paint entries the solver mixes over (AC-1).
  final List<SeedPaintEntry> entries;

  /// The LLM's candidate paint combinations per target descriptor (AC-2).
  final List<CandidateMapping> candidateMappings;

  /// The Phase-0.5 validation record gating whether this dataset ships (AC-5/6).
  final ValidationManifest manifest;

  /// Whether this dataset has no paint entries (the empty shell placeholder).
  bool get isEmpty => entries.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is SeedDataset &&
      other.brand == brand &&
      other.medium == medium &&
      listEquals(other.entries, entries) &&
      listEquals(other.candidateMappings, candidateMappings) &&
      other.manifest == manifest;

  @override
  int get hashCode => Object.hash(
        brand,
        medium,
        Object.hashAll(entries),
        Object.hashAll(candidateMappings),
        manifest,
      );

  @override
  String toString() => 'SeedDataset($brand, ${medium?.name}, '
      '${entries.length} paints, ${candidateMappings.length} mappings)';
}
