import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/consent/consent_store.dart';
import 'package:paint_color_assistant/sharing/sharing_scope.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

SharingDependencies _deps() => SharingDependencies(
      consentStore: PersistentConsentStore(InMemoryPersistentStore()),
    );

void main() {
  testWidgets('of() returns the dependencies exposed above a descendant',
      (tester) async {
    final deps = _deps();
    late SharingDependencies seen;
    await tester.pumpWidget(
      SharingScope(
        dependencies: deps,
        child: Builder(
          builder: (context) {
            seen = SharingScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(seen, deps), isTrue);
  });

  testWidgets('maybeOf returns the dependencies when present and null when absent',
      (tester) async {
    final deps = _deps();
    final seen = <SharingDependencies?>[];
    await tester.pumpWidget(
      SharingScope(
        dependencies: deps,
        child: Builder(
          builder: (context) {
            seen.add(SharingScope.maybeOf(context));
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen.add(SharingScope.maybeOf(context));
          return const SizedBox();
        },
      ),
    );
    expect(identical(seen[0], deps), isTrue);
    expect(seen[1], isNull);
  });

  test('updateShouldNotify tracks whether the dependencies changed', () {
    final shared = _deps();
    final a = SharingScope(dependencies: _deps(), child: const SizedBox());
    final b = SharingScope(dependencies: _deps(), child: const SizedBox());
    final c = SharingScope(dependencies: shared, child: const SizedBox());
    final d = SharingScope(dependencies: shared, child: const SizedBox());
    expect(a.updateShouldNotify(b), isTrue);
    expect(c.updateShouldNotify(d), isFalse);
  });
}
