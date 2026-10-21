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

/// The shipped, plugin-backed [CameraPermission] (bs-19 PERM-1 shell).
///
/// This is the inert skeleton, in the spirit of the CAM-2 camera-source shell:
/// construction is cheap and device-free, [status] starts
/// [CameraPermissionState.undetermined], and the real platform [request] — the
/// camera plugin's permission prompt — lands in PERM-2, which also drives the
/// production source selection from the resolved state. Until then [request]
/// throws so no half-wired permission path can ship silently.
class PluginCameraPermission implements CameraPermission {
  /// Creates the inert permission shell (no platform call).
  PluginCameraPermission();

  // Starts undetermined; PERM-2 makes this mutable when it wires the real
  // platform request that moves it to granted/denied.
  final CameraPermissionState _status = CameraPermissionState.undetermined;

  @override
  CameraPermissionState get status => _status;

  @override
  Future<CameraPermissionState> request() async =>
      throw UnimplementedError('Camera permission request lands in PERM-2.');
}
