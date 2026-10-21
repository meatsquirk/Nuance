import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/camera_capture_source.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

void main() {
  group('CameraCaptureSource (CAM-2 shell)', () {
    test('constructs cheaply and is a CaptureSource', () {
      final source = CameraCaptureSource();
      expect(source, isA<CaptureSource>());
    });

    test('frames is an empty stream (no device feed yet)', () async {
      final source = CameraCaptureSource();
      expect(await source.frames.toList(), isEmpty);
    });

    test('stability is an empty stream (no settle signal yet)', () async {
      final source = CameraCaptureSource();
      expect(await source.stability.toList(), isEmpty);
    });

    test('reports adequate lighting and no reference card', () {
      final source = CameraCaptureSource();
      expect(source.lighting, Lighting.adequate);
      expect(source.referenceCardPresent, isFalse);
    });

    test('normaliseAgainstCard returns the reading unchanged (D-6 deferred)',
        () {
      final source = CameraCaptureSource();
      const raw = ColorCoordinates(lightness: 58, a: 36, b: 34);
      expect(source.normaliseAgainstCard(raw), same(raw));
    });

    test('records locks independently and settles once all three are set', () {
      final source = CameraCaptureSource();
      expect(source.locks, const CaptureLocks());
      source.lockExposure();
      expect(source.locks.exposure, isTrue);
      expect(source.locks.allLocked, isFalse);
      source.lockWhiteBalance();
      expect(source.locks.whiteBalance, isTrue);
      source.lockFocus();
      expect(source.locks.focus, isTrue);
      expect(source.locks.allLocked, isTrue);
    });

    test('holds the most recently imported photo', () {
      final source = CameraCaptureSource();
      expect(source.importedPhoto, isNull);
      final photo = ImportedPhoto(
        image: const Frame(
          width: 1,
          height: 1,
          pixels: [Pixel(10, 20, 30)],
        ),
        pointX: 0,
        pointY: 0,
      );
      source.importPhoto(photo);
      expect(source.importedPhoto, same(photo));
    });

    test('records the torch on/off state', () {
      final source = CameraCaptureSource();
      expect(source.torchOn, isFalse);
      source.turnTorchOn();
      expect(source.torchOn, isTrue);
      source.turnTorchOff();
      expect(source.torchOn, isFalse);
    });

    test('reports the inert sRGB / processed capture defaults (D-6)', () {
      final source = CameraCaptureSource();
      expect(source.supportsWideGamut, isFalse);
      expect(source.supportsRaw, isFalse);
      expect(source.colorSpace, CaptureColorSpace.srgb);
      expect(source.captureMode, CaptureMode.processed);
    });

    test('identifies as the live camera source (bs-19 PERM-1)', () {
      expect(CameraCaptureSource().kind, CaptureSourceKind.camera);
    });
  });
}
