import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/compare/difference.dart' show deltaE00;
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/correction/correction_controller.dart';
import 'package:paint_color_assistant/correction/correction_speech.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
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

// Fixtures for the CORRECT-3 correction-over-palette test: the owned paints, the
// Deep-Olive target and the current mix with room for the search to perturb.
const _ochre = Paint(
  id: 'py43',
  name: 'Yellow Ochre',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
);
const _black = Paint(
  id: 'pbk9',
  name: 'Ivory Black',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 16, a: 0, b: 1),
);
const _correctTarget = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -1.2561, b: 23.9671),
  provenance: Provenance(ProvenanceTier.estimated),
);
const _correctPalette =
    PaintPalette(name: 'My paints', paints: [_white, _ochre, _black]);
const _correctMix = Recipe(
  medium: PaintMedium.acrylic,
  components: [
    RecipeComponent(paint: _ochre, partsFraction: 0.55),
    RecipeComponent(paint: _black, partsFraction: 0.25),
    RecipeComponent(paint: _white, partsFraction: 0.20),
  ],
  predictedColor: ColorCoordinates(lightness: 31, a: 0, b: 8),
  deltaE00: 12,
);

/// An inert [CaptureSource] for the LOOP-2 shell: the controller never drives
/// it yet, so every member throws rather than pretend to capture.
class _InertCaptureSource implements CaptureSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Records every utterance the controller speaks, so a speak action's output
/// (AC-7) can be asserted without a real speech backend.
class _RecordingSpeech implements Speech {
  final List<String> utterances = [];

  @override
  Future<void> speak(String utterance) async => utterances.add(utterance);
}

CorrectionController _controller({
  SampleSource? sampleSource,
  PaletteSource? paletteSource,
  Speech? speech,
}) =>
    CorrectionController(
      captureSource: _InertCaptureSource(),
      target: _olive,
      currentMix: _mix,
      paletteSource: paletteSource ?? const InMemoryPaletteSource(),
      correctionEngine: const SubtractiveCorrectionEngine(),
      sampleSource: sampleSource ?? const InMemorySampleSource(),
      speech: speech ?? const NoopSpeech(),
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
        expect(controller.state.correction, isNotNull,
            reason: 'CORRECT-3: the check also reads the concrete correction');
        expect(controller.state.correction!.isEmpty, isTrue,
            reason: 'with no palette (this controller) there are no paints to '
                'add, so the correction is empty — not null');
        expect(notified, greaterThanOrEqualTo(1),
            reason: 'the check notifies the screen and the read endpoint');
      });

      test(
          'reads the concrete correction over the selected palette, delegating '
          'to the engine (CORRECT-3)', () async {
        final controller = CorrectionController(
          captureSource: SoftwareCaptureSource(_offScene),
          target: _correctTarget,
          currentMix: _correctMix,
          paletteSource:
              const InMemoryPaletteSource(catalogue: [_correctPalette]),
          correctionEngine: const SubtractiveCorrectionEngine(),
        );

        await controller.checkMix();

        final swatch = controller.state.mixedSwatch;
        expect(swatch, isNotNull);
        final correction = controller.state.correction;
        expect(correction, isNotNull,
            reason: 'the check reads the correction over the palette');
        expect(
          correction,
          const SubtractiveCorrectionEngine()
              .correct(swatch!, _correctTarget, _correctMix, _correctPalette),
          reason: 'the controller delegates the correction to the engine — it '
              'does not compute the colour maths itself (D-2/D-3)',
        );
        expect(correction!.isEmpty, isFalse,
            reason: 'an off mix over a real palette yields a correction');
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
            reason: 'a fresh photo clears any prior correction — rephotograph '
                'reads the difference only (CORRECT-3 wired the correction into '
                'checkMix; unifying re-photograph is a follow-up)');
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

    group('speakCorrection (LOOP-4, AC-7)', () {
      test(
          'speaks the checked difference and each paint to add as one utterance, '
          'built through the speech builder', () async {
        final speech = _RecordingSpeech();
        final controller = CorrectionController(
          captureSource: SoftwareCaptureSource(_offScene),
          target: _correctTarget,
          currentMix: _correctMix,
          paletteSource:
              const InMemoryPaletteSource(catalogue: [_correctPalette]),
          correctionEngine: const SubtractiveCorrectionEngine(),
          speech: speech,
        );
        await controller.checkMix();
        final difference = controller.state.difference;
        final correction = controller.state.correction;
        expect(difference, isNotNull);
        expect(correction, isNotNull);
        expect(correction!.isEmpty, isFalse,
            reason: 'an off mix over a real palette yields paints to add');

        await controller.speakCorrection();

        expect(speech.utterances, hasLength(1),
            reason: 'the correction is spoken as exactly one utterance');
        final spoken = speech.utterances.single;
        expect(spoken, correctionSpeech(controller.state),
            reason: 'the controller speaks exactly the builder output — it does '
                'not phrase the utterance itself (D-2/D-3)');
        expect(spoken, contains(difference!.verdict),
            reason: 'the utterance states the difference verdict');
        for (final addition in correction.additions) {
          expect(spoken, contains(addition.paint.name),
              reason: 'the utterance names each paint to add '
                  '(${addition.paint.name})');
        }
      });

      test('is inert before the mix is checked — nothing to speak', () async {
        final speech = _RecordingSpeech();
        final controller = _controller(speech: speech);

        await controller.speakCorrection();

        expect(controller.state.hasChecked, isFalse);
        expect(speech.utterances, isEmpty,
            reason: 'with no reading yet there is nothing to speak');
      });
    });

    group('saveConfirmed (LOOP-6, AC-9)', () {
      CorrectionController saveController(CaptureSource source) =>
          CorrectionController(
            captureSource: source,
            target: _correctTarget, // starts estimated, so a confirm is real
            currentMix: _mix,
            paletteSource: const InMemoryPaletteSource(),
            correctionEngine: const SubtractiveCorrectionEngine(),
          );

      test(
          'promotes the checked target to Confirmed, records the note, appends '
          'the measured swatch as evidence and persists it', () async {
        final controller = saveController(SoftwareCaptureSource(_offScene));
        await controller.checkMix();
        final swatch = controller.state.mixedSwatch;
        expect(swatch, isNotNull, reason: 'the check photographs the swatch');
        expect(_correctTarget.provenance.tier,
            isNot(ProvenanceTier.confirmed),
            reason: 'the target starts pre-confirmed, so the promotion is real');
        var notified = 0;
        controller.addListener(() => notified++);

        controller.saveConfirmed();

        final saved = controller.state.savedProvenance;
        expect(saved, isNotNull,
            reason: 'saving records the promoted provenance');
        expect(saved!.tier, ProvenanceTier.confirmed,
            reason: 'promoted to the Confirmed tier (AC-9)');
        expect(saved.label, 'Confirmed',
            reason: 'the shared tier label is unchanged (G-4(d))');
        expect(saved.note, isNotNull,
            reason: 'a note records how it was confirmed');
        expect(saved.note, contains('you measured this'),
            reason: 'the painter-facing phrasing rides the note (G-4(d))');
        expect(saved.note, contains('photograph'),
            reason: 'the note records it was confirmed after the painter '
                'photographed their own swatch (D-8)');
        final held = controller.savedSamples
            .where((s) => s.name == _correctTarget.name)
            .toList();
        expect(held, hasLength(1),
            reason: 'the confirmed sample is exposed in the saved catalogue');
        expect(held.single.provenance.tier, ProvenanceTier.confirmed,
            reason: 'the persisted sample carries the Confirmed tier');
        expect(held.single.evidence.map((e) => e.coordinates),
            contains(swatch!.coordinates),
            reason: 'the measured swatch is appended as evidence (append-only)');
        expect(notified, greaterThanOrEqualTo(1),
            reason: 'the save notifies the screen and the read endpoint');
      });

      test(
          'honest-provenance guard: a save before any check promotes nothing',
          () async {
        final controller = saveController(SoftwareCaptureSource(_offScene));
        var notified = 0;
        controller.addListener(() => notified++);

        controller.saveConfirmed(); // no check first

        expect(controller.state.savedProvenance, isNull,
            reason: 'no value graduates to Confirmed without the painter\'s own '
                'measured swatch (D-8)');
        expect(controller.state.hasChecked, isFalse);
        expect(
            controller.savedSamples
                .where((s) => s.provenance.tier == ProvenanceTier.confirmed),
            isEmpty,
            reason: 'nothing is persisted when there is no swatch to confirm');
        expect(notified, 0, reason: 'an inert save does not notify');
      });

      test('leaves the injected read-only catalogue untouched', () async {
        final controller = CorrectionController(
          captureSource: SoftwareCaptureSource(_offScene),
          target: _correctTarget,
          currentMix: _mix,
          paletteSource: const InMemoryPaletteSource(),
          correctionEngine: const SubtractiveCorrectionEngine(),
          sampleSource: const InMemorySampleSource(samples: [_olive]),
        );
        await controller.checkMix();

        controller.saveConfirmed();

        expect(controller.savedSamples, hasLength(2),
            reason: 'the seeded sample plus the newly confirmed one');
        expect(controller.savedSamples.first, _olive,
            reason: 'the injected catalogue is read first, unchanged');
      });
    });
  });
}
