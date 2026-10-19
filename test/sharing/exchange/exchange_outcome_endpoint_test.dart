import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/exchange/exchange_outcome_endpoint.dart';
import 'package:paint_color_assistant/sharing/exchange/exchange_scheduler.dart';

void main() {
  testWidgets('is the zero tally in the shell', (tester) async {
    await tester.pumpWidget(
      const ExchangeOutcomeEndpoint(child: SizedBox()),
    );
    final seen = tester.widget<ExchangeOutcomeEndpoint>(
      find.byType(ExchangeOutcomeEndpoint),
    );
    expect(seen.offered, 0);
    expect(seen.received, 0);
    expect(seen.dedupDrops, 0);
    expect(seen.exchanges, 0);
    expect(seen.waitedOnExchange, isFalse);
  });

  testWidgets('exposes the running outcome to a descendant', (tester) async {
    const outcome = ExchangeOutcome(
      offered: 3,
      received: 5,
      dedupDrops: 2,
      exchanges: 1,
      waitedOnExchange: false,
    );
    await tester.pumpWidget(
      const ExchangeOutcomeEndpoint(outcome: outcome, child: SizedBox()),
    );
    final seen = tester.widget<ExchangeOutcomeEndpoint>(
      find.byType(ExchangeOutcomeEndpoint),
    );
    expect(seen.outcome, outcome);
    expect(seen.offered, 3);
    expect(seen.received, 5);
    expect(seen.dedupDrops, 2);
    expect(seen.exchanges, 1);
  });

  testWidgets('of() returns the endpoint and maybeOf is null when absent',
      (tester) async {
    final seenOf = <ExchangeOutcomeEndpoint>[];
    final seenMaybe = <ExchangeOutcomeEndpoint?>[];
    await tester.pumpWidget(
      ExchangeOutcomeEndpoint(
        child: Builder(
          builder: (context) {
            seenOf.add(ExchangeOutcomeEndpoint.of(context));
            seenMaybe.add(ExchangeOutcomeEndpoint.maybeOf(context));
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seenMaybe.add(ExchangeOutcomeEndpoint.maybeOf(context));
          return const SizedBox();
        },
      ),
    );
    expect(seenOf, hasLength(1));
    expect(seenMaybe[0], isNotNull);
    expect(seenMaybe[1], isNull);
  });

  testWidgets('is findable by its stable endpoint key', (tester) async {
    await tester.pumpWidget(
      const ExchangeOutcomeEndpoint(
        key: ExchangeOutcomeEndpoint.endpointKey,
        child: SizedBox(),
      ),
    );
    expect(find.byKey(ExchangeOutcomeEndpoint.endpointKey), findsOneWidget);
  });

  test('updateShouldNotify tracks the outcome', () {
    const a = ExchangeOutcomeEndpoint(
      outcome: ExchangeOutcome(offered: 1),
      child: SizedBox(),
    );
    const same = ExchangeOutcomeEndpoint(
      outcome: ExchangeOutcome(offered: 1),
      child: SizedBox(),
    );
    const changed = ExchangeOutcomeEndpoint(
      outcome: ExchangeOutcome(offered: 2),
      child: SizedBox(),
    );
    expect(a.updateShouldNotify(same), isFalse);
    expect(a.updateShouldNotify(changed), isTrue);
  });
}
