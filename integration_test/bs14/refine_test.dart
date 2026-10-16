// bs-14 acceptance criteria — crowd refine / never-promote / quality controls
// (ITEST-4).
//
// One *pending* integration test per AC-8, AC-9, AC-11 and AC-12, written
// against the real sharing subsystem through the public surface only — the real
// `EvidenceMerge` and `CrowdRefine` (riding bs-13's real `ProvenanceDerivation`)
// and the real `SourceRateLimiter`, observed through `MappingEvidenceEndpoint`.
// Each test encodes the AC's intended behaviour and is *pending* until its
// behaviour phase lands:
//
//   AC-8  → MERGE-3 (recompute an Estimated value as the robust central
//                    estimate of the clustered peer records; needs MERGE-2 to
//                    have appended them first)
//   AC-9  → MERGE-4 (crowd evidence never promotes to Confirmed) — green at the
//                    baseline (bs-13's `tierFor` already excludes
//                    `peerContributed` by fall-through), so it is *limited*
//                    until MERGE-4 adds the high-tier-peer case; see the
//                    augmentation row in modules/ITEST.md
//   AC-11 → MERGE-3 (statistical outliers discarded from the estimate; same
//                    code path as AC-8, distinct fixture — D-6)
//   AC-12 → MERGE-5 (bound the volume any one source may contribute)
//
// The pending gate (`acTest`, keyed to `BS14_RUN_PENDING`) skips these in the
// default run (so the suite stays green with all four pending) and runs them
// under `--dart-define=BS14_RUN_PENDING=true` (the red baseline). Each red
// pending test fails on a Then assertion that names its owning phase — never a
// harness crash.
//
// Runs on the host `flutter-tester` device (pure-Dart sharing logic, no camera):
//   flutter test integration_test/bs14/refine_test.dart -d flutter-tester
//   flutter test integration_test/bs14/refine_test.dart -d flutter-tester \
//       --dart-define=BS14_RUN_PENDING=true   # red baseline
//
// One bs-14 app-booting file per `flutter test` invocation (flutter-tester
// app-relaunch limitation); these four tests boot no app, but the convention
// stands for the suite as a whole.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/provenance_derivation.dart';

import 'harness.dart';

/// The stored Estimated starting value of `seedMapping` — the LLM seed's rough
/// guess, deliberately offset from where the peer records actually cluster
/// ([seedMappingValue]). Refinement moves this *toward* the clustered estimate;
/// an impl that ignores the crowd leaves it here (the AC-8/AC-11 discriminator).
const ColorCoordinates _staleSeed =
    ColorCoordinates(lightness: 70, a: -6, b: 16);

/// `seedMapping`'s prior LLM-seed evidence point — an Estimated origin, so the
/// mapping derives `estimated` before any crowd evidence arrives (AC-9 Given).
const EvidencePoint _llmSeedPoint = EvidencePoint(
  coordinates: seedMappingValue,
  source: 'llm-seed',
  kind: EvidenceKind.llmSeed,
);

/// The real bs-13 derivation — used for the user-facing provenance *label*
/// (AC-9 reads `qualifier`) and the own-measured-swatch promotion *control*
/// (`promoteWithOwnSwatch`). Never a hand-faked label or tier.
const ProvenanceDerivation _derivation = ProvenanceDerivation();

void main() {
  group('bs-14 crowd-refine, never-promote & quality acceptance criteria', () {
    // -----------------------------------------------------------------------
    // AC-8 — clustered crowd records improve an Estimated mapping's value: the
    // recomputed value is the robust central estimate of the clustered records,
    // outliers discarded (not the plain mean, not the stale seed).
    // Owner: MERGE-3 (needs MERGE-2's append).
    // -----------------------------------------------------------------------
    acTest('AC-8', 'TestAC08_ClusteredRefine', () {
      const EvidenceMerge merge = EvidenceMerge();
      const CrowdRefine refine = CrowdRefine();

      // Given: several peer-contributed records for one Estimated mapping — a
      // tight cluster of 7 plus one far statistical outlier (8 records).
      final List<MixAccuracyRecord> records =
          peerRecords(7, outlier: true);
      final List<MixAccuracyRecord> cluster = records.sublist(0, 7);
      final ColorCoordinates clusterCentroid = _meanLab(cluster);
      final ColorCoordinates plainMeanOfAll = _meanLab(records);

      // Given checks (the fixture discriminates the two wrong impls):
      expect(records, hasLength(8),
          reason: 'AC-8 Given: 7 clustered records + 1 outlier');
      // The clustered records centre on the mapping's refined value.
      _expectClose(clusterCentroid, seedMappingValue, 0.01,
          'AC-8 Given: the 7 clustered records centre on seedMappingValue');
      // The stored Estimated value is NOT already the clustered estimate, so an
      // impl that ignores the crowd (keeps the stored value) is caught.
      expect(_dist(_staleSeed, seedMappingValue), greaterThan(5.0),
          reason: 'AC-8 Given: the stale stored seed is far from the cluster '
              '(so "ignore the crowd" is discriminated)');
      // The plain mean of ALL points (outlier included) is pulled well away
      // from the cluster centroid, so an impl that plain-averages is caught.
      expect(_dist(plainMeanOfAll, seedMappingValue), greaterThan(3.0),
          reason: 'AC-8 Given: the plain mean of all 8 is pulled toward the '
              'outlier (so "plain-average everything" is discriminated)');

      // When: the records are merged into the mapping's (empty) evidence log and
      // the local value is recomputed.
      final List<EvidencePoint> merged =
          merge.ingest(const <EvidencePoint>[], sourcedFromDistinctPeers(records));
      final RefineResult result = refine.refine(_staleSeed, merged);
      final ColorCoordinates refined =
          mappingEndpoint(value: result.value, evidence: merged).view!.value;

      // Then: the recomputed value is the robust central estimate of the
      // clustered records with the outlier discarded — within tolerance of the
      // cluster centroid, not the plain mean of everything. At the shell
      // `refine` returns the stale stored seed unchanged (no recompute), so this
      // reddens the baseline. (Rejects: ignoring the crowd → stays at the stale
      // seed; plain-averaging all 8 → pulled toward the outlier.)
      _expectClose(refined, seedMappingValue, 1.5,
          'AC-8: the recomputed value is the robust central estimate of the '
          'clustered records (outlier discarded) — MERGE-3');
      expect(_dist(refined, plainMeanOfAll), greaterThan(1.5),
          reason: 'AC-8: the result is NOT the plain mean of all points — the '
              'outlier was not averaged in — MERGE-3');
    });

    // -----------------------------------------------------------------------
    // AC-9 — crowd evidence never promotes a value to Confirmed: a mapping
    // refined by peer-contributed records stays "Estimated — not yet verified"
    // until the painter confirms it with their own measured mix.
    // Owner: MERGE-4 (augments this test — see the augmentation row). Green at
    // the baseline: bs-13's `tierFor` already excludes `peerContributed`, so the
    // never-promote invariant holds trivially; the control below proves the
    // derivation CAN change (so the invariant is not vacuous), but the strongest
    // wrong impl (a high-tier peer record that promotes) can only be exercised
    // once MERGE-2 appends peer points and MERGE-4 formally excludes them.
    // -----------------------------------------------------------------------
    acTest('AC-9', 'TestAC09_NeverPromotes', () {
      const EvidenceMerge merge = EvidenceMerge();
      const CrowdRefine refine = CrowdRefine();

      // Given: an Estimated mapping (its only prior evidence is the LLM seed) …
      final List<EvidencePoint> seedEvidence = <EvidencePoint>[_llmSeedPoint];
      expect(_derivation.tierFor(seedEvidence), ProvenanceTier.estimated,
          reason: 'AC-9 Given: the mapping starts Estimated');
      // … refined by several peer-contributed records.
      final List<SourcedRecord> peers =
          sourcedFromDistinctPeers(peerRecords(5));
      expect(peers, hasLength(5),
          reason: 'AC-9 Given: five peer-contributed records arrive');
      expect(peers.every((s) => s.record.declaredPalette.isPresent), isTrue,
          reason: 'AC-9 Given: every peer record is interpretable');
      final List<EvidencePoint> refinedEvidence =
          merge.ingest(seedEvidence, peers);

      // When: the local value is recomputed and its user-facing provenance is
      // shown (the derived tier and its full qualifier label).
      final RefineResult result =
          refine.refine(seedMappingValue, refinedEvidence);
      final MappingEvidenceEndpoint endpoint = mappingEndpoint(
        value: result.value,
        evidence: refinedEvidence,
        tier: result.tier,
        label: _derivation.qualifier(result.tier),
      );

      // Then: it remains Estimated — the derived tier is `estimated` and the
      // user-facing label is exactly "Estimated — not yet verified". Crowd
      // evidence refines the value but never promotes the tier (SI D2).
      // (Rejects: promoting to Confirmed/Measured because peer evidence is
      // present or high-tier, or showing "verified".)
      expect(endpoint.view!.tier, ProvenanceTier.estimated,
          reason: 'AC-9: crowd evidence leaves the tier Estimated — MERGE-4');
      expect(endpoint.view!.label, 'Estimated — not yet verified',
          reason: 'AC-9: the user-facing provenance stays '
              '"Estimated — not yet verified" — MERGE-4');

      // Control (G3/G5 — the reading CAN change): the SAME mapping, when the
      // painter records their OWN measured swatch for it, IS promoted to
      // Confirmed — "Confirmed — you measured this". This proves "stays
      // Estimated" above is a real result of the peer evidence, not a constant.
      final ({List<EvidencePoint> evidence, ProvenanceTier tier}) promoted =
          _derivation.promoteWithOwnSwatch(
        refinedEvidence,
        const EvidencePoint(
          coordinates: seedMappingValue,
          source: 'own-swatch',
          kind: EvidenceKind.photographedSwatch,
        ),
      );
      expect(promoted.tier, ProvenanceTier.confirmed,
          reason: 'AC-9 control: the painter\'s own measured mix DOES promote '
              'to Confirmed (so the Estimated result above is meaningful)');
      expect(_derivation.qualifier(promoted.tier), 'Confirmed — you measured this',
          reason: 'AC-9 control: an own-mix confirmation reads '
              '"Confirmed — you measured this"');
    });

    // -----------------------------------------------------------------------
    // AC-11 — statistical outliers are discarded from the local estimate: a far
    // outlier is excluded rather than averaged in. Same code path as AC-8
    // (D-6), distinct fixture (6 tight + 1 far). Owner: MERGE-3.
    // -----------------------------------------------------------------------
    acTest('AC-11', 'TestAC11_OutlierDiscarded', () {
      const EvidenceMerge merge = EvidenceMerge();
      const CrowdRefine refine = CrowdRefine();

      // Given: six tightly-clustered peer records plus one far statistical
      // outlier (7 records).
      final List<MixAccuracyRecord> records =
          peerRecords(6, outlier: true);
      final List<MixAccuracyRecord> cluster = records.sublist(0, 6);
      final ColorCoordinates clusterCentroid = _meanLab(cluster);
      final ColorCoordinates plainMeanOfAll = _meanLab(records);

      // Given checks:
      expect(records, hasLength(7),
          reason: 'AC-11 Given: 6 clustered records + 1 far outlier');
      _expectClose(clusterCentroid, seedMappingValue, 0.01,
          'AC-11 Given: the 6 clustered records centre on seedMappingValue');
      // The outlier is genuinely far, so averaging it in pulls the plain mean
      // well off the cluster — the fixture discriminates "average everything".
      expect(_dist(plainMeanOfAll, clusterCentroid), greaterThan(3.0),
          reason: 'AC-11 Given: including the outlier pulls the plain mean far '
              'off the cluster centroid (so "average all 7" is discriminated)');

      // When: the records are merged and the local estimate is computed.
      final List<EvidencePoint> merged =
          merge.ingest(const <EvidencePoint>[], sourcedFromDistinctPeers(records));
      final ColorCoordinates estimate =
          refine.refine(_staleSeed, merged).value;

      // Then: the outlier is excluded — the estimate is within tolerance of the
      // 6-record cluster centroid, NOT the all-7 plain mean. At the shell
      // `refine` returns the stale seed unchanged, so this reddens the baseline.
      // (Rejects: averaging all 7 → the estimate is pulled toward the outlier.)
      _expectClose(estimate, clusterCentroid, 1.5,
          'AC-11: the estimate equals the cluster centroid with the outlier '
          'discarded — MERGE-3');
      expect(_dist(estimate, plainMeanOfAll), greaterThan(1.5),
          reason: 'AC-11: the outlier is discarded, not averaged in — the '
              'estimate is not the all-7 plain mean — MERGE-3');
    });

    // -----------------------------------------------------------------------
    // AC-12 — the volume one source can contribute is bounded: a flood from a
    // single source is capped per source, excess rejected, other sources
    // unaffected. Owner: MERGE-5.
    // -----------------------------------------------------------------------
    acTest('AC-12', 'TestAC12_RateLimited', () {
      const EvidenceMerge merge = EvidenceMerge();
      const int cap = SourceRateLimiter.defaultMaxPerSource;
      const String flooder = 'flooder';
      const String honest = 'honest-peer';
      const int honestCount = 5;

      // Given: a stream of many records from a single source, well over the
      // per-source cap, plus a few honest records from a different source.
      const int floodCount = 100;
      final List<SourcedRecord> flood =
          sourcedFromOnePeer(peerRecords(floodCount, spread: 0.1),
              source: flooder);
      final List<SourcedRecord> honestRecords = sourcedFromOnePeer(
          peerRecords(honestCount, spread: 0.1),
          source: honest);
      final List<SourcedRecord> incoming = <SourcedRecord>[
        ...flood,
        ...honestRecords,
      ];

      // Given checks:
      expect(cap, greaterThan(0),
          reason: 'AC-12 Given: a positive per-source cap is configured');
      expect(floodCount, greaterThan(cap),
          reason: 'AC-12 Given: the single-source flood exceeds the cap');
      expect(flood.map((s) => s.source).toSet(), <String>{flooder},
          reason: 'AC-12 Given: the flood all comes from one source');
      expect(honestRecords, hasLength(honestCount),
          reason: 'AC-12 Given: the honest peer contributes a few records');

      // When: the records are ingested into the mapping's (empty) evidence log.
      final List<EvidencePoint> merged =
          merge.ingest(const <EvidencePoint>[], incoming);
      final List<EvidencePoint> observed =
          mappingEndpoint(value: seedMappingValue, evidence: merged).view!.evidence;

      // Then: the count accepted from the flooding source is capped at the
      // per-source limit (< the 100 offered); the excess is rejected. At the
      // shell nothing is appended (0 accepted), so this reddens the baseline.
      // (Rejects: no cap → all 100 accepted.)
      expect(_countFrom(observed, flooder), cap,
          reason: 'AC-12: the flooding source is capped at the per-source '
              'limit ($cap), the excess rejected — MERGE-5');

      // Then: the honest peer is unaffected — all of its records are accepted.
      // (Rejects: a global cap that starves other sources once a flooder fills
      // it.)
      expect(_countFrom(observed, honest), honestCount,
          reason: 'AC-12: a flood from one source never starves another — the '
              'honest peer\'s records are all accepted — MERGE-5');
    });
  });
}

// ---------------------------------------------------------------------------
// Local helpers.
// ---------------------------------------------------------------------------

/// Asserts [actual] is within [tol] of [expected] on each CIELAB axis.
void _expectClose(
  ColorCoordinates actual,
  ColorCoordinates expected,
  double tol,
  String reason,
) {
  expect(actual.lightness, closeTo(expected.lightness, tol),
      reason: '$reason (L)');
  expect(actual.a, closeTo(expected.a, tol), reason: '$reason (a)');
  expect(actual.b, closeTo(expected.b, tol), reason: '$reason (b)');
}

/// The Euclidean distance between two CIELAB points — a coarse ΔE used only to
/// show the fixtures discriminate (cluster vs. plain-mean vs. stale seed).
double _dist(ColorCoordinates x, ColorCoordinates y) {
  final double dl = x.lightness - y.lightness;
  final double da = x.a - y.a;
  final double db = x.b - y.b;
  return math.sqrt(dl * dl + da * da + db * db);
}

/// The mean CIELAB of the measured colours behind [records].
ColorCoordinates _meanLab(Iterable<MixAccuracyRecord> records) {
  final List<MixAccuracyRecord> list = records.toList();
  var l = 0.0, a = 0.0, b = 0.0;
  for (final MixAccuracyRecord r in list) {
    l += r.measuredColour.lab.lightness;
    a += r.measuredColour.lab.a;
    b += r.measuredColour.lab.b;
  }
  final int n = list.length;
  return ColorCoordinates(lightness: l / n, a: a / n, b: b / n);
}

/// The number of peer-contributed evidence points in [points] tagged [source].
int _countFrom(List<EvidencePoint> points, String source) => points
    .where((EvidencePoint p) =>
        p.kind == EvidenceKind.peerContributed && p.source == source)
    .length;
