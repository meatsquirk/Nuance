import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/consent/consent_store.dart';
import 'package:paint_color_assistant/sharing/consent/sharing_consent.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

void main() {
  late InMemoryPersistentStore backing;
  late PersistentConsentStore store;

  setUp(() {
    backing = InMemoryPersistentStore();
    store = PersistentConsentStore(backing);
  });

  test('load returns the not-opted-in default when nothing is saved', () async {
    expect(await store.load(), const SharingConsent());
    expect((await store.load()).consented, isFalse);
  });

  test('a saved consent round-trips its flag and offer copy', () async {
    const consent = SharingConsent(consented: true, offerCopy: 'custom offer');

    await store.save(consent);

    expect(await store.load(), consent);
  });

  test('the stored body is the {consented, offerCopy} shape', () async {
    await store.save(const SharingConsent(consented: true));

    expect(
      await backing.get(
        PersistentConsentStore.collection,
        PersistentConsentStore.documentId,
      ),
      {
        'consented': true,
        'offerCopy': SharingConsent.defaultOfferCopy,
      },
    );
  });

  test('saving again replaces the one consent rather than adding another',
      () async {
    await store.save(const SharingConsent());
    await store.save(const SharingConsent(consented: true));

    expect((await store.load()).consented, isTrue);
    expect(
      (await backing.list(PersistentConsentStore.collection)).length,
      1,
    );
  });

  test('changes forwards the backing store notifications', () async {
    var fired = 0;
    void listener() => fired++;
    store.changes.addListener(listener);

    await store.save(const SharingConsent(consented: true));

    expect(fired, greaterThan(0));
    store.changes.removeListener(listener);
  });
}
