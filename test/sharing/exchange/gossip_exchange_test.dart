import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/exchange/gossip_exchange.dart';
import 'package:paint_color_assistant/sharing/exchange/peer_transport.dart';
import 'package:paint_color_assistant/sharing/exchange/seen_set.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';

import '_support.dart';

void main() {
  group('ExchangeReport', () {
    test('empty carries nothing', () {
      expect(ExchangeReport.empty.offered, isEmpty);
      expect(ExchangeReport.empty.received, isEmpty);
      expect(ExchangeReport.empty.dedupDrops, 0);
      expect(ExchangeReport.empty.exchangesConducted, 0);
    });

    test('carries what crossed the boundary in a round', () {
      final report = ExchangeReport(
        offered: [record('a')],
        received: [record('b'), record('c')],
        dedupDrops: 2,
        exchangesConducted: 1,
      );
      expect(report.offered, hasLength(1));
      expect(report.received, hasLength(2));
      expect(report.dedupDrops, 2);
      expect(report.exchangesConducted, 1);
    });
  });

  group('GossipExchange (EXCHANGE-3: no peer ⇒ no exchange)', () {
    test('no peer reachable ⇒ silent no-op round', () async {
      final transport = FakePeerTransport(peers: const <Peer>[]);
      final exchange =
          GossipExchange(transport: transport, seenSet: SeenSet());

      final report = await exchange.exchangeOnce([record('x')]);

      expect(transport.discoverCalls, 1, reason: 'the discovery seam is wired');
      expect(report.exchangesConducted, 0, reason: 'no peer ⇒ no exchange');
      expect(report.offered, isEmpty);
      expect(report.received, isEmpty);
      expect(report.dedupDrops, 0);
    });

    test('exposes its collaborators', () {
      final transport = FakePeerTransport();
      final seenSet = SeenSet();
      final exchange = GossipExchange(transport: transport, seenSet: seenSet);
      expect(exchange.transport, same(transport));
      expect(exchange.seenSet, same(seenSet));
    });
  });

  group('GossipExchange (EXCHANGE-2: exchange only the missing records, AC-6)',
      () {
    final r1 = record('r1');
    final r2 = record('r2');
    final r3 = record('r3');

    test('offers a peer only what it is missing, keyed by content hash, and '
        'takes what it offers back', () async {
      // The peer already offers back r2 (a content-equal copy) and r3; I hold
      // {r1, r2}. r2 is common by content hash, so only r1 is missing.
      final transport = FakePeerTransport(
        peers: const [Peer('b')],
        offering: [r2, r3],
      );
      final exchange =
          GossipExchange(transport: transport, seenSet: SeenSet());

      final report = await exchange.exchangeOnce([r1, record('r2')]);

      expect(report.exchangesConducted, 1);
      // Only the missing r1 crossed — r2 was common (by content hash) and
      // dropped; the diff is not keyed by object identity (the r2 copy differs).
      expect(_hashes(transport.offered), {r1.contentHash},
          reason: 'offer only the record the peer is missing');
      expect(_hashes(report.offered), {r1.contentHash});
      // The peer's r2 and r3 are taken back (neither seen before).
      expect(_hashes(report.received), {r2.contentHash, r3.contentHash});
      expect(report.dedupDrops, 0);
    });

    test('an already-seen record is not re-offered in a later round (dedup, '
        'D-7)', () async {
      // The peer holds nothing, so r1 is missing on the first round and offered.
      final transport =
          FakePeerTransport(peers: const [Peer('b')]);
      final exchange =
          GossipExchange(transport: transport, seenSet: SeenSet());

      final first = await exchange.exchangeOnce([r1]);
      expect(_hashes(first.offered), {r1.contentHash});
      expect(transport.offered, hasLength(1));

      // Nothing changed at the peer; r1 is now already-seen, so the second round
      // drops it rather than re-offering it — and makes no offer call.
      final second = await exchange.exchangeOnce([r1]);
      expect(second.offered, isEmpty, reason: 'already-seen ⇒ not re-offered');
      expect(second.dedupDrops, 1);
      expect(transport.offered, hasLength(1),
          reason: 'the peer was not offered r1 a second time');
    });

    test('a record is offered to only one peer per round (cross-peer dedup)',
        () async {
      // Two reachable peers, neither holding anything; I hold one record.
      final transport = FakePeerTransport(peers: const [Peer('a'), Peer('b')]);
      final exchange =
          GossipExchange(transport: transport, seenSet: SeenSet());

      final report = await exchange.exchangeOnce([r1]);

      expect(report.exchangesConducted, 2,
          reason: 'one exchange conducted per reachable peer');
      // Offered to the first peer, then registered — the second peer sees it as
      // already-seen and it is dropped, so it crosses exactly once.
      expect(transport.offered, hasLength(1));
      expect(_hashes(report.offered), {r1.contentHash});
      expect(report.dedupDrops, 1);
    });

    test('a record received from one peer is not re-taken from another',
        () async {
      // I hold nothing; both reachable peers offer back the same record.
      final transport = FakePeerTransport(
        peers: const [Peer('a'), Peer('b')],
        offering: [r2],
      );
      final exchange =
          GossipExchange(transport: transport, seenSet: SeenSet());

      final report = await exchange.exchangeOnce(const []);

      expect(report.exchangesConducted, 2);
      expect(transport.offered, isEmpty, reason: 'I had nothing to offer');
      // r2 is taken once; the second peer's copy is already-seen and dropped.
      expect(_hashes(report.received), {r2.contentHash});
      expect(report.dedupDrops, 1);
    });
  });
}

/// The set of content hashes behind [records] — how the exchange compares what
/// crossed independent of object identity (D-7).
Set<String> _hashes(Iterable<MixAccuracyRecord> records) =>
    <String>{for (final r in records) r.contentHash};
