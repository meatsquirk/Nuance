import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';

AppDependencies _deps() => const AppDependencies(
      colorScience: ColorScienceImpl(),
      speech: NoopSpeech(),
      haptics: NoopHaptics(),
    );

// A fresh, non-canonical instance each call (the `const` version above is
// canonicalised, so two calls return the same object).
AppDependencies _freshDeps() => AppDependencies(
      colorScience: ColorScienceImpl(),
      speech: NoopSpeech(),
      haptics: NoopHaptics(),
    );

void main() {
  group('AppDependencies', () {
    test('defaults the router to a const AppRouter', () {
      expect(_deps().router, isA<AppRouter>());
    });

    test('keeps an explicitly injected router', () {
      const router = AppRouter();
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        router: router,
      );
      expect(identical(deps.router, router), isTrue);
    });
  });

  group('buildApp', () {
    testWidgets('opens on the Readout route inside a MaterialApp',
        (tester) async {
      await tester.pumpWidget(buildApp(_deps()));
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Readout'), findsOneWidget);
    });

    testWidgets('injects the dependencies via AppScope', (tester) async {
      final deps = _deps();
      late AppDependencies seen;
      await tester.pumpWidget(
        buildApp(deps),
      );
      // Reach the scope from a descendant context below the MaterialApp.
      final context = tester.element(find.text('Readout'));
      seen = AppScope.of(context);
      expect(identical(seen, deps), isTrue);
    });
  });

  group('AppScope', () {
    testWidgets('of() returns the nearest scope dependencies', (tester) async {
      final deps = _deps();
      late AppDependencies seen;
      await tester.pumpWidget(
        AppScope(
          dependencies: deps,
          child: Builder(
            builder: (context) {
              seen = AppScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(identical(seen, deps), isTrue);
    });

    test('updateShouldNotify is true when dependencies change', () {
      final a = AppScope(dependencies: _freshDeps(), child: const SizedBox());
      final b = AppScope(dependencies: _freshDeps(), child: const SizedBox());
      // Distinct AppDependencies instances → notify.
      expect(a.updateShouldNotify(b), isTrue);
    });

    test('updateShouldNotify is false when dependencies are identical', () {
      final deps = _deps();
      final a = AppScope(dependencies: deps, child: const SizedBox());
      final b = AppScope(dependencies: deps, child: const SizedBox());
      expect(a.updateShouldNotify(b), isFalse);
    });
  });
}
