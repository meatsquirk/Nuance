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
  int exposureLocks = 0;
  int whiteBalanceLocks = 0;
  int focusLocks = 0;
  int torchOnCalls = 0;
  int torchOffCalls = 0;

  @override
  Future<void> start(void Function(CameraImage image) onImage) async {
    started = true;
    _onImage = onImage;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> lockExposure() async => exposureLocks++;

  @override
  Future<void> lockWhiteBalance() async => whiteBalanceLocks++;

  @override
  Future<void> lockFocus() async => focusLocks++;

  @override
  Future<void> turnTorchOn() async => torchOnCalls++;

  @override
  Future<void> turnTorchOff() async => torchOffCalls++;

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

    test('each lock control forwards to the device (CAM-5)', () {
      // The lock reaches the real camera, not just local state: each control
      // records its lock in `locks` *and* drives the matching device control,
      // so on a device AE·AWB·AF are actually held (the D-5 walkthrough).
      final device = _FakeCameraDevice();
      final source = CameraCaptureSource(device: device);

      source.lockExposure();
      expect(source.locks.exposure, isTrue);
      expect(device.exposureLocks, 1, reason: 'AE lock reaches the device');

      source.lockWhiteBalance();
      expect(source.locks.whiteBalance, isTrue);
      expect(device.whiteBalanceLocks, 1, reason: 'AWB lock reaches the device');

      source.lockFocus();
      expect(source.locks.focus, isTrue);
      expect(device.focusLocks, 1, reason: 'AF lock reaches the device');

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

    test('the torch toggle forwards to the device (CAM-6)', () {
      // The torch reaches the real camera flash, not just local state: each
      // control records `torchOn` *and* drives the matching device call, so on
      // a device the flash lights and extinguishes (the D-5 walkthrough).
      final device = _FakeCameraDevice();
      final source = CameraCaptureSource(device: device);

      source.turnTorchOn();
      expect(source.torchOn, isTrue);
      expect(device.torchOnCalls, 1, reason: 'the on-path lights the device');
      expect(device.torchOffCalls, 0);

      source.turnTorchOff();
      expect(source.torchOn, isFalse);
      expect(device.torchOffCalls, 1,
          reason: 'the off-path extinguishes the device');
      expect(device.torchOnCalls, 1);
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
