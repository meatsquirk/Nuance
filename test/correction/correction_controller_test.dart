import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/compare/difference.dart' show deltaE00;
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/correction/correction_controller.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
);
const _mix = Recipe(
  medium: PaintMedium.acrylic,
  components: [RecipeComponent(paint: _white, partsFraction: 1)],
  predictedColor: ColorCoordinates(lightness: 96, a: 0, b: 2),
  deltaE00: 1.2,
);

/// An inert [CaptureSource] for the LOOP-2 shell: the controller never drives
/// it yet, so every member throws rather than pretend to capture.
class _InertCaptureSource implements CaptureSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

CorrectionController _controller({
  SampleSource? sampleSource,
  PaletteSource? paletteSource,
}) =>
    CorrectionController(
      captureSource: _InertCaptureSource(),
      target: _olive,
      currentMix: _mix,
      paletteSource: paletteSource ?? const InMemoryPaletteSource(),
      correctionEngine: const SubtractiveCorrectionEngine(),
      sampleSource: sampleSource ?? const InMemorySampleSource(),
    );

/// An off-reading scene whose ground truth sits clear of [_olive] (too dark and
/// shifted), so a checked swatch reads a real, non-zero distance from the target.
const _offScene = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 36, a: -12.2, b: 27.4),
);

/// A corrected-mix scene sitting much nearer [_olive] than [_offScene], so a
/// re-photograph of it reads a smaller distance (the painter adjusted the mix).
const _closerScene = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 41, a: -6, b: 21),
);

/// A [SoftwareCaptureSource] whose live scene the test swaps between captures,
/// so a re-photograph reads a different swatch than the first check (AC-8) —
/// the unit-test analogue of the acceptance suite's `FakeCaptureSource`.
class _RephotographSource extends SoftwareCaptureSource {
  _RephotographSource(super.scene);

  SceneSpec? _next;

  /// Stages [scene] for the *next* capture, leaving earlier captures untouched.
  void rephotographAs(SceneSpec scene) => _next = scene;

  @override
  Stream<Frame> get frames =>
      _next == null ? super.frames : SoftwareCaptureSource(_next!).frames;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CorrectionController', () {
    test('holds the injected seams', () {
      final controller = _controller();
      expect(controller.captureSource, isA<CaptureSource>());
      expect(controller.paletteSource, isA<InMemoryPaletteSource>());
      expect(controller.correctionEngine, isA<SubtractiveCorrectionEngine>());
      expect(controller.mixingEngine, isA<SubtractiveMixingEngine>());
      expect(controller.sampleSource, isA<InMemorySampleSource>());
      expect(controller.speech, isA<NoopSpeech>());
      expect(controller.router, isNotNull);
    });

    test('initial state: target + mix set, nothing checked or saved', () {
      final state = _controller().state;
      expect(state.target, _olive);
      expect(state.currentMix, _mix);
      expect(state.mixedSwatch, isNull);
      expect(state.difference, isNull);
      expect(state.correction, isNull);
      expect(state.savedProvenance, isNull);
      expect(state.hasChecked, isFalse);
    });

    test('savedSamples delegates to the sample source', () {
      final controller = _controller(
        sampleSource: const InMemorySampleSource(samples: [_olive]),
      );
      expect(controller.savedSamples, [_olive]);
    });

    group('checkMix (LOOP-3, AC-1)', () {
      CorrectionController checkController(CaptureSource source) =>
          CorrectionController(
            captureSource: source,
            target: _olive,
            currentMix: _mix,
            paletteSource: const InMemoryPaletteSource(),
            correctionEngine: const SubtractiveCorrectionEngine(),
          );

      test(
          'photographs the swatch as a measured sample and reads its difference '
          'from the target', () async {
        final controller = checkController(SoftwareCaptureSource(_offScene));
        var notified = 0;
        controller.addListener(() => notified++);

        await controller.checkMix();

        final swatch = controller.state.mixedSwatch;
        expect(swatch, isNotNull,
            reason: 'the check photographs the swatch');
        expect(swatch!.provenance.tier, ProvenanceTier.measured,
            reason: 'a photographed swatch is a measured reading');
        expect(controller.state.hasChecked, isTrue);
        final difference = controller.state.difference;
        expect(difference, isNotNull,
            reason: 'the swatch is compared to the target');
        expect(difference!.deltaE00,
            deltaE00(swatch.coordinates, _olive.coordinates),
            reason: 'the stated distance is the swatch→target ΔE00, read '
                'through the engine');
        expect(difference.deltaE00, greaterThan(0),
            reason: 'an off-reading is a real, non-zero distance');
        expect(controller.state.correction, isNull,
            reason: 'LOOP-3 reads the difference only; CORRECT-3 adds the '
                'concrete correction');
        expect(notified, greaterThanOrEqualTo(1),
            reason: 'the check notifies the screen and the read endpoint');
      });

      test('leaves the state unchecked when the feed yields no frame', () async {
        final controller = checkController(
          SoftwareCaptureSource(const SceneSpec(
            groundTruth: ColorCoordinates(lightness: 36, a: -12.2, b: 27.4),
            frames: [],
          )),
        );

        await controller.checkMix();

        expect(controller.state.mixedSwatch, isNull);
        expect(controller.state.difference, isNull);
        expect(controller.state.hasChecked, isFalse);
      });
    });

    group('rephotograph (LOOP-5, AC-8)', () {
      CorrectionController sourceController(CaptureSource source) =>
          CorrectionController(
            captureSource: source,
            target: _olive,
            currentMix: _mix,
            paletteSource: const InMemoryPaletteSource(),
            correctionEngine: const SubtractiveCorrectionEngine(),
          );

      test(
          're-measures a fresh swatch and re-reads the difference, replacing the '
          'prior reading with the new scene', () async {
        final source = _RephotographSource(_offScene);
        final controller = sourceController(source);
        await controller.checkMix();
        final firstSwatch = controller.state.mixedSwatch;
        final firstDelta = controller.state.difference!.deltaE00;
        expect(firstSwatch, isNotNull, reason: 'the first check photographs it');

        // The painter adjusts the mix; the swatch now reads closer to target.
        source.rephotographAs(_closerScene);
        var notified = 0;
        controller.addListener(() => notified++);

        await controller.rephotograph();

        final swatch = controller.state.mixedSwatch;
        expect(swatch, isNotNull,
            reason: 'the re-photograph re-measures the swatch');
        expect(swatch!.provenance.tier, ProvenanceTier.measured,
            reason: 'a re-photographed swatch is a measured reading');
        expect(swatch.coordinates, isNot(firstSwatch!.coordinates),
            reason: 'the re-measured swatch is the new scene, not the first');
        final difference = controller.state.difference;
        expect(difference, isNotNull,
            reason: 'the re-photograph re-compares to the target');
        expect(difference!.deltaE00,
            deltaE00(swatch.coordinates, _olive.coordinates),
            reason: 'the re-checked distance is read through the engine');
        expect(difference.deltaE00, lessThan(firstDelta),
            reason: 'the closer swatch reads a smaller distance (AC-8)');
        expect(controller.state.correction, isNull,
            reason: 'a fresh photo clears any prior correction until CORRECT-3');
        expect(notified, greaterThanOrEqualTo(1),
            reason: 're-photograph notifies the screen and the read endpoint');
      });

      test('leaves the state untouched when the feed yields no frame', () async {
        final controller = sourceController(
          _RephotographSource(const SceneSpec(
            groundTruth: ColorCoordinates(lightness: 36, a: -12.2, b: 27.4),
            frames: [],
          )),
        );

        await controller.rephotograph();

        expect(controller.state.mixedSwatch, isNull);
        expect(controller.state.difference, isNull);
        expect(controller.state.hasChecked, isFalse);
      });
    });

    group('actions still inert until their phase', () {
      test('speakCorrection throws until LOOP-4', () {
        expect(() => _controller().speakCorrection(), throwsUnimplementedError);
      });
      test('saveConfirmed throws until LOOP-6', () {
        expect(() => _controller().saveConfirmed(), throwsUnimplementedError);
      });
    });
  });
}
