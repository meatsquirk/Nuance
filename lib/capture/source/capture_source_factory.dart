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
