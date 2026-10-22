import '../camera_permission.dart';
import 'camera_capture_source.dart';
import 'capture_source.dart';

/// Selects the [CaptureSource] the app assembles onto the Capture screen
/// (bs-19 CAM-2 seam).
///
/// The single point at which the live [CameraCaptureSource] is chosen over the
/// deterministic software source. This is the shell seam: it returns
/// [softwareFallback] unchanged by default, so the shipped app's behaviour is
/// identical to bs-02 and the acceptance harness keeps driving the software
/// source. Passing [useCamera] true selects the (still inert, CAM-2) camera
/// source instead.
///
/// PERM-2 drives [useCamera] from the resolved camera permission and device
/// availability (granted and a camera present → the live source; denied or no
/// camera → the software fallback, AC-7 / AC-8). The fallback is passed as a
/// builder so this factory stays free of the demo-scene wiring that lives with
/// the production assembly.
CaptureSource selectCaptureSource({
  required CaptureSource Function() softwareFallback,
  bool useCamera = false,
}) =>
    useCamera ? CameraCaptureSource() : softwareFallback();

/// Decides whether the production assembly opens on the live camera source
/// (bs-19 PERM-5, §9 production activation).
///
/// The pure half of the shipped source selection, split out so the whole
/// decision is unit-testable off-device while only the real device probe
/// (`availableCameras()` in `main.dart`) stays coverage-exempt (plan D-5). The
/// truth table over [hasCamera] × [permission]:
///
/// - no camera present → the software scene, whatever the permission (AC-8);
/// - a camera present but permission already [CameraPermissionState.denied] →
///   the software scene (the painter opted out — don't re-open the live feed);
/// - a camera present and permission granted or still undetermined → the live
///   [CameraCaptureSource], letting the Capture host prompt on first entry and
///   fall back on denial (AC-7, PERM-2).
///
/// At shipped startup the permission is undetermined (nothing is asked until
/// the host prompts), so in practice this reduces to "a camera is present"; the
/// denied branch guards the re-assembly case and keeps the decision honest.
bool selectUseCamera({
  required bool hasCamera,
  required CameraPermissionState permission,
}) =>
    hasCamera && permission != CameraPermissionState.denied;
