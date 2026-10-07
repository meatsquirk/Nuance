import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

void main() {
  const groundTruth = ColorCoordinates(lightness: 42, a: -8, b: 20);

  group('SceneSpec', () {
    test('defaults to adequate light, lockable, no card, no noise, no frames',
        () {
      // Built non-const so the const constructor is covered at runtime.
      // ignore: prefer_const_constructors
      final scene = SceneSpec(groundTruth: groundTruth);
      expect(scene.groundTruth, groundTruth);
      expect(scene.lighting, Lighting.adequate);
      expect(scene.canLock, isTrue);
      expect(scene.referenceCardPresent, isFalse);
      expect(scene.noise, 0.0);
      expect(scene.frames, isNull);
    });

    test('carries overridden scene settings', () {
      const scene = SceneSpec(
        groundTruth: groundTruth,
        lighting: Lighting.low,
        canLock: false,
        referenceCardPresent: true,
        noise: 1.5,
      );
      expect(scene.lighting, Lighting.low);
      expect(scene.canLock, isFalse);
      expect(scene.referenceCardPresent, isTrue);
      expect(scene.noise, 1.5);
    });
  });

  group('SoftwareCaptureSource', () {
    test('exposes the scene lighting and card presence', () {
      final source = SoftwareCaptureSource(
        const SceneSpec(
          groundTruth: groundTruth,
          lighting: Lighting.low,
          referenceCardPresent: true,
        ),
      );
      expect(source.scene.groundTruth, groundTruth);
      expect(source.lighting, Lighting.low);
      expect(source.referenceCardPresent, isTrue);
    });

    test('replays an explicit frame list', () async {
      final frames = [
        Frame(width: 1, height: 1, pixels: const [Pixel(1, 2, 3)]),
        Frame(width: 1, height: 1, pixels: const [Pixel(4, 5, 6)]),
      ];
      final source = SoftwareCaptureSource(
        SceneSpec(groundTruth: groundTruth, frames: frames),
      );
      expect(await source.frames.toList(), frames);
    });

    test('emits no frames when the scene has none (deferred to SOURCE-2)',
        () async {
      final source =
          SoftwareCaptureSource(const SceneSpec(groundTruth: groundTruth));
      expect(await source.frames.toList(), isEmpty);
    });

    test('emits no stability signal yet (deferred to SOURCE-2)', () async {
      final source =
          SoftwareCaptureSource(const SceneSpec(groundTruth: groundTruth));
      expect(await source.stability.toList(), isEmpty);
    });

    test('records exposure, white-balance and focus locks', () {
      final source =
          SoftwareCaptureSource(const SceneSpec(groundTruth: groundTruth));
      expect(source.locks.allLocked, isFalse);

      source.lockExposure();
      expect(source.locks.exposure, isTrue);

      source.lockWhiteBalance();
      expect(source.locks.whiteBalance, isTrue);

      source.lockFocus();
      expect(source.locks, const CaptureLocks(
        exposure: true,
        whiteBalance: true,
        focus: true,
      ));
      expect(source.locks.allLocked, isTrue);
    });
  });
}
