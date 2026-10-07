import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_read_endpoint.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';

SoftwareCaptureSource _captureSource() => SoftwareCaptureSource(
      const SceneSpec(
        groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
      ),
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
