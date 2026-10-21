import 'package:camera/camera.dart';

/// The painter's camera-permission state (bs-19 D-3/D-5).
///
/// The three states the OS permission flow resolves to. [undetermined] is the
/// pre-prompt state — the OS has not yet been asked — so the app requests
/// permission at first live-capture entry (AC-7). Availability (whether the
/// device has a usable camera at all, AC-8) is a separate concern, observed
/// through the active source kind rather than this permission state.
enum CameraPermissionState {
  /// Not yet decided — the OS will prompt on the first [CameraPermission.request].
  undetermined,

  /// The painter granted camera access — the live source may be selected.
  granted,

  /// The painter denied camera access — the app falls back to the software
  /// source and shows the "camera access needed" affordance (AC-7).
  denied,
}

/// A seam over the device camera-permission status and request (bs-19 PERM-1).
///
/// Abstracted so the production source-selection (PERM-2) is testable
/// off-device: the camera plugin's platform channels cannot run under
/// `flutter-tester`, so the unit and acceptance suites inject a recording fake
/// (plan D-5) while the shipped app uses [PluginCameraPermission]. The reading
/// pipeline stays source-agnostic; this seam only decides *which* source the
/// assembly selects.
abstract class CameraPermission {
  /// The current permission state, without prompting the painter.
  CameraPermissionState get status;

  /// Requests camera access — prompting the OS when [status] is
  /// [CameraPermissionState.undetermined] — and resolves to the new state.
  Future<CameraPermissionState> request();
}

/// The shipped, plugin-backed [CameraPermission] (bs-19 PERM-2).
///
/// Construction is cheap and device-free — [status] starts
/// [CameraPermissionState.undetermined] and nothing is asked until [request].
/// [request] drives the OS prompt through the `camera` plugin: it opens the
/// first camera, whose `initialize()` triggers the platform permission dialog,
/// and maps the outcome to granted (initialised) or denied (the plugin raised a
/// `CameraException`, e.g. access denied or no camera). Like the live
/// [PluginCameraDevice] (CAM-3) the platform calls run only on a real device and
/// are verified by the sign-off walkthrough (plan D-5), so they are exempt from
/// the coverage gate; the Capture host's selection logic that consumes this is
/// covered off-device through the injected [CameraPermission] fake.
class PluginCameraPermission implements CameraPermission {
  /// Creates the permission wrapper (no platform call until [request]).
  PluginCameraPermission();

  // Starts undetermined; [request] moves it to granted/denied once the OS
  // prompt resolves.
  CameraPermissionState _status = CameraPermissionState.undetermined;

  @override
  CameraPermissionState get status => _status;

  // coverage:ignore-start
  @override
  Future<CameraPermissionState> request() async {
    try {
      final cameras = await availableCameras();
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
      );
      // `initialize()` is what surfaces the OS camera-permission dialog; it
      // completes once the painter grants access and throws if they deny.
      await controller.initialize();
      await controller.dispose();
      return _status = CameraPermissionState.granted;
    } on CameraException {
      return _status = CameraPermissionState.denied;
    }
  }
  // coverage:ignore-end
}
