// Acceptance suite for bs-09 Advanced capture.
//
// CAPTURE-1 (scaffold) seeded the pending gate (`bs09/pending.dart`, all 10 ACs
// pending, each mapped to the behaviour phase that un-pends it). ITEST-1 adds
// the bs-09 harness (`advanced_capture_harness.dart`: the Given/When/Then
// vocabulary over bs-02's `CaptureHarness` + the bs-09 fixtures) and here:
//   * scaffold guards over the pending gate (so it cannot pass vacuously);
//   * fixture guards over `SCENE_THREE_POINTS` (its three points sampled through
//     bs-02's real `sampleAreaAverage` are mutually distinct and distinct from
//     the field) and over the capability / platform scenes (through the real
//     `SoftwareCaptureSource` getters), so the fixtures the AC tests lean on are
//     themselves checked; and
//   * a never-pending smoke test proving SCREEN-1's shells wire end to end — the
//     assembled app opens on Capture with the torch / sample-points /
//     send-to-comparison controls present, the readings region empty, and no
//     torch-warning banner (AC-1's `torchOn == false` precondition).
// ITEST-2/3 register one *pending* `acTestWidgets` per AC; the behaviour phases
// un-pend each by deleting its row in `bs09/pending.dart`.
//
// Default `flutter test integration_test/advanced_capture_test.dart -d <udid>`
// skips pending ACs; `--dart-define=BS09_RUN_PENDING=true` runs them (red
// baseline / un-pend run). A booted device udid is mandatory — without `-d` the
// run executes zero tests and still exits 0 (false green; carried flake).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_readings_list.dart';

import 'advanced_capture_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('bs-09 pending gate (scaffold guard)', () {
    test('pending map covers exactly AC-1..AC-10', () {
      final expected = {for (var i = 1; i <= 10; i++) 'AC-$i'};
      expect(pendingACs.keys.toSet(), expected);
    });

    test('every pending AC is owned by a real behaviour phase', () {
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} owner "${entry.value}" is not a bs-09 '
              'behaviour phase',
        );
      }
    });

    test('pendingSkipReason skips a pending AC by default, runs it when forced',
        () {
      expect(pendingSkipReason('AC-1'), isNotNull);
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
      // An AC absent from the map (un-pended) always runs.
      expect(pendingSkipReason('AC-999'), isNull);
    });
  });

  group('bs-09 harness fixtures (ITEST-1 guard)', () {
    // The multi-point fixture the AC-3/AC-4/AC-5 tests lean on must offer three
    // points that sample to mutually distinct colours (and not the field), or
    // those tests could pass without keeping per-point values apart. Checked
    // through bs-02's real sampling maths — never faked.

    test('SCENE_THREE_POINTS declares three points and three expected colours',
        () {
      expect(SCENE_THREE_POINTS.points, hasLength(3));
      expect(SCENE_THREE_POINTS.colorsAtPoints, hasLength(3));
    });

    test('each SCENE_THREE_POINTS point samples to its declared colour', () {
      for (var i = 0; i < SCENE_THREE_POINTS.points.length; i++) {
        final sampled =
            sampleSceneAt(SCENE_THREE_POINTS.scene, SCENE_THREE_POINTS.points[i]);
        expect(
          labDistance(sampled, SCENE_THREE_POINTS.colorsAtPoints[i]),
          lessThan(3.0),
          reason: 'point ${SCENE_THREE_POINTS.points[i]} should sample to its '
              'declared colour',
        );
      }
    });

    test('SCENE_THREE_POINTS points are mutually distinct and off the field',
        () {
      const field = ColorCoordinates(lightness: 50, a: 0, b: 0);
      final sampled = [
        for (final p in SCENE_THREE_POINTS.points)
          sampleSceneAt(SCENE_THREE_POINTS.scene, p),
      ];
      for (var i = 0; i < sampled.length; i++) {
        expect(
          labDistance(sampled[i], field),
          greaterThan(20.0),
          reason: 'point $i must not read as the neutral field',
        );
        for (var j = i + 1; j < sampled.length; j++) {
          expect(
            labDistance(sampled[i], sampled[j]),
            greaterThan(20.0),
            reason: 'points $i and $j must be well apart so a per-point value '
                'cannot be confused for another (AC-4)',
          );
        }
      }
    });

    test('SCENE_WIDE supports wide gamut; SCENE_NARROW does not (AC-6↔AC-8 '
        'control)', () {
      expect(FakeCaptureSource(SCENE_WIDE.spec).supportsWideGamut, isTrue);
      expect(FakeCaptureSource(SCENE_NARROW.spec).supportsWideGamut, isFalse);
    });

    test('SCENE_RAW supports RAW; a non-RAW device does not (AC-7 control)', () {
      expect(FakeCaptureSource(SCENE_RAW.spec).supportsRaw, isTrue);
      expect(FakeCaptureSource(SCENE_NARROW.spec).supportsRaw, isFalse);
    });

    test('SCENE_DIM_TORCH is dim with a torch that biases the reading', () {
      expect(FakeCaptureSource(SCENE_DIM_TORCH.spec).lighting, Lighting.low);
      expect(SCENE_DIM_TORCH.spec.torchAvailable, isTrue);
      expect(
        SCENE_DIM_TORCH.spec.torchColorShift,
        greaterThan(0),
        reason: 'the torch must shift the reading, or AC-1/AC-2 are vacuous',
      );
    });

    test('SCENE_ANDROID and SCENE_IOS share ground truth but differ in raw '
        '(AC-10 enforces differing raw)', () {
      expect(SCENE_ANDROID.groundTruth, SCENE_IOS.groundTruth);
      expect(SCENE_ANDROID.spec.platform, CapturePlatform.android);
      expect(SCENE_IOS.spec.platform, CapturePlatform.ios);
      expect(SCENE_ANDROID.spec.referenceCardPresent, isTrue);
      expect(SCENE_IOS.spec.referenceCardPresent, isTrue);
      // Both raws non-zero and different, so AC-10 cannot pass merely because
      // the two fixtures' raw was identical.
      expect(SCENE_ANDROID.spec.rawColorShift, isNot(0));
      expect(SCENE_IOS.spec.rawColorShift, isNot(0));
      expect(
        SCENE_ANDROID.spec.rawColorShift,
        isNot(SCENE_IOS.spec.rawColorShift),
      );
    });
  });

  group('bs-09 harness smoke (ITEST-1)', () {
    testWidgets(
        'the assembled app opens on Capture with the torch, sample-points and '
        'send-to-comparison controls, an empty readings region and no torch '
        'warning', (tester) async {
      final h = await givenCaptureOf(tester, SCENE_DIM_TORCH);

      // The fixture booted and the read endpoint is wired: a dim scene, torch
      // off (AC-1's precondition), no readings and no banner yet.
      expect(h.source.lighting, Lighting.low);
      expect(h.state.torchOn, isFalse);
      expect(h.state.torchWarning, isNull);
      expect(h.state.markedPoints, isEmpty);
      expect(h.state.markedReadings, isEmpty);

      // The three new SCREEN-1 controls are present, the torch reading "Torch"
      // while off.
      expect(find.byKey(CaptureControls.torchKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(CaptureControls.torchKey),
          matching: find.text('Torch'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(CaptureControls.samplePointsKey), findsOneWidget);
      expect(find.byKey(CaptureControls.sendToComparisonKey), findsOneWidget);

      // The multi-point readings region is present but empty, and no marked
      // point is drawn.
      expect(find.byKey(CaptureReadingsList.readingsListKey), findsOneWidget);
      expect(find.byKey(CaptureReadingsList.readingKey(0)), findsNothing);
      expect(
        find.byKey(CaptureLiveView.markedPointKey(const MarkedPoint(14, 14))),
        findsNothing,
      );

      // The torch colour-temperature banner is absent while the torch is off.
      expect(find.byKey(CaptureLiveView.torchWarningKey), findsNothing);
    });
  });
}
