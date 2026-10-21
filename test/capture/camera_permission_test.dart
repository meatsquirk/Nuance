import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/camera_permission.dart';

void main() {
  group('PluginCameraPermission (PERM-1 shell)', () {
    test('starts undetermined — no prompt on construction', () {
      expect(PluginCameraPermission().status, CameraPermissionState.undetermined);
    });

    test('request is deferred to PERM-2 (throws until wired)', () async {
      await expectLater(
        PluginCameraPermission().request(),
        throwsA(isA<UnimplementedError>()),
      );
    });

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
