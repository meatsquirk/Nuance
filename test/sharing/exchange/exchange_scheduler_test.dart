import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/exchange/exchange_scheduler.dart';
import 'package:paint_color_assistant/sharing/exchange/gossip_exchange.dart';
import 'package:paint_color_assistant/sharing/exchange/peer_transport.dart';
import 'package:paint_color_assistant/sharing/exchange/seen_set.dart';

import '_support.dart';

GossipExchange _exchange(PeerTransportKind kind) {
  switch (kind) {
    case PeerTransportKind.ok:
      return GossipExchange(
        transport: FakePeerTransport(peers: const [Peer('a')]),
        seenSet: SeenSet(),
      );
    case PeerTransportKind.throwing:
      return GossipExchange(
        transport: ThrowingPeerTransport(),
        seenSet: SeenSet(),
      );
  }
}

enum PeerTransportKind { ok, throwing }

void main() {
  group('ExchangeOutcome', () {
    test('empty is the zero tally', () {
      expect(ExchangeOutcome.empty.offered, 0);
      expect(ExchangeOutcome.empty.received, 0);
      expect(ExchangeOutcome.empty.dedupDrops, 0);
      expect(ExchangeOutcome.empty.exchanges, 0);
      expect(ExchangeOutcome.empty.waitedOnExchange, isFalse);
    });

    test('fold adds a report\'s counts, carrying waited through', () {
      const base = ExchangeOutcome(
        offered: 1,
        received: 1,
        dedupDrops: 1,
        exchanges: 1,
        waitedOnExchange: true,
      );
      final folded = base.fold(
        ExchangeReport(
          offered: [record('a')],
          received: [record('b'), record('c')],
          dedupDrops: 2,
          exchangesConducted: 1,
        ),
      );
      expect(folded.offered, 2);
      expect(folded.received, 3);
      expect(folded.dedupDrops, 3);
      expect(folded.exchanges, 2);
      expect(folded.waitedOnExchange, isTrue);
    });

    test('withWaited sets only the waited flag', () {
      const base = ExchangeOutcome(offered: 2, exchanges: 1);
      expect(base.withWaited(true).waitedOnExchange, isTrue);
      expect(base.withWaited(false).waitedOnExchange, isFalse);
      expect(base.withWaited(true).offered, 2);
      expect(base.withWaited(true).exchanges, 1);
    });

    test('value equality and hashCode over every field', () {
      const a = ExchangeOutcome(
        offered: 1,
        received: 2,
        dedupDrops: 3,
        exchanges: 4,
        waitedOnExchange: true,
      );
      const same = ExchangeOutcome(
        offered: 1,
        received: 2,
        dedupDrops: 3,
        exchanges: 4,
        waitedOnExchange: true,
      );
      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a == const ExchangeOutcome(offered: 9), isFalse);
      expect(a == const ExchangeOutcome(offered: 1, received: 9), isFalse);
      expect(a == const ExchangeOutcome(offered: 1, received: 2, dedupDrops: 9),
          isFalse);
      expect(
          a ==
              const ExchangeOutcome(
                  offered: 1, received: 2, dedupDrops: 3, exchanges: 9),
          isFalse);
      expect(
          a ==
              const ExchangeOutcome(
                  offered: 1,
                  received: 2,
                  dedupDrops: 3,
                  exchanges: 4,
                  waitedOnExchange: false),
          isFalse);
      expect(a == Object(), isFalse);
    });

    test('toString names the tally', () {
      expect(
        const ExchangeOutcome(offered: 1).toString(),
        'ExchangeOutcome(offered 1, received 0, dedupDrops 0, exchanges 0, '
        'waited false)',
      );
    });
  });

  group('ExchangeScheduler', () {
    test('settled is null before the first trigger', () {
      final scheduler = ExchangeScheduler(_exchange(PeerTransportKind.ok));
      expect(scheduler.settled, isNull);
      expect(scheduler.outcome, ExchangeOutcome.empty);
    });

    test('trigger returns before the round completes — no wait', () async {
      final gate = Completer<List<Peer>>();
      final scheduler = ExchangeScheduler(
        GossipExchange(
          transport: GatedPeerTransport(gate),
          seenSet: SeenSet(),
        ),
      );

      scheduler.trigger([record('x')]);

      // The round is still pending (gate unresolved), yet trigger has returned.
      expect(scheduler.outcome.waitedOnExchange, isFalse);
      expect(scheduler.settled, isNotNull);

      gate.complete(const <Peer>[]);
      await scheduler.settled;

      // The shell exchanges nothing, so the tally stays empty.
      expect(scheduler.outcome, ExchangeOutcome.empty);
      expect(scheduler.outcome.exchanges, 0);
    });

    test('a background failure is swallowed silently (D-5)', () async {
      final scheduler = ExchangeScheduler(_exchange(PeerTransportKind.throwing));

      scheduler.trigger([record('x')]);
      await scheduler.settled; // must not throw

      expect(scheduler.outcome, ExchangeOutcome.empty);
      expect(scheduler.outcome.waitedOnExchange, isFalse);
    });
  });
}
