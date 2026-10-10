import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
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

void main() {
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

    group('actions are inert in the LOOP-2 shell', () {
      test('checkMix throws until LOOP-3', () {
        expect(() => _controller().checkMix(), throwsUnimplementedError);
      });
      test('rephotograph throws until LOOP-5', () {
        expect(() => _controller().rephotograph(), throwsUnimplementedError);
      });
      test('speakCorrection throws until LOOP-4', () {
        expect(() => _controller().speakCorrection(), throwsUnimplementedError);
      });
      test('saveConfirmed throws until LOOP-6', () {
        expect(() => _controller().saveConfirmed(), throwsUnimplementedError);
      });
    });
  });
}
