// bs-19 Live camera capture — acceptance tests for the *permission &
// availability* ACs (ITEST-3): the runtime permission request with its
// graceful fallback, and the no-camera fallback.
//
// One *pending* `acTestWidgets` per AC, driving the real assembled app through
// `givenLiveCamera`. Skipped in the default run; executed under
// `--dart-define=BS19_RUN_PENDING=true`; un-pended by the owning behaviour
// phase (AC-7 → PERM-2, AC-8 → PERM-3) by deleting its row in `pendingACs`.
//
//   * AC-7 TestAC07_PermissionFallback — permission is requested once; granted
//     selects the live camera, denied falls back to software with a "camera
//     access needed" affordance and no crash.
//   * AC-8 TestAC08_NoCameraFallback   — a device with no usable camera falls
//     back to the software source, still reads, and never crashes.
//
// Both ACs rest on the production *source selection*, which the assembly does
// not run yet (the harness injects the source directly at
// `AppDependencies.captureSource`, and PERM-1 wired the `CameraPermission`
// seam but not its injection). So each stays red on a Then naming its owner:
// AC-7 on the first permission request (PERM-2), AC-8 on the software fallback
// (PERM-3). The tests are written complete, against the resolved observables,
// for those phases to make green.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/camera_permission.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  acTestWidgets(
    'AC-7',
    'TestAC07_PermissionFallback — permission is requested, granted selects the '
        'camera, denial falls back gracefully',
    (tester) async {
      // ---- Granted branch ---------------------------------------------------
      // Given: camera permission has not yet been decided — a recording seam
      // that starts undetermined and will resolve to granted. Checked on the
      // seam itself, before the screen is opened: no request made yet.
      final granted = RecordingCameraPermission(
        initial: CameraPermissionState.undetermined,
        resolvesTo: CameraPermissionState.granted,
      );
      expect(granted.requestCount, 0,
          reason: 'AC-7 Given: no permission request has been made yet');
      expect(granted.status, CameraPermissionState.undetermined,
          reason: 'AC-7 Given: permission is undecided');

      // When: the painter opens the Capture screen for a live reading.
      final h = await givenLiveCamera(
        tester,
        source: ScriptedCameraSource(
          initialFrames: [FRAME_CYAN],
          permissionState: CameraPermissionState.undetermined,
        ),
        permission: granted,
      );

      // Then: the app requested camera permission exactly once — red until
      // PERM-2 wires the CameraPermission seam into the assembly and requests on
      // first live-capture entry (rejects never requesting).
      expect(granted.requestCount, 1,
          reason: 'AC-7: opening Capture requests camera permission exactly '
              'once (PERM-2 wires the CameraPermission seam into buildApp)');
      // …and if permission is granted the live camera source becomes active.
      expect(h.activeSourceKind, CaptureSourceKind.camera,
          reason: 'AC-7: granted permission selects the live camera source');
      expect(h.permissionState, CameraPermissionState.granted,
          reason: 'AC-7: the resolved permission is surfaced as granted');

      // ---- Denied branch ----------------------------------------------------
      // A fresh app (buildApp reuses its root element across a second pumpWidget
      // of the same type, so the first controller/source would otherwise
      // persist). The seam resolves to denied this time.
      await tester.pumpWidget(const SizedBox());
      final denied = RecordingCameraPermission(
        initial: CameraPermissionState.undetermined,
        resolvesTo: CameraPermissionState.denied,
      );
      final h2 = await givenLiveCamera(
        tester,
        source: ScriptedCameraSource(
          initialFrames: [FRAME_CYAN],
          permissionState: CameraPermissionState.undetermined,
        ),
        permission: denied,
      );
      // Then: permission is still requested once on the denied path…
      expect(denied.requestCount, 1,
          reason: 'AC-7: permission is requested once on the denied path too');
      // …and if permission is denied the app falls back to the software source
      // without crashing, and shows a "camera access needed" affordance.
      expect(h2.activeSourceKind, CaptureSourceKind.software,
          reason: 'AC-7: denied permission falls back to the software source '
              '(rejects staying on a dead camera source)');
      expect(h2.permissionState, CameraPermissionState.denied,
          reason: 'AC-7: the denied decision is surfaced');
      expect(find.textContaining('Camera access'), findsOneWidget,
          reason: 'AC-7: a "camera access needed" affordance is shown so the '
              'painter can retry or open settings');
      expect(tester.takeException(), isNull,
          reason: 'AC-7: denial falls back without crashing (no black screen)');
    },
  );

  acTestWidgets(
    'AC-8',
    'TestAC08_NoCameraFallback — a device with no usable camera falls back to '
        'software and still reads',
    (tester) async {
      // Given: the device reports no usable camera — the scripted availability
      // signal the production probe (PERM-3) resolves. Checked on the source.
      final source = ScriptedCameraSource(
        initialFrames: [FRAME_CYAN],
        available: false,
      );
      expect(source.available, isFalse,
          reason: 'AC-8 Given: the scripted device reports no usable camera');

      // When: the Capture screen opens.
      final h = await givenLiveCamera(tester, source: source);

      // Then: the app falls back to the software source — red until PERM-3
      // probes availability and selects the fallback (rejects forcing a camera
      // source that cannot stream / a black view).
      expect(h.activeSourceKind, CaptureSourceKind.software,
          reason: 'AC-8: no usable camera falls back to the software source '
              '(PERM-3)');
      // …and the painter can still read on the fallback, with no crash.
      expect(h.state.currentSample, isNotNull,
          reason: 'AC-8: the painter can still take a reading on the fallback');
      expect(tester.takeException(), isNull,
          reason: 'AC-8: no camera falls back without crashing (no black view)');
    },
  );
}
