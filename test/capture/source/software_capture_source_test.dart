import 'package:color_models/color_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/sampling.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

void main() {
  const groundTruth = ColorCoordinates(lightness: 42, a: -8, b: 20);

  // The ground-truth colour as the sRGB pixel the generated feed renders it to.
  final truthRgb = LabColor(
    groundTruth.lightness,
    groundTruth.a,
    groundTruth.b,
  ).toRgbColor();
  final truthPixel =
      Pixel(truthRgb.red, truthRgb.green, truthRgb.blue);

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

    test('defaults the bs-09 capability knobs off (no change to bs-02 scenes)',
        () {
      const scene = SceneSpec(groundTruth: groundTruth);
      expect(scene.torchAvailable, isFalse);
      expect(scene.torchColorShift, 0.0);
      expect(scene.supportsWideGamut, isFalse);
      expect(scene.supportsRaw, isFalse);
      expect(scene.platform, CapturePlatform.android);
      expect(scene.rawColorShift, 0.0);
    });

    test('carries overridden bs-09 capability knobs', () {
      const scene = SceneSpec(
        groundTruth: groundTruth,
        torchAvailable: true,
        torchColorShift: 2.5,
        supportsWideGamut: true,
        supportsRaw: true,
        platform: CapturePlatform.ios,
        rawColorShift: -1.5,
      );
      expect(scene.torchAvailable, isTrue);
      expect(scene.torchColorShift, 2.5);
      expect(scene.supportsWideGamut, isTrue);
      expect(scene.supportsRaw, isTrue);
      expect(scene.platform, CapturePlatform.ios);
      expect(scene.rawColorShift, -1.5);
    });
  });

  test('CapturePlatform names Android and iOS', () {
    expect(CapturePlatform.values,
        [CapturePlatform.android, CapturePlatform.ios]);
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

    test('normalises a reading against the card to ground truth (AC-8)', () {
      final source = SoftwareCaptureSource(
        const SceneSpec(groundTruth: groundTruth, referenceCardPresent: true),
      );
      // A reading well off ground truth: the reference card recovers the true
      // colour, so normalising it returns the ground truth (ΔE00 0), independent
      // of how far the raw reading had drifted.
      const raw = ColorCoordinates(lightness: 70, a: 30, b: -10);
      expect(source.normaliseAgainstCard(raw), groundTruth);
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

    test('generates a finite feed of the ground-truth colour when the scene '
        'has no explicit frames', () async {
      final source =
          SoftwareCaptureSource(const SceneSpec(groundTruth: groundTruth));
      final feed = await source.frames.toList();
      // Finite (so a test pumpAndSettle drains it) and non-empty.
      expect(feed, isNotEmpty);
      expect(feed.length, kStabilityFrameTarget);
      // With no noise every frame is a uniform frame of the ground-truth colour.
      for (final frame in feed) {
        expect(frame.width, 64);
        expect(frame.height, 64);
        expect(frame.pixels, everyElement(truthPixel));
      }
    });

    test('generates a noisy feed whose per-frame mean is the ground truth',
        () async {
      final source = SoftwareCaptureSource(
        const SceneSpec(groundTruth: groundTruth, noise: 6),
      );
      final feed = await source.frames.toList();
      // The frames vary (noise applied) but average back to the ground truth,
      // so a multi-frame commit (AC-11) recovers it.
      final distinct = feed.map((f) => f.pixels.first).toSet();
      expect(distinct.length, greaterThan(1),
          reason: 'noise must make the frames differ');
      expect(averageFrames(feed).pixels.first, truthPixel,
          reason: 'the per-pixel mean over the feed is the ground truth');
    });

    test('emits no stability signal yet (the settling signal lands in '
        'CAPTURE-3)', () async {
      final source =
          SoftwareCaptureSource(const SceneSpec(groundTruth: groundTruth));
      expect(await source.stability.toList(), isEmpty);
    });

    test('holds no imported photo until one is imported, then returns it '
        '(AC-9)', () {
      final source =
          SoftwareCaptureSource(const SceneSpec(groundTruth: groundTruth));
      expect(source.importedPhoto, isNull);

      final image = Frame(
        width: 2,
        height: 2,
        pixels: const [
          Pixel(1, 2, 3),
          Pixel(4, 5, 6),
          Pixel(7, 8, 9),
          Pixel(10, 11, 12),
        ],
      );
      source.importPhoto(ImportedPhoto(image: image, pointX: 1, pointY: 0));

      final imported = source.importedPhoto;
      expect(imported, isNotNull);
      expect(imported!.image, same(image));
      expect(imported.pointX, 1);
      expect(imported.pointY, 0);
    });

    test('torch is off until lit, then tracks on/off (AC-1, AC-2)', () {
      final source =
          SoftwareCaptureSource(const SceneSpec(groundTruth: groundTruth));
      expect(source.torchOn, isFalse);

      source.turnTorchOn();
      expect(source.torchOn, isTrue);

      source.turnTorchOff();
      expect(source.torchOn, isFalse);
    });

    test('surfaces the scene wide-gamut and RAW capabilities (AC-6, AC-7)', () {
      final plain =
          SoftwareCaptureSource(const SceneSpec(groundTruth: groundTruth));
      expect(plain.supportsWideGamut, isFalse);
      expect(plain.supportsRaw, isFalse);

      final capable = SoftwareCaptureSource(const SceneSpec(
        groundTruth: groundTruth,
        supportsWideGamut: true,
        supportsRaw: true,
      ));
      expect(capable.supportsWideGamut, isTrue);
      expect(capable.supportsRaw, isTrue);
    });

    test('captures in Display P3 on a wide-gamut device (AC-6)', () {
      final source = SoftwareCaptureSource(const SceneSpec(
        groundTruth: groundTruth,
        supportsWideGamut: true,
      ));
      expect(source.colorSpace, CaptureColorSpace.displayP3,
          reason: 'a wide-gamut device captures in the widest space it offers');
      // A wide-gamut device that is not RAW-capable still captures processed —
      // the mode tracks `supportsRaw`, not the gamut.
      expect(source.captureMode, CaptureMode.processed);
    });

    test('falls back to the sRGB space on a device without wide gamut (AC-8)',
        () {
      final source =
          SoftwareCaptureSource(const SceneSpec(groundTruth: groundTruth));
      expect(source.colorSpace, CaptureColorSpace.srgb,
          reason: 'the narrower standard space is selected and labelled');
      expect(source.captureMode, CaptureMode.processed);
    });

    test('captures RAW in the widest space on a RAW-capable device (AC-7)', () {
      final source = SoftwareCaptureSource(const SceneSpec(
        groundTruth: groundTruth,
        supportsRaw: true,
        supportsWideGamut: true,
      ));
      // RAW-capable → the mode is raw and the space is the widest it offers
      // (Display P3), not the processed sRGB pipeline.
      expect(source.captureMode, CaptureMode.raw);
      expect(source.colorSpace, CaptureColorSpace.displayP3,
          reason: 'RAW uses the widest space the device offers');
    });

    test('tags the generated feed with its capture space, encoding wide-gamut '
        'frames in Display P3 that still sample to the ground truth (AC-6)',
        () async {
      final wide = SoftwareCaptureSource(const SceneSpec(
        groundTruth: groundTruth,
        supportsWideGamut: true,
      ));
      final feed = await wide.frames.toList();
      // Every frame is a genuine Display P3 buffer — not sRGB bits relabelled —
      // so its pixels differ from the sRGB rendering of the same colour.
      for (final frame in feed) {
        expect(frame.colorSpace, FrameColorSpace.displayP3);
      }
      expect(feed.first.pixels.first, isNot(truthPixel),
          reason: 'a P3 buffer is re-encoded, not the sRGB pixel');
      // Sampling the P3 feed (space-aware) recovers the ground-truth colour,
      // which the committed Sample.colorSpace then tags displayP3.
      final sampled = LabColor(
        groundTruth.lightness,
        groundTruth.a,
        groundTruth.b,
      ).toRgbColor();
      final read = sampleAreaAverage(
          averageFrames(feed), feed.first.width ~/ 2, feed.first.height ~/ 2);
      final readRgb = LabColor(read.lightness, read.a, read.b).toRgbColor();
      final l1 = (readRgb.red - sampled.red).abs() +
          (readRgb.green - sampled.green).abs() +
          (readRgb.blue - sampled.blue).abs();
      expect(l1, lessThan(9),
          reason: 'the wide-gamut capture converts honestly to ground truth');
    });

    test('a non-wide feed stays tagged sRGB (unchanged bs-02 behaviour)',
        () async {
      final source =
          SoftwareCaptureSource(const SceneSpec(groundTruth: groundTruth));
      final feed = await source.frames.toList();
      for (final frame in feed) {
        expect(frame.colorSpace, FrameColorSpace.srgb);
      }
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

    test('identifies as the software source (bs-19 PERM-1)', () {
      final source = SoftwareCaptureSource(
        const SceneSpec(groundTruth: groundTruth),
      );
      expect(source.kind, CaptureSourceKind.software);
    });

    test('is always available — the software source never falls back on itself '
        '(bs-19 AC-8)', () {
      final source = SoftwareCaptureSource(
        const SceneSpec(groundTruth: groundTruth),
      );
      expect(source.available, isTrue);
    });
  });
}
