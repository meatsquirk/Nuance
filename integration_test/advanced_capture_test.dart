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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_readings_list.dart';
import 'package:paint_color_assistant/capture/capture_screen.dart';

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
      // Drive both modes through the explicit `forceRunPending` override rather
      // than the ambient `runPending`, so the guard is deterministic in either
      // run — the red-baseline pass sets `BS09_RUN_PENDING=true`, under which the
      // ambient form would report "run" and this assertion would spuriously flip
      // (the bs-08 ITEST-2 fix).
      expect(pendingSkipReason('AC-1', forceRunPending: false), isNotNull);
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
      // An AC absent from the map (un-pended) always runs, in either mode.
      expect(pendingSkipReason('AC-999', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-999', forceRunPending: true), isNull);
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

  // One *pending* acceptance test per AC-1..AC-5 (ITEST-2), each registered
  // through the bs-09 pending gate so the default suite skips it until its
  // behaviour phase deletes its row in `bs09/pending.dart`. Every `when`-action
  // over a deferred control throws `UnimplementedError('<phase>')` until that
  // phase lands — which is the designed red baseline for these tests (see the
  // ITEST-2 red-baseline table in `modules/ITEST.md`).
  group('bs-09 acceptance — torch + multi-point (ITEST-2)', () {
    acTestWidgets('AC-1', 'TorchWarnsColourTemp', (tester) async {
      // Given: Capture open on a dim scene, torch off, no warning yet.
      final h = await givenCaptureOf(tester, SCENE_DIM_TORCH);
      expect(find.byType(CaptureScreen), findsOneWidget,
          reason: 'the Capture screen is shown');
      expect(h.source.lighting, Lighting.low);
      expect(h.state.torchOn, isFalse);
      // Reject "warning present before the torch is on": no banner yet.
      expect(find.byKey(CaptureLiveView.torchWarningKey), findsNothing);

      // When: the painter turns the torch on (owner SCREEN-2; the torch
      // mechanism it rests on is CAPTURE-3 — the stub throws until then).
      await h.whenTurnTorchOn();

      // Then: the torch is on and a colour-temperature bias warning is shown.
      expect(h.state.torchOn, isTrue);
      expect(find.byKey(CaptureLiveView.torchWarningKey), findsOneWidget);
      final warning =
          tester.widget<Text>(find.byKey(CaptureLiveView.torchWarningKey)).data;
      expect(warning, isNotNull);
      final text = warning!.toLowerCase();
      // Reject a warning that toggles silently or omits the colour-temperature
      // bias it must name.
      expect(text, contains('temperature'),
          reason: 'the warning must name the torch colour temperature');
      expect(text, anyOf(contains('bias'), contains('skew'), contains('shift')),
          reason: 'the warning must say the colour temperature biases the '
              'reading');
    });

    acTestWidgets('AC-2', 'ReadingLabelledTorchLit', (tester) async {
      // Given: Capture open on a dim torch scene.
      final h = await givenCaptureOf(tester, SCENE_DIM_TORCH);
      expect(h.state.torchOn, isFalse);

      // Control (same test, G5): a commit taken with the torch OFF is labelled
      // NOT torch-lit — so the Then below cannot pass by stamping every sample.
      await h.whenCommit();
      expect(h.state.lastCommittedSample, isNotNull,
          reason: 'an ambient reading commits');
      expect(h.state.lastCommittedSample!.litByTorch, isFalse,
          reason: 'control: a torch-off reading is not torch-lit');

      // When: turn the torch on, acknowledge its warning (torch stays lit), and
      // commit a reading under the torch (owner CAPTURE-3).
      await h.whenTurnTorchOn();
      await h.whenAcknowledgeTorchWarning();
      expect(h.state.torchOn, isTrue, reason: 'the torch stays lit');
      expect(h.state.torchWarning, isNull,
          reason: 'acknowledging dismisses the banner but keeps the torch on');
      await h.whenCommit();

      // Then: the reading taken under the torch is labelled lit by the torch.
      expect(h.state.lastCommittedSample, isNotNull,
          reason: 'a sample is committed under the torch');
      expect(h.state.lastCommittedSample!.litByTorch, isTrue);
    });

    acTestWidgets('AC-3', 'MultiPointSamplesAllAtOnce', (tester) async {
      final points = SCENE_THREE_POINTS.points;
      // Given: Capture open on the three-point scene; mark all three points.
      final h = await givenCaptureOf(tester, SCENE_THREE_POINTS.scene);
      await h.whenMarkPoints(points);
      expect(h.state.markedPoints, hasLength(3),
          reason: 'three points are marked before sampling (owner CAPTURE-4)');

      // When: sample the marked points together ("Sample points").
      await h.whenSamplePoints();

      // Then: exactly one reading per marked point — rejecting both "only the
      // centre sampled" and "one averaged reading over all points" (count 1).
      expect(h.state.markedReadings, hasLength(3));
      expect(
        h.state.markedReadings.map((r) => r.position).toSet(),
        points.toSet(),
        reason: 'one reading per marked point (not one averaged over all)',
      );
    });

    acTestWidgets('AC-4', 'EachPointKeepsPositionValue', (tester) async {
      final points = SCENE_THREE_POINTS.points;
      final expected = SCENE_THREE_POINTS.colorsAtPoints;
      // Given: mark + sample the three points (as AC-3); three readings exist.
      final h = await givenCaptureOf(tester, SCENE_THREE_POINTS.scene);
      await h.whenMarkPoints(points);
      await h.whenSamplePoints();
      expect(h.state.markedReadings, hasLength(3),
          reason: 'three readings exist to show (owner SCREEN-3)');

      // Then: the readings list is shown, and each reading keeps its own
      // position and its own value == that point's area-average. Checking per
      // point rejects "all readings show one colour", "readings share a
      // position", and "a reading's value is the frame centre, not its point".
      expect(find.byKey(CaptureReadingsList.readingsListKey), findsOneWidget);
      final byPosition = {
        for (final r in h.state.markedReadings) r.position: r.coordinates,
      };
      expect(byPosition.keys.toSet(), points.toSet(),
          reason: 'each reading keeps a distinct marked position');
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        expect(byPosition.containsKey(point), isTrue);
        expect(
          labDistance(byPosition[point]!, expected[i]),
          lessThan(3.0),
          reason: 'the reading at $point carries that point\'s own colour, not '
              'the frame centre or another point',
        );
        // The shown row is labelled with the position it was sampled from.
        expect(
          find.descendant(
            of: find.byKey(CaptureReadingsList.readingsListKey),
            matching: find.textContaining('Point (${point.x}, ${point.y})'),
          ),
          findsOneWidget,
          reason: 'the shown reading is labelled with its own position',
        );
      }
    });

    acTestWidgets('AC-5', 'TwoPointsToComparison', (tester) async {
      final points = SCENE_THREE_POINTS.points;
      // Given: mark + sample the three points (as AC-3); three readings exist.
      final h = await givenCaptureOf(tester, SCENE_THREE_POINTS.scene);
      await h.whenMarkPoints(points);
      await h.whenSamplePoints();
      expect(h.state.markedReadings, hasLength(3),
          reason: 'three readings exist to choose from');
      final readingP1 = h.state.markedReadings
          .firstWhere((r) => r.position == points[0]);
      final readingP3 = h.state.markedReadings
          .firstWhere((r) => r.position == points[2]);

      // When: send the two chosen readings (P1, P3) to a comparison (owner
      // CAPTURE-5 — the pair handoff opens both comparison slots at once).
      await h.whenSendPairToComparison(0, 2);

      // Then: the comparison opens with BOTH slots filled from the handoff —
      // slotA == the P1 reading, slotB == the P3 reading. Rejecting "one slot
      // filled, the other awaiting the picker", a swap/duplication, and the
      // wrong two being carried.
      final comparison = h.comparisonController.state;
      expect(comparison.slotA, isNotNull, reason: 'slot A is filled');
      expect(comparison.slotB, isNotNull, reason: 'slot B is filled');
      expect(
        labDistance(comparison.slotA!.coordinates, readingP1.coordinates),
        lessThan(3.0),
        reason: 'slot A carries the reading at P1',
      );
      expect(
        labDistance(comparison.slotB!.coordinates, readingP3.coordinates),
        lessThan(3.0),
        reason: 'slot B carries the reading at P3',
      );
      expect(
        labDistance(
            comparison.slotA!.coordinates, comparison.slotB!.coordinates),
        greaterThan(3.0),
        reason: 'the two slots carry different readings (not a duplicate)',
      );
    });
  });
}
