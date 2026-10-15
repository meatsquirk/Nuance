// bs-13 Paint-dataset-integrity acceptance suite — runner (ITEST-1 scaffold).
//
// ITEST-1 lands two never-pending jobs here; ITEST-2/3 add the one pending test
// per AC (AC-1/2/4/5/6/11 via `acTestWidgets`, AC-3/7/8/9/10 via `acTest`):
//   1. a **smoke test** proving the shells wire end to end — the real app
//      assembled through `buildApp` surfaces the injected shipped seed through
//      the `DatasetReadEndpoint`, the shipped loader resolves, and the
//      provenance read seam + the reusable guards are reachable;
//   2. **guard tests over the pending gate / fixtures / controls**, so the
//      scaffold cannot pass vacuously — the pending map must cover exactly the
//      11 ACs (each owned by a real behaviour phase), the fakes must record, the
//      recorded manifest + control manifests must encode their intended
//      pass/fail condition, and the planted guard-control source files must
//      exist on disk.
//
// Run (default, pending skipped):
//   flutter test integration_test/bs13/dataset_test.dart -d flutter-tester
// Run-pending / red baseline (ITEST-2/3):
//   …same… --dart-define=BS13_RUN_PENDING=true
// A `-d` is mandatory — without a device the run executes zero tests and still
// exits 0 (false green; Known flakes).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'dataset_harness.dart';

/// A small non-empty seed injected by the smoke test to prove the endpoint
/// surfaces exactly the wired seed — stable across phases (it does not depend on
/// what the shipped asset becomes at SEED-3).
const SeedDataset _smokeSeed = SeedDataset(
  brand: 'Smoke Brand',
  medium: PaintMedium.oil,
  entries: [
    SeedPaintEntry(
      id: 'smoke-white',
      name: 'Smoke White',
      brand: 'Smoke Brand',
      medium: PaintMedium.oil,
      masstone: ColorCoordinates(lightness: 95, a: 0, b: 2),
      pigmentIndex: 'PW6',
      origin: SeedOrigin.reviewedOptical,
    ),
  ],
  candidateMappings: [
    CandidateMapping(
      targetDescriptor: 'warm grey',
      candidatePaintIds: ['smoke-white'],
    ),
  ],
  manifest: ValidationManifest.empty(),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: the assembled app surfaces the wired seed and the read seams',
    (tester) async {
      final harness = await givenTheDatasetApp(tester, seed: _smokeSeed);

      // The DatasetReadEndpoint surfaces exactly the injected seed end to end.
      expect(harness.dataset, _smokeSeed);
      expect(harness.manifest, _smokeSeed.manifest);
      expect(harness.dataset.entries, isNotEmpty);
      expect(harness.dataset.candidateMappings, isNotEmpty);

      // Opening the app alone drives no spoken output / haptic (no runtime LLM
      // or narration in bs-13).
      expect(harness.speech.utterances, isEmpty);
      expect(harness.haptics.confirmations, 0);

      // The shipped loader resolves to a dataset (empty in the shell, the real
      // asset from SEED-3 — asserted by type so this holds across phases).
      expect(await loadShippedSeed(), isA<SeedDataset>());

      // The provenance read seam is reachable over a sample's evidence.
      final sample = sampleWithEvidence(
        stored: ProvenanceTier.estimated,
        evidence: const [evLlmSeed, evUserSwatch],
      );
      final prov = provenanceOf(sample);
      expect(prov.evidence, sample.evidence); // append-only read, order kept
      expect(prov.derivedTier, isA<ProvenanceTier>());

      // The reusable guards are reachable and return a result list (the real
      // zero-offender / control assertions are the pending AC tests, red until
      // GUARD-2 — this holds whether a guard is still the stub or the real scan).
      expect(ratioProvenanceGuard(), isA<List<GuardOffender>>());
      expect(noLookupTableGuard(), isA<List<GuardOffender>>());
      expect(noClaimedValueGuard(), isA<List<GuardOffender>>());
    },
  );

  group('pending gate', () {
    test('pending map is a subset of the 11 ACs, each owned by a real behaviour phase',
        () {
      // The suite enumerates exactly 11 ACs, none duplicated.
      expect(allACs.length, 11);
      expect(allACs.toSet().length, allACs.length);
      // Every pending key is a real bs-13 AC (pending ⊆ all) — an un-pended AC
      // is simply absent, never a stray key.
      expect(allACs.toSet().containsAll(pendingACs.keys), isTrue);
      // AC-8 (evidence append-only) is un-pended at ITEST-3 — green at baseline
      // (the PROV-1 shell froze a working append-only add), so it is not in the
      // pending map and runs by default.
      expect(pendingACs.containsKey('AC-8'), isFalse,
          reason: 'AC-8 is un-pended (green at baseline); PROV-2 still owns it');
      // Every other AC is still pending until its behaviour phase lands.
      expect(pendingACs.keys.toSet(), allACs.toSet().difference({'AC-8'}));
      // Every owner is a declared behaviour phase (catches a typo'd / stale
      // owner).
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases.contains(entry.value),
          isTrue,
          reason: '${entry.key} owner ${entry.value} is not a behaviour phase',
        );
      }
      // Every behaviour phase owns at least one AC (no dead phase in the set).
      for (final phase in behaviorPhases) {
        expect(
          pendingACs.values.contains(phase),
          isTrue,
          reason: '$phase owns no pending AC',
        );
      }
    });

    test('skips a pending AC by default and runs it under run-pending', () {
      // A pending AC is skipped in the default run…
      expect(pendingSkipReason('AC-1', forceRunPending: false), isNotNull);
      // …and executes when run-pending is forced.
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
      // An AC absent from the pending map always runs (the un-pended path a
      // behaviour phase reaches) — control uses a name not in the map.
      expect(pendingSkipReason('AC-999', forceRunPending: false), isNull);
    });
  });

  group('fakes record', () {
    test('FakeSpeech and FakeHaptics actually capture, so the smoke test is not vacuous',
        () {
      final speech = FakeSpeech();
      expect(speech.utterances, isEmpty);
      speech.speak('hello');
      expect(speech.utterances, contains('hello'));

      final haptics = FakeHaptics();
      expect(haptics.confirmations, 0);
      haptics.confirm();
      expect(haptics.confirmations, 1);
    });
  });

  group('fixtures and controls encode their intended condition', () {
    test('heldOutManifest records a 50–100 held-out count and a distribution',
        () {
      expect(heldOutManifest.heldOutCount, inInclusiveRange(50, 100));
      expect(heldOutManifest.deltaE00Distribution, isNotEmpty);
      expect(heldOutManifest.deltaE00Distribution.length,
          heldOutManifest.heldOutCount);
      // The passing manifest beats the LLM alone and clears the threshold (the
      // two conditions AC-6 checks) — SEED-5 makes `shippable` honour them.
      expect(heldOutManifest.hybridMeanDeltaE00,
          lessThan(heldOutManifest.llmAloneMeanDeltaE00));
      expect(heldOutManifest.hybridMeanDeltaE00,
          lessThan(heldOutManifest.usableThreshold));
    });

    test('control manifests fail exactly one ship condition each', () {
      // Fails the threshold, still beats the LLM.
      expect(control_manifestFailThreshold.hybridMeanDeltaE00,
          greaterThan(control_manifestFailThreshold.usableThreshold));
      expect(control_manifestFailThreshold.hybridMeanDeltaE00,
          lessThan(control_manifestFailThreshold.llmAloneMeanDeltaE00));
      // Clears the threshold, does NOT beat the LLM.
      expect(control_manifestFailBeatsLlm.hybridMeanDeltaE00,
          lessThan(control_manifestFailBeatsLlm.usableThreshold));
      expect(control_manifestFailBeatsLlm.hybridMeanDeltaE00,
          greaterThanOrEqualTo(control_manifestFailBeatsLlm.llmAloneMeanDeltaE00));
    });

    test('evidence fixtures carry one of each EvidenceKind', () {
      expect(evInstrument.kind, EvidenceKind.instrumentMeasured);
      expect(evSolver.kind, EvidenceKind.solverCalculated);
      expect(evLlmSeed.kind, EvidenceKind.llmSeed);
      expect(evUserSwatch.kind, EvidenceKind.photographedSwatch);
      expect(evOpinion.kind, EvidenceKind.opinion);
      // The opinion-only control is an estimate backed only by seed + opinion.
      expect(control_opinionOnly.provenance.tier, ProvenanceTier.estimated);
      expect(
        control_opinionOnly.evidence.map((e) => e.kind),
        everyElement(isIn(const [EvidenceKind.llmSeed, EvidenceKind.opinion])),
      );
    });

    test('the planted guard-control source files exist on disk', () {
      final controlPaths = [
        ...control_llmRatio,
        ...control_lookupTable,
        ...control_claimedSpectral,
      ];
      // Size-assert first, so the loop can't pass vacuously if a path list were
      // ever emptied (one planted file per guard control).
      expect(controlPaths, hasLength(3));
      for (final path in controlPaths) {
        expect(File(path).existsSync(), isTrue,
            reason: 'missing planted control fixture: $path (cwd ${Directory.current.path})');
      }
    });
  });

  // -------------------------------------------------------------------------
  // bs-13 dataset acceptance criteria — ITEST-2 (AC-1,2,3,4,5,6,11).
  //
  // One *pending* test per AC: each is skipped in the default run and executes
  // under `--dart-define=BS13_RUN_PENDING=true` (the red-baseline / un-pend
  // run). At the shell baseline each fails cleanly — the shipped seed is empty
  // (AssetSeedLoader shell), the shipped manifest is the non-shippable empty
  // placeholder, and the guards return the `ruleNotYetEnforced` sentinel — so a
  // test fails on a Then (AC-3/5/6) or on a Given precondition naming its owning
  // phase (AC-1/2/4/11). Each behaviour phase un-pends its AC by deleting the
  // row in `pending.dart`. ITEST-3 adds AC-7/8/9/10 to this file.
  //
  // AC-1 and AC-4 carry a GUARD-2 augmentation (the structural no-lookup /
  // no-claimed-value guard control is not assertable until GUARD-2 fills the
  // real scan) → graded *B pending GUARD-2*; the core behaviour here is
  // assertable at A once SEED-3/SEED-4 land.
  group('bs-13 dataset acceptance criteria', () {
    acTestWidgets('AC-1', 'TestAC01_RecipesSolvedFromOpticalData',
        (tester) async {
      final h = await givenTheDatasetApp(tester);
      final entries = h.dataset.entries;
      // Given: the shipped seed carries optical entries (masstone), not stored
      // answers (SEED-3 ships the asset) — checked before solving so an empty
      // shell seed fails here, naming the owning phase, rather than in the
      // engine.
      expect(entries, isNotEmpty,
          reason: 'AC-1 Given: the shipped seed carries optical entries (SEED-3)');
      expect(entries.every((e) => e.masstone.lightness.isFinite), isTrue,
          reason: 'AC-1 Given: each entry carries masstone optical data, not an '
              'RGB→recipe answer');
      expect(h.dataset.candidateMappings.every((m) => m.candidatePaintIds.isNotEmpty),
          isTrue,
          reason: 'AC-1 Given: candidate mappings carry paint-id sets only, '
              'never finished recipes or ratios');

      // When: a recipe is produced for the target over the seed via the real
      // engine's inverse solve (through the shipped optical data).
      final seedIds = {for (final e in entries) e.id};
      final palette =
          PaintPalette(name: h.dataset.brand, paints: [for (final e in entries) e.toPaint()]);
      final recipes = solveRecipes(AC1_TARGET, palette);

      // Then: the recipe is produced by the solver from the stored optical data
      // — every component is a seed optical paint, and its predicted colour is
      // the engine's forward mix of those components (a stored answer need not be
      // forward-consistent). The seed has no stored target→recipe answer the
      // result could have been retrieved from (candidate mappings carry no
      // ratios/answers, asserted above).
      expect(recipes, isNotEmpty,
          reason: 'AC-1: the solver produces a recipe over the stored optical data');
      final top = recipes.first;
      expect(top.components, isNotEmpty);
      expect(top.components.every((c) => seedIds.contains(c.paint.id)), isTrue,
          reason: 'AC-1: every component is a seed optical paint (mixed over the '
              'stored atoms, not retrieved)');
      final predicted =
          realEngine.forward({for (final c in top.components) c.paint: c.partsFraction});
      expect((predicted.lightness - top.predictedColor.lightness).abs(), lessThan(1.0));
      expect((predicted.a - top.predictedColor.a).abs(), lessThan(1.0));
      expect((predicted.b - top.predictedColor.b).abs(), lessThan(1.0),
          reason: 'AC-1: the recipe\'s predicted colour is the engine\'s forward '
              'mix of its components — produced by the solver, not a stored answer');
      // Augmentation (GUARD-2, B pending): the source-level no-lookup-table
      // guard (zero offenders over lib/ + `control_lookupTable` listed) is added
      // once GUARD-2 fills the real scan — see TestAC03 for the guard pattern.
    });

    acTestWidgets('AC-2', 'TestAC02_CandidatesFromLlm', (tester) async {
      final h = await givenTheDatasetApp(tester);
      final mappings = h.dataset.candidateMappings;
      // Given: the shipped seed exposes candidate combinations and their origins
      // (SEED-4 records them) — checked before the Then so the empty shell seed
      // fails here, naming the owner.
      expect(mappings, isNotEmpty,
          reason: 'AC-2 Given: the shipped seed exposes candidate combinations (SEED-4)');
      final seedIds = {for (final e in h.dataset.entries) e.id};

      // When: the candidate combinations are read from the seed.
      // Then: every candidate paint-set carries origin `llmSeed` (the LLM's
      // qualitative knowledge) and references real shipped paints; and there is
      // no runtime LLM — the candidates are fixed build-time data (identical
      // across loads) and booting drives no narration.
      expect(mappings.every((m) => m.origin == SeedOrigin.llmSeed), isTrue,
          reason: 'AC-2: every candidate combination is stamped llmSeed');
      expect(mappings.every((m) => m.candidatePaintIds.every(seedIds.contains)),
          isTrue,
          reason: 'AC-2: candidate paint ids reference shipped seed entries '
              '(grounded, not fabricated at runtime)');
      final reload = await loadShippedSeed();
      expect(reload.candidateMappings, mappings,
          reason: 'AC-2: candidates are static build-time data (identical across '
              'loads), not generated by a runtime LLM');
      expect(h.speech.utterances, isEmpty,
          reason: 'AC-2: booting the app invokes no runtime LLM / narration');
    });

    acTest('AC-3', 'TestAC03_RatiosFromSolverNeverLlm', () {
      // Given: the planted control carrying a seed-stored ratio exists on disk,
      // so the guard's discrimination is exercisable.
      expect(control_llmRatio, hasLength(1));
      expect(File(control_llmRatio.single).existsSync(), isTrue,
          reason: 'AC-3 Given: the planted llm-ratio control source exists');

      // When: a mix's parts are produced — the guard scans lib/ (ratio
      // producers) and the seed schema (a ratio field).
      final offenders = ratioProvenanceGuard();

      // Then: zero offenders over the shipped code — every ratio comes from
      // SubtractiveMixingEngine and the seed schema carries no ratio field.
      expect(offenders, isEmpty,
          reason: 'AC-3: no ratio originates from the seed/LLM — only the solver '
              '(offenders: ${offenders.join(', ')})');
      // Control: pointed at the planted llm-ratio record, the guard lists it —
      // proving it catches a real offender, not an empty vacuous pass.
      final controlOffenders =
          ratioProvenanceGuard(roots: control_llmRatio, schemaFiles: control_llmRatio);
      expect(controlOffenders, isNotEmpty,
          reason: 'AC-3 control: the guard flags the planted seed-stored ratio');
      expect(controlOffenders.any((o) => (o.path ?? '').endsWith('control_llm_ratio.dart')),
          isTrue,
          reason: 'AC-3 control: the offender names the planted control file');
    });

    acTestWidgets('AC-4', 'TestAC04_MetadataAcceptedClaimedValuesRejected',
        (tester) async {
      final h = await givenTheDatasetApp(tester);
      final entries = h.dataset.entries;
      // Given: the shipped seed carries ingested entries (SEED-4 ingests them),
      // at least one bearing accepted LLM metadata (a pigment index) so its
      // retention is observable — checked first so the empty shell fails here.
      expect(entries, isNotEmpty,
          reason: 'AC-4 Given: the shipped seed carries ingested entries (SEED-4)');
      final withMeta = entries.where((e) => e.pigmentIndex != null).toList();
      expect(withMeta, isNotEmpty,
          reason: 'AC-4 Given: SEED-4 keeps accepted metadata (pigment index) on '
              'ingested entries');

      // When: the data is ingested (the shipped seed is the ingest result).
      // Then: the accepted metadata (pigment index, and the optical masstone) is
      // retained on every metadata-bearing entry and survives mapping to the
      // frozen Paint; the ingest drops no valid metadata.
      for (final e in withMeta) {
        expect(e.pigmentIndex, isNotNull, reason: 'AC-4: pigment-index metadata retained');
        expect(e.masstone.lightness.isFinite, isTrue,
            reason: 'AC-4: the optical masstone is retained');
        expect(e.toPaint().pigmentIndex, e.pigmentIndex,
            reason: 'AC-4: accepted metadata survives the mapping to Paint');
      }
      // The claimed values (LLM spectral curves / ratios) are rejected — the
      // stored SeedPaintEntry carries only accepted metadata fields. The
      // structural proof (the schema declares no claimed field; a planted
      // claimed-value entry is listed by the guard) is the GUARD-2 augmentation
      // (TestAC04 → B pending GUARD-2).
    });

    acTestWidgets('AC-5', 'TestAC05_HeldOutValidationRecorded', (tester) async {
      final h = await givenTheDatasetApp(tester);
      final manifest = h.manifest;
      // When: the held-out recipes are mixed and measured, recorded in the
      // shipped seed's validation manifest (SEED-5).
      // Then: the manifest records a held-out count in [50, 100] and a non-empty
      // ΔE00 distribution, one value per held-out recipe.
      expect(manifest.heldOutCount, inInclusiveRange(50, 100),
          reason: 'AC-5: the shipped manifest records 50–100 held-out recipes (SEED-5)');
      expect(manifest.deltaE00Distribution, isNotEmpty,
          reason: 'AC-5: a ΔE00 distribution is recorded');
      expect(manifest.deltaE00Distribution.length, manifest.heldOutCount,
          reason: 'AC-5: one recorded ΔE00 per held-out recipe');
      expect(manifest.deltaE00Distribution.every((d) => d.isFinite && d >= 0), isTrue,
          reason: 'AC-5: the distribution holds real, non-negative ΔE00 values');
    });

    acTestWidgets('AC-6', 'TestAC06_SeedShipsOnlyOnEvidence', (tester) async {
      final h = await givenTheDatasetApp(tester);
      // Given: the fixtures encode the two ship conditions — the passing manifest
      // clears the usable threshold AND beats the LLM alone; each control fails
      // exactly one of the two.
      expect(heldOutManifest.hybridMeanDeltaE00,
          lessThan(heldOutManifest.usableThreshold),
          reason: 'AC-6 Given: passing manifest clears the threshold');
      expect(heldOutManifest.hybridMeanDeltaE00,
          lessThan(heldOutManifest.llmAloneMeanDeltaE00),
          reason: 'AC-6 Given: passing manifest beats the LLM alone');
      expect(control_manifestFailThreshold.hybridMeanDeltaE00,
          greaterThan(control_manifestFailThreshold.usableThreshold),
          reason: 'AC-6 Given: threshold-control fails the threshold');
      expect(control_manifestFailThreshold.hybridMeanDeltaE00,
          lessThan(control_manifestFailThreshold.llmAloneMeanDeltaE00),
          reason: 'AC-6 Given: threshold-control still beats the LLM (fails only the threshold)');
      expect(control_manifestFailBeatsLlm.hybridMeanDeltaE00,
          lessThan(control_manifestFailBeatsLlm.usableThreshold),
          reason: 'AC-6 Given: beats-control clears the threshold');
      expect(control_manifestFailBeatsLlm.hybridMeanDeltaE00,
          greaterThanOrEqualTo(control_manifestFailBeatsLlm.llmAloneMeanDeltaE00),
          reason: 'AC-6 Given: beats-control does not beat the LLM (fails only beats-LLM)');

      // When: the ship decision is made (ValidationManifest.shippable, SEED-5).
      // Then: a manifest ships iff it clears the threshold AND beats the LLM
      // alone. The controls — each failing exactly one condition — are NOT
      // shippable, so a decision that checked only one condition would wrongly
      // ship one of them (the discriminating rejection).
      expect(heldOutManifest.shippable, isTrue,
          reason: 'AC-6: a manifest clearing the threshold and beating the LLM is shippable');
      expect(control_manifestFailThreshold.shippable, isFalse,
          reason: 'AC-6 control: fails the threshold → not shippable');
      expect(control_manifestFailBeatsLlm.shippable, isFalse,
          reason: 'AC-6 control: does not beat the LLM → not shippable');
      // The shipped seed itself ships only on this recorded evidence.
      expect(h.manifest.shippable, isTrue,
          reason: 'AC-6: the shipped seed ships on its recorded evidence (SEED-5)');
    });

    acTestWidgets('AC-11', 'TestAC11_ShippedSeedStaysNarrow', (tester) async {
      final h = await givenTheDatasetApp(tester);
      final entries = h.dataset.entries;
      // Given: the shipped seed carries paint entries (SEED-3 ships the asset) —
      // checked first so the empty shell fails here, naming the owner.
      expect(entries, isNotEmpty,
          reason: 'AC-11 Given: the shipped seed carries entries (SEED-3)');

      // When: the seed's scope is set (the shipped asset).
      // Then: it covers one brand, one medium, and ~15 paints (count 12–18) —
      // every entry is that one brand and medium, so a multi-brand / multi-medium
      // seed is rejected.
      expect(h.dataset.brand, isNotEmpty, reason: 'AC-11: the seed names one brand');
      expect(h.dataset.medium, isNotNull, reason: 'AC-11: the seed covers one medium');
      expect(entries.every((e) => e.brand == h.dataset.brand), isTrue,
          reason: 'AC-11: every entry is the one brand (no multi-brand seed)');
      expect(entries.every((e) => e.medium == h.dataset.medium), isTrue,
          reason: 'AC-11: every entry is the one medium (no multi-medium seed)');
      expect(entries.length, inInclusiveRange(12, 18),
          reason: 'AC-11: ~15 paints (scope pinned narrow)');
    });

    // -----------------------------------------------------------------------
    // ITEST-3 — the runtime provenance ACs (AC-7/8/9/10). Pure-Dart `acTest`
    // over the frozen provenance seam: `sampleWithEvidence` builds the Given as
    // data, `derivation.tierFor` / `derivation.appendEvidence` is the When, and
    // `provenanceOf` (the `ProvenanceReadEndpoint`) is an observation point.
    //
    // At the PROV-1 shell `ProvenanceDerivation.tierFor` returns the caller's
    // `fallback` unchanged, so AC-7/9/10 fail cleanly on a Then (the derived
    // tier is the fallback, not the origin's tier). AC-8 is different: the shell
    // froze a *working* append (`appendEvidence` already returns
    // `[...old, new]`), so AC-8 is **green at baseline** and is un-pended here
    // (recorded "green at baseline"); PROV-2 still owns it (keeps it green + unit
    // coverage). The user-facing qualifier strings ("… — not yet verified",
    // "… — you measured this") are the bs-01/bs-06 display layer (this feature's
    // Boundary); bs-13 enforces the derived *tier*, which is what these assert.
    acTest('AC-7', 'TestAC07_EnforcedProvenanceTierByOrigin', () {
      // Given: a value entering the dataset from each of the four spec origins,
      // built as a single evidence point of that kind (the Scenario Outline's
      // four rows). Every stored value carries a non-null enforced Provenance
      // (SI D9) — a value with no tier is impossible by construction, checked.
      for (final ev in const [evInstrument, evSolver, evLlmSeed, evUserSwatch]) {
        final s = sampleWithEvidence(
            stored: ProvenanceTier.estimated, evidence: [ev]);
        expect(s.provenance.tier, isA<ProvenanceTier>(),
            reason: 'AC-7 Given: every stored value carries an enforced tier');
        expect(s.evidence.single, ev,
            reason: 'AC-7 Given: the value carries exactly its origin evidence');
      }

      // When: the value is stored (its tier is derived from its evidence
      // origin). Then: each origin derives its spec tier — a contrasting
      // `fallback` is passed in every case so the answer must come from the
      // evidence origin, not the fallback (a stub that ignores evidence returns
      // the fallback and fails each assertion).
      expect(
        derivation.tierFor(const [evInstrument],
            fallback: ProvenanceTier.estimated),
        ProvenanceTier.measured,
        reason: 'AC-7: a spectrophotometer measurement → Measured',
      );
      expect(
        derivation.tierFor(const [evSolver],
            fallback: ProvenanceTier.estimated),
        ProvenanceTier.calculated,
        reason: 'AC-7: the physics solver over measured pigment data → Calculated',
      );
      expect(
        derivation.tierFor(const [evLlmSeed],
            fallback: ProvenanceTier.measured),
        ProvenanceTier.estimated,
        reason: 'AC-7: an unconfirmed LLM seed → Estimated (from the origin, not '
            'the contrasting fallback)',
      );
      expect(
        derivation.tierFor(const [evUserSwatch],
            fallback: ProvenanceTier.estimated),
        ProvenanceTier.confirmed,
        reason: "AC-7: the user's own measured mix → Confirmed",
      );

      // And observed through the read endpoint: a value stored Estimated but
      // backed by an instrument measurement surfaces the derived Measured tier
      // (the endpoint derives from evidence, falling back to the stored tier
      // only when nothing contributes) — so the enforced tier is observable, not
      // just the stored one.
      final measured = sampleWithEvidence(
        stored: ProvenanceTier.estimated,
        evidence: const [evInstrument],
      );
      expect(provenanceOf(measured).derivedTier, ProvenanceTier.measured,
          reason: 'AC-7: ProvenanceReadEndpoint surfaces the enforced derived tier');
    });

    acTest('AC-8', 'TestAC08_EvidenceAppendOnly', () {
      // Given: a value already carrying evidence of its origin (an LLM seed).
      final base = sampleWithEvidence(
        stored: ProvenanceTier.estimated,
        evidence: const [evLlmSeed],
      );
      expect(provenanceOf(base).evidence, const [evLlmSeed],
          reason: 'AC-8 Given: the value already carries its origin evidence');

      // When: new evidence for that value is recorded via the append-only add.
      final appended = derivation.appendEvidence(base.evidence, evUserSwatch);

      // Then: the new point is appended and the earlier point is retained —
      // length grows by exactly one, the prior point is still first, the new
      // point is last, order preserved.
      expect(appended, hasLength(2));
      expect(appended.first, evLlmSeed,
          reason: 'AC-8: the earlier evidence is retained, in place');
      expect(appended.last, evUserSwatch,
          reason: 'AC-8: the new evidence is appended at the end');
      expect(appended, const [evLlmSeed, evUserSwatch],
          reason: 'AC-8: append-only — order preserved, nothing dropped');

      // The append does not mutate the prior evidence (it returns a new list;
      // history on the original value is never lost or reordered).
      expect(base.evidence, const [evLlmSeed],
          reason: 'AC-8: the append leaves the prior evidence unchanged');

      // Control: the API is append-only — a further append keeps growing and
      // never shrinks or loses an earlier point (there is no remove/replace in
      // the API; history is monotonic).
      final again = derivation.appendEvidence(appended, evOpinion);
      expect(again, hasLength(3));
      expect(again.take(2), const [evLlmSeed, evUserSwatch],
          reason: 'AC-8 control: every earlier point survives each append '
              '(monotonic, append-only)');
      expect(again.last, evOpinion);

      // Observed through the read endpoint on the rebuilt value.
      expect(provenanceOf(base.copyWith(evidence: appended)).evidence,
          const [evLlmSeed, evUserSwatch],
          reason: 'AC-8: the endpoint surfaces the appended, order-preserved evidence');
    });

    acTest('AC-9', 'TestAC09_PromotedOnlyByMeasuredSwatch', () {
      // Given: an Estimated value — its only evidence is an unconfirmed LLM
      // seed, so its derived tier is Estimated (PROV-2 derives this; checked as
      // a precondition so the real promotion is the discriminating Then).
      final estimated = sampleWithEvidence(
        stored: ProvenanceTier.estimated,
        evidence: const [evLlmSeed],
      );
      expect(
        derivation.tierFor(estimated.evidence,
            fallback: ProvenanceTier.estimated),
        ProvenanceTier.estimated,
        reason: 'AC-9 Given: the value is "Estimated — not yet verified" (PROV-2)',
      );

      // When: the painter records a photographed/instrument-measured swatch of
      // their own mix (appended as a photographedSwatch evidence point).
      final afterSwatch =
          derivation.appendEvidence(estimated.evidence, evUserSwatch);

      // Then: the value may be promoted to Confirmed — the derived tier becomes
      // Confirmed, driven ONLY by the swatch (the LLM seed alone never confirmed
      // it, asserted in the Given above — so the swatch is what promotes).
      expect(
        derivation.tierFor(afterSwatch, fallback: ProvenanceTier.estimated),
        ProvenanceTier.confirmed,
        reason: 'AC-9: a photographed/measured swatch promotes Estimated → '
            'Confirmed (PROV-3)',
      );
      // Augmentation (PROV-3, B pending): once the promotion rule lands, assert
      // the Estimated→Confirmed transition through the promotion wrapper and
      // that an instrument-measured swatch promotes likewise — Test
      // augmentations table.
    });

    acTest('AC-10', 'TestAC10_OpinionsNeverPromote', () {
      // Given: an Estimated value given only an opinion on top of its LLM seed
      // (the `control_opinionOnly` fixture). Its stored tier is Estimated and
      // its evidence is exactly {llmSeed, opinion}.
      expect(control_opinionOnly.provenance.tier, ProvenanceTier.estimated,
          reason: 'AC-10 Given: the value is Estimated');
      expect(
        control_opinionOnly.evidence.map((e) => e.kind),
        everyElement(isIn(const [EvidenceKind.llmSeed, EvidenceKind.opinion])),
        reason: 'AC-10 Given: the value carries only an LLM seed and an opinion',
      );
      expect(
        control_opinionOnly.evidence.any((e) => e.kind == EvidenceKind.opinion),
        isTrue,
        reason: 'AC-10 Given: an opinion is present',
      );

      // When: only votes/opinions are offered. Then: the value is NOT promoted —
      // it stays Estimated, because an opinion contributes nothing to the tier.
      // (A pure synchronous derivation — no settle point needed for the negative
      // Then.)
      expect(
        derivation.tierFor(control_opinionOnly.evidence,
            fallback: ProvenanceTier.estimated),
        ProvenanceTier.estimated,
        reason: 'AC-10: an opinion never raises the tier — stays Estimated',
      );

      // Control: the derivation is NOT merely returning the fallback regardless
      // of evidence — a real measurement on the same starting value DOES raise
      // the tier (to Measured). So "stays Estimated" above is because the opinion
      // is inert, not because the model ignores its evidence. This control fails
      // at the shell baseline (the stub returns the fallback), pinning the test
      // red until PROV-3.
      final withMeasurement =
          derivation.appendEvidence(const [evLlmSeed], evInstrument);
      expect(
        derivation.tierFor(withMeasurement, fallback: ProvenanceTier.estimated),
        ProvenanceTier.measured,
        reason: 'AC-10 control: a non-opinion origin (instrument) does raise the '
            'tier — so the opinion case is real inertness, not a vacuous pass',
      );
    });
  });
}
