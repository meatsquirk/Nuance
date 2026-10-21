import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/camera_capture_source.dart';
import 'package:paint_color_assistant/capture/source/capture_source_factory.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

void main() {
  SoftwareCaptureSource buildSoftware() => SoftwareCaptureSource(
        const SceneSpec(
          groundTruth: ColorCoordinates(lightness: 58, a: 36, b: 34),
        ),
      );

  group('selectCaptureSource (CAM-2 seam)', () {
    test('returns the software fallback by default', () {
      final fallback = buildSoftware();
      final source = selectCaptureSource(softwareFallback: () => fallback);
      // The shell seam leaves the app on the software source unchanged (bs-02).
      expect(source, same(fallback));
    });

    test('selects the live camera source when useCamera is true', () {
      final source = selectCaptureSource(
        softwareFallback: buildSoftware,
        useCamera: true,
      );
      expect(source, isA<CameraCaptureSource>());
    });
  });
}
