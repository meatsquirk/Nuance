// Acceptance-suite harness for bs-13 Paint dataset integrity and provenance
// (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and controls the AC tests (ITEST-2,
// ITEST-3) are written against. The suite drives the *real* assembled app
// through the single production `buildApp` entry (bs-01 D-7): a scenario loads
// the shipped seed through the real `AssetSeedLoader`, injects it as
// `AppDependencies.seedDataset`, and observes it through the wired
// [DatasetReadEndpoint] (the loaded `SeedDataset`'s entries, their origins and
// the ship-gate `ValidationManifest`). The runtime provenance ACs read the pure
// domain model directly — [ProvenanceDerivation.tierFor] / the append-only add /
// [ProvenanceReadEndpoint] over a `Sample`'s evidence — and the structural ACs
// read the reusable guards over `lib/` + the seed schema. Only the platform
// speech/haptics sinks are faked (bs-01's `FakeSpeech`/`FakeHaptics`) and the
// deliberate **control** fixtures; no colour maths, no ingest and no provenance
// logic is faked — the real `SubtractiveMixingEngine`, the shipped `deltaE00`
// and the real dataset/provenance model are exercised.
//
// bs-13's own suite is pure-Dart (dataset / model / guards — no camera), so it
// runs on the host `flutter-tester` device, not an iOS sim — and the guards read
// the repo source tree through `dart:io`, so the cwd must be the repo root (the
// host VM's cwd under `flutter-tester`).
//
// The pending gate (all 11 ACs → owning phase) lives in `bs13/pending.dart`
// (seeded in this phase); this harness re-exports it, the guards and the fakes
// so an AC test imports only this file.
//
// Fixture identifiers mirror the master plan's fixture table verbatim (so the
// AC catalogue references them one-to-one), which means this file opts out of
// lowerCamelCase for the `shippedSeed` / `realEngine` / `heldOutManifest` /
// `ev*` / `control_*` names.
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/dataset/dataset_read_endpoint.dart';
import 'package:paint_color_assistant/dataset/seed_dataset.dart';
import 'package:paint_color_assistant/dataset/seed_loader.dart';
import 'package:paint_color_assistant/dataset/validation_manifest.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/provenance_derivation.dart';
import 'package:paint_color_assistant/domain/provenance_read_endpoint.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';

import '../fakes/fake_haptics.dart';
import '../fakes/fake_speech.dart';

// Re-export the pending gate, the guards and the fakes so an AC test only needs
// to import this harness.
export '../fakes/fake_haptics.dart';
export '../fakes/fake_speech.dart';
export 'guards/no_claimed_value_guard.dart';
export 'guards/no_lookup_table_guard.dart';
export 'guards/ratio_provenance_guard.dart';
export 'guards/source_scan.dart';
export 'pending.dart';

// Re-export the shipped ΔE00 and the domain/dataset types the AC tests build
// scenarios from, so an AC test imports only this harness.
export 'package:paint_color_assistant/compare/difference.dart' show deltaE00;
export 'package:paint_color_assistant/dataset/dataset_read_endpoint.dart';
export 'package:paint_color_assistant/dataset/seed_dataset.dart';
export 'package:paint_color_assistant/dataset/seed_loader.dart';
export 'package:paint_color_assistant/dataset/validation_manifest.dart';
export 'package:paint_color_assistant/domain/color_coordinates.dart';
export 'package:paint_color_assistant/domain/paint.dart';
export 'package:paint_color_assistant/domain/provenance.dart';
export 'package:paint_color_assistant/domain/provenance_derivation.dart';
export 'package:paint_color_assistant/domain/provenance_read_endpoint.dart';
export 'package:paint_color_assistant/domain/sample.dart';
export 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
export 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
export 'package:paint_color_assistant/recipes/palette.dart';

// ---------------------------------------------------------------------------
// Fixtures — the real shipped seed, the real engine, and the recorded manifest.
// Values are the ones named in the master plan's fixture table.
// ---------------------------------------------------------------------------

/// The real bs-04 mixing engine — stateless and `const` — used to solve a recipe
/// over the shipped seed's optical data (AC-1). Not faked: the recipe the AC-1
/// test checks is produced by this solver, never retrieved from a stored answer.
const SubtractiveMixingEngine realEngine = SubtractiveMixingEngine();

/// The real loader over the shipped seed asset. The AC tests load the seed
/// through this (not a hand-built dataset) so they observe exactly what ships.
/// In the SEED-2 shell it returns [SeedDataset.empty]; SEED-3 ships the asset.
const SeedLoader shippedSeedLoader = AssetSeedLoader();

/// Loads the shipped [SeedDataset] via the real [AssetSeedLoader] (the
/// `shippedSeed` fixture). Empty in the shell until SEED-3 ships the asset.
Future<SeedDataset> loadShippedSeed() => shippedSeedLoader.load();

/// A CIELAB target for the AC-1 solve — a warm mid-grey the shipped seed's
/// paints can mix toward. Carried as a [Sample] because the engine's
/// `inverse(Sample, PaintPalette, MixOptions)` takes one.
const Sample AC1_TARGET = Sample(
  coordinates: ColorCoordinates(lightness: 62, a: 2, b: 6),
  provenance: Provenance(ProvenanceTier.estimated),
  name: 'warm grey target',
);

/// The default solver options for the AC-1 recipe solve.
const MixOptions AC1_OPTIONS = MixOptions();

/// A **passing** recorded validation manifest (AC-5/AC-6): a held-out count in
/// [50, 100], a non-empty ΔE00 distribution, and a hybrid that both clears the
/// usable threshold and beats the LLM alone. (SEED-5 makes the real
/// [ValidationManifest.shippable] honour these; the shell placeholder is always
/// false — the AC-6 test is pending until then.)
final ValidationManifest heldOutManifest = ValidationManifest(
  heldOutCount: 72,
  deltaE00Distribution: _distributionAround(mean: 2.4, count: 72),
  hybridMeanDeltaE00: 2.4,
  llmAloneMeanDeltaE00: 5.1,
  usableThreshold: 3.0,
);

/// Control: a manifest that beats the LLM alone but **fails the usable
/// threshold** (hybrid mean 4.2 > threshold 3.0) — must be **not** shippable
/// (AC-6).
final ValidationManifest control_manifestFailThreshold = ValidationManifest(
  heldOutCount: 72,
  deltaE00Distribution: _distributionAround(mean: 4.2, count: 72),
  hybridMeanDeltaE00: 4.2,
  llmAloneMeanDeltaE00: 5.1,
  usableThreshold: 3.0,
);

/// Control: a manifest that clears the threshold but **does not beat the LLM
/// alone** (hybrid 2.4 ≥ llm 2.0) — must be **not** shippable (AC-6).
final ValidationManifest control_manifestFailBeatsLlm = ValidationManifest(
  heldOutCount: 72,
  deltaE00Distribution: _distributionAround(mean: 2.4, count: 72),
  hybridMeanDeltaE00: 2.4,
  llmAloneMeanDeltaE00: 2.0,
  usableThreshold: 3.0,
);

/// A representative, deterministic ΔE00 distribution of [count] values centred
/// near [mean] (a small symmetric spread), so a manifest fixture carries a
/// non-empty distribution without pretending to be a physical measurement
/// (D-5). Deterministic — no RNG — so the suite is reproducible.
List<double> _distributionAround({required double mean, required int count}) =>
    [for (var i = 0; i < count; i++) mean + ((i % 7) - 3) * 0.1];

// ---------------------------------------------------------------------------
// Evidence-point fixtures — one of each EvidenceKind (AC-7/8/9/10).
// ---------------------------------------------------------------------------

const ColorCoordinates _evLab = ColorCoordinates(lightness: 50, a: 12, b: 24);

/// Instrument-measured evidence → derives the **Measured** tier (AC-7).
const EvidencePoint evInstrument = EvidencePoint(
  coordinates: _evLab,
  source: 'spectrophotometer-1',
  kind: EvidenceKind.instrumentMeasured,
);

/// Solver-calculated evidence → derives the **Calculated** tier (AC-7).
const EvidencePoint evSolver = EvidencePoint(
  coordinates: _evLab,
  source: 'mix-solver',
  kind: EvidenceKind.solverCalculated,
);

/// LLM-seeded evidence → derives the **Estimated** tier (AC-7); the starting
/// point an own swatch promotes (AC-9) and an opinion never promotes (AC-10).
const EvidencePoint evLlmSeed = EvidencePoint(
  coordinates: _evLab,
  source: 'llm-seed',
  kind: EvidenceKind.llmSeed,
);

/// The painter's own photographed/measured swatch → derives the **Confirmed**
/// tier and is the only kind that promotes an estimate (AC-7/AC-9).
const EvidencePoint evUserSwatch = EvidencePoint(
  coordinates: _evLab,
  source: 'own-swatch',
  kind: EvidenceKind.photographedSwatch,
);

/// A stated opinion → contributes nothing to the tier and never promotes
/// (AC-10).
const EvidencePoint evOpinion = EvidencePoint(
  coordinates: _evLab,
  source: 'opinion',
  kind: EvidenceKind.opinion,
);

// ---------------------------------------------------------------------------
// Guard-scanned control fixtures (planted source files). Each is a list of
// paths the matching guard is pointed at (its `roots` / `schemaFiles` override)
// to prove it flags a real offender. Repo-relative, resolved against the repo
// root (the `flutter-tester` cwd).
// ---------------------------------------------------------------------------

/// A planted seed record carrying a recipe **ratio** field — the AC-3
/// ratio-provenance guard, pointed here, must list it.
const List<String> control_llmRatio = <String>[
  'integration_test/bs13/guards/fixtures/control_llm_ratio.dart',
];

/// A planted target-colour → recipe **answer mapping** — the AC-1 no-lookup
/// guard, pointed here, must list it.
const List<String> control_lookupTable = <String>[
  'integration_test/bs13/guards/fixtures/control_lookup_table.dart',
];

/// A planted seed entry carrying a **claimed spectral curve** alongside valid
/// metadata — the AC-4 no-claimed-value guard, pointed here, must list the
/// claimed field.
const List<String> control_claimedSpectral = <String>[
  'integration_test/bs13/guards/fixtures/control_claimed_spectral.dart',
];

/// An Estimated value given only an `opinion` evidence point — must stay
/// Estimated under re-derivation (AC-10). The in-code control value for the
/// provenance model (the guard-scanned controls above are source files).
final Sample control_opinionOnly = sampleWithEvidence(
  stored: ProvenanceTier.estimated,
  evidence: const [evLlmSeed, evOpinion],
);

// ---------------------------------------------------------------------------
// Given/When/Then vocabulary.
// ---------------------------------------------------------------------------

/// A booted bs-13 app observed through its read endpoints.
///
/// [dataset] is the shipped [SeedDataset] as the wired [DatasetReadEndpoint]
/// exposes it (AC-1/2/4/5/6/11 read here); [manifest] is its ship-gate
/// [ValidationManifest]. The faked platform sinks are exposed for the AC tests
/// that assert "no runtime LLM / speaks nothing".
class DatasetAppHarness {
  DatasetAppHarness(
    this.tester, {
    required this.dataset,
    required this.speech,
    required this.haptics,
  });

  /// The driver for the booted app.
  final WidgetTester tester;

  /// The shipped seed as the [DatasetReadEndpoint] exposes it.
  final SeedDataset dataset;

  /// The faked speech sink (no runtime LLM / spoken output in bs-13).
  final FakeSpeech speech;

  /// The faked haptics sink.
  final FakeHaptics haptics;

  /// The dataset's ship-gate validation manifest (convenience).
  ValidationManifest get manifest => dataset.manifest;
}

/// Boots the real app through `buildApp` with [seed] wired as the shipped seed
/// and returns a [DatasetAppHarness] observing it through the
/// [DatasetReadEndpoint].
///
/// When [seed] is omitted the real shipped seed is loaded via the
/// [AssetSeedLoader] (`shippedSeed`) — so a scenario observes exactly what
/// ships. The app opens on its default Readout route; the endpoint is mounted at
/// the app root regardless of route, so no navigation is needed.
Future<DatasetAppHarness> givenTheDatasetApp(
  WidgetTester tester, {
  SeedDataset? seed,
}) async {
  // Open a fresh app each time (mirrors the other harnesses) so a repeated
  // `given` in one test does not reuse a prior tree's State.
  await tester.pumpWidget(const SizedBox());
  await tester.pump();

  final resolvedSeed = seed ?? await loadShippedSeed();
  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  final deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: haptics,
    seedDataset: resolvedSeed,
  );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();

  final observed = tester
      .widget<DatasetReadEndpoint>(
          find.byKey(DatasetReadEndpoint.endpointKey))
      .dataset;
  return DatasetAppHarness(
    tester,
    dataset: observed,
    speech: speech,
    haptics: haptics,
  );
}

/// Builds a [Sample] carrying [evidence] and a [stored] tier, for the AC-7/8/9/10
/// provenance scenarios (the Given is built as data and observed through
/// [ProvenanceReadEndpoint] / [ProvenanceDerivation]).
Sample sampleWithEvidence({
  required ProvenanceTier stored,
  List<EvidencePoint> evidence = const [],
  ColorCoordinates coordinates = _evLab,
}) =>
    Sample(
      coordinates: coordinates,
      provenance: Provenance(stored),
      evidence: evidence,
    );

/// Observes [sample]'s provenance — its append-only [evidence] list and its
/// derived tier — through the real [ProvenanceReadEndpoint] (AC-7/8/9/10).
ProvenanceReadEndpoint provenanceOf(Sample sample) =>
    ProvenanceReadEndpoint(sample);

/// The shared const derivation the model uses (AC-7/9/10 read through it).
const ProvenanceDerivation derivation = ProvenanceDerivation();

/// Solves the top recipes for [target] over [palette] with the real engine
/// (AC-1's When). A thin pass-through so the AC test reads as the catalogue's
/// "a recipe is produced … via `realEngine.inverse`".
List<Recipe> solveRecipes(
  Sample target,
  PaintPalette palette, {
  MixOptions options = AC1_OPTIONS,
}) =>
    realEngine.inverse(target, palette, options);
