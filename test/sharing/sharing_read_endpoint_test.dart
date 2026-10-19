import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/consent/sharing_consent.dart';
import 'package:paint_color_assistant/sharing/sharing_read_endpoint.dart';

void main() {
  testWidgets('exposes the consent fields and is observable from a descendant',
      (tester) async {
    late SharingConsentReadEndpoint seen;
    await tester.pumpWidget(
      const SharingConsentReadEndpoint(
        consent: SharingConsent(),
        child: _Probe(),
      ),
    );
    seen = tester.widget<SharingConsentReadEndpoint>(
      find.byType(SharingConsentReadEndpoint),
    );
    // The invisibility inventory is empty in the shell (names no network).
    expect(seen.consented, isFalse);
    expect(seen.offerCopy, SharingConsent.defaultOfferCopy);
    expect(seen.userFacingSharingSurfaces, isEmpty);
  });

  testWidgets('of() returns the endpoint and maybeOf is null when absent',
      (tester) async {
    final seenOf = <SharingConsentReadEndpoint>[];
    final seenMaybe = <SharingConsentReadEndpoint?>[];
    await tester.pumpWidget(
      SharingConsentReadEndpoint(
        consent: const SharingConsent(consented: true),
        child: Builder(
          builder: (context) {
            seenOf.add(SharingConsentReadEndpoint.of(context));
            seenMaybe.add(SharingConsentReadEndpoint.maybeOf(context));
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seenMaybe.add(SharingConsentReadEndpoint.maybeOf(context));
          return const SizedBox();
        },
      ),
    );
    expect(seenOf.single.consented, isTrue);
    expect(seenMaybe[0], isNotNull);
    expect(seenMaybe[1], isNull);
  });

  testWidgets('is findable by its stable endpoint key', (tester) async {
    await tester.pumpWidget(
      const SharingConsentReadEndpoint(
        key: SharingConsentReadEndpoint.endpointKey,
        consent: SharingConsent(),
        child: SizedBox(),
      ),
    );
    expect(find.byKey(SharingConsentReadEndpoint.endpointKey), findsOneWidget);
  });

  test('updateShouldNotify tracks the consent and the surface inventory', () {
    const a = SharingConsentReadEndpoint(
      consent: SharingConsent(),
      child: SizedBox(),
    );
    const sameAsA = SharingConsentReadEndpoint(
      consent: SharingConsent(),
      child: SizedBox(),
    );
    const consentChanged = SharingConsentReadEndpoint(
      consent: SharingConsent(consented: true),
      child: SizedBox(),
    );
    const surfacesChanged = SharingConsentReadEndpoint(
      consent: SharingConsent(),
      userFacingSharingSurfaces: ['recipes improve over time'],
      child: SizedBox(),
    );
    expect(a.updateShouldNotify(sameAsA), isFalse);
    expect(a.updateShouldNotify(consentChanged), isTrue);
    expect(a.updateShouldNotify(surfacesChanged), isTrue);
  });
}

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
