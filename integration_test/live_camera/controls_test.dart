// bs-19 Live camera capture — acceptance tests for the *device control* ACs
// (ITEST-3): the torch and the camera lifecycle.
//
// One *pending* `acTestWidgets` per AC, driving the real assembled app through
// `givenLiveCamera` (the harness injects a `ScriptedCameraSource` at the
// `AppDependencies.captureSource` seam; the controller, the torch/commit
// plumbing and the feed subscription are the shipped code). Skipped in the
// default run; executed under `--dart-define=BS19_RUN_PENDING=true`; un-pended
// by the owning behaviour phase (AC-6 → CAM-6, AC-9 → CAM-7) by deleting its
// row in `pendingACs`.
//
//   * AC-6 TestAC06_Torch     — the torch toggles the device light and stamps
//     a reading committed while it is lit.
//   * AC-9 TestAC09_Lifecycle — the camera is released on background and
//     re-acquired on resume.
//
// Both read through the public surface only: the rendered torch controls /
// warning banner, the capture read endpoint's observable state, and the
// scripted source's acquire/release/torch recorders (which count the controls
// and subscriptions the real controller drove). The permission / platform ACs
// live in `permission_test.dart` / `platform_test.dart`; keep the files
// disjoint (ITEST-3 owns all three).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';

import 'harness.dart';

/// The real colour-science used to turn a sampled CIELAB reading back into sRGB
/// channels, so an AC-9 Then can compare the resumed reading to the known
/// reticle [Pixel] in device channels (the reading_test idiom).
const ColorScience _science = ColorScienceImpl();

/// The L1 sRGB gap under which a sampled reading counts as *equal* to a known
/// reticle colour — wide enough for the Lab round-trip's rounding, far below the
/// >180 separation between [RETICLE_CYAN] and [RETICLE_ORANGE].
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

/// The torch toggle's current label within its control — "✓ Torch" while lit,
/// "Torch" while off.
Finder _torchLabel(String text) => find.descendant(
      of: find.byKey(CaptureControls.torchKey),
      matching: find.text(text),
    );

/// Backgrounds the app through the valid lifecycle transition sequence
/// (resumed → inactive → hidden → paused), delivering every step to the
/// observers, then draining the microtask queue so an async release (a feed
/// subscription being cancelled) settles.
///
/// It must NOT pump a frame: on the live integration binding the engine stops
/// producing frames while the app is paused, so a pump-while-paused would hang
/// forever. The lifecycle dispatches reach observers synchronously, and
/// [WidgetTester.idle] runs the event loop without a frame, so a CAM-7 observer
/// that releases the camera (synchronously or on a microtask) is observable
/// here without pumping.
Future<void> _background(WidgetTester tester) async {
  for (final s in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
  await tester.idle();
}

/// Foregrounds the app again (paused → hidden → inactive → resumed), then pumps
/// — safe now because `resumed` re-enables frames.
Future<void> _foreground(WidgetTester tester) async {
  for (final s in const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  acTestWidgets(
    'AC-6',
    'TestAC06_Torch — the torch toggles the device light and stamps a reading '
        'taken while it is lit',
    (tester) async {
      // ---- Scenario A: the toggle reaches the source, and off extinguishes --
      // Given: the Capture screen is reading the live camera source, the torch
      // is off — checked through the source state, the control label and the
      // call recorders before the When.
      final source = ScriptedCameraSource(initialFrames: [FRAME_CYAN]);
      final h = await givenLiveCamera(tester, source: source);
      expect(source.torchOn, isFalse,
          reason: 'AC-6 Given: the device torch starts off');
      expect(h.state.torchOn, isFalse,
          reason: 'AC-6 Given: the capture state starts torch-off');
      expect(source.torchOnCalls, 0,
          reason: 'AC-6 Given: the torch has not been driven yet');
      expect(_torchLabel('Torch'), findsOneWidget,
          reason: 'AC-6 Given: the control shows the torch-off affordance');
      expect(find.byKey(CaptureLiveView.torchWarningKey), findsNothing,
          reason: 'AC-6 Given: no torch colour-temperature warning while off');

      // When: the painter turns the torch on.
      await h.whenTurnTorchOn();

      // Then: the device torch is lit — and the toggle actually *reached the
      // source* (AUGMENTATION, CAM-6): a UI flag flipping on its own would leave
      // torchOnCalls at 0.
      expect(source.torchOn, isTrue,
          reason: 'AC-6: the device torch is lit');
      expect(source.torchOnCalls, 1,
          reason: 'AC-6: the toggle reached the source exactly once '
              '(rejects a torch toggle that never reaches the device)');
      expect(h.state.torchOn, isTrue,
          reason: 'AC-6: the capture state reflects the lit torch');
      expect(_torchLabel('✓ Torch'), findsOneWidget,
          reason: 'AC-6: the control now shows the torch-on affordance');
      expect(find.byKey(CaptureLiveView.torchWarningKey), findsOneWidget,
          reason: 'AC-6: lighting the torch raises its colour-temperature '
              'warning');

      // And: turning the torch off extinguishes the device light (AUGMENTATION,
      // CAM-6 — settle point: whenTurnTorchOff's pumpAndSettle rebuilt the view).
      await h.whenTurnTorchOff();
      expect(source.torchOn, isFalse,
          reason: 'AC-6: turning the torch off extinguishes the device light');
      expect(source.torchOffCalls, 1,
          reason: 'AC-6: the off-path reached the source exactly once');
      expect(h.state.torchOn, isFalse,
          reason: 'AC-6: the capture state reflects the extinguished torch');
      expect(find.byKey(CaptureLiveView.torchWarningKey), findsNothing,
          reason: 'AC-6: the torch warning clears once the torch is off');

      // ---- Scenario B: a reading committed while lit is stamped litByTorch ---
      // Tear the first app down before mounting the next: buildApp reuses its
      // root element across a second pumpWidget of the same type, so the Capture
      // controller would otherwise keep the first (now torch-off) source.
      await tester.pumpWidget(const SizedBox());
      final litSource = ScriptedCameraSource(initialFrames: [FRAME_CYAN]);
      final h2 = await givenLiveCamera(tester, source: litSource);
      await h2.whenTurnTorchOn();
      await h2.whenCommit();
      final litCommit = h2.state.lastCommittedSample;
      expect(litCommit, isNotNull,
          reason: 'AC-6: a reading was committed while the torch was lit');
      expect(litCommit!.litByTorch, isTrue,
          reason: 'AC-6: a reading committed while the torch is lit is stamped '
              'litByTorch');

      // ---- Control: a reading committed with the torch OFF is NOT stamped ----
      // Rejects a commit that always stamps litByTorch regardless of the torch.
      await tester.pumpWidget(const SizedBox());
      final darkSource = ScriptedCameraSource(initialFrames: [FRAME_CYAN]);
      final h3 = await givenLiveCamera(tester, source: darkSource);
      await h3.whenCommit();
      final darkCommit = h3.state.lastCommittedSample;
      expect(darkCommit, isNotNull,
          reason: 'AC-6 control: a reading was committed with the torch off');
      expect(darkCommit!.litByTorch, isFalse,
          reason: 'AC-6 control: a torch-off commit is not stamped litByTorch '
              '(rejects a stamp that ignores the torch state)');
    },
  );

  acTestWidgets(
    'AC-9',
    'TestAC09_Lifecycle — the camera is released on background and re-acquired '
        'on resume',
    (tester) async {
      // Given: the Capture screen is reading the live camera source. The feed
      // has been acquired exactly once (the controller subscribed on entry) and
      // nothing has been released — checked through the source's acquire/release
      // recorders — and the live reading is rendering (not a frozen/black feed).
      final source = ScriptedCameraSource(initialFrames: [FRAME_CYAN]);
      final h = await givenLiveCamera(tester, source: source);
      // Settle the stability counter so the live view stops scheduling frames;
      // otherwise the self-rescheduling settle tick deadlocks the pump across
      // the lifecycle transition below.
      await tester.pumpAndSettle();
      expect(source.acquireCount, 1,
          reason: 'AC-9 Given: the camera feed is acquired once on entry');
      expect(source.releaseCount, 0,
          reason: 'AC-9 Given: nothing has been released yet');
      final opening = _readingOf(h);
      expect(_distToReticle(opening, RETICLE_CYAN), lessThan(_readingToleranceL1),
          reason: 'AC-9 Given: the live feed is rendering the opening frame');

      // When: the app is backgrounded (or the Capture screen is disposed).
      await _background(tester);

      // Then: the camera controller is released — red until CAM-7 releases the
      // controller on pause (a leaked controller would never release).
      expect(source.releaseCount, greaterThanOrEqualTo(1),
          reason: 'AC-9: the camera controller is released on background '
              '(CAM-7 — rejects leaking the controller)');

      // When: the app returns to the Capture screen.
      await _foreground(tester);

      // Then: the camera is re-acquired — a fresh subscription — so the feed
      // can resume (CAM-7; rejects staying frozen after resume).
      expect(source.acquireCount, greaterThanOrEqualTo(2),
          reason: 'AC-9: the camera is re-acquired on resume (CAM-7)');

      // And: the live feed renders again without a frozen or black frame — a
      // new frame flows through to the reading (settle point: the pump inside
      // whenFrameChangesTo, after the resumed feed delivers it).
      await h.whenFrameChangesTo(FRAME_ORANGE);
      final resumed = _readingOf(h);
      expect(_distToReticle(resumed, RETICLE_ORANGE), lessThan(_readingToleranceL1),
          reason: 'AC-9: the feed resumes and the reading follows the live '
              'frame again (rejects a frozen/black feed after resume)');
    },
  );
}
