import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

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
