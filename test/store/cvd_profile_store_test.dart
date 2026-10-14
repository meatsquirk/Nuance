import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/store/cvd_profile_store.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

void main() {
  late InMemoryPersistentStore backing;
  late CvdProfileStore store;

  setUp(() {
    backing = InMemoryPersistentStore();
    store = CvdProfileStore(backing);
  });

  test('load returns null when no profile has been saved', () async {
    expect(await store.load(), isNull);
  });

  test('count is zero when no profile has been saved', () async {
    expect(await store.count(), 0);
  });

  test('a saved profile round-trips its type and severity', () async {
    const profile = CvdProfile(type: CvdType.tritan, severity: 0.42);

    await store.save(profile);

    expect(await store.load(), profile);
    expect(await store.count(), 1);
  });

  test('the stored body is the {type, severity} shape (D-2)', () async {
    await store.save(const CvdProfile(type: CvdType.protan, severity: 0.75));

    expect(
      await backing.get(CvdProfileStore.collection, CvdProfileStore.documentId),
      {'type': 'protan', 'severity': 0.75},
    );
  });

  test('saving again replaces the one profile rather than adding another',
      () async {
    await store.save(const CvdProfile(type: CvdType.protan, severity: 0.3));
    await store.save(const CvdProfile(type: CvdType.deutan, severity: 0.9));

    expect(await store.load(), const CvdProfile(type: CvdType.deutan, severity: 0.9));
    expect(await store.count(), 1);
  });

  test('a whole-number severity deserializes back to a double', () async {
    // The default profile severity is 1; a JSON round-trip (the shipped
    // DriftPersistentStore) can hand it back as an int-valued num, so load
    // casts via num.toDouble() — asserted here so that path stays covered.
    await store.save(const CvdProfile(type: CvdType.deutan));

    expect(await store.load(), const CvdProfile(type: CvdType.deutan, severity: 1.0));
  });

  test('changes forwards the backing store notification (bs-10 AC-6)', () async {
    // The live-recompute listener (DALT-11) listens here; a save to this store —
    // or a direct write to the same backing store (the AC-6 harness path) —
    // fires it, so the app root can re-read the saved profile.
    var fired = 0;
    store.changes.addListener(() => fired++);

    await store.save(const CvdProfile(type: CvdType.protan));
    expect(fired, 1, reason: 'a save fires the forwarded change notification');

    await backing.delete(
        CvdProfileStore.collection, CvdProfileStore.documentId);
    expect(fired, 2,
        reason: 'a direct backing write fires the same forwarded signal');
  });
}
