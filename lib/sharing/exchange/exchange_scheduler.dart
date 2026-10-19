import 'package:flutter/foundation.dart';

import '../record/mix_accuracy_record.dart';
import 'gossip_exchange.dart';

/// The running tally of what the background gossip exchange has done, surfaced to
/// the acceptance suite through `ExchangeOutcomeEndpoint` (bs-14 EXCHANGE-1).
///
/// [offered], [received] and [dedupDrops] accumulate across rounds; [exchanges]
/// counts the peers an exchange was actually conducted with (zero while no peer
/// is reachable, the AC-7 invariant); and [waitedOnExchange] records whether any
/// core flow ever blocked on the exchange — always false, because the scheduler
/// is fire-and-forget (the AC-2 / AC-7 "no wait" invariant).
@immutable
class ExchangeOutcome {
  /// Creates an outcome tally.
  const ExchangeOutcome({
    this.offered = 0,
    this.received = 0,
    this.dedupDrops = 0,
    this.exchanges = 0,
    this.waitedOnExchange = false,
  });

  /// The zero tally before any round has run.
  static const ExchangeOutcome empty = ExchangeOutcome();

  /// Total records offered to peers across all rounds.
  final int offered;

  /// Total records received from peers across all rounds.
  final int received;

  /// Total records dropped as already-seen (D-7).
  final int dedupDrops;

  /// Number of peers an exchange was actually conducted with.
  final int exchanges;

  /// Whether a core flow ever waited on the exchange (always false — the
  /// scheduler never blocks a caller).
  final bool waitedOnExchange;

  /// This tally with [report]'s counts added in; [waitedOnExchange] is carried
  /// through unchanged.
  ExchangeOutcome fold(ExchangeReport report) => ExchangeOutcome(
        offered: offered + report.offered.length,
        received: received + report.received.length,
        dedupDrops: dedupDrops + report.dedupDrops,
        exchanges: exchanges + report.exchangesConducted,
        waitedOnExchange: waitedOnExchange,
      );

  /// This tally with [waitedOnExchange] set to [waited].
  ExchangeOutcome withWaited(bool waited) => ExchangeOutcome(
        offered: offered,
        received: received,
        dedupDrops: dedupDrops,
        exchanges: exchanges,
        waitedOnExchange: waited,
      );

  @override
  bool operator ==(Object other) =>
      other is ExchangeOutcome &&
      other.offered == offered &&
      other.received == received &&
      other.dedupDrops == dedupDrops &&
      other.exchanges == exchanges &&
      other.waitedOnExchange == waitedOnExchange;

  @override
  int get hashCode =>
      Object.hash(offered, received, dedupDrops, exchanges, waitedOnExchange);

  @override
  String toString() =>
      'ExchangeOutcome(offered $offered, received $received, '
      'dedupDrops $dedupDrops, exchanges $exchanges, waited $waitedOnExchange)';
}

/// Fires gossip rounds **fire-and-forget**, so no core flow ever waits on the
/// exchange (bs-14 EXCHANGE-1).
///
/// [trigger] launches one [GossipExchange.exchangeOnce] round without awaiting it
/// and returns immediately; the round's [ExchangeReport] is folded into [outcome]
/// when (and if) it completes, and any failure is swallowed silently (D-5).
/// Because the caller never awaits, a core flow that triggers a round proceeds
/// without being blocked by it — the invariant AC-2 ("no per-exchange action")
/// and AC-7 ("no peer ⇒ no wait") rest on.
class ExchangeScheduler {
  /// Creates a scheduler driving [_exchange].
  ExchangeScheduler(this._exchange);

  final GossipExchange _exchange;

  ExchangeOutcome _outcome = ExchangeOutcome.empty;
  Future<void>? _settled;

  /// The running tally of what the exchange has done so far.
  ExchangeOutcome get outcome => _outcome;

  /// A future that completes when the most recently triggered round has settled
  /// (success or swallowed failure), for tests that need to observe the folded
  /// [outcome]. Null before the first [trigger]. Production never awaits it.
  Future<void>? get settled => _settled;

  /// Launches one gossip round over [mine] without waiting for it.
  ///
  /// Returns synchronously; the round runs in the background and folds its report
  /// into [outcome] on completion. A thrown error is swallowed so a background
  /// failure never surfaces to the caller (D-5).
  void trigger(Iterable<MixAccuracyRecord> mine) {
    _settled = _exchange.exchangeOnce(mine).then((report) {
      _outcome = _outcome.fold(report);
    }).catchError((Object _) {
      // Fire-and-forget: a background exchange failure is silent (D-5).
    });
    // The round above runs in the background; the caller is not waiting on it.
    _outcome = _outcome.withWaited(false);
  }
}
