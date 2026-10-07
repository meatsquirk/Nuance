// bs-02 Sample-capture acceptance suite.
//
// ITEST-1 lands the never-pending scaffold here — a smoke test proving the
// shells wire end to end, and guard tests over the pending gate, the fixtures
// and the fakes so the scaffold cannot pass vacuously. ITEST-2 / ITEST-3 append
// one *pending* `acTestWidgets` per AC (`TestAC01_…`) to this file.
//
// Default: `flutter test integration_test/capture_test.dart` (pending ACs
// skipped). Run-pending: `BS02_RUN_PENDING=1 flutter test
// integration_test/capture_test.dart` (the red-baseline / un-pend run).

import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_eyedropper.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_read_endpoint.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';

import 'capture_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: the assembled app boots to a Capture screen showing every region',
    (tester) async {
      final harness = await givenCaptureOf(tester, SCENE_OLIVE);

      // Booted to the Capture route (a capture source was injected), not the
      // Readout. (The app-bar title "Capture" is scoped to the AppBar — the E20
      // button also reads "Capture".)
      expect(find.widgetWithText(AppBar, 'Capture'), findsOneWidget);
      expect(find.byKey(CaptureReadEndpoint.endpointKey), findsOneWidget);

      // The live view, the eyedropper + reticle, and every E15–E21 control
      // anchor the AC finders rely on are rendered.
      expect(find.byKey(CaptureLiveView.liveViewKey), findsOneWidget);
      expect(find.byKey(CaptureEyedropper.eyedropperKey), findsOneWidget);
      expect(find.byKey(CaptureEyedropper.reticleKey), findsOneWidget);
      for (final key in const [
        CaptureControls.dismissWarningKey, // E15
        CaptureControls.lockKey, // E16
        CaptureControls.calibrateKey, // E17
        CaptureControls.radiusKey, // E18
        CaptureControls.importKey, // E19
        CaptureControls.captureKey, // E20
        CaptureControls.valueOnlyKey, // E21
      ]) {
        expect(find.byKey(key), findsOneWidget);
      }

      // The default readings render as text (bs-01 label contract), the warning
      // is hidden, and opening the screen fires no haptic.
      expect(find.byKey(CaptureLiveView.stabilityKey), findsOneWidget);
      expect(find.text('SETTLING 0/12'), findsOneWidget);
      expect(find.text('Approximate'), findsOneWidget);
      expect(find.byKey(CaptureLiveView.warningKey), findsNothing);

      // The observable state is the default capture (auto, 5 px, approximate),
      // readable through the endpoint the AC Thens use.
      expect(harness.state.lockState, LockState.auto);
      expect(harness.state.radiusPx, 5);
      expect(harness.state.currentSample, isNull);
      expect(harness.haptics.confirmations, 0);
    },
  );

  group('pending gate', () {
    // The owner of each AC is the phase whose acceptance gate un-pends it,
    // matching ITEST's red-baseline *Owning phase* column. Pinned exactly so a
    // typo'd id, a missing AC, a stray AC or a re-owned AC fails this test
    // rather than passing vacuously.
    const expectedOwners = {
      'AC-1': 'SCREEN-2',
      'AC-2': 'SOURCE-2',
      'AC-3': 'SCREEN-2',
      'AC-4': 'CAPTURE-3',
      'AC-5': 'CAPTURE-3',
      'AC-6': 'CAPTURE-4',
      'AC-7': 'CAPTURE-4',
      'AC-8': 'CAPTURE-5',
      'AC-9': 'SOURCE-3',
      'AC-10': 'SCREEN-3',
      'AC-11': 'CAPTURE-6',
    };

    test('all 11 ACs are pending, each owned by a real behaviour phase', () {
      expect(pendingACs, expectedOwners);
      expect(pendingACs.length, 11);
      for (final owner in pendingACs.values) {
        expect(behaviorPhases, contains(owner),
            reason: '"$owner" is not a known bs-02 behaviour phase');
      }
    });

    test('a pending AC is skipped by default and runs only in run-pending mode',
        () {
      // A mapped (pending) AC: skipped in the default run, run in run-pending.
      expect(pendingSkipReason('AC-1', forceRunPending: false), isNotNull);
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
      // An un-mapped AC always runs, in either mode — the end state as each
      // behaviour phase deletes its row.
      expect(pendingSkipReason('AC-unmapped', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-unmapped', forceRunPending: true), isNull);
    });
  });

  group('fixtures and fakes are sound (no vacuous controls)', () {
    test('SCENE_CENTRE_VARIED has three distinct colours: centre, 5 px ring, '
        'outer — so a point / wrong-radius read is actually caught', () {
      final frame = SCENE_CENTRE_VARIED.spec.frames!.single;
      final cx = frame.width ~/ 2;
      final cy = frame.height ~/ 2;
      final centre = frame.pixelAt(cx, cy); // the point-read distractor
      final ring5 = frame.pixelAt(cx + 3, cy); // inside the 5 px disc, off-centre
      final outer = frame.pixelAt(cx + 15, cy); // in the 21 px outer band
      expect(centre, isNot(ring5),
          reason: 'centre pixel must differ from the 5 px average');
      expect(ring5, isNot(outer),
          reason: '5 px and 21 px averages must differ');
      expect(centre, isNot(outer));
    });

    test('PHOTO_SWATCH point P differs from the image centre (P ≠ centre)', () {
      final image = PHOTO_SWATCH.image;
      final atP = image.pixelAt(PHOTO_SWATCH.pointX, PHOTO_SWATCH.pointY);
      final atCentre = image.pixelAt(image.width ~/ 2, image.height ~/ 2);
      expect(atP, isNot(atCentre),
          reason: 'sampling P must be distinguishable from the image centre');
    });

    test('FakeCaptureSource exposes ground truth and counts each frame read',
        () async {
      final source = FakeCaptureSource(SCENE_CENTRE_VARIED.spec);
      expect(source.framesRead, 0);
      expect(source.groundTruth, SCENE_CENTRE_VARIED.groundTruth);

      final frames = await source.frames.toList();
      expect(frames, isNotEmpty);
      expect(source.framesRead, frames.length,
          reason: 'every pulled frame must be counted');
    });

    test('FakeHaptics counts confirmation pulses', () async {
      final haptics = FakeHaptics();
      expect(haptics.confirmations, 0);
      await haptics.confirm();
      expect(haptics.confirmations, 1);
    });
  });
}
