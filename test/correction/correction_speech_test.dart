import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/correction/correction_speech.dart';
import 'package:paint_color_assistant/correction/correction_state.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';

const _target = Sample(
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
const _ochre = Paint(
  id: 'py43',
  name: 'Yellow Ochre',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
);
const _mix = Recipe(
  medium: PaintMedium.acrylic,
  components: [RecipeComponent(paint: _white, partsFraction: 1)],
  predictedColor: ColorCoordinates(lightness: 96, a: 0, b: 2),
  deltaE00: 1.2,
);
const _difference = Difference(
  deltaE00: 7.25,
  verdict: 'noticeably off',
  valueReading: 'too dark by 6',
  hueReading: 'shifted toward green',
  withinTolerance: false,
);

/// A checked state carrying [_difference] and [correction] (target/mix fixed).
CorrectionState _checked(Correction? correction) => const CorrectionState(
      target: _target,
      currentMix: _mix,
      mixedSwatch: _target, // any measured swatch — marks the mix as checked
      difference: _difference,
    ).copyWithCorrection(correction);

/// Local helper: [CorrectionState] has no copyWith, so rebuild it with the given
/// correction (the fields the speech reads are fixed above).
extension on CorrectionState {
  CorrectionState copyWithCorrection(Correction? correction) => CorrectionState(
        target: target,
        currentMix: currentMix,
        mixedSwatch: mixedSwatch,
        difference: difference,
        correction: correction,
      );
}

void main() {
  group('correctionSpeech', () {
    test('is null before the mix is checked (no difference)', () {
      const state = CorrectionState(target: _target, currentMix: _mix);
      expect(correctionSpeech(state), isNull);
    });

    test('states the difference verdict, distance and value-leading decomposition',
        () {
      final spoken = correctionSpeech(_checked(const Correction()))!;
      // Value leads hue (D-5), and the distance is rounded to one decimal.
      expect(spoken, contains('noticeably off'));
      expect(spoken, contains('delta-E00 7.3'));
      final valueAt = spoken.indexOf('too dark by 6');
      final hueAt = spoken.indexOf('shifted toward green');
      expect(valueAt, greaterThanOrEqualTo(0));
      expect(hueAt, greaterThan(valueAt),
          reason: 'the value reading leads the hue reading');
    });

    test('states "No paints to add." for an empty correction (AC-6)', () {
      expect(correctionSpeech(_checked(const Correction())),
          contains('No paints to add.'));
    });

    test('states "No paints to add." when the correction is null', () {
      // A difference with no correction computed still speaks, saying there is
      // nothing to add rather than returning null (null means "not checked").
      expect(correctionSpeech(_checked(null)), contains('No paints to add.'));
    });

    test('names each measured paint to add with its amount (AC-4)', () {
      final spoken = correctionSpeech(_checked(const Correction(additions: [
        CorrectionAddition(paint: _white, parts: 1),
        CorrectionAddition(paint: _ochre, parts: 0.5),
      ])))!;
      expect(spoken, contains('Add to your mix:'));
      // parts == 1.0 → singular "1 part"; a fractional amount → plural "parts".
      expect(spoken, contains('add about 1 part of Titanium White.'));
      expect(spoken, contains('add about 0.5 parts of Yellow Ochre.'));
      expect(spoken, isNot(contains('a touch of')));
    });

    test('speaks a trace addition as "a touch of" (AC-5)', () {
      final spoken = correctionSpeech(_checked(const Correction(additions: [
        CorrectionAddition(paint: _ochre, parts: 0.01, isTrace: true),
      ])))!;
      expect(spoken, contains('a touch of Yellow Ochre.'));
      expect(spoken, isNot(contains('add about')));
    });
  });
}
