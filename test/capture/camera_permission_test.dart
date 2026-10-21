import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/camera_permission.dart';

void main() {
  group('PluginCameraPermission (PERM-2)', () {
    test('starts undetermined — no prompt on construction', () {
      expect(PluginCameraPermission().status, CameraPermissionState.undetermined);
    });

    // PERM-2 wires `request()` to the `camera` plugin's `initialize()` prompt;
    // that platform call runs only on a real device and is verified by the
    // sign-off walkthrough (plan D-5), so — like [PluginCameraDevice] (CAM-3) —
    // it is coverage-exempt and not exercised here. The Capture host's
    // permission-driven source selection that consumes this seam is covered
    // off-device through the injected fake (see build_app_test).

    test('is a CameraPermission', () {
      expect(PluginCameraPermission(), isA<CameraPermission>());
    });
  });

  test('CameraPermissionState enumerates undetermined / granted / denied', () {
    expect(CameraPermissionState.values, <CameraPermissionState>[
      CameraPermissionState.undetermined,
      CameraPermissionState.granted,
      CameraPermissionState.denied,
    ]);
  });
}
