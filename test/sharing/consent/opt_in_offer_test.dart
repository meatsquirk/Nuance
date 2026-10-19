import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/consent/consent_store.dart';
import 'package:paint_color_assistant/sharing/consent/opt_in_offer.dart';
import 'package:paint_color_assistant/sharing/consent/sharing_consent.dart';
import 'package:paint_color_assistant/sharing/sharing_read_endpoint.dart';
import 'package:paint_color_assistant/sharing/sharing_scope.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

/// Mounts the offer under both sharing scopes carrying [consent], over [store].
Widget _underScopes(SharingConsent consent, ConsentStore store) => MaterialApp(
      home: SharingScope(
        dependencies: SharingDependencies(consentStore: store),
        child: SharingConsentReadEndpoint(
          consent: consent,
          child: const Scaffold(body: Center(child: SharingOptInOffer())),
        ),
      ),
    );

void main() {
  group('SharingOptInOffer', () {
    testWidgets('renders nothing outside a sharing-enabled tree (no scopes)',
        (tester) async {
      // Neither the read endpoint nor the scope is above it (a bare tree / a
      // build with no store) — the offer is inert.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SharingOptInOffer())),
      );
      expect(find.byKey(SharingOptInOffer.offerKey), findsNothing);
    });

    testWidgets('renders nothing when the consent endpoint is present but no '
        'SharingScope is mounted', (tester) async {
      // The read endpoint is above it but the scope (the consent store) is not,
      // so there is nothing to opt in through — inert.
      await tester.pumpWidget(
        const MaterialApp(
          home: SharingConsentReadEndpoint(
            consent: SharingConsent(),
            child: Scaffold(body: SharingOptInOffer()),
          ),
        ),
      );
      expect(find.byKey(SharingOptInOffer.offerKey), findsNothing);
    });

    testWidgets('shows the plain-language offer while the painter has not opted '
        'in', (tester) async {
      final store = PersistentConsentStore(InMemoryPersistentStore());
      await tester.pumpWidget(_underScopes(const SharingConsent(), store));

      // Present and labelled with the frozen outcome-only copy (names no
      // mechanism).
      expect(find.byKey(SharingOptInOffer.offerKey), findsOneWidget);
      expect(find.text(SharingConsent.defaultOfferCopy), findsOneWidget);
    });

    testWidgets('records consent through the store when tapped', (tester) async {
      final store = PersistentConsentStore(InMemoryPersistentStore());
      await tester.pumpWidget(_underScopes(const SharingConsent(), store));

      await tester.tap(find.byKey(SharingOptInOffer.offerKey));
      await tester.pumpAndSettle();

      // The opt-in action flips consent to opted-in through the same store
      // contract, leaving the offer copy unchanged.
      final saved = await store.load();
      expect(saved.consented, isTrue);
      expect(saved.offerCopy, SharingConsent.defaultOfferCopy);
    });

    testWidgets('renders nothing once the painter has opted in', (tester) async {
      final store = PersistentConsentStore(InMemoryPersistentStore());
      await tester.pumpWidget(
        _underScopes(const SharingConsent(consented: true), store),
      );
      // The one-time offer is never re-presented after opt-in.
      expect(find.byKey(SharingOptInOffer.offerKey), findsNothing);
    });
  });
}
