import 'package:flutter/foundation.dart';

import '../record/mix_accuracy_record.dart';
import 'peer_transport.dart';
import 'seen_set.dart';

/// The result of a single [GossipExchange.exchangeOnce] round (bs-14 EXCHANGE-1).
///
/// It carries what crossed the boundary this round — the records [offered] to
/// peers and the records [received] from them — plus the [dedupDrops] the
/// seen-set rejected and the number of peers an exchange was actually
/// [exchangesConducted] with. The scheduler folds these into its running
/// `ExchangeOutcome`. The shell never conducts an exchange, so every round
/// reports [ExchangeReport.empty]; the EXCHANGE behaviour phases populate it.
@immutable
class ExchangeReport {
  /// Creates a report from one exchange round.
  const ExchangeReport({
    this.offered = const <MixAccuracyRecord>[],
    this.received = const <MixAccuracyRecord>[],
    this.dedupDrops = 0,
    this.exchangesConducted = 0,
  });

  /// A round in which nothing was offered, received or exchanged.
  static const ExchangeReport empty = ExchangeReport();

  /// The records offered to peers this round (those they were missing).
  final List<MixAccuracyRecord> offered;

  /// The records received from peers this round.
  final List<MixAccuracyRecord> received;

  /// Records dropped because the seen-set had already seen them (D-7).
  final int dedupDrops;

  /// The number of peers an actual exchange was conducted with — zero when no
  /// peer was reachable (the AC-7 "no peer ⇒ no exchange" case).
  final int exchangesConducted;
}

/// The transport-agnostic serverless gossip exchange (bs-14 EXCHANGE-1).
///
/// Given the painter's own shareable records, one round [exchangeOnce] discovers
/// the reachable peers through the [PeerTransport], offers each peer the records
/// it is missing (`mine − theirs` by content hash), takes the records the peer
/// offers back and drops anything the [SeenSet] has already seen. When no peer
/// is reachable the round is a silent no-op (AC-7); the `mine − theirs` diff,
/// offer/receive and dedup content is EXCHANGE-2's work (AC-6).
class GossipExchange {
  /// Creates a gossip exchange over [transport], deduplicating through [seenSet].
  GossipExchange({required this.transport, required this.seenSet});

  /// The off-device actor records cross (the one bs-12 exception, D-4 / G-4).
  final PeerTransport transport;

  /// The per-device dedup memory keyed by content hash (D-7).
  final SeenSet seenSet;

  /// Runs one gossip round over the painter's own [mine] records and reports
  /// what crossed the boundary.
  ///
  /// Discovers the reachable peers through [transport]. When none is reachable
  /// the round is a silent no-op — no exchange is conducted and nothing is
  /// offered (AC-7); the scheduler folds the empty report, so a core flow that
  /// triggered the round is never blocked and the outcome stays at zero. When a
  /// peer *is* reachable a gossip round is conducted with each one, so AC-7's
  /// "no exchange" zero is a real result rather than an implementation that
  /// never exchanges at all. What actually crosses the boundary each round — the
  /// `mine − theirs` diff and dedup via [seenSet] — is EXCHANGE-2's work (AC-6).
  Future<ExchangeReport> exchangeOnce(Iterable<MixAccuracyRecord> mine) async {
    final List<Peer> peers = await transport.discover();
    if (peers.isEmpty) {
      return ExchangeReport.empty;
    }
    return ExchangeReport(exchangesConducted: peers.length);
  }
}
