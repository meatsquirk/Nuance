import 'package:flutter/widgets.dart';

import 'exchange_scheduler.dart';

/// A read-only observation seam over the gossip exchange's running
/// [ExchangeOutcome], for the bs-14 acceptance suite (EXCHANGE-1).
///
/// Mirrors the sibling read endpoints (`RecordInspectEndpoint`,
/// `SharingConsentReadEndpoint`): an [InheritedWidget] the suite finds by its
/// [endpointKey] to read what the UI never surfaces — how much the silent
/// background exchange [offered] and [received], how many duplicates it dropped
/// ([dedupDrops]), how many peer [exchanges] it conducted, and crucially whether
/// any core flow ever [waitedOnExchange] (AC-2 / AC-7). All zero / false in the
/// shell — the skeleton exchanges nothing — until the EXCHANGE behaviour phases.
class ExchangeOutcomeEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [outcome] to descendants.
  const ExchangeOutcomeEndpoint({
    this.outcome = ExchangeOutcome.empty,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('exchange-outcome-endpoint');

  /// The running tally the gossip scheduler maintains.
  final ExchangeOutcome outcome;

  /// Records offered to peers so far.
  int get offered => outcome.offered;

  /// Records received from peers so far.
  int get received => outcome.received;

  /// Already-seen records dropped so far (D-7).
  int get dedupDrops => outcome.dedupDrops;

  /// Peer exchanges conducted so far.
  int get exchanges => outcome.exchanges;

  /// Whether any core flow ever waited on the exchange (false by contract).
  bool get waitedOnExchange => outcome.waitedOnExchange;

  /// The nearest enclosing endpoint above [context]. Throws if there is none.
  static ExchangeOutcomeEndpoint of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<ExchangeOutcomeEndpoint>();
    assert(
      endpoint != null,
      'No ExchangeOutcomeEndpoint found above this widget.',
    );
    return endpoint!;
  }

  /// The nearest enclosing endpoint above [context], or null when there is none
  /// — for trees that mount no exchange observation.
  static ExchangeOutcomeEndpoint? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExchangeOutcomeEndpoint>();

  @override
  bool updateShouldNotify(ExchangeOutcomeEndpoint oldWidget) =>
      outcome != oldWidget.outcome;
}
