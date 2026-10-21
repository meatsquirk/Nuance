// bs-19 Live camera capture — acceptance tests for the *reading* ACs (ITEST-2).
//
// One *pending* `acTestWidgets` per AC, driving the real assembled app through
// `givenLiveCamera` (the harness injects a `ScriptedCameraSource` at the
// `AppDependencies.captureSource` seam; everything else — the controller, the
// sampling layer, the lock plumbing and the warning rebuild — is the shipped
// code). Skipped in the default run; executed under
// `--dart-define=BS19_RUN_PENDING=true`; un-pended by the owning behaviour phase
// (AC-3 → CAM-4, AC-5 → CAM-5) by deleting its row in `pendingACs`.
//
//   * AC-3 TestAC03_ReadingFollowsFrame — the reading tracks the live frame.
//   * AC-5 TestAC05_LockClearsWarning  — locking the real source clears the
//     "exposure not locked" approximate warning.
//
// Both read through the public surface only: the rendered warning text and the
// capture read endpoint's observable `currentSample` / `source.locks`. The AC-1
// / AC-2 / AC-4 (preview / conversion) ACs live in `preview_test.dart`; keep the
// two files disjoint (ITEST-2 owns both; ITEST-3 owns the control / permission /
// platform files).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';

import 'harness.dart';

/// The real colour-science used to turn a sampled CIELAB reading back into sRGB
/// channels, so a Then can compare the reading to the known reticle [Pixel] in
/// device channels (the same idiom the bs-02 `capture_test` uses).
const ColorScience _science = ColorScienceImpl();

/// The L1 sRGB gap under which a sampled reading counts as *equal* to a known
/// reticle colour: wide enough to absorb the Lab round-trip's rounding, far
/// below the >180 separation between [RETICLE_CYAN] and [RETICLE_ORANGE] a
/// stale / fixed sampler would leave (so the control still discriminates).
const int _readingToleranceL1 = 45;

/// L1 sRGB distance between a sampled colour and a known [Pixel].
int _distToReticle(SRGBColor sampled, Pixel reticle) =>
    (sampled.red - reticle.r).abs() +
    (sampled.green - reticle.g).abs() +
    (sampled.blue - reticle.b).abs();

/// The sRGB channels of the capture's current reading.
SRGBColor _readingOf(LiveCameraHarness h) {
  final sample = h.state.currentSample;
  expect(sample, isNotNull, reason: 'a live reading has been sampled');
  return _science.toSRGB(sample!.coordinates);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  acTestWidgets(
    'AC-3',
    'TestAC03_ReadingFollowsFrame — the reading tracks the live camera frame',
    (tester) async {
      // Given: the Capture screen is reading the live camera source, whose feed
      // opens on a known cyan frame (c1). Checked through the read endpoint: the
      // current reading equals c1 under the reticle.
      final h = await givenLiveCamera(tester);
      final before = _readingOf(h);
      expect(_distToReticle(before, RETICLE_CYAN), lessThan(_readingToleranceL1),
          reason: 'AC-3 Given: the reading opens on the live c1 frame colour');
      // Control precondition: c1 and c2 are well separated, so "reading == c2"
      // genuinely rejects a sampler stuck on c1 (and vice versa).
      expect(_distToReticle(before, RETICLE_ORANGE),
          greaterThan(_readingToleranceL1 * 3),
          reason: 'AC-3 control: c1 (cyan) and c2 (orange) are distinct colours');

      // When: the camera frame under the reticle changes to a new colour (c2).
      await h.whenFrameChangesTo(FRAME_ORANGE);

      // Then: the current reading updates to c2, and equals the live frame's
      // pixel under the reticle — not a fixed or stale value. The settle point
      // is the pump inside whenFrameChangesTo, after which the new frame has
      // flowed source → controller → state.
      final after = _readingOf(h);
      expect(_distToReticle(after, RETICLE_ORANGE), lessThan(_readingToleranceL1),
          reason: 'AC-3: the reading follows the live frame to c2');
      expect(_distToReticle(after, RETICLE_CYAN),
          greaterThan(_readingToleranceL1 * 3),
          reason: 'AC-3: the reading is the live frame colour, not a fixed value '
              '(rejects a stale / placeholder / constant sampler)');
    },
  );

  acTestWidgets(
    'AC-5',
    'TestAC05_LockClearsWarning — locking AE·AWB·AF settles the live camera and '
        'clears the "exposure not locked" warning',
    (tester) async {
      // Given: the Capture screen is reading the live camera source, exposure is
      // not locked, and the reading is marked approximate because of it — the
      // "Exposure not locked" warning is shown over the feed.
      final source = ScriptedCameraSource(initialFrames: [FRAME_CYAN]);
      final h = await givenLiveCamera(tester, source: source);
      expect(source.locks.allLocked, isFalse,
          reason: 'AC-5 Given: AE·AWB·AF start unlocked on the source');
      final warning = find.descendant(
        of: find.byKey(CaptureLiveView.downgradeReasonsKey),
        matching: find.text(AccuracyDowngradeReason.exposureUnlocked.label),
      );
      expect(warning, findsOneWidget,
          reason: 'AC-5 Given: the "exposure not locked" approximate warning is '
              'shown while exposure is auto');

      // When: the painter locks AE, AWB and AF together.
      await h.whenLock();

      // Then: the live camera's exposure/white-balance/focus are held at the
      // source, and the approximate warning clears. Settle point: whenLock's
      // pumpAndSettle has rebuilt the live view from the new lock state.
      expect(source.locks.allLocked, isTrue,
          reason: 'AC-5: the lock reached the source — AE·AWB·AF are held');
      expect(
        find.descendant(
          of: find.byKey(CaptureLiveView.downgradeReasonsKey),
          matching: find.text(AccuracyDowngradeReason.exposureUnlocked.label),
        ),
        findsNothing,
        reason: 'AC-5: the "exposure not locked" warning clears once locked',
      );

      // CONTROL (G2 — the configured Given must be what answers): a source that
      // cannot hold its locks keeps allLocked false though the painter taps lock.
      // The warning must STAY, proving it clears from the *source's* lock state,
      // not merely from the UI's own lock flag flipping on the tap (which the
      // controller sets regardless). Rejects "clear the warning without locking"
      // and "locking state not reflected from the source".
      // Tear the first app down before mounting the control's: `buildApp`'s
      // root element is reused across a second `pumpWidget` of the same type, so
      // the Capture controller (built once in initState over the first source)
      // would otherwise persist and the control would silently share the locked
      // first source. An intervening pump of a different root forces the first
      // app to unmount so the control gets a fresh controller over `stuck`.
      await tester.pumpWidget(const SizedBox());
      final stuck = ScriptedCameraSource(
        initialFrames: [FRAME_CYAN],
        canLock: false,
      );
      final h2 = await givenLiveCamera(tester, source: stuck);
      await h2.whenLock();
      expect(stuck.locks.allLocked, isFalse,
          reason: 'AC-5 control: the stuck source never holds its locks');
      expect(
        find.descendant(
          of: find.byKey(CaptureLiveView.downgradeReasonsKey),
          matching: find.text(AccuracyDowngradeReason.exposureUnlocked.label),
        ),
        findsOneWidget,
        reason: 'AC-5 control: with the source unlocked the warning stays — it '
            'tracks source lock state, not the UI lock flag',
      );
    },
  );
}
