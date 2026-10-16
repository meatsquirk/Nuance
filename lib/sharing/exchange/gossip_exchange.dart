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
/// offers back and drops anything the [SeenSet] has already seen. That diff,
/// offer/receive and dedup logic is the EXCHANGE behaviour phases' work; this
/// shell wires the collaborators and the async discovery seam but exchanges
/// nothing — every round returns [ExchangeReport.empty].
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
  /// The shell establishes the async discovery seam the behaviour phases build
  /// on — it awaits [PeerTransport.discover] so the scheduler has a real
  /// fire-and-forget boundary — but computes no diff and exchanges nothing, so it
  /// always returns [ExchangeReport.empty]. EXCHANGE-2 computes `mine − theirs`
  /// and offers/receives through the transport, deduplicating via [seenSet];
  /// EXCHANGE-3 handles the no-peer case.
  Future<ExchangeReport> exchangeOnce(Iterable<MixAccuracyRecord> mine) async {
    await transport.discover();
    return ExchangeReport.empty;
  }
}
