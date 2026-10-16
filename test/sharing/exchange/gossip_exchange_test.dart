import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/exchange/gossip_exchange.dart';
import 'package:paint_color_assistant/sharing/exchange/peer_transport.dart';
import 'package:paint_color_assistant/sharing/exchange/seen_set.dart';

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

    test('a reachable peer ⇒ a round is conducted with each one', () async {
      final transport = FakePeerTransport(peers: const [Peer('a'), Peer('b')]);
      final exchange =
          GossipExchange(transport: transport, seenSet: SeenSet());

      final report = await exchange.exchangeOnce([record('x')]);

      expect(transport.discoverCalls, 1, reason: 'the discovery seam is wired');
      expect(report.exchangesConducted, 2,
          reason: 'one exchange conducted per reachable peer');
      // The mine − theirs offer/receive content is EXCHANGE-2's (AC-6); this
      // phase establishes only that a round happens per reachable peer.
      expect(report.offered, isEmpty);
      expect(report.received, isEmpty);
    });

    test('exposes its collaborators', () {
      final transport = FakePeerTransport();
      final seenSet = SeenSet();
      final exchange = GossipExchange(transport: transport, seenSet: seenSet);
      expect(exchange.transport, same(transport));
      expect(exchange.seenSet, same(seenSet));
    });
  });
}
