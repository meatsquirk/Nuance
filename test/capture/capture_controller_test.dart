import 'package:color_models/color_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';

/// Exposes the protected [CaptureController.emit] seam so the shell's single
/// mutation path is testable before the behaviour phases drive it.
class _TestController extends CaptureController {
  _TestController({required super.source});

  void pump(CaptureState next) => emit(next);
}

SoftwareCaptureSource _source() => SoftwareCaptureSource(
      const SceneSpec(
        groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
      ),
    );

void main() {
  group('construction', () {
    test('holds the injected source and starts in the default state', () {
      final source = _source();
      final controller = CaptureController(source: source);
      expect(controller.source, same(source));
      expect(controller.state, const CaptureState());
      controller.dispose();
    });
  });

  group('deferred actions throw until their behaviour phase', () {
    late CaptureController controller;

    setUp(() => controller = CaptureController(source: _source()));
    tearDown(() => controller.dispose());

    test('lock', () => expect(controller.lock, throwsUnimplementedError));
    test('setRadius',
        () => expect(() => controller.setRadius(21), throwsUnimplementedError));
    test('calibrate',
        () => expect(controller.calibrate, throwsUnimplementedError));
    test('dismissWarning',
        () => expect(controller.dismissWarning, throwsUnimplementedError));
    test('toggleValueOnly',
        () => expect(controller.toggleValueOnly, throwsUnimplementedError));
    test('commit', () => expect(controller.commit, throwsUnimplementedError));
  });

  group('live feed → currentSample (SOURCE-2)', () {
    test('samples the centre of each live frame into currentSample', () async {
      const px = Pixel(60, 140, 210);
      final source = SoftwareCaptureSource(
        SceneSpec(
          groundTruth: const ColorCoordinates(lightness: 40, a: -8, b: 24),
          frames: [
            Frame(width: 4, height: 4, pixels: List<Pixel>.filled(16, px)),
          ],
        ),
      );
      final controller = CaptureController(source: source);
      // Not sampled synchronously — the feed drives it on the event loop.
      expect(controller.state.currentSample, isNull);

      await pumpEventQueue();

      final sample = controller.state.currentSample;
      expect(sample, isNotNull);
      // A measured reading at the current (approximate) accuracy.
      expect(sample!.provenance.tier, ProvenanceTier.measured);
      expect(sample.accuracy, CaptureAccuracy.approximate);
      // The sampled colour round-trips back to the frame pixel.
      final rgb = LabColor(
        sample.coordinates.lightness,
        sample.coordinates.a,
        sample.coordinates.b,
      ).toRgbColor();
      final l1 =
          (rgb.red - px.r).abs() + (rgb.green - px.g).abs() + (rgb.blue - px.b).abs();
      expect(l1, lessThan(9));
      controller.dispose();
    });

    test('dispose cancels the feed subscription (no late sample lands)',
        () async {
      final source = SoftwareCaptureSource(
        SceneSpec(
          groundTruth: const ColorCoordinates(lightness: 40, a: -8, b: 24),
          frames: [
            Frame(
              width: 2,
              height: 2,
              pixels: List<Pixel>.filled(4, const Pixel(10, 20, 30)),
            ),
          ],
        ),
      );
      final controller = CaptureController(source: source)..dispose();
      await pumpEventQueue();
      // Cancelled before the feed delivered, so no sample ever lands.
      expect(controller.state.currentSample, isNull);
    });
  });

  group('emit', () {
    test('replaces the state and notifies when it changes', () {
      final controller = _TestController(source: _source());
      var notified = 0;
      controller.addListener(() => notified++);

      const next = CaptureState(stabilityCount: 6);
      controller.pump(next);

      expect(controller.state, next);
      expect(notified, 1);
      controller.dispose();
    });

    test('is a no-op when the new state equals the current state', () {
      final controller = _TestController(source: _source());
      var notified = 0;
      controller.addListener(() => notified++);

      controller.pump(const CaptureState());

      expect(controller.state, const CaptureState());
      expect(notified, 0);
      controller.dispose();
    });
  });
}
