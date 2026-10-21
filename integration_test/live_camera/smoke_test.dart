// Harness tests for the bs-19 live-camera acceptance suite (ITEST-1).
//
// Two jobs, both never pending:
//   1. a smoke test proving the shells wire end to end — the real app assembled
//      through `buildApp` over a scripted camera source boots to the Capture
//      route, the read endpoint answers (active source kind + permission state),
//      the live feed reaches the controller (a reading is sampled), and the
//      render path paints the live camera frame (AC-1 delivered by VIEW-2);
//   2. guard tests over the pending gate and the fixtures, so the scaffold
//      can't pass vacuously — the pending map must cover exactly the 10 ACs
//      (each owned by a real behaviour phase), the gate must skip a pending AC
//      only in the default run, and the scripted source + recording permission
//      must actually record what the app drives them with.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/camera_permission.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_read_endpoint.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: the assembled app boots to Capture over the scripted camera source, '
    'the read endpoint answers and the live feed reaches the controller',
    (tester) async {
      final harness = await givenLiveCamera(tester);

      // Booted to the Capture route: the read endpoint and every control anchor
      // the AC finders use are mounted.
      expect(
        find.byKey(CaptureReadEndpoint.endpointKey, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byKey(CaptureLiveView.liveViewKey), findsOneWidget);
      expect(find.byKey(CaptureControls.lockKey), findsOneWidget);
      expect(find.byKey(CaptureControls.torchKey), findsOneWidget);
      expect(find.byKey(CaptureControls.valueOnlyKey), findsOneWidget);
      expect(find.byKey(CaptureControls.captureKey), findsOneWidget);

      // The read endpoint surfaces the active source selection (the scripted
      // source stands for the live camera) and the resolved permission state:
      // PERM-2 wired the request, and the harness's default recorder grants, so
      // the camera is kept and the permission reads granted.
      expect(harness.activeSourceKind, CaptureSourceKind.camera);
      expect(harness.permissionState, CameraPermissionState.granted);

      // The feed is wired end to end: the seed frame flowed source → controller
      // → state, so a reading has been sampled under the reticle.
      expect(harness.state.currentSample, isNotNull);

      // …and the render path now paints the live camera frame — VIEW-2 wired
      // the active source's frame into the live view, so the flat placeholder
      // is gone (AC-1 delivered).
      expect(harness.showsPlaceholder, isFalse);
    },
  );

  group('pending gate', () {
    test(
        'the pending map holds exactly the bs-19 ACs not yet delivered, each '
        'owned by a real behaviour phase', () {
      // The 10 ACs, less those a landed behaviour phase has un-pended. CAM-3
      // un-pended AC-2; each later phase adds its AC here as it lands, so this
      // guard stays an exact-set assertion (non-vacuous) rather than drifting
      // to a bare count as the map shrinks.
      const unpendedACs = <String>{
        'AC-1', 'AC-2', 'AC-3', 'AC-4', 'AC-5', // VIEW-2, CAM-3, CAM-4, VIEW-3, CAM-5
        'AC-6', // CAM-6
        'AC-7', // PERM-2
        'AC-9', // CAM-7
      };
      final expectedPending = <String>{
        for (var n = 1; n <= 10; n++) 'AC-$n',
      }..removeAll(unpendedACs);
      expect(pendingACs.keys.toSet(), expectedPending,
          reason: 'only not-yet-delivered ACs stay pending');
      // A delivered AC is no longer skipped — it runs in the default suite.
      for (final ac in unpendedACs) {
        expect(pendingSkipReason(ac, forceRunPending: false), isNull,
            reason: '$ac is delivered, so the default run executes it');
      }
      // Every owner names a real behaviour phase (rejects a typo'd / stale row).
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} names unknown phase "${entry.value}"',
        );
      }
    });

    test('a pending AC is skipped only in the default run; it runs in '
        'run-pending mode, and an un-pended AC always runs', () {
      // AC-8 is pending (owned by PERM-3): skipped by default, run under
      // run-pending. The reason names its owner so a red-baseline failure is
      // attributable. (AC-1 was the example until VIEW-2; AC-3 until CAM-4;
      // AC-4 until VIEW-3; AC-5 until CAM-5; AC-6 until CAM-6; AC-7 until PERM-2.)
      final reason = pendingSkipReason('AC-8', forceRunPending: false);
      expect(reason, isNotNull);
      expect(reason, contains('PERM-3'));
      expect(pendingSkipReason('AC-8', forceRunPending: true), isNull);

      // An AC absent from the map (none is un-pended yet, so use an unmapped id)
      // always runs, in either mode — the gate never skips a non-pending AC.
      expect(pendingSkipReason('AC-unmapped', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-unmapped', forceRunPending: true), isNull);

      // The ambient path `acTestWidgets` uses agrees with the current mode.
      expect(
        pendingSkipReason('AC-4'),
        pendingSkipReason('AC-4', forceRunPending: runPending),
      );
    });
  });

  group('ScriptedCameraSource records what the app drives it with', () {
    test('the lock controls reach the source and settle allLocked', () {
      final source = ScriptedCameraSource();
      expect(source.locks.allLocked, isFalse);
      expect(source.lockCalls, 0);

      source.lockExposure();
      source.lockWhiteBalance();
      source.lockFocus();

      expect(source.lockCalls, 3);
      expect(source.locks.allLocked, isTrue);
    });

    test('a source that cannot lock ignores the lock controls', () {
      final source = ScriptedCameraSource(canLock: false);
      source.lockExposure();
      source.lockWhiteBalance();
      source.lockFocus();
      expect(source.lockCalls, 0);
      expect(source.locks.allLocked, isFalse);
    });

    test('the torch toggles reach the source and are counted both ways', () {
      final source = ScriptedCameraSource();
      expect(source.torchOn, isFalse);

      source.turnTorchOn();
      expect(source.torchOn, isTrue);
      expect(source.torchOnCalls, 1);

      source.turnTorchOff();
      expect(source.torchOn, isFalse);
      expect(source.torchOffCalls, 1);
    });

    test('kind is settable so one fixture stands for either selection', () {
      final source = ScriptedCameraSource(kind: CaptureSourceKind.camera);
      expect(source.kind, CaptureSourceKind.camera);
      source.setKind(CaptureSourceKind.software);
      expect(source.kind, CaptureSourceKind.software);
    });

    test('the feed replays the seed frames then forwards pushed ones', () async {
      final source = ScriptedCameraSource(initialFrames: [FRAME_CYAN]);
      addTearDown(source.dispose);
      final seen = <Frame>[];
      final sub = source.frames.listen(seen.add);
      await Future<void>.delayed(Duration.zero);
      expect(seen, [FRAME_CYAN], reason: 'the seed frame replays on subscribe');

      source.emitFrame(FRAME_ORANGE);
      await Future<void>.delayed(Duration.zero);
      expect(seen, [FRAME_CYAN, FRAME_ORANGE],
          reason: 'a pushed frame reaches the subscriber');
      await sub.cancel();
    });

    test('knownFrame builds a uniform frame of the given colour', () {
      final frame = knownFrame(RETICLE_ORANGE, width: 8, height: 8);
      expect(frame.width, 8);
      expect(frame.height, 8);
      expect(frame.pixelAt(4, 4), RETICLE_ORANGE);
      expect(frame.pixelAt(0, 0), RETICLE_ORANGE);
    });
  });

  group('RecordingCameraPermission records requests', () {
    test('request is counted and resolves to the scripted outcome', () async {
      final granting = RecordingCameraPermission();
      expect(granting.status, CameraPermissionState.undetermined);
      expect(granting.requestCount, 0);

      final result = await granting.request();
      expect(result, CameraPermissionState.granted);
      expect(granting.status, CameraPermissionState.granted);
      expect(granting.requestCount, 1);
    });

    test('a denying recorder resolves every request to denied', () async {
      final denying = RecordingCameraPermission(
        resolvesTo: CameraPermissionState.denied,
      );
      expect(await denying.request(), CameraPermissionState.denied);
      expect(denying.status, CameraPermissionState.denied);
      expect(denying.requestCount, 1);
    });
  });
}
