import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/frame_conversion.dart';

/// Builds a minimal real [CameraImage] without a device, so the conversion's
/// signature and shell behaviour are exercised on the host.
CameraImage _fakeCameraImage() => CameraImage.fromPlatformInterface(
      CameraImageData(
        format: const CameraImageFormat(ImageFormatGroup.bgra8888, raw: 0),
        planes: <CameraImagePlane>[
          CameraImagePlane(bytes: Uint8List(4), bytesPerRow: 4),
        ],
        width: 1,
        height: 1,
      ),
    );

void main() {
  test('frameFromCameraImage is an unimplemented stub until CAM-3', () {
    // The CAM-2 shell fixes the CameraImage → Frame signature but refuses to run
    // rather than return a wrong buffer; the real conversion lands in CAM-3.
    expect(
      () => frameFromCameraImage(_fakeCameraImage()),
      throwsUnimplementedError,
    );
  });
}
