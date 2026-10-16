import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/sharing/consent/consent_store.dart';
import 'package:paint_color_assistant/sharing/consent/opt_in_offer.dart';
import 'package:paint_color_assistant/sharing/consent/sharing_consent.dart';
import 'package:paint_color_assistant/sharing/exchange/exchange_outcome_endpoint.dart';
import 'package:paint_color_assistant/sharing/exchange/peer_transport.dart';
import 'package:paint_color_assistant/sharing/inactive_peer_transport.dart';
import 'package:paint_color_assistant/sharing/sharing_read_endpoint.dart';
import 'package:paint_color_assistant/sharing/sharing_scope.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

AppDependencies _deps({PersistentStore? store, PeerTransport? peerTransport}) =>
    AppDependencies(
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      store: store,
      peerTransport: peerTransport,
    );

SharingConsentReadEndpoint _endpoint(WidgetTester tester) =>
    tester.widget<SharingConsentReadEndpoint>(
      find.byKey(SharingConsentReadEndpoint.endpointKey),
    );

void main() {
  testWidgets(
      'buildApp mounts the SharingScope + consent read endpoint when a store '
      'is wired (CORE-2)', (tester) async {
    await tester.pumpWidget(buildApp(_deps(store: InMemoryPersistentStore())));

    // The SharingScope is present, holding the injected consent store.
    final scope = tester.widget<SharingScope>(find.byType(SharingScope));
    expect(scope.dependencies.consentStore, isNotNull);

    // The read endpoint the acceptance suite observes: a fresh install is not
    // opted in, is shown the frozen plain-language offer, and the one
    // user-facing sharing surface before opt-in is exactly that offer — which
    // names no mechanism (the invisibility guarantee, CORE-3 AC-1).
    final endpoint = tester.widget<SharingConsentReadEndpoint>(
      find.byKey(SharingConsentReadEndpoint.endpointKey),
    );
    expect(endpoint.consented, isFalse);
    expect(endpoint.offerCopy, 'help improve recipe accuracy by sharing anonymous mix results');
    expect(endpoint.userFacingSharingSurfaces, <String>[endpoint.offerCopy]);
  });

  testWidgets('buildApp mounts no SharingScope when no store is wired',
      (tester) async {
    await tester.pumpWidget(buildApp(_deps()));
    expect(find.byType(SharingScope), findsNothing);
    expect(find.byKey(SharingConsentReadEndpoint.endpointKey), findsNothing);
    // With no sharing scope mounted, the home-screen offer is inert.
    expect(find.byKey(SharingOptInOffer.offerKey), findsNothing);
  });

  testWidgets(
      'the home offer opts in once: tapping it records consent live and the '
      'offer is not shown again (CORE-3 AC-1)', (tester) async {
    // Inject the inert transport: opting in fires the background round, and the
    // real LocalNetworkTransport would start timer-based discovery here.
    await tester.pumpWidget(buildApp(_deps(
      store: InMemoryPersistentStore(),
      peerTransport: const InactivePeerTransport(),
    )));
    await tester.pumpAndSettle();

    // A fresh install is shown the offer and is not opted in.
    expect(_endpoint(tester).consented, isFalse);
    expect(find.byKey(SharingOptInOffer.offerKey), findsOneWidget);

    await tester.tap(find.byKey(SharingOptInOffer.offerKey));
    await tester.pumpAndSettle();

    // _SharingRoot re-read the store, so the endpoint now reads consented, the
    // surface inventory shows only the mechanism-free "recipes improve" signal
    // (CORE-4) and the one-time offer is gone.
    final after = _endpoint(tester);
    expect(after.consented, isTrue);
    expect(after.userFacingSharingSurfaces,
        <String>[SharingConsent.recipesImproveSignal]);
    expect(find.byKey(SharingOptInOffer.offerKey), findsNothing);
  });

  testWidgets(
      'buildApp loads an already-opted-in consent from the store at boot',
      (tester) async {
    final store = InMemoryPersistentStore();
    await PersistentConsentStore(store)
        .save(const SharingConsent(consented: true));

    await tester.pumpWidget(buildApp(_deps(
      store: store,
      peerTransport: const InactivePeerTransport(),
    )));
    await tester.pumpAndSettle();

    // _SharingRoot adopts the stored consent; the ongoing mechanism-free
    // "recipes improve" signal is the one surface shown (CORE-4).
    final endpoint = _endpoint(tester);
    expect(endpoint.consented, isTrue);
    expect(endpoint.userFacingSharingSurfaces,
        <String>[SharingConsent.recipesImproveSignal]);
    expect(find.byKey(SharingOptInOffer.offerKey), findsNothing);
  });

  testWidgets(
      'opting in runs a silent, fire-and-forget background exchange and mounts '
      'the outcome endpoint (CORE-4 AC-2)', (tester) async {
    final store = InMemoryPersistentStore();
    await PersistentConsentStore(store)
        .save(const SharingConsent(consented: true));

    await tester.pumpWidget(buildApp(_deps(
      store: store,
      peerTransport: const InactivePeerTransport(),
    )));
    await tester.pumpAndSettle();

    // The scheduler is wired into the sharing scope, so a core flow can reach
    // the exchange — and a round was fired when the opted-in consent was adopted
    // (settled is non-null only after a trigger).
    final scope = tester.widget<SharingScope>(find.byType(SharingScope));
    final scheduler = scope.dependencies.exchangeScheduler;
    expect(scheduler, isNotNull);
    expect(scheduler!.settled, isNotNull,
        reason: 'opting in fires one background round');

    // It is fire-and-forget (no core flow waited) and, over the injected inert
    // transport, reaches no peer — a silent no-op. (The shipped default is the
    // real LocalNetworkTransport, EXCHANGE-4; this test pins the inert one so it
    // stays deterministic.)
    expect(scheduler.outcome.waitedOnExchange, isFalse);
    expect(scheduler.outcome.exchanges, 0);

    // The outcome observation seam is mounted and reflects that zero / not-waited
    // state.
    final outcome = tester.widget<ExchangeOutcomeEndpoint>(
      find.byKey(ExchangeOutcomeEndpoint.endpointKey),
    );
    expect(outcome.waitedOnExchange, isFalse);
    expect(outcome.exchanges, 0);
  });

  testWidgets(
      'a fresh, not-opted-in install fires no background round (CORE-4)',
      (tester) async {
    await tester.pumpWidget(buildApp(_deps(store: InMemoryPersistentStore())));
    await tester.pumpAndSettle();

    // Not opted in ⇒ no exchange is started: the scheduler is wired but never
    // triggered (settled stays null), the control that shows the opt-in gate is
    // real.
    final scope = tester.widget<SharingScope>(find.byType(SharingScope));
    expect(scope.dependencies.exchangeScheduler, isNotNull);
    expect(scope.dependencies.exchangeScheduler!.settled, isNull,
        reason: 'no background round runs until the painter opts in');
  });

  testWidgets(
      '_SharingRoot drops a store load that completes after it is unmounted',
      (tester) async {
    // Boot with a store (starts the async consent load), then replace the tree
    // before settling so _SharingRoot unmounts with the load still in flight —
    // the load must early-return rather than setState on a dead element.
    await tester.pumpWidget(buildApp(_deps(store: InMemoryPersistentStore())));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    expect(find.byKey(SharingConsentReadEndpoint.endpointKey), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
