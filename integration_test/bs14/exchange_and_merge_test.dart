// bs-14 acceptance criteria — serverless exchange + append-only merge (ITEST-3).
//
// One *pending* integration test per AC-6, AC-7 and AC-10, written against the
// real sharing subsystem through the public surface only — the real
// `GossipExchange`/`ExchangeScheduler` over the fake loopback `PeerTransport`
// (the one sanctioned fake, D-3), observed through `ExchangeOutcomeEndpoint` and
// the transport's own delivered-inbox; and the real `EvidenceMerge` observed
// through `MappingEvidenceEndpoint`. Each test encodes the AC's intended
// behaviour and is *pending* until its behaviour phase lands:
//
//   AC-6  → EXCHANGE-2 (exchange only the records each peer is missing)
//   AC-7  → EXCHANGE-3 (no peer ⇒ no exchange, no wait)
//   AC-10 → MERGE-2    (append-only, source-tagged merge)
//
// The pending gate (`acTest`, keyed to `BS14_RUN_PENDING`) skips these in the
// default run (so the suite stays green with all three pending) and runs them
// under `--dart-define=BS14_RUN_PENDING=true` (the red baseline). Each pending
// test fails on a Then assertion that names its owning phase — never a harness
// crash.
//
// Runs on the host `flutter-tester` device (pure-Dart sharing logic, no camera):
//   flutter test integration_test/bs14/exchange_and_merge_test.dart -d flutter-tester
//   flutter test integration_test/bs14/exchange_and_merge_test.dart -d flutter-tester \
//       --dart-define=BS14_RUN_PENDING=true   # red baseline
//
// One bs-14 app-booting file per `flutter test` invocation (flutter-tester
// app-relaunch limitation); these three tests boot no app, but the convention
// stands for the suite as a whole.

import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  group('bs-14 exchange & append-only merge acceptance criteria', () {
    // -----------------------------------------------------------------------
    // AC-6 — two reachable installs exchange only the records each is missing,
    // keyed by content hash, duplicates and already-seen records dropped.
    // Owner: EXCHANGE-2.
    // -----------------------------------------------------------------------
    acTest('AC-6', 'TestAC06_ExchangeOnlyMissing', () async {
      // Three distinct records (distinct content hashes), plus two content-equal
      // but *distinct-object* copies of r2 — one held by A, one by B — so that a
      // diff keyed by object identity would (wrongly) re-offer r2, while a diff
      // keyed by content hash drops it (D-7).
      final MixAccuracyRecord r1 =
          _recordAt(const ColorCoordinates(lightness: 60, a: 1, b: 5));
      final MixAccuracyRecord r2a =
          _recordAt(const ColorCoordinates(lightness: 62, a: 2, b: 6));
      final MixAccuracyRecord r2b =
          _recordAt(const ColorCoordinates(lightness: 62, a: 2, b: 6));
      final MixAccuracyRecord r3 =
          _recordAt(const ColorCoordinates(lightness: 64, a: 3, b: 7));

      // Given: two installs reachable on one local network — A holds {r1, r2},
      // B holds {r2, r3} (r2 the common record, by content hash).
      final TwoInstalls t = twoInstalls(
        aRecords: <MixAccuracyRecord>[r1, r2a],
        bRecords: <MixAccuracyRecord>[r2b, r3],
      );
      // Given check: the three records are pairwise distinct by content hash,
      // and A's/B's r2 are a content-equal but distinct object pair — so the
      // content-hash-vs-identity discrimination below is real.
      expect(
        <String>{r1.contentHash, r2a.contentHash, r3.contentHash},
        hasLength(3),
        reason: 'AC-6 Given: r1, r2, r3 are distinct records (distinct hashes)',
      );
      expect(r2a, equals(r2b),
          reason: 'AC-6 Given: A\'s and B\'s r2 are value-equal copies');
      expect(r2a.contentHash, r2b.contentHash,
          reason: 'AC-6 Given: the two r2 copies share a content hash');
      expect(identical(r2a, r2b), isFalse,
          reason: 'AC-6 Given: the two r2 copies are distinct objects '
              '(so an identity-keyed diff would re-offer r2)');
      // Given check: the peer is reachable and each holds the set above.
      expect(t.network.peersReachable, isTrue,
          reason: 'AC-6 Given: the installs are reachable on the network');
      expect((await t.a.transport.discover()).map((p) => p.id),
          contains(t.b.id),
          reason: 'AC-6 Given: A discovers B on the network');
      expect(t.a.ownRecords, orderedEquals(<MixAccuracyRecord>[r1, r2a]),
          reason: 'AC-6 Given: A holds {r1, r2}');
      expect(t.b.ownRecords, orderedEquals(<MixAccuracyRecord>[r2b, r3]),
          reason: 'AC-6 Given: B holds {r2, r3}');

      // When: A and B each run one background gossip round.
      final ExchangeOutcome aOutcome = await runExchange(t.a);
      await runExchange(t.b);

      // Then: each offered only the record the other was missing, keyed by
      // content hash — A offered just r1 to B (r2 common ⇒ dropped), B offered
      // just r3 to A. Reading the transport's delivered inbox is the truest
      // observable of "what crossed". (Rejects: offering the full set, or keying
      // the diff by object identity so the common r2 crosses anyway.)
      expect(_hashesOf(t.network.inboxOf(t.b.id)),
          equals(<String>{r1.contentHash}),
          reason: 'AC-6: A offers B only the missing r1 (r2 common, dropped) '
              '— EXCHANGE-2');
      expect(_hashesOf(t.network.inboxOf(t.a.id)),
          equals(<String>{r3.contentHash}),
          reason: 'AC-6: B offers A only the missing r3 (r2 common, dropped) '
              '— EXCHANGE-2');

      // Then: the exchange is observable through the outcome endpoint — a peer
      // exchange was conducted and exactly one record was offered.
      final ExchangeOutcomeEndpoint aEndpoint = exchangeEndpoint(aOutcome);
      expect(aEndpoint.exchanges, greaterThanOrEqualTo(1),
          reason: 'AC-6: A conducted a peer exchange');
      expect(aEndpoint.offered, 1,
          reason: 'AC-6: A offered exactly the one missing record');

      // Then: already-seen records are not re-offered. A runs a second round
      // with nothing changed at B; because A already offered r1 (the seen-set
      // remembers it by content hash), it is not delivered to B a second time —
      // B's inbox still holds exactly one r1. (Rejects: re-offering already-seen
      // records every round.)
      await runExchange(t.a);
      expect(t.network.inboxOf(t.b.id), hasLength(1),
          reason: 'AC-6: an already-seen record is not re-offered (dedup) '
              '— EXCHANGE-2');
      expect(_hashesOf(t.network.inboxOf(t.b.id)),
          equals(<String>{r1.contentHash}),
          reason: 'AC-6: the one delivered record is still just r1');
    });

    // -----------------------------------------------------------------------
    // AC-7 — with no peer reachable, no exchange occurs and no core function
    // waits on one. Owner: EXCHANGE-3.
    // -----------------------------------------------------------------------
    acTest('AC-7', 'TestAC07_NoPeerNoWait', () async {
      // Given: two installs, but no peer is reachable (discovery finds nobody).
      final TwoInstalls none = twoInstalls(
        aRecords: <MixAccuracyRecord>[
          _recordAt(const ColorCoordinates(lightness: 60, a: 1, b: 5)),
        ],
        bRecords: <MixAccuracyRecord>[
          _recordAt(const ColorCoordinates(lightness: 64, a: 3, b: 7)),
        ],
        peersReachable: false,
      );
      // Given check: no peer is reachable — discovery returns none.
      expect(none.network.peersReachable, isFalse,
          reason: 'AC-7 Given: no peer is reachable');
      expect(await none.a.transport.discover(), isEmpty,
          reason: 'AC-7 Given: discovery finds no peer');

      // When: a core flow runs and triggers a background round. The scheduler is
      // fire-and-forget, so `trigger` returns synchronously — the core flow does
      // not block on discovery. Read the no-wait invariant the instant control
      // returns, before the round settles.
      none.a.scheduler.trigger(none.a.ownRecords);
      expect(none.a.scheduler.outcome.waitedOnExchange, isFalse,
          reason: 'AC-7: the core flow is not blocked on the exchange');
      // Let the background round settle (swallowing any failure, D-5): it must
      // complete normally, never throw, with no peer present.
      await expectLater(none.a.scheduler.settled, completes,
          reason: 'AC-7: a no-peer round settles without throwing');
      final ExchangeOutcome noPeerOutcome = none.a.scheduler.outcome;

      // Then: no exchange occurred and nothing was waited on — read through the
      // documented outcome endpoint. (Rejects: a core flow that blocks/awaits
      // discovery, or throws when no peer is present.)
      final ExchangeOutcomeEndpoint noPeerEndpoint =
          exchangeEndpoint(noPeerOutcome);
      expect(noPeerEndpoint.exchanges, 0,
          reason: 'AC-7: no peer ⇒ no exchange conducted');
      expect(noPeerEndpoint.offered, 0,
          reason: 'AC-7: no peer ⇒ nothing offered');
      expect(noPeerEndpoint.waitedOnExchange, isFalse,
          reason: 'AC-7: no core function waited on the exchange');

      // Control: "no exchange occurred" is only meaningful if an exchange *would*
      // occur when a peer IS reachable — otherwise an impl that never exchanges
      // at all would pass vacuously (G3/G5). With a reachable peer holding a
      // record the other is missing, a peer exchange is conducted. This control
      // is red at the shell (which exchanges nothing) and goes green once the
      // exchange behaviour lands — the discriminator that keeps AC-7 honest.
      final TwoInstalls reachable = twoInstalls(
        aRecords: <MixAccuracyRecord>[
          _recordAt(const ColorCoordinates(lightness: 60, a: 1, b: 5)),
        ],
        bRecords: <MixAccuracyRecord>[
          _recordAt(const ColorCoordinates(lightness: 64, a: 3, b: 7)),
        ],
      );
      final ExchangeOutcome reachableOutcome = await runExchange(reachable.a);
      expect(exchangeEndpoint(reachableOutcome).exchanges,
          greaterThanOrEqualTo(1),
          reason: 'AC-7 control: a reachable peer DOES get an exchange '
              '(so the no-peer zero above is a real result) — EXCHANGE-3');
      expect(reachableOutcome.waitedOnExchange, isFalse,
          reason: 'AC-7 control: even a real exchange is never waited on');
    });

    // -----------------------------------------------------------------------
    // AC-10 — records from many devices merge without overwriting: each is
    // appended and tagged peer-contributed, none overwrites another.
    // Owner: MERGE-2.
    // -----------------------------------------------------------------------
    acTest('AC-10', 'TestAC10_AppendOnlyMerge', () {
      const EvidenceMerge merge = EvidenceMerge();

      // Given: one mapping already carries a prior evidence point (its LLM seed),
      // and three mix-accuracy records arrive for it from three distinct devices.
      const EvidencePoint priorSeed = EvidencePoint(
        coordinates: seedMappingValue,
        source: 'llm-seed',
        kind: EvidenceKind.llmSeed,
      );
      final List<EvidencePoint> existing = <EvidencePoint>[priorSeed];
      final List<SourcedRecord> incoming =
          sourcedFromDistinctPeers(peerRecords(3));
      // Given checks: exactly three incoming records, from three distinct
      // sources, with three distinct measured colours — so "dedups distinct
      // measurements" is a wrong impl this test can catch.
      expect(incoming, hasLength(3),
          reason: 'AC-10 Given: three records arrive');
      expect(incoming.map((s) => s.source).toSet(), hasLength(3),
          reason: 'AC-10 Given: the three records come from distinct sources');
      expect(
        incoming.map((s) => s.record.measuredColour.lab).toSet(),
        hasLength(3),
        reason: 'AC-10 Given: the three measurements are distinct',
      );

      // When: they are merged into the local copy, observed through the mapping
      // evidence endpoint.
      final List<EvidencePoint> merged = merge.ingest(existing, incoming);
      final MappingEvidenceEndpoint endpoint =
          mappingEndpoint(value: seedMappingValue, evidence: merged);
      final List<EvidencePoint> observed = endpoint.view!.evidence;

      // Then: all three are appended — the log grew by exactly three.
      // (Rejects: deduping distinct measurements, or overwriting on merge.)
      expect(observed, hasLength(existing.length + 3),
          reason: 'AC-10: all three distinct records are appended — MERGE-2');

      // Then: the prior point is unchanged and still first — nothing was
      // overwritten and order is preserved. (Rejects: overwrite/replace.)
      expect(observed.first, priorSeed,
          reason: 'AC-10: the prior seed point is preserved, not overwritten');
      expect(observed.sublist(0, existing.length), orderedEquals(existing),
          reason: 'AC-10: prior evidence is unchanged and order is preserved');

      // Then: each appended point is tagged peer-contributed, carries the source
      // it arrived from, and holds that record's measured colour — in arrival
      // order. (Rejects: dropping the source tag, or mislabelling the kind.)
      for (var i = 0; i < incoming.length; i++) {
        final EvidencePoint appended = observed[existing.length + i];
        expect(appended.kind, EvidenceKind.peerContributed,
            reason: 'AC-10: appended point $i is tagged peer-contributed');
        expect(appended.source, incoming[i].source,
            reason: 'AC-10: appended point $i carries its source tag '
                '(${incoming[i].source})');
        expect(appended.coordinates, incoming[i].record.measuredColour.lab,
            reason: 'AC-10: appended point $i carries the record\'s measured '
                'colour');
      }
    });
  });
}

/// Builds a shareable [MixAccuracyRecord] for the seed mapping whose measured
/// colour is [lab] (its CIELCh derived by the real colour science), carrying the
/// present seed palette so it is interpretable. Distinct [lab]s ⇒ distinct
/// content hashes (D-7).
MixAccuracyRecord _recordAt(ColorCoordinates lab) => MixAccuracyRecord(
      paintCombination: seedCombination,
      declaredPalette: seedPalette,
      measuredColour: measuredColourOf(lab),
      tier: MeasurementTier.cardLess,
    );

/// The set of content hashes behind [records] — how the exchange ACs compare
/// "what crossed" independent of object identity (D-7).
Set<String> _hashesOf(Iterable<MixAccuracyRecord> records) =>
    <String>{for (final MixAccuracyRecord r in records) r.contentHash};
