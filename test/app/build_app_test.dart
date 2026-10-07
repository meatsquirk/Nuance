import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/compare/comparison_read_endpoint.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';

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

    test('defaults the initial sample to the demo sample', () {
      expect(_deps().initialSample, same(demoSample));
    });

    test('keeps an explicitly injected initial sample', () {
      const sample = Sample(
        name: 'Deep Olive Green',
        coordinates: ColorCoordinates(lightness: 40, a: -8, b: 24),
        provenance: Provenance(ProvenanceTier.measured),
      );
      const deps = AppDependencies(
        colorScience: ColorScienceImpl(),
        speech: NoopSpeech(),
        haptics: NoopHaptics(),
        initialSample: sample,
      );
      expect(deps.initialSample, same(sample));
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

    test('defaults the CVD profile to deutan (bs-03 D-4)', () {
      expect(_deps().cvdProfile, const CvdProfile(type: CvdType.deutan));
    });

    test('defaults the confusion check to the inert NoopConfusionCheck', () {
      expect(_deps().confusionCheck, isA<NoopConfusionCheck>());
    });

    test('keeps an explicitly injected CVD profile and confusion check', () {
      const profile = CvdProfile(type: CvdType.protan, severity: 0.6);
      const check = NoopConfusionCheck();
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        cvdProfile: profile,
        confusionCheck: check,
      );
      expect(deps.cvdProfile, same(profile));
      expect(identical(deps.confusionCheck, check), isTrue);
    });

    test('defaults the sample source to an empty in-memory catalogue (D-7)',
        () {
      expect(_deps().sampleSource, isA<InMemorySampleSource>());
      expect(_deps().sampleSource.savedSamples(), isEmpty);
    });

    test('defaults the comparison entry to null (opens on Readout — D-8)', () {
      expect(_deps().comparisonEntry, isNull);
    });

    test('keeps an explicitly injected sample source and comparison entry', () {
      const source = InMemorySampleSource();
      const entry = ComparisonEntry();
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        sampleSource: source,
        comparisonEntry: entry,
      );
      expect(identical(deps.sampleSource, source), isTrue);
      expect(identical(deps.comparisonEntry, entry), isTrue);
    });
  });

  group('buildApp', () {
    testWidgets('opens on the Readout screen inside a MaterialApp',
        (tester) async {
      await tester.pumpWidget(buildApp(_deps()));
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(ReadoutScreen), findsOneWidget);
      expect(find.text('Readout'), findsOneWidget);
    });

    testWidgets('opens the Readout on the injected initial sample',
        (tester) async {
      const sample = Sample(
        name: 'Deep Olive Green',
        coordinates: ColorCoordinates(lightness: 40, a: -8, b: 24),
        provenance: Provenance(ProvenanceTier.measured),
      );
      await tester.pumpWidget(
        buildApp(
          AppDependencies(
            colorScience: const ColorScienceImpl(),
            speech: const NoopSpeech(),
            haptics: const NoopHaptics(),
            initialSample: sample,
          ),
        ),
      );
      final screen = tester.widget<ReadoutScreen>(find.byType(ReadoutScreen));
      expect(screen.sample, same(sample));
      expect(find.text('Deep Olive Green'), findsOneWidget);
    });

    testWidgets('injects the dependencies via AppScope', (tester) async {
      final deps = _deps();
      late AppDependencies seen;
      await tester.pumpWidget(
        buildApp(deps),
      );
      // Reach the scope from a descendant context below the MaterialApp.
      final context = tester.element(find.byType(ReadoutScreen));
      seen = AppScope.of(context);
      expect(identical(seen, deps), isTrue);
    });

    testWidgets('opens on the Comparison screen when a comparison entry is set '
        '(D-8)', (tester) async {
      await tester.pumpWidget(
        buildApp(
          AppDependencies(
            colorScience: const ColorScienceImpl(),
            speech: const NoopSpeech(),
            haptics: const NoopHaptics(),
            comparisonEntry: const ComparisonEntry(),
          ),
        ),
      );
      expect(find.byType(ComparisonHomeScreen), findsOneWidget);
      expect(find.byType(ReadoutScreen), findsNothing);
      expect(find.text('Comparison'), findsOneWidget);
      // Empty catalogue, no pre-selected pair → both slots empty, no statement.
      expect(find.text('Slot A: (empty)'), findsOneWidget);
      expect(find.text('Slot B: (empty)'), findsOneWidget);
    });
  });

  group('ComparisonHomeScreen', () {
    const sampleA = Sample(
      name: 'Warm Terracotta',
      coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
      provenance: Provenance(ProvenanceTier.measured),
    );
    const sampleB = Sample(
      name: 'Raw Sienna Light',
      coordinates: ColorCoordinates(lightness: 70, a: 12.5, b: 21.65),
      provenance: Provenance(ProvenanceTier.measured),
    );

    testWidgets('renders a pre-placed slot A and an empty slot B',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ComparisonHomeScreen(initialA: sampleA)),
      );
      expect(find.text('Slot A: Warm Terracotta'), findsOneWidget);
      expect(find.text('Slot B: (empty)'), findsOneWidget);
    });

    testWidgets('renders a pre-placed slot B and an empty slot A',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ComparisonHomeScreen(initialB: sampleB)),
      );
      expect(find.text('Slot B: Raw Sienna Light'), findsOneWidget);
      expect(find.text('Slot A: (empty)'), findsOneWidget);
    });

    testWidgets('wraps its subtree in a ComparisonReadEndpoint for the suite',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ComparisonHomeScreen()),
      );
      expect(
        find.byKey(ComparisonReadEndpoint.endpointKey),
        findsOneWidget,
      );
      // Read from a descendant below the endpoint (the shell body's Scaffold).
      final context = tester.element(find.byType(Scaffold));
      final controller = ComparisonReadEndpoint.of(context);
      expect(controller.state.hasBothSlots, isFalse);
    });

    testWidgets('disposes its controller when removed from the tree',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ComparisonHomeScreen(initialA: sampleA)),
      );
      // Replace the screen so its State.dispose() runs without error.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(find.byType(ComparisonHomeScreen), findsNothing);
    });
  });

  group('ComparisonEntry', () {
    test('is a marker that opts into the comparison entry', () {
      // Constructed at runtime (non-const) so the constructor line is covered.
      // ignore: prefer_const_constructors
      expect(ComparisonEntry(), isA<ComparisonEntry>());
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
