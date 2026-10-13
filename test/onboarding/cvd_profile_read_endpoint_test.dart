import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/cvd_profile_read_endpoint.dart';
import 'package:paint_color_assistant/store/cvd_profile_store.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

CvdProfileStore _store() => CvdProfileStore(InMemoryPersistentStore());

void main() {
  testWidgets('of() returns the store exposed above a descendant',
      (tester) async {
    final store = _store();
    late CvdProfileStore seen;
    await tester.pumpWidget(
      CvdProfileReadEndpoint(
        store: store,
        child: Builder(
          builder: (context) {
            seen = CvdProfileReadEndpoint.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(seen, store), isTrue);
  });

  testWidgets('is findable by its stable endpoint key', (tester) async {
    await tester.pumpWidget(
      CvdProfileReadEndpoint(
        key: CvdProfileReadEndpoint.endpointKey,
        store: _store(),
        child: const SizedBox(),
      ),
    );
    expect(find.byKey(CvdProfileReadEndpoint.endpointKey), findsOneWidget);
  });

  test('updateShouldNotify tracks whether the store changed', () {
    final a = CvdProfileReadEndpoint(store: _store(), child: const SizedBox());
    final b = CvdProfileReadEndpoint(store: _store(), child: const SizedBox());
    final shared = _store();
    final c = CvdProfileReadEndpoint(store: shared, child: const SizedBox());
    final d = CvdProfileReadEndpoint(store: shared, child: const SizedBox());
    expect(a.updateShouldNotify(b), isTrue);
    expect(c.updateShouldNotify(d), isFalse);
  });
}
