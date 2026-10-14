import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/repeatable_speech.dart';
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
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_read_endpoint.dart';
import 'package:paint_color_assistant/display/settings_screen.dart';
import 'package:paint_color_assistant/display/spoken_output_panel.dart';
import 'package:paint_color_assistant/compare/comparison_read_endpoint.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/onboarding/onboarding_read_endpoint.dart';
import 'package:paint_color_assistant/palette/palette_read_endpoint.dart';
import 'package:paint_color_assistant/palette/palette_screen.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_read_endpoint.dart';
import 'package:paint_color_assistant/projects/project_source.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/recipes/recipe_read_endpoint.dart';
import 'package:paint_color_assistant/store/cvd_profile_store.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';
import 'package:paint_color_assistant/store/source_photo_store.dart';

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

/// A [Speech] that records each utterance, so a test can observe that the
/// app-wide [RepeatableSpeech] delegates (and a repeat re-delegates) to the one
/// injected inner sink (bs-08 SPEECH-1).
class _RecordingSpeech implements Speech {
  final List<String> utterances = [];

  @override
  Future<void> speak(String utterance) async => utterances.add(utterance);
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

    test('defaults the project source to an empty in-memory catalogue (bs-06)',
        () {
      expect(_deps().projectSource, isA<InMemoryProjectSource>());
      expect(_deps().projectSource.projects(), isEmpty);
    });

    test('defaults the display controller to null (buildApp owns one — bs-08)',
        () {
      expect(_deps().displayController, isNull);
    });

    test('keeps an explicitly injected display controller', () {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        displayController: controller,
      );
      expect(identical(deps.displayController, controller), isTrue);
    });

    test('defaults the palette entry to null (opens on Readout — bs-06)', () {
      expect(_deps().paletteEntry, isNull);
    });

    test('keeps an explicitly injected project source and palette entry', () {
      const source = InMemoryProjectSource();
      const entry = PaletteEntry();
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        projectSource: source,
        paletteEntry: entry,
      );
      expect(identical(deps.projectSource, source), isTrue);
      expect(identical(deps.paletteEntry, entry), isTrue);
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

    testWidgets('injects the dependencies via AppScope, with the app-wide '
        'speech wrapped in a RepeatableSpeech (bs-08 SPEECH-1)', (tester) async {
      final deps = _deps();
      late AppDependencies seen;
      await tester.pumpWidget(
        buildApp(deps),
      );
      // Reach the scope from a descendant context below the MaterialApp.
      final context = tester.element(find.byType(ReadoutScreen));
      seen = AppScope.of(context);
      // The injected speech is wrapped so the readout speaks through the
      // repeatable seam, while every other service is the same injected one.
      expect(seen.speech, isA<RepeatableSpeech>());
      expect(identical((seen.speech as RepeatableSpeech).inner, deps.speech),
          isTrue);
      expect(identical(seen.colorScience, deps.colorScience), isTrue);
      expect(identical(seen.haptics, deps.haptics), isTrue);
      expect(identical(seen.router, deps.router), isTrue);
      expect(identical(seen.initialSample, deps.initialSample), isTrue);
    });

    testWidgets('AppScope.maybeOf returns the dependencies when present and '
        'null when absent (bs-10: standalone ColorChip fallback)',
        (tester) async {
      // Present: a descendant below buildApp's AppScope sees the deps.
      await tester.pumpWidget(buildApp(_deps()));
      final present = tester.element(find.byType(ReadoutScreen));
      expect(AppScope.maybeOf(present), isNotNull);
      expect(AppScope.maybeOf(present)!.speech, isA<RepeatableSpeech>());

      // Absent: no AppScope above the context → null (not an assertion throw,
      // unlike AppScope.of), so a standalone surface can fall back.
      AppDependencies? seen = _deps();
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            seen = AppScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );
      expect(seen, isNull);
    });

    testWidgets('reuses an already-repeatable injected speech as-is, and leaves '
        'its injector to own it (bs-08 SPEECH-1)', (tester) async {
      final repeatable = RepeatableSpeech(const NoopSpeech());
      addTearDown(repeatable.dispose);
      await tester.pumpWidget(
        buildApp(
          AppDependencies(
            colorScience: const ColorScienceImpl(),
            speech: repeatable,
            haptics: const NoopHaptics(),
          ),
        ),
      );
      final context = tester.element(find.byType(ReadoutScreen));
      // The same instance is provided (not double-wrapped).
      expect(identical(AppScope.of(context).speech, repeatable), isTrue);

      // buildApp does not dispose an injected speech — it is still usable after
      // the tree is torn down.
      await tester.pumpWidget(const SizedBox());
      repeatable.addListener(() {});
      expect(repeatable.canRepeat, isFalse);
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

    testWidgets(
        'sending a pair of marked readings opens the Comparison with both '
        'slots filled (AC-5)', (tester) async {
      await tester.pumpWidget(buildApp(_captureDeps(_captureSource())));
      await tester.pumpAndSettle(); // let the live feed buffer a frame

      final controller = tester
          .widget<CaptureReadEndpoint>(
            find.byKey(CaptureReadEndpoint.endpointKey),
          )
          .controller;

      // Mark and sample two points, then send them straight to a comparison.
      controller
        ..markPoint(2, 2)
        ..markPoint(6, 6)
        ..sampleMarkedPoints();
      controller.sendPairToComparison(0, 1);
      await tester.pumpAndSettle();

      // The pair handoff opens the real Comparison — not the Readout — with
      // both slots filled from the sent readings (bs-09 AC-5, D-9).
      expect(find.byType(ReadoutScreen), findsNothing,
          reason: 'the pair handoff opens the Comparison, not the Readout');
      final comparison = tester
          .widget<ComparisonReadEndpoint>(
            find.byKey(ComparisonReadEndpoint.endpointKey, skipOffstage: false),
          )
          .controller;
      expect(comparison.state.slotA, isNotNull, reason: 'slot A is filled');
      expect(comparison.state.slotB, isNotNull, reason: 'slot B is filled');
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

  group('buildApp display layer (bs-08)', () {
    testWidgets('mounts a DisplayReadEndpoint over a controller whose default '
        'simulation type is the painter\'s CVD type (D-2)', (tester) async {
      // _deps() carries the default deutan profile.
      await tester.pumpWidget(buildApp(_deps()));
      final endpoint = tester.widget<DisplayReadEndpoint>(
        find.byKey(DisplayReadEndpoint.endpointKey),
      );
      expect(endpoint.controller.defaultSimulationType, CvdType.deutan);
      // The shipped view: no simulation, no grayscale.
      expect(endpoint.settings.simulationOn, isFalse);
      expect(endpoint.settings.grayscale, isFalse);
    });

    testWidgets('derives the default simulation type from an injected profile',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          AppDependencies(
            colorScience: const ColorScienceImpl(),
            speech: const NoopSpeech(),
            haptics: const NoopHaptics(),
            cvdProfile: const CvdProfile(type: CvdType.tritan, severity: 0.5),
          ),
        ),
      );
      final endpoint = tester.widget<DisplayReadEndpoint>(
        find.byKey(DisplayReadEndpoint.endpointKey),
      );
      expect(endpoint.controller.defaultSimulationType, CvdType.tritan);
    });

    testWidgets('uses an injected display controller as-is', (tester) async {
      final controller = DisplayController(
        defaultSimulationType: CvdType.protan,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        buildApp(
          AppDependencies(
            colorScience: const ColorScienceImpl(),
            speech: const NoopSpeech(),
            haptics: const NoopHaptics(),
            displayController: controller,
          ),
        ),
      );
      final endpoint = tester.widget<DisplayReadEndpoint>(
        find.byKey(DisplayReadEndpoint.endpointKey),
      );
      expect(identical(endpoint.controller, controller), isTrue);
    });

    testWidgets('disposes the default controller it owns when torn down',
        (tester) async {
      await tester.pumpWidget(buildApp(_deps()));
      final controller = tester
          .widget<DisplayReadEndpoint>(
            find.byKey(DisplayReadEndpoint.endpointKey),
          )
          .controller;
      await tester.pumpWidget(const SizedBox());
      // A disposed ChangeNotifier throws if listened to again.
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    testWidgets('leaves an injected controller alive when torn down (its '
        'injector owns it)', (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        buildApp(
          AppDependencies(
            colorScience: const ColorScienceImpl(),
            speech: const NoopSpeech(),
            haptics: const NoopHaptics(),
            displayController: controller,
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      // Not disposed by buildApp: still usable (no throw).
      controller.addListener(() {});
      expect(controller.settings.simulationOn, isFalse);
    });
  });

  group('buildApp display chrome (bs-08 SETTINGS-1)', () {
    testWidgets('surfaces the open-settings entry (E2) on the home screen',
        (tester) async {
      await tester.pumpWidget(buildApp(_deps()));
      // The shared chrome wraps every route, so the entry is present over the
      // screen (here the Readout home).
      expect(find.byType(DisplayChrome), findsOneWidget);
      expect(find.byKey(DisplaySettingsButton.openKey), findsOneWidget);
      // The panel is not shown until the painter opens it.
      expect(find.byKey(DisplaySettingsScreen.panelKey), findsNothing);
    });

    testWidgets('opening the entry shows the settings panel over the current '
        'screen, closing returns to it', (tester) async {
      await tester.pumpWidget(buildApp(_deps()));
      expect(find.byType(ReadoutScreen), findsOneWidget);

      await tester.tap(find.byKey(DisplaySettingsButton.openKey));
      await tester.pumpAndSettle();
      // The panel is shown; the feature screen is still mounted underneath.
      expect(find.byKey(DisplaySettingsScreen.panelKey), findsOneWidget);
      expect(find.byType(ReadoutScreen), findsOneWidget);

      await tester.tap(find.byKey(DisplaySettingsScreen.closeKey));
      await tester.pumpAndSettle();
      expect(find.byKey(DisplaySettingsScreen.panelKey), findsNothing);
      expect(find.byType(ReadoutScreen), findsOneWidget);
    });

    testWidgets('the panel reads the app-wide controller — its controls drive '
        'the live display settings', (tester) async {
      await tester.pumpWidget(buildApp(_deps()));
      final controller = tester
          .widget<DisplayReadEndpoint>(
            find.byKey(DisplayReadEndpoint.endpointKey),
          )
          .controller;

      await tester.tap(find.byKey(DisplaySettingsButton.openKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(DisplaySettingsScreen.simulationOptionKey(CvdType.protan)),
      );
      await tester.pump();

      expect(controller.settings.simulationType, CvdType.protan);
    });
  });

  group('buildApp spoken-output chrome (bs-08 SPEECH-1)', () {
    testWidgets('surfaces the spoken-output panel (E50) on every screen, inert '
        'until something is spoken', (tester) async {
      await tester.pumpWidget(buildApp(_deps()));
      // The persistent panel is present over the screen from the start.
      expect(find.byKey(SpokenOutputPanel.panelKey), findsOneWidget);
      // Nothing spoken yet: no repeat control and no last-spoken text.
      expect(find.byKey(SpokenOutputPanel.repeatKey), findsNothing);
      expect(find.byKey(SpokenOutputPanel.lastSpokenKey), findsNothing);
    });

    testWidgets('speaking through the app-wide seam shows the panel, and the '
        'repeat control replays the exact utterance (AC-8)', (tester) async {
      final recorder = _RecordingSpeech();
      await tester.pumpWidget(
        buildApp(
          AppDependencies(
            colorScience: const ColorScienceImpl(),
            speech: recorder,
            haptics: const NoopHaptics(),
          ),
        ),
      );
      final context = tester.element(find.byType(ReadoutScreen));
      final speech = AppScope.of(context).speech as RepeatableSpeech;

      // A reading is spoken through the one injected seam (the readout's path).
      await speech.speak('Warm Terracotta, lightness 58');
      await tester.pump();
      expect(find.byKey(SpokenOutputPanel.repeatKey), findsOneWidget);
      expect(find.text('Warm Terracotta, lightness 58'), findsOneWidget);
      expect(recorder.utterances, ['Warm Terracotta, lightness 58']);

      // Repeating replays the same utterance through the same inner sink.
      await tester.tap(find.byKey(SpokenOutputPanel.repeatKey));
      await tester.pump();
      expect(recorder.utterances, [
        'Warm Terracotta, lightness 58',
        'Warm Terracotta, lightness 58',
      ]);
    });

    testWidgets('disposes the speech wrapper it owns when torn down',
        (tester) async {
      await tester.pumpWidget(buildApp(_deps()));
      final context = tester.element(find.byType(ReadoutScreen));
      final speech = AppScope.of(context).speech as RepeatableSpeech;
      await tester.pumpWidget(const SizedBox());
      // A disposed ChangeNotifier throws if listened to again.
      expect(() => speech.addListener(() {}), throwsFlutterError);
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

    test('defaults the persistence seams to null (no store wired, bs-06)', () {
      final deps = _deps();
      expect(deps.store, isNull);
      expect(deps.sourcePhotoStore, isNull);
    });

    test('carries an injected persistent store and source-photo sink', () {
      final store = InMemoryPersistentStore();
      final photos = InMemorySourcePhotoStore();
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        store: store,
        sourcePhotoStore: photos,
      );
      expect(deps.store, same(store));
      expect(deps.sourcePhotoStore, same(photos));
    });
  });

  group('PaletteEntry', () {
    test('is a plain opt-in marker', () {
      // Non-const so the const constructor line is covered.
      // ignore: prefer_const_constructors
      expect(PaletteEntry(), isA<PaletteEntry>());
    });
  });

  group('AppDependencies.withCvdProfile (bs-07 AC-13, D-3)', () {
    test('replaces only the CVD profile, keeping every other service', () {
      final store = InMemoryPersistentStore();
      final photos = InMemorySourcePhotoStore();
      final source = _captureSource();
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        captureSource: source,
        cvdProfile: const CvdProfile(type: CvdType.deutan),
        store: store,
        sourcePhotoStore: photos,
      );

      const measured = CvdProfile(type: CvdType.protan, severity: 0.6);
      final next = deps.withCvdProfile(measured);

      // Only the profile changed…
      expect(next.cvdProfile, measured);
      // …every other injected service is carried over unchanged.
      expect(identical(next.colorScience, deps.colorScience), isTrue);
      expect(identical(next.speech, deps.speech), isTrue);
      expect(identical(next.haptics, deps.haptics), isTrue);
      expect(identical(next.captureSource, source), isTrue);
      expect(identical(next.confusionCheck, deps.confusionCheck), isTrue);
      expect(identical(next.store, store), isTrue);
      expect(identical(next.sourcePhotoStore, photos), isTrue);
    });
  });

  group('LiveProfileScope (bs-07 AC-13, D-3)', () {
    testWidgets('of() returns the enclosing scope\'s save callback',
        (tester) async {
      void onSaved(CvdProfile _) {}
      ValueChanged<CvdProfile>? seen;
      await tester.pumpWidget(
        LiveProfileScope(
          onProfileSaved: onSaved,
          child: Builder(
            builder: (context) {
              seen = LiveProfileScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, same(onSaved));
    });

    testWidgets('of() returns null when no scope is mounted', (tester) async {
      ValueChanged<CvdProfile>? seen = (_) {};
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            seen = LiveProfileScope.of(context);
            return const SizedBox();
          },
        ),
      );
      expect(seen, isNull);
    });

    test('updateShouldNotify tracks the callback identity', () {
      void a(CvdProfile _) {}
      void b(CvdProfile _) {}
      final scopeA = LiveProfileScope(onProfileSaved: a, child: const SizedBox());
      final scopeB = LiveProfileScope(onProfileSaved: b, child: const SizedBox());
      final scopeA2 =
          LiveProfileScope(onProfileSaved: a, child: const SizedBox());
      expect(scopeA.updateShouldNotify(scopeB), isTrue);
      expect(scopeA.updateShouldNotify(scopeA2), isFalse);
    });
  });

  group('buildApp live profile (bs-07 AC-13, D-3)', () {
    testWidgets(
        'a saved assessment reconfigures the live AppDependencies.cvdProfile',
        (tester) async {
      final store = InMemoryPersistentStore();
      const injected = CvdProfile(type: CvdType.deutan); // severity 1.0
      final deps = AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        cvdProfile: injected,
        store: store,
      );
      await tester.pumpWidget(buildApp(deps));
      await tester.pumpAndSettle();

      CvdProfile live() => tester
          .widget<AppScope>(find.byType(AppScope))
          .dependencies
          .cvdProfile;
      // Before any save the live profile is the injected default. The startup
      // tree injects the deps unchanged except for bs-08's one-time speech wrap
      // (a RepeatableSpeech over the injected sink, SPEECH-1); crucially no
      // withCvdProfile copy has happened yet, so the live cvdProfile is the
      // exact injected object (bs-07 AC-13 — no reconfiguration until a save).
      expect(live(), injected);
      final readoutContext = tester.element(find.byType(ReadoutScreen));
      final startup = AppScope.of(readoutContext);
      expect(identical(startup.cvdProfile, injected), isTrue);
      expect(startup.speech, isA<RepeatableSpeech>());
      expect(identical((startup.speech as RepeatableSpeech).inner, deps.speech),
          isTrue);

      // Reach the self-assessment the production way and drive it to a saved
      // result through the controller (the UI flow is the acceptance suite's; a
      // unit test only needs the save to fire the live reconfiguration).
      final navigator =
          tester.firstState<NavigatorState>(find.byType(Navigator));
      unawaited(navigator.push<void>(deps.router.toSelfAssessment()));
      await tester.pumpAndSettle();
      final controller = tester
          .widget<OnboardingReadEndpoint>(
            find.byKey(OnboardingReadEndpoint.endpointKey),
          )
          .controller;
      controller.reportDiagnosis(CvdType.protan);
      controller.advanceToResult();
      await controller.save();
      await tester.pumpAndSettle();

      // The root re-injected the measured profile on the one seam every CVD
      // consumer reads — off the default deutan.
      final saved = await CvdProfileStore(store).load();
      expect(saved, isNotNull);
      expect(live(), saved, reason: 'the live cvdProfile equals the saved one');
      expect(live(), isNot(injected),
          reason: 'the pipeline moved off the injected default');
    });
  });

  group('buildApp live profile store listener (bs-10 AC-6, DALT-11)', () {
    CvdProfile liveProfile(WidgetTester tester) => tester
        .widget<AppScope>(find.byType(AppScope))
        .dependencies
        .cvdProfile;

    AppDependencies depsOver(InMemoryPersistentStore store,
            {CvdProfile injected = const CvdProfile(type: CvdType.deutan)}) =>
        AppDependencies(
          colorScience: const ColorScienceImpl(),
          speech: const NoopSpeech(),
          haptics: const NoopHaptics(),
          cvdProfile: injected,
          store: store,
        );

    testWidgets(
        'a profile written straight to the store (not via the onboarding '
        'callback) recomputes the live cvdProfile', (tester) async {
      final store = InMemoryPersistentStore();
      const injected = CvdProfile(type: CvdType.deutan); // severity 1.0
      await tester.pumpWidget(buildApp(depsOver(store, injected: injected)));
      await tester.pumpAndSettle();
      expect(liveProfile(tester), injected);

      // The AC-6 acceptance path: a save written straight to the store the app
      // listens to, bypassing [LiveProfileScope]'s onProfileSaved callback.
      const protan = CvdProfile(type: CvdType.protan, severity: 0.6);
      await CvdProfileStore(store).save(protan);
      await tester.pumpAndSettle();
      expect(liveProfile(tester), protan,
          reason: 'the root re-read the saved profile off the store change');

      // Clearing the store re-reads to the injected default (the null-load
      // fallback) — so a cleared profile stops applying a stale remap.
      await store.delete(
          CvdProfileStore.collection, CvdProfileStore.documentId);
      await tester.pumpAndSettle();
      expect(liveProfile(tester), injected,
          reason: 'a cleared store falls back to the injected default');
    });

    testWidgets('a store change to the same profile leaves the live one intact',
        (tester) async {
      final store = InMemoryPersistentStore();
      const injected = CvdProfile(type: CvdType.deutan);
      await tester.pumpWidget(buildApp(depsOver(store, injected: injected)));
      await tester.pumpAndSettle();
      final before = liveProfile(tester);

      // Saving the same profile fires the store notifier but re-reads to an
      // equal value, so the root takes no new copy (the deps object is unchanged).
      await CvdProfileStore(store).save(injected);
      await tester.pumpAndSettle();
      expect(identical(liveProfile(tester), before), isTrue,
          reason: 'an equal saved profile leaves the injected deps untouched');
    });

    testWidgets(
        'an in-flight re-read after the app is torn down is a safe no-op',
        (tester) async {
      final store = InMemoryPersistentStore();
      await tester.pumpWidget(buildApp(depsOver(store)));
      await tester.pumpAndSettle();

      // The store notifies synchronously, so the re-read's load() is already in
      // flight when the tree is replaced; its completion must find the state
      // unmounted and return without calling setState.
      unawaited(
          CvdProfileStore(store).save(const CvdProfile(type: CvdType.protan)));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
      expect(find.byType(AppScope), findsNothing);
      // No "setState after dispose" exception was thrown tearing the tree down.
    });
  });

  group('PaletteHomeScreen', () {
    AppDependencies paletteDeps({
      PaletteSource paletteSource = const InMemoryPaletteSource(),
      ProjectSource projectSource = const InMemoryProjectSource(),
    }) =>
        AppDependencies(
          colorScience: const ColorScienceImpl(),
          speech: const NoopSpeech(),
          haptics: const NoopHaptics(),
          paletteEntry: const PaletteEntry(),
          paletteSource: paletteSource,
          projectSource: projectSource,
        );

    testWidgets('buildApp opens on the Palette screen when an entry is set',
        (tester) async {
      await tester.pumpWidget(buildApp(paletteDeps()));
      expect(find.byType(PaletteHomeScreen), findsOneWidget);
      expect(find.byType(PaletteScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Palette'), findsOneWidget);
    });

    testWidgets('wraps its subtree in both read endpoints for the suite',
        (tester) async {
      await tester.pumpWidget(buildApp(paletteDeps()));
      expect(find.byKey(PaletteReadEndpoint.endpointKey), findsOneWidget);
      expect(find.byKey(ProjectReadEndpoint.endpointKey), findsOneWidget);
    });

    testWidgets('builds its controllers over the injected sources',
        (tester) async {
      final palettes = InMemoryPaletteSource(
        catalogue: const [PaintPalette(name: 'My paints')],
      );
      final projects = InMemoryProjectSource(
        catalogue: const [Project(id: 'p1', name: 'Harbor at Dusk')],
      );
      await tester.pumpWidget(
        buildApp(paletteDeps(paletteSource: palettes, projectSource: projects)),
      );
      final context = tester.element(find.byType(PaletteScreen));
      expect(PaletteReadEndpoint.of(context).palettes, hasLength(1));
      expect(ProjectReadEndpoint.of(context).projects, hasLength(1));
    });

    testWidgets('mounts a RecipeReadEndpoint sharing the selected palette (AC-5)',
        (tester) async {
      final palettes = InMemoryPaletteSource(
        catalogue: const [
          PaintPalette(name: 'My paints'),
          PaintPalette(name: 'Travel set'),
        ],
      );
      await tester.pumpWidget(buildApp(paletteDeps(paletteSource: palettes)));
      final context = tester.element(find.byType(PaletteScreen));
      expect(find.byKey(RecipeReadEndpoint.endpointKey), findsOneWidget);
      // Recipe search opens constrained to the first listed palette (D-5) — the
      // same one the PaletteController makes active.
      expect(
        RecipeReadEndpoint.of(context).state.selectedPalette?.name,
        'My paints',
      );
    });

    testWidgets('selecting a palette re-points the shared RecipeController (AC-5)',
        (tester) async {
      final palettes = InMemoryPaletteSource(
        catalogue: const [
          PaintPalette(name: 'My paints'),
          PaintPalette(name: 'Travel set'),
        ],
      );
      await tester.pumpWidget(buildApp(paletteDeps(paletteSource: palettes)));
      final context = tester.element(find.byType(PaletteScreen));
      final paletteController = PaletteReadEndpoint.of(context);

      // Selecting the second palette on the Palette screen must re-solve recipes
      // against it — the bs-06 → bs-04 wiring (onPaletteSelected → selectPalette).
      paletteController.selectPalette(paletteController.palettes[1]);
      await tester.pump();

      expect(
        RecipeReadEndpoint.of(context).state.selectedPalette?.name,
        'Travel set',
      );
    });

    testWidgets('disposes its controllers when removed from the tree',
        (tester) async {
      await tester.pumpWidget(buildApp(paletteDeps()));
      expect(find.byType(PaletteHomeScreen), findsOneWidget);
      // Replacing the tree tears the home screen down; a leaked ChangeNotifier
      // (palette, project or the shared recipe controller) would trip the
      // flutter_test dispose-guard.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(find.byType(PaletteHomeScreen), findsNothing);
    });
  });

  group('loadCvdProfile (bs-07 D-3/G-4)', () {
    test('returns the saved profile when one is stored', () async {
      final store = CvdProfileStore(InMemoryPersistentStore());
      const saved = CvdProfile(type: CvdType.protan, severity: 0.6);
      await store.save(saved);

      expect(await loadCvdProfile(store), saved);
    });

    test('falls back to the deutan default when none is stored', () async {
      final store = CvdProfileStore(InMemoryPersistentStore());

      expect(await loadCvdProfile(store), const CvdProfile(type: CvdType.deutan));
    });
  });
}
