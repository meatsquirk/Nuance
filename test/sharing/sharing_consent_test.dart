import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/consent/sharing_consent.dart';

void main() {
  group('SharingConsent', () {
    test('defaults to not opted in with the standard offer copy', () {
      const consent = SharingConsent();
      expect(consent.consented, isFalse);
      expect(consent.offerCopy, SharingConsent.defaultOfferCopy);
    });

    test('the default offer copy is the spec wording verbatim (AC-1)', () {
      expect(
        SharingConsent.defaultOfferCopy,
        'help improve recipe accuracy by sharing anonymous mix results',
      );
    });

    test('the recipes-improve signal names an outcome, not a mechanism (AC-2)',
        () {
      final signal = SharingConsent.recipesImproveSignal.toLowerCase();
      // It is the "recipes improve over time" outcome wording the AC-2 test
      // recognises...
      expect(signal, contains('recipe'));
      expect(signal, contains('improve'));
      // ...and names no sharing mechanism (peers/devices/syncing/network/etc.).
      for (final concept in const <String>[
        'peer',
        'device',
        'sync',
        'network',
        'wi-fi',
        'wifi',
        'bluetooth',
        'nearby',
        'server',
        'upload',
        'download',
        'cloud',
      ]) {
        expect(signal, isNot(contains(concept)),
            reason: 'the opted-in signal must not name "$concept"');
      }
    });

    test('copyWith replaces only the fields it is given', () {
      const base = SharingConsent();

      expect(base.copyWith(consented: true).consented, isTrue);
      expect(base.copyWith(consented: true).offerCopy, base.offerCopy);
      expect(base.copyWith(offerCopy: 'other').offerCopy, 'other');
      expect(base.copyWith(offerCopy: 'other').consented, isFalse);
      // Neither given → an equal value.
      expect(base.copyWith(), base);
    });

    test('equality is by consented and offerCopy', () {
      const a = SharingConsent(consented: true);
      const b = SharingConsent(consented: true);
      const differentFlag = SharingConsent();
      const differentCopy = SharingConsent(consented: true, offerCopy: 'x');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(differentFlag));
      expect(a, isNot(differentCopy));
      // A non-SharingConsent compares unequal (the `other is` guard).
      final Object notConsent = 'not a consent';
      expect(a == notConsent, isFalse);
    });

    test('toString names both fields', () {
      const consent = SharingConsent(consented: true, offerCopy: 'copy');
      expect(consent.toString(), contains('consented: true'));
      expect(consent.toString(), contains('copy'));
    });
  });
}
