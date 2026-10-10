import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_read_endpoint.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/correction/correction_read_endpoint.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine_impl.dart';
import 'package:paint_color_assistant/compare/comparison_read_endpoint.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/recipes/recipe_read_endpoint.dart';

const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
);
const _mix = Recipe(
  medium: PaintMedium.acrylic,
  components: [RecipeComponent(paint: _white, partsFraction: 1)],
  predictedColor: ColorCoordinates(lightness: 96, a: 0, b: 2),
  deltaE00: 1.2,
);

SoftwareCaptureSource _captureSource() => SoftwareCaptureSource(
      const SceneSpec(
        groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
      ),
    );

/// Deps that open the Correction loop: a correction entry plus a fake capture
/// source for its camera (the entry wins over the capture source in `buildApp`).
AppDependencies _correctionDeps() => AppDependencies(
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      captureSource: _captureSource(),
      correctionEntry: const CorrectionEntry(target: _olive, currentMix: _mix),
    );

AppDependencies _captureDeps(SoftwareCaptureSource source) => AppDependencies(
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      captureSource: source,
    );

/// A [Haptics] that counts the confirmation pulses, so a test can observe the
/// capture → Readout → confirm handoff (bs-01 AC-12).
class _RecordingHaptics implements Haptics {
  int confirmations = 0;

  @override
  Future<void> confirm() async => confirmations++;
}

AppDependencies _captureDepsWith(
  SoftwareCaptureSource source,
  Haptics haptics,
) =>
    AppDependencies(
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: haptics,
      captureSource: source,
    );

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

    test('defaults the capture source to null (bs-01 opens on the Readout)',
        () {
      expect(_deps().captureSource, isNull);
    });

    test('keeps an explicitly injected capture source', () {
      final source = _captureSource();
      expect(_captureDeps(source).captureSource, same(source));
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

    test('defaults the confusion check to the shipped DichromatConfusionCheck '
        '(CVD-2)', () {
      expect(_deps().confusionCheck, isA<DichromatConfusionCheck>());
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

    test('defaults the mixing engine to the v1 SubtractiveMixingEngine (D-2)',
        () {
      expect(_deps().mixingEngine, isA<SubtractiveMixingEngine>());
    });

    test('keeps an explicitly injected mixing engine', () {
      const engine = SubtractiveMixingEngine();
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        mixingEngine: engine,
      );
      expect(identical(deps.mixingEngine, engine), isTrue);
      expect(deps.mixingEngine, isA<MixingEngine>());
    });

    test(
        'defaults the correction engine to the stub SubtractiveCorrectionEngine '
        '(D-2/D-3)', () {
      expect(_deps().correctionEngine, isA<SubtractiveCorrectionEngine>());
    });

    test('keeps an explicitly injected correction engine', () {
      const engine = SubtractiveCorrectionEngine();
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        correctionEngine: engine,
      );
      expect(identical(deps.correctionEngine, engine), isTrue);
      expect(deps.correctionEngine, isA<CorrectionEngine>());
    });

    test('defaults the palette source to an empty in-memory catalogue (D-5)',
        () {
      expect(_deps().paletteSource, isA<InMemoryPaletteSource>());
      expect(_deps().paletteSource.palettes(), isEmpty);
    });

    test('defaults the recipes entry to null (opens on Readout — D-6)', () {
      expect(_deps().recipesEntry, isNull);
    });

    test('keeps an explicitly injected palette source and recipes entry', () {
      const source = InMemoryPaletteSource();
      const entry = RecipesEntry(target: _olive);
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        paletteSource: source,
        recipesEntry: entry,
      );
      expect(identical(deps.paletteSource, source), isTrue);
      expect(identical(deps.recipesEntry, entry), isTrue);
    });

    test('defaults the correction entry to null (opens on Readout — D-2)', () {
      expect(_deps().correctionEntry, isNull);
    });

    test('keeps an explicitly injected correction entry', () {
      const entry = CorrectionEntry(target: _olive, currentMix: _mix);
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        correctionEntry: entry,
      );
      expect(identical(deps.correctionEntry, entry), isTrue);
      expect(deps.correctionEntry!.target, _olive);
      expect(deps.correctionEntry!.currentMix, _mix);
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

    testWidgets('opens on the Capture screen when a capture source is wired',
        (tester) async {
      final source = _captureSource();
      await tester.pumpWidget(buildApp(_captureDeps(source)));

      // The Capture screen, not the Readout, is shown.
      expect(find.byType(CaptureHomeScreen), findsOneWidget);
      expect(find.byType(ReadoutScreen), findsNothing);
      expect(find.widgetWithText(AppBar, 'Capture'), findsOneWidget);
    });

    testWidgets(
        'the Capture screen exposes a read endpoint over the injected source',
        (tester) async {
      final source = _captureSource();
      await tester.pumpWidget(buildApp(_captureDeps(source)));

      final endpoint = tester.widget<CaptureReadEndpoint>(
        find.byKey(CaptureReadEndpoint.endpointKey),
      );
      // The controller reads from the injected source and the screen opens at
      // "SETTLING 0/12" — the reading begins settling on the first rendered
      // frame (CAPTURE-3), so the open state is asserted on the live view.
      expect(identical(endpoint.controller.source, source), isTrue);
      expect(find.text('SETTLING 0/12'), findsOneWidget);
    });

    testWidgets('disposes the capture controller when the screen is torn down',
        (tester) async {
      await tester.pumpWidget(buildApp(_captureDeps(_captureSource())));
      final controller = tester
          .widget<CaptureReadEndpoint>(
            find.byKey(CaptureReadEndpoint.endpointKey),
          )
          .controller;

      // Replacing the whole app tears the Capture screen down → dispose runs.
      await tester.pumpWidget(const SizedBox());

      // A disposed ChangeNotifier throws if listened to again.
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    testWidgets('a commit opens the captured reading\'s Readout and confirms',
        (tester) async {
      final haptics = _RecordingHaptics();
      await tester.pumpWidget(
        buildApp(_captureDepsWith(_captureSource(), haptics)),
      );
      // The live feed samples a reading on open; capturing commits it.
      expect(haptics.confirmations, 0);

      await tester.tap(find.byKey(CaptureControls.captureKey));
      await tester.pumpAndSettle();

      // The commit navigates to bs-01's Readout for the captured sample (D-5),
      // where the just-captured marker fires exactly one confirmation haptic.
      expect(find.byType(ReadoutScreen), findsOneWidget,
          reason: 'the commit opens the Readout');
      expect(find.widgetWithText(AppBar, 'Readout'), findsOneWidget);
      expect(haptics.confirmations, 1,
          reason: 'the just-captured reading confirms with one haptic (AC-12)');
    });

    testWidgets('a low-light commit keeps the painter on the Capture screen',
        (tester) async {
      final haptics = _RecordingHaptics();
      final source = SoftwareCaptureSource(
        const SceneSpec(
          groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
          lighting: Lighting.low,
        ),
      );
      await tester.pumpWidget(buildApp(_captureDepsWith(source, haptics)));

      await tester.tap(find.byKey(CaptureControls.captureKey));
      await tester.pumpAndSettle();

      // A low-light commit lands a sample but does not open the Readout: the
      // painter stays on Capture to dismiss the warning and continue capturing
      // at the lower accuracy (AC-6/AC-7). No reading lands, so no haptic fires.
      expect(find.byType(ReadoutScreen), findsNothing,
          reason: 'a low-light commit stays on the Capture screen');
      expect(find.byType(CaptureHomeScreen), findsOneWidget);
      expect(haptics.confirmations, 0);
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

    testWidgets('opens on the Recipes screen when a recipes entry is set (D-6)',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          const AppDependencies(
            colorScience: ColorScienceImpl(),
            speech: NoopSpeech(),
            haptics: NoopHaptics(),
            recipesEntry: RecipesEntry(target: _olive),
          ),
        ),
      );
      expect(find.byType(RecipesHomeScreen), findsOneWidget);
      expect(find.byType(ReadoutScreen), findsNothing);
      expect(find.text('Recipes'), findsOneWidget);
      expect(find.text('Recipe target: Deep Olive Green'), findsOneWidget);
    });

    testWidgets(
        'opens on the Correction screen when a correction entry is set, '
        'winning over the capture source (D-2)', (tester) async {
      await tester.pumpWidget(buildApp(_correctionDeps()));

      // The correction entry is checked before the capture source, so the loop
      // opens on the Correction screen and reuses the source as its camera.
      expect(find.byType(CorrectionHomeScreen), findsOneWidget);
      expect(find.byType(CaptureHomeScreen), findsNothing);
      expect(find.byType(ReadoutScreen), findsNothing);
      expect(find.widgetWithText(AppBar, 'Correction'), findsOneWidget);
      expect(find.text('Correction target: Deep Olive Green'), findsOneWidget);
    });
  });

  group('RecipesHomeScreen', () {
    testWidgets('renders the named mixing target under a Recipes app bar',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RecipesHomeScreen(target: _olive)),
      );
      expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
      expect(find.text('Recipe target: Deep Olive Green'), findsOneWidget);
    });

    testWidgets('falls back to (unnamed) for a target with no name',
        (tester) async {
      const unnamed = Sample(
        coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
        provenance: Provenance(ProvenanceTier.measured),
      );
      await tester.pumpWidget(
        const MaterialApp(home: RecipesHomeScreen(target: unnamed)),
      );
      expect(find.text('Recipe target: (unnamed)'), findsOneWidget);
    });

    testWidgets('wraps its subtree in a RecipeReadEndpoint over the target',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RecipesHomeScreen(target: _olive)),
      );
      expect(find.byKey(RecipeReadEndpoint.endpointKey), findsOneWidget);
      final context = tester.element(find.byType(Scaffold));
      final controller = RecipeReadEndpoint.of(context);
      expect(controller.state.target, _olive);
      expect(controller.state.recipes, isEmpty);
    });

    testWidgets('disposes its controller when removed from the tree',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RecipesHomeScreen(target: _olive)),
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(find.byType(RecipesHomeScreen), findsNothing);
    });
  });

  group('RecipesEntry', () {
    test('carries the mixing target', () {
      // Constructed at runtime (non-const) so the constructor line is covered.
      // ignore: prefer_const_constructors
      final entry = RecipesEntry(target: _olive);
      expect(entry.target, _olive);
    });
  });

  group('CorrectionEntry', () {
    test('carries the target and the current mix', () {
      // Constructed at runtime (non-const) so the constructor line is covered.
      // ignore: prefer_const_constructors
      final entry = CorrectionEntry(target: _olive, currentMix: _mix);
      expect(entry.target, _olive);
      expect(entry.currentMix, _mix);
    });
  });

  group('CorrectionHomeScreen', () {
    Widget home({Sample target = _olive}) => MaterialApp(
          home: CorrectionHomeScreen(
            target: target,
            currentMix: _mix,
            captureSource: _captureSource(),
          ),
        );

    testWidgets('renders the named target under a Correction app bar',
        (tester) async {
      await tester.pumpWidget(home());
      expect(find.widgetWithText(AppBar, 'Correction'), findsOneWidget);
      expect(find.text('Correction target: Deep Olive Green'), findsOneWidget);
    });

    testWidgets('falls back to (unnamed) for a target with no name',
        (tester) async {
      const unnamed = Sample(
        coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
        provenance: Provenance(ProvenanceTier.measured),
      );
      await tester.pumpWidget(home(target: unnamed));
      expect(find.text('Correction target: (unnamed)'), findsOneWidget);
    });

    testWidgets('wraps its subtree in a CorrectionReadEndpoint over the mix',
        (tester) async {
      await tester.pumpWidget(home());
      expect(find.byKey(CorrectionReadEndpoint.endpointKey), findsOneWidget);
      final context = tester.element(find.byType(Scaffold));
      final controller = CorrectionReadEndpoint.of(context);
      expect(controller.state.target, _olive);
      expect(controller.state.currentMix, _mix);
      expect(controller.state.hasChecked, isFalse);
    });

    testWidgets('disposes its controller when removed from the tree',
        (tester) async {
      await tester.pumpWidget(home());
      final controller = tester
          .widget<CorrectionReadEndpoint>(
            find.byKey(CorrectionReadEndpoint.endpointKey),
          )
          .controller;
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(find.byType(CorrectionHomeScreen), findsNothing);
      // A disposed ChangeNotifier throws if listened to again.
      expect(() => controller.addListener(() {}), throwsFlutterError);
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
