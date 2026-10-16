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

  group('GossipExchange (shell)', () {
    test('awaits discovery but exchanges nothing', () async {
      final transport = FakePeerTransport(peers: const [Peer('a')]);
      final exchange =
          GossipExchange(transport: transport, seenSet: SeenSet());

      final report = await exchange.exchangeOnce([record('x')]);

      expect(transport.discoverCalls, 1, reason: 'the discovery seam is wired');
      expect(report.offered, isEmpty);
      expect(report.received, isEmpty);
      expect(report.exchangesConducted, 0);
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
