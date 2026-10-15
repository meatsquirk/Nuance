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
    test('covers exactly the 11 bs-13 ACs, each owned by a real behaviour phase',
        () {
      // Every AC the suite enumerates is pending at ITEST-1 (no behaviour has
      // landed yet): the pending map's keys are exactly the 11 ACs.
      expect(pendingACs.keys.toSet(), allACs.toSet());
      expect(allACs.length, 11);
      // No AC appears twice and none is unaccounted for.
      expect(allACs.toSet().length, allACs.length);
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
}
