// bs-14 acceptance-suite scaffold tests (ITEST-1).
//
// Three things, none an AC test:
//   1. a **smoke test** proving the shells wire end to end — the real app boots
//      and surfaces the consent read endpoint, and the real record / exchange /
//      merge / refine services are reachable through the harness and observed
//      through their read endpoints. It asserts only **wiring invariants** (the
//      frozen offer copy, the fire-and-forget no-wait contract, the append-only
//      merge, bs-13's tier derivation, the no-palette exclusion) that hold in
//      every phase, so it stays green as the behaviour phases land — it never
//      asserts a shell stub value that a behaviour phase will change.
//   2. **pending-gate** tests — the 12-AC map is well-formed and each pending AC
//      is owned by a real behaviour phase; the gate skips a pending AC by default
//      and runs it under the flag.
//   3. **fixture / fake-transport** guards — the fixtures encode their intended
//      condition and the fake loopback transport behaves as a real transport
//      would, so the AC tests that build on them are not vacuous.
//
// Runs on the host `flutter-tester` device (pure-Dart sharing logic, no camera):
//   flutter test integration_test/bs14/harness_test.dart -d flutter-tester
//
// AC ids are the plan's verbatim names, so this file opts out of lowerCamelCase
// for the fabricated-id case.
// ignore_for_file: constant_identifier_names

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  // -------------------------------------------------------------------------
  // 1. Smoke — the shells wire end to end (wiring invariants only).
  // -------------------------------------------------------------------------
  testWidgets(
    'smoke: the assembled app surfaces the consent endpoint and the sharing '
    'services wire through their read endpoints',
    (WidgetTester tester) async {
      final SharingAppHarness app = await givenTheSharingApp(tester);

      // The consent read endpoint is mounted (CORE-2). A fresh install has no
      // saved consent, so it is not opted in; the offer copy is the frozen
      // plain-language wording; nothing is spoken or buzzed by booting.
      expect(app.consented, isFalse);
      expect(app.offerCopy, SharingConsent.defaultOfferCopy);
      expect(app.speech.utterances, isEmpty);
      expect(app.haptics.confirmations, 0);
      // The inventory accessor is wired (the invisibility guarantee itself —
      // that a populated inventory never names peers/devices/syncing/network —
      // is AC-1/AC-2's assertion, where CORE-3 fills the inventory and the check
      // discriminates; here it is legitimately empty — maximal invisibility — so
      // a smoke assertion over it would be vacuous).
      expect(app.userFacingSharingSurfaces, isA<List<String>>());

      // Exchange wiring: a fire-and-forget round runs over the real gossip +
      // scheduler + transport. Whatever a round does, a core flow never waits on
      // it (the AC-2/AC-7 contract), and the round really consulted the
      // transport (not a no-op short-circuit).
      final TwoInstalls pair = twoInstalls(
        aRecords: peerRecords(1),
        bRecords: peerRecords(1, spread: 2),
      );
      final ExchangeOutcome outcome = await runExchange(pair.a);
      final ExchangeOutcomeEndpoint exEndpoint = exchangeEndpoint(outcome);
      expect(exEndpoint.waitedOnExchange, isFalse);
      expect(pair.a.transport.discoverCalls, greaterThanOrEqualTo(1));

      // Record wiring: the builder is reachable, and the record endpoint carries
      // exactly what it is given (a hand-built record round-trips). A record
      // without a declared palette never reaches the share-set (AC-5 holds in
      // every phase: the shell shares nothing; RECORD-3 excludes no-palette).
      final MixAccuracyRecord sample = peerRecords(1).single;
      expect(recordEndpoint(prepared: sample).prepared, same(sample));
      pair.a.recordBuilder.prepare(confirmedEvidence, palette: seedPalette);
      final List<MixAccuracyRecord> shareSet =
          pair.a.recordBuilder.selectShareSet(<MixAccuracyRecord>[noPaletteRecord]);
      expect(recordEndpoint(shareSet: shareSet).shareSet, isNot(contains(noPaletteRecord)));

      // Merge wiring: the append-only merge rides bs-13's evidence model —
      // merging nothing preserves the existing log in order (append-only never
      // drops), and the merge endpoint carries the result.
      const List<EvidencePoint> existing = <EvidencePoint>[
        EvidencePoint(
          coordinates: seedMappingValue,
          source: 'llm-seed',
          kind: EvidenceKind.llmSeed,
        ),
      ];
      final List<EvidencePoint> merged =
          pair.a.merge.ingest(existing, const <SourcedRecord>[]);
      expect(merged, orderedEquals(existing));

      // Refine wiring: the tier is genuinely DERIVED from the evidence by
      // bs-13's real ProvenanceDerivation, not a constant — an instrument point
      // derives Measured (a stub that always returned Estimated would fail this),
      // which proves the linkage. The remaining two cases encode the invariant
      // the crowd refiner must keep: an llmSeed-only mapping is Estimated, and
      // peer-contributed evidence never raises the tier above the Estimated
      // fallback (AC-9's never-promote invariant). The mapping endpoint carries
      // the derived state.
      expect(
        pair.a.refine.refine(seedMappingValue, const <EvidencePoint>[
          EvidencePoint(
            coordinates: seedMappingValue,
            source: 'spectrophotometer',
            kind: EvidenceKind.instrumentMeasured,
          ),
        ]).tier,
        ProvenanceTier.measured,
      );
      final RefineResult refined = pair.a.refine.refine(seedMappingValue, existing);
      expect(refined.tier, ProvenanceTier.estimated);
      const EvidencePoint peerPoint = EvidencePoint(
        coordinates: seedMappingValue,
        source: 'peer-X',
        kind: EvidenceKind.peerContributed,
      );
      expect(
        pair.a.refine
            .refine(seedMappingValue, const <EvidencePoint>[peerPoint])
            .tier,
        ProvenanceTier.estimated,
      );
      final MappingEvidenceEndpoint mapEndpoint =
          mappingEndpoint(value: refined.value, tier: refined.tier);
      expect(mapEndpoint.view!.value, seedMappingValue);
      expect(mapEndpoint.view!.tier, ProvenanceTier.estimated);
      expect(mapEndpoint.view!.label, 'Estimated — not yet verified');
    },
  );

  // -------------------------------------------------------------------------
  // 2. Pending gate.
  // -------------------------------------------------------------------------
  group('pending gate', () {
    test('covers exactly the 12 ACs, each pending AC owned by a real phase', () {
      // The suite's ACs are exactly AC-1..AC-12 — a missing or stray AC test
      // can't pass vacuously.
      expect(allACs, hasLength(12));
      expect(
        allACs.toSet(),
        <String>{for (var i = 1; i <= 12; i++) 'AC-$i'},
      );
      // Every pending AC is a real AC and is owned by a real behaviour phase.
      for (final MapEntry<String, String> entry in pendingACs.entries) {
        expect(allACs, contains(entry.key), reason: '${entry.key} is not an AC');
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} owned by unknown phase ${entry.value}',
        );
      }
      // Behaviour phases un-pend their ACs as they land: a completed behaviour
      // phase is a real behaviour phase that no longer owns any pending AC.
      for (final String phase in completedBehaviorPhases) {
        expect(behaviorPhases, contains(phase),
            reason: '$phase is marked completed but is not a behaviour phase');
        expect(pendingACs.values, isNot(contains(phase)),
            reason: '$phase is marked completed but still owns a pending AC');
      }
      // CORE-3 (AC-1), RECORD-2 (AC-3, AC-4), RECORD-3 (AC-5), MERGE-2 (AC-10),
      // MERGE-3 (AC-8, AC-11) and MERGE-4 (AC-9) have landed — each un-pended
      // the AC(s) it owns; the rest stay pending, so a not-yet-built AC still
      // can't pass vacuously.
      expect(
          completedBehaviorPhases,
          containsAll(<String>[
            'CORE-3',
            'RECORD-2',
            'RECORD-3',
            'MERGE-2',
            'MERGE-3',
            'MERGE-4',
          ]));
      const Set<String> unpended = <String>{
        'AC-1',
        'AC-3',
        'AC-4',
        'AC-5',
        'AC-8',
        'AC-9',
        'AC-10',
        'AC-11',
      };
      expect(pendingACs.keys.toSet().intersection(unpended), isEmpty);
      expect(pendingACs.keys.toSet(), allACs.toSet().difference(unpended));
    });

    test('skips a pending AC by default and runs it under the flag', () {
      // AC-2 is still pending (owned by CORE-4), so it is skipped in the default
      // (not run-pending) mode with a reason naming its owner, and runs when
      // run-pending is forced. The mode is pinned via forceRunPending so the
      // assertion is deterministic whichever mode the suite itself runs in.
      expect(pendingSkipReason('AC-2', forceRunPending: false), isNotNull);
      expect(pendingSkipReason('AC-2', forceRunPending: false), contains('CORE-4'));
      expect(pendingSkipReason('AC-2', forceRunPending: true), isNull);
      // AC-1 is un-pended (CORE-3), so it always runs, in either mode — as does
      // an AC with no pending row at all.
      expect(pendingSkipReason('AC-1', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
      expect(pendingSkipReason('AC-999', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-999', forceRunPending: true), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // 3. Fixtures encode their intended condition.
  // -------------------------------------------------------------------------
  group('fixtures encode their intended condition', () {
    test('seedMapping is an LLM-seeded (Estimated) mapping with a present palette',
        () {
      expect(seedMapping.origin, SeedOrigin.llmSeed);
      expect(seedMapping.candidatePaintIds, isNotEmpty);
      expect(
        seedCombination.paintIds,
        List<String>.of(seedMapping.candidatePaintIds)..sort(),
      );
      expect(seedPalette.isPresent, isTrue);
    });

    test('measuredColourOf derives a CIELCh consistent with its CIELAB', () {
      final MeasuredColour mc = measuredColourOf(seedMappingValue);
      expect(mc.lab, seedMappingValue);
      expect(mc.lch.lightness, closeTo(seedMappingValue.lightness, 1e-9));
      final double expectedChroma = math.sqrt(
          seedMappingValue.a * seedMappingValue.a +
              seedMappingValue.b * seedMappingValue.b);
      expect(mc.lch.chroma, closeTo(expectedChroma, 1e-6));
    });

    test('peerRecords produces distinct, non-colliding records', () {
      final List<MixAccuracyRecord> records = peerRecords(7);
      expect(records, hasLength(7));
      // Distinct colours ⇒ distinct content hashes: none collapses by accident.
      final Set<String> hashes =
          records.map((MixAccuracyRecord r) => r.contentHash).toSet();
      expect(hashes, hasLength(7));
    });

    test('peerRecords(outlier: true) appends one record far from the cluster',
        () {
      final List<MixAccuracyRecord> clustered = peerRecords(6, spread: 0.4);
      final List<MixAccuracyRecord> withOutlier =
          peerRecords(6, spread: 0.4, outlier: true);
      expect(withOutlier, hasLength(clustered.length + 1));
      // The appended record is far from the cluster centroid; the clustered ones
      // are near it.
      final ColorCoordinates centroid = _centroid(
          clustered.map((MixAccuracyRecord r) => r.measuredColour.lab));
      final double outlierDist = _labDistance(
          withOutlier.last.measuredColour.lab, centroid);
      final double clusterMax = clustered
          .map((MixAccuracyRecord r) =>
              _labDistance(r.measuredColour.lab, centroid))
          .reduce(math.max);
      expect(outlierDist, greaterThan(clusterMax * 10));
    });

    test('noPaletteRecord has no declared palette; confirmedEvidence is an own '
        'swatch', () {
      expect(noPaletteRecord.declaredPalette.isPresent, isFalse);
      expect(
        confirmedEvidence.evidence.map((EvidencePoint e) => e.kind),
        contains(EvidenceKind.photographedSwatch),
      );
    });

    test('source taggers assign distinct vs single sources', () {
      final List<MixAccuracyRecord> records = peerRecords(3);
      expect(
        sourcedFromDistinctPeers(records).map((SourcedRecord s) => s.source).toSet(),
        hasLength(3),
      );
      expect(
        sourcedFromOnePeer(records).map((SourcedRecord s) => s.source).toSet(),
        hasLength(1),
      );
    });
  });

  // -------------------------------------------------------------------------
  // 4. The fake loopback transport behaves as a real transport would.
  // -------------------------------------------------------------------------
  group('fake peer transport', () {
    test('two installs discover each other', () async {
      final TwoInstalls pair = twoInstalls();
      expect(await pair.a.transport.discover(), <Peer>[const Peer('install-B')]);
      expect(await pair.b.transport.discover(), <Peer>[const Peer('install-A')]);
    });

    test('offer delivers to the target inbox; receive reads the offering',
        () async {
      final List<MixAccuracyRecord> bOffering = peerRecords(2, spread: 1);
      final TwoInstalls pair = twoInstalls(bRecords: bOffering);
      // A reads what B is offering.
      expect(await pair.a.transport.receive(const Peer('install-B')), bOffering);
      // A offers a record to B; it lands in B's inbox.
      final MixAccuracyRecord r = peerRecords(1).single;
      await pair.a.transport.offer(const Peer('install-B'), <MixAccuracyRecord>[r]);
      expect(pair.network.inboxOf('install-B'), <MixAccuracyRecord>[r]);
      expect(pair.network.inboxOf('install-A'), isEmpty);
    });

    test('no peer reachable ⇒ discover returns none (AC-7 setup)', () async {
      final TwoInstalls pair = twoInstalls(peersReachable: false);
      expect(await pair.a.transport.discover(), isEmpty);
      expect(await pair.b.transport.discover(), isEmpty);
    });
  });
}

/// The mean CIELAB coordinate of [points].
ColorCoordinates _centroid(Iterable<ColorCoordinates> points) {
  final List<ColorCoordinates> list = points.toList();
  final int n = list.length;
  double l = 0, a = 0, b = 0;
  for (final ColorCoordinates c in list) {
    l += c.lightness;
    a += c.a;
    b += c.b;
  }
  return ColorCoordinates(lightness: l / n, a: a / n, b: b / n);
}

/// The Euclidean CIELAB distance between [x] and [y] (ΔE*ab, enough to tell a
/// cluster from a far outlier in a fixture guard).
double _labDistance(ColorCoordinates x, ColorCoordinates y) {
  final double dl = x.lightness - y.lightness;
  final double da = x.a - y.a;
  final double db = x.b - y.b;
  return math.sqrt(dl * dl + da * da + db * db);
}
