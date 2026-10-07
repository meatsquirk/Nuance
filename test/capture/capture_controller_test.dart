import 'dart:async';

import 'package:color_models/color_models.dart';
import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
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

/// A [CaptureSource] whose live feed and imported photo the test drives
/// frame-by-frame, so the photo-import switch (SOURCE-3) can be observed against
/// a feed that is still live after the import — which `Stream.fromIterable`
/// cannot show, as it drains at subscription.
class _ControllableSource implements CaptureSource {
  final StreamController<Frame> _frames = StreamController<Frame>();

  @override
  Stream<Frame> get frames => _frames.stream;

  /// Delivers one live frame to the controller's subscription.
  void emitFrame(Frame frame) => _frames.add(frame);

  @override
  ImportedPhoto? importedPhoto;

  @override
  void importPhoto(ImportedPhoto photo) => importedPhoto = photo;

  @override
  CaptureLocks get locks => const CaptureLocks();

  @override
  Stream<StabilityReading> get stability =>
      Stream<StabilityReading>.empty();

  @override
  Lighting get lighting => Lighting.adequate;

  @override
  bool get referenceCardPresent => false;

  @override
  void lockExposure() {}

  @override
  void lockWhiteBalance() {}

  @override
  void lockFocus() {}
}

/// A uniform [size]×[size] frame of one [pixel].
Frame _uniformFrame(Pixel pixel, {int size = 16}) => Frame(
      width: size,
      height: size,
      pixels: List<Pixel>.filled(size * size, pixel),
    );

/// L1 distance between a sampled CIELAB colour, rendered back to sRGB, and a
/// known pixel — so a sample can be matched against the frame it came from.
int _l1(ColorCoordinates lab, Pixel px) {
  final rgb = LabColor(lab.lightness, lab.a, lab.b).toRgbColor();
  return (rgb.red - px.r).abs() +
      (rgb.green - px.g).abs() +
      (rgb.blue - px.b).abs();
}

void main() {
  // The controller schedules a per-frame settling tick on the scheduler binding
  // at construction (CAPTURE-3), so the binding must be initialised even for the
  // plain (non-widget) tests that only build a controller.
  TestWidgetsFlutterBinding.ensureInitialized();

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

    // lock() is live as of CAPTURE-3 (see the 'lock lifecycle' group below).
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

  group('stability settling + lock lifecycle (CAPTURE-3)', () {
    // Mount the controller in a listening tree so each rendered frame drives the
    // settling tick, exactly as the Capture screen does in production.
    Widget host(CaptureController controller) => MaterialApp(
          home: ListenableBuilder(
            listenable: controller,
            builder: (_, _) => Text(controller.state.stabilityText),
          ),
        );

    testWidgets('settling climbs one step per rendered frame while unlocked',
        (tester) async {
      final controller = CaptureController(source: _source());
      addTearDown(controller.dispose);

      // Before the first frame the tick is scheduled but has not fired: the
      // screen opens at "SETTLING 0/12".
      expect(controller.state.stabilityCount, 0);
      expect(controller.state.stabilityText, 'SETTLING 0/12');

      await tester.pumpWidget(host(controller)); // one rendered frame
      expect(controller.state.stabilityCount, 1);
      await tester.pump();
      expect(controller.state.stabilityCount, 2);
    });

    testWidgets('settling stops once stable and does not overshoot',
        (tester) async {
      final controller = CaptureController(source: _source());
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller));

      // Pump well past the target; the counter caps at kStabilityFrameTarget.
      for (var i = 0; i < kStabilityFrameTarget + 5; i++) {
        await tester.pump();
      }
      expect(controller.state.stabilityCount, kStabilityFrameTarget);
      expect(controller.state.isStable, isTrue);
      expect(controller.state.stabilityText, 'STABLE 12/12');
    });

    testWidgets('lock() locks AE/AWB/AF on the source and settles to STABLE',
        (tester) async {
      final source = _source();
      final controller = CaptureController(source: source);
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller)); // mid-settle (count 1)

      controller.lock();

      expect(source.locks.allLocked, isTrue);
      expect(controller.state.lockState, LockState.locked);
      expect(controller.state.stabilityCount, kStabilityFrameTarget);
      expect(controller.state.stabilityText, 'STABLE 12/12');
      expect(controller.state.lockIndicatorText, 'AE · AWB · AF LOCKED');
    });

    testWidgets('a locked reading no longer settles on later frames',
        (tester) async {
      final controller = CaptureController(source: _source());
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller));
      controller.lock();

      // Further frames must not move the (already settled, locked) reading.
      await tester.pump();
      await tester.pump();
      expect(controller.state.lockState, LockState.locked);
      expect(controller.state.stabilityCount, kStabilityFrameTarget);
    });

    testWidgets('disposing stops the settling tick (no late mutation)',
        (tester) async {
      final controller = CaptureController(source: _source());
      controller.dispose();

      // The pending post-frame tick fires on this frame but must bail out, since
      // the controller is disposed (no emit on a disposed ChangeNotifier).
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(controller.state.stabilityCount, 0);
    });
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

  group('photo import → currentSample (SOURCE-3, AC-9)', () {
    // A 16×16 image: a magenta swatch disc (radius 6) at the off-centre point
    // P = (3, 3) over a grey field. The disc is wider than the default 5 px
    // sampling radius, so a sample at P averages to the swatch; the image
    // centre (8, 8) lies ≈7 px from P, outside the disc, so it is grey. A
    // correct import samples P (magenta), not the centre and not the live feed.
    const bg = Pixel(120, 120, 120);
    const swatch = Pixel(210, 40, 90);
    const pointX = 3;
    const pointY = 3;
    const swatchRadiusPx = 6;
    Frame swatchImage() {
      final pixels = <Pixel>[];
      for (var y = 0; y < 16; y++) {
        for (var x = 0; x < 16; x++) {
          final dx = x - pointX;
          final dy = y - pointY;
          pixels.add(
              dx * dx + dy * dy <= swatchRadiusPx * swatchRadiusPx ? swatch : bg);
        }
      }
      return Frame(width: 16, height: 16, pixels: pixels);
    }

    test('samples the staged photo at point P and switches off the live feed',
        () async {
      final source = _ControllableSource();
      final controller = CaptureController(source: source);
      addTearDown(controller.dispose);

      // Control: before import, a live frame drives currentSample — so the
      // feed demonstrably *can* change the reading.
      const liveColour = Pixel(20, 180, 60);
      source.emitFrame(_uniformFrame(liveColour));
      await pumpEventQueue();
      final live = controller.state.currentSample;
      expect(live, isNotNull);
      expect(_l1(live!.coordinates, liveColour), lessThan(9),
          reason: 'the live feed drives the reading before import');

      // When: the painter imports a photo and samples its point P.
      source.importPhoto(
        ImportedPhoto(image: swatchImage(), pointX: pointX, pointY: pointY),
      );
      controller.importPhoto();

      // Then: the reading is the colour at P — a measured sample at the current
      // accuracy — not the image centre and not the live feed.
      final imported = controller.state.currentSample;
      expect(imported, isNotNull);
      expect(imported!.provenance.tier, ProvenanceTier.measured);
      expect(imported.accuracy, CaptureAccuracy.approximate);
      expect(_l1(imported.coordinates, swatch), lessThan(9),
          reason: 'the sample is the colour at point P of the photo');
      expect(_l1(imported.coordinates, bg), greaterThan(9),
          reason: 'rejects sampling the image centre (grey field)');
      expect(_l1(imported.coordinates, liveColour), greaterThan(9),
          reason: 'rejects sampling the live feed instead of the photo');

      // And: a later live frame of a *different* colour does not overwrite the
      // imported reading — the import switched sampling off the feed.
      source.emitFrame(_uniformFrame(const Pixel(250, 250, 10)));
      await pumpEventQueue();
      expect(controller.state.currentSample, same(imported),
          reason: 'the live feed no longer overwrites the imported sample');
    });

    test('importPhoto with no photo staged is a no-op', () {
      final source = _ControllableSource();
      final controller = CaptureController(source: source);
      addTearDown(controller.dispose);
      expect(source.importedPhoto, isNull);

      controller.importPhoto();

      expect(controller.state.currentSample, isNull,
          reason: 'no staged photo → nothing sampled');
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
