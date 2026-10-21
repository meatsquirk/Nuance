import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/camera_capture_source.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

/// A fake [CameraDevice] that records its lifecycle and lets a test push the
/// [CameraImage]s the real plugin would stream (CAM-3 frame-feed coverage).
class _FakeCameraDevice implements CameraDevice {
  void Function(CameraImage image)? _onImage;
  bool started = false;
  bool stopped = false;

  @override
  Future<void> start(void Function(CameraImage image) onImage) async {
    started = true;
    _onImage = onImage;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  /// Delivers [image] as if the device produced a frame.
  void emit(CameraImage image) => _onImage?.call(image);
}

/// A 2×2 BGRA8888 [CameraImage], every pixel [colour].
CameraImage _bgra(Pixel colour) {
  const w = 2, h = 2;
  final bytes = Uint8List(w * h * 4);
  for (var i = 0; i < w * h; i++) {
    bytes[i * 4 + 0] = colour.b;
    bytes[i * 4 + 1] = colour.g;
    bytes[i * 4 + 2] = colour.r;
    bytes[i * 4 + 3] = 255;
  }
  return CameraImage.fromPlatformInterface(
    CameraImageData(
      format: const CameraImageFormat(ImageFormatGroup.bgra8888, raw: 0),
      width: w,
      height: h,
      planes: [
        CameraImagePlane(
            bytes: bytes, bytesPerRow: w * 4, bytesPerPixel: 4, width: w, height: h),
      ],
    ),
  );
}

void main() {
  group('CameraCaptureSource', () {
    test('constructs cheaply with the default plugin device', () {
      // The no-arg constructor falls back to PluginCameraDevice without
      // touching the platform (no acquisition until frames is listened to).
      final source = CameraCaptureSource();
      expect(source, isA<CaptureSource>());
    });

    test('frames starts the device, converts each image, and releases on cancel',
        () async {
      final device = _FakeCameraDevice();
      final source = CameraCaptureSource(device: device);
      const colour = Pixel(10, 180, 240);

      final seen = <Frame>[];
      final sub = source.frames.listen(seen.add);
      await Future<void>.delayed(Duration.zero); // let onListen run
      expect(device.started, isTrue, reason: 'first listen starts the device');

      device.emit(_bgra(colour));
      await Future<void>.delayed(Duration.zero);
      expect(seen, hasLength(1), reason: 'the delivered image is emitted');
      expect(seen.single.pixelAt(0, 0), colour,
          reason: 'each image is converted through frame_conversion');

      await sub.cancel();
      expect(device.stopped, isTrue, reason: 'cancelling releases the device');
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
