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

/// Re-opens the assembled app on [scene] in the same tester after an earlier
/// capture has already committed.
///
/// An adequate-light commit navigates to the Readout (D-5), so the first app's
/// Navigator has the Readout pushed. A plain second `pumpWidget(buildApp(…))`
/// would update that same MaterialApp / Navigator element in place — reusing it
/// with the Readout still on top, so the Capture controls are gone. Unmounting
/// with a throwaway root first disposes the first app (cancelling its feed and
/// timers) so the next `buildApp` mounts a fresh Navigator on Capture. Used by
/// the AC-6/AC-7/AC-8/AC-10 capability- and platform-controls, which commit on a
/// second scene in the same test.
Future<CaptureHarness> rebootCaptureOf(
  WidgetTester tester,
  CaptureScene scene,
) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  return givenCaptureOf(tester, scene);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('bs-09 pending gate (scaffold guard)', () {
    // Un-pended by the behaviour phases so far: CAPTURE-3 un-pended AC-2 (torch
    // mechanism + litByTorch stamp); SCREEN-2 un-pended AC-1 (torch control +
    // colour-temperature warning banner); SOURCE-2 un-pended AC-6 and AC-8
    // (colour-space selection + narrower fallback + tag). This set grows one
    // behaviour phase at a time as each deletes its row in `bs09/pending.dart`;
    // the pending map must stay the exact complement of it across all 10 ACs.
    const unpended = <String>{
      'AC-1',
      'AC-2',
      'AC-6',
      'AC-8',
    };

    test('pending map is the exact complement of the un-pended ACs across all '
        'AC-1..AC-10', () {
      for (var i = 1; i <= 10; i++) {
        final ac = 'AC-$i';
        expect(
          pendingACs.containsKey(ac),
          !unpended.contains(ac),
          reason: unpended.contains(ac)
              ? '$ac is un-pended and must not be in the pending map'
              : '$ac must still have a pending entry',
        );
      }
      expect(pendingACs.length, 10 - unpended.length);
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
      // (the bs-08 ITEST-2 fix). The pending example is read from `pendingACs`
      // itself so it stays honest as each behaviour phase un-pends its AC
      // (SCREEN-2 un-pended AC-1, which used to be this example); once the map
      // drains at the last behaviour phase the skip branch is vacuous and only
      // the run branches below fire.
      if (pendingACs.isNotEmpty) {
        final stillPending = pendingACs.keys.first;
        expect(pendingSkipReason(stillPending, forceRunPending: false),
            isNotNull);
        expect(pendingSkipReason(stillPending, forceRunPending: true), isNull);
      }
      // An un-pended AC always runs, in either mode: AC-1 (SCREEN-2) is
      // delivered, so it is no longer skipped by default.
      expect(pendingSkipReason('AC-1', forceRunPending: false), isNull);
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

  // One *pending* acceptance test per AC-6..AC-10 (ITEST-3), appended as a second
  // group after the ITEST-2 group (shared file — append, never rewrite). Each is
  // registered through the same bs-09 pending gate, so the default suite skips it
  // until its behaviour phase deletes its row in `bs09/pending.dart`. The colour
  // space / RAW / normalization behaviour these assert lands in SOURCE-2/3/4, so
  // each fails its Then at the red baseline (see the ITEST-3 red-baseline table in
  // `modules/ITEST.md`) rather than throwing.
  group('bs-09 acceptance — colour-space / RAW / normalization (ITEST-3)', () {
    acTestWidgets('AC-6', 'TaggedWithColourSpace', (tester) async {
      // Given: Capture open on a wide-gamut device; the source reports it.
      final h = await givenCaptureOf(tester, SCENE_WIDE);
      expect(find.byType(CaptureScreen), findsOneWidget,
          reason: 'the Capture screen is shown');
      expect(h.source.supportsWideGamut, isTrue,
          reason: 'SCENE_WIDE is a wide-gamut device');

      // When: commit a reading (owner SOURCE-2 — the source selects the wide
      // space and the commit threads it onto Sample.colorSpace).
      await h.whenCommit();

      // Then: the committed sample is tagged with the wide space it was taken in,
      // and its colour converts honestly (stays near ground truth). Rejects
      // `colorSpace` null/untagged and a sample tagged `srgb` on a wide device.
      final sample = h.state.lastCommittedSample;
      expect(sample, isNotNull, reason: 'a sample is committed');
      expect(sample!.colorSpace, CaptureColorSpace.displayP3);
      expect(
        labDistance(sample.coordinates, h.source.groundTruth),
        lessThan(3.0),
        reason: 'the wide-gamut capture still converts to ground truth',
      );

      // Control (same AC, G5): a narrower device tags `srgb`, so the tag tracks
      // the capability actually used — it is not a constant `displayP3`.
      final narrow = await rebootCaptureOf(tester, SCENE_NARROW);
      expect(narrow.source.supportsWideGamut, isFalse);
      await narrow.whenCommit();
      expect(narrow.state.lastCommittedSample!.colorSpace,
          CaptureColorSpace.srgb,
          reason: 'control: a non-wide device is tagged srgb, not displayP3');
    });

    acTestWidgets('AC-7', 'RawWhereSupported', (tester) async {
      // Given: Capture open on a RAW-capable device; the source reports it.
      final h = await givenCaptureOf(tester, SCENE_RAW);
      expect(h.source.supportsRaw, isTrue,
          reason: 'SCENE_RAW is a RAW-capable device');

      // When: commit a reading (owner SOURCE-3 — RAW capture in the widest space).
      await h.whenCommit();

      // Then: the sample records RAW capture in the widest space the device
      // offers (SCENE_RAW is also wide-gamut), not the processed sRGB pipeline.
      // Rejects `captureMode == processed` on a RAW device and RAW set but the
      // space still narrow.
      final sample = h.state.lastCommittedSample;
      expect(sample, isNotNull, reason: 'a sample is committed');
      expect(sample!.captureMode, CaptureMode.raw);
      expect(sample.colorSpace, CaptureColorSpace.displayP3,
          reason: 'RAW uses the widest space the device offers, not sRGB');

      // Control (same AC, G5): a non-RAW device commits `processed`, so the mode
      // tracks the capability — it is not a constant `raw`.
      final processed = await rebootCaptureOf(tester, SCENE_NARROW);
      expect(processed.source.supportsRaw, isFalse);
      await processed.whenCommit();
      expect(processed.state.lastCommittedSample!.captureMode,
          CaptureMode.processed,
          reason: 'control: a non-RAW device captures processed, not raw');
    });

    acTestWidgets('AC-8', 'FallbackLabelsNarrower', (tester) async {
      // Given: Capture open on a device WITHOUT wide-gamut capture.
      final h = await givenCaptureOf(tester, SCENE_NARROW);
      expect(h.source.supportsWideGamut, isFalse,
          reason: 'SCENE_NARROW has no wide-gamut capture');

      // When: commit a reading (owner SOURCE-2 — the narrower space is selected
      // and labelled).
      await h.whenCommit();

      // Then: the capture falls back to the device's standard space and the
      // narrower space is *labelled* (not left null). Rejects `colorSpace` null
      // (fallback unlabelled).
      final sample = h.state.lastCommittedSample;
      expect(sample, isNotNull, reason: 'a sample is committed');
      expect(sample!.colorSpace, isNotNull,
          reason: 'the fallback space is labelled, not dropped');
      expect(sample.colorSpace, CaptureColorSpace.srgb);

      // Control (same AC, G5): a wide-gamut device is labelled `displayP3`, so
      // `srgb` here is the *fallback actually used*, not a constant srgb tag.
      // This control discriminates only once SOURCE-2 lands, which is why AC-8 is
      // red at baseline (SCENE_WIDE is tagged srgb until then).
      final wide = await rebootCaptureOf(tester, SCENE_WIDE);
      expect(wide.source.supportsWideGamut, isTrue);
      await wide.whenCommit();
      expect(wide.state.lastCommittedSample!.colorSpace,
          CaptureColorSpace.displayP3,
          reason: 'control: a wide device is tagged displayP3, so srgb is a '
              'genuine fallback');
    });

    acTestWidgets('AC-9', 'NormalizedTaggedSample', (tester) async {
      // Given: Capture open on a platform scene (Android) whose raw carries a
      // platform offset; a capture is committable.
      final h = await givenCaptureOf(tester, SCENE_ANDROID);
      expect(find.byType(CaptureScreen), findsOneWidget,
          reason: 'the Capture screen is shown');
      expect(SCENE_ANDROID.spec.rawColorShift, isNot(0),
          reason: 'the platform feeds offset raw, so "normalized" is a real '
              'check — not raw already at ground truth');

      // When: commit and hand the sample to the rest of the app (owner SOURCE-4 —
      // the capture contract returns a normalized, tagged sample).
      await h.whenCommit();

      // Then: the sample is normalized — its coordinates are canonical CIELAB at
      // ground truth, NOT the raw device values the platform fed — and it is
      // colour-space tagged. Rejects coordinates left as raw (the platform offset
      // not removed) and a null tag.
      final sample = h.state.lastCommittedSample;
      expect(sample, isNotNull, reason: 'a sample is committed');
      expect(sample!.colorSpace, isNotNull,
          reason: 'the contract guarantees a colour-space tag');
      expect(
        labDistance(sample.coordinates, h.source.groundTruth),
        lessThan(3.0),
        reason: 'coordinates are normalized to canonical CIELAB, not the raw '
            'platform values',
      );
    });

    acTestWidgets('AC-10', 'PlatformAgnosticSample', (tester) async {
      // Given: the same scene captured through two platforms whose raw differs
      // pre-normalization (enforced by the fixtures), each committing a sample.
      expect(
        SCENE_ANDROID.spec.rawColorShift,
        isNot(SCENE_IOS.spec.rawColorShift),
        reason: 'the two platforms feed different raw, so matching after '
            'normalization is a genuine result, not identical fixtures',
      );
      final android = await givenCaptureOf(tester, SCENE_ANDROID);
      await android.whenCommit();
      final androidSample = android.state.lastCommittedSample;
      expect(androidSample, isNotNull, reason: 'Android commits a sample');

      final ios = await rebootCaptureOf(tester, SCENE_IOS);
      await ios.whenCommit();
      final iosSample = ios.state.lastCommittedSample;
      expect(iosSample, isNotNull, reason: 'iOS commits a sample');

      // When: hand each committed sample to the colour-science layer (read its
      // normalized coordinates + tag).
      // Then: the rest of the app sees no platform difference — the two samples
      // are equal-normalized (coordinates coincide) with an identical tag.
      // Rejects coordinates that diverge (platform leaks through) and differing
      // tags (owner SOURCE-4).
      expect(
        labDistance(androidSample!.coordinates, iosSample!.coordinates),
        lessThan(0.5),
        reason: 'both platforms normalize to the identical canonical colour',
      );
      expect(androidSample.colorSpace, iosSample.colorSpace,
          reason: 'both platforms carry the identical colour-space tag');
    });
  });
}
