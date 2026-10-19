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
/// `ExchangeOutcome`. A round with no reachable peer reports
/// [ExchangeReport.empty] (AC-7).
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

/// The transport-agnostic serverless gossip exchange (bs-14 EXCHANGE-1/2).
///
/// Given the painter's own shareable records, one round [exchangeOnce] discovers
/// the reachable peers through the [PeerTransport], offers each peer the records
/// it is missing (`mine − theirs` by content hash), takes the records the peer
/// offers back and drops anything the [SeenSet] has already seen. When no peer
/// is reachable the round is a silent no-op (AC-7).
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
  /// triggered the round is never blocked and the outcome stays at zero.
  ///
  /// With a peer reachable, a gossip round is conducted with each one (AC-6).
  /// For that peer the exchange is kept minimal, keyed by [MixAccuracyRecord.contentHash]:
  ///
  /// * **Offer only what the peer is missing.** A record of [mine] whose content
  ///   hash the peer already offers back is not re-offered (the peer has it);
  ///   everything else is a candidate. A candidate the [SeenSet] has already
  ///   seen — one offered or received in an earlier round — is dropped as a
  ///   duplicate (`dedupDrops`, D-7) and never re-offered; a genuinely new
  ///   record is registered and offered. So each side offers the other exactly
  ///   the records it lacks, once.
  /// * **Take what the peer offers back,** dropping anything the [SeenSet] has
  ///   already seen; the survivors are the round's [ExchangeReport.received]
  ///   (handed to the merge, MERGE).
  ///
  /// Registering an offered or received record in [seenSet] is what makes a
  /// second round over an unchanged peer a silent no-op — the already-seen
  /// records are dropped rather than re-exchanged.
  Future<ExchangeReport> exchangeOnce(Iterable<MixAccuracyRecord> mine) async {
    final List<Peer> peers = await transport.discover();
    if (peers.isEmpty) {
      return ExchangeReport.empty;
    }
    final List<MixAccuracyRecord> mineList = List<MixAccuracyRecord>.of(mine);
    final List<MixAccuracyRecord> offered = <MixAccuracyRecord>[];
    final List<MixAccuracyRecord> received = <MixAccuracyRecord>[];
    var dedupDrops = 0;
    for (final Peer peer in peers) {
      final List<MixAccuracyRecord> theirs = await transport.receive(peer);
      final Set<String> theirHashes = <String>{
        for (final MixAccuracyRecord r in theirs) r.contentHash,
      };
      // Offer the peer only the records it is missing (mine − theirs by content
      // hash), dropping any the seen-set has already handled this device.
      final List<MixAccuracyRecord> toOffer = <MixAccuracyRecord>[];
      for (final MixAccuracyRecord record in mineList) {
        if (theirHashes.contains(record.contentHash)) {
          continue; // the peer already has it — not missing, not a dedup drop
        }
        if (!seenSet.register(record)) {
          dedupDrops++; // already offered/received before (D-7)
          continue;
        }
        toOffer.add(record);
      }
      if (toOffer.isNotEmpty) {
        await transport.offer(peer, toOffer);
      }
      offered.addAll(toOffer);
      // Take what the peer offers back, dropping anything already seen.
      for (final MixAccuracyRecord record in theirs) {
        if (!seenSet.register(record)) {
          dedupDrops++;
          continue;
        }
        received.add(record);
      }
    }
    return ExchangeReport(
      offered: offered,
      received: received,
      dedupDrops: dedupDrops,
      exchangesConducted: peers.length,
    );
  }
}
