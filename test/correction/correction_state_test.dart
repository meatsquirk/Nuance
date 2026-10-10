import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/correction/correction_state.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';

const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _unnamed = Sample(
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _swatch = Sample(
  name: 'My mix',
  coordinates: ColorCoordinates(lightness: 36, a: -4, b: 18),
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
const _difference = Difference(
  deltaE00: 6,
  verdict: 'noticeably off',
  valueReading: 'too dark by 6',
  hueReading: 'shifted toward green',
  withinTolerance: false,
);
const _correction = Correction(
  additions: [CorrectionAddition(paint: _white, parts: 1)],
);
const _confirmed =
    Provenance(ProvenanceTier.confirmed, note: 'you measured this');

void main() {
  group('CorrectionState', () {
    test('initial state: target + mix set, nothing checked or saved', () {
      const state = CorrectionState(target: _olive, currentMix: _mix);
      expect(state.target, _olive);
      expect(state.currentMix, _mix);
      expect(state.mixedSwatch, isNull);
      expect(state.difference, isNull);
      expect(state.correction, isNull);
      expect(state.savedProvenance, isNull);
      expect(state.hasChecked, isFalse);
    });

    test('hasChecked is true once a swatch is photographed', () {
      const state = CorrectionState(
        target: _olive,
        currentMix: _mix,
        mixedSwatch: _swatch,
      );
      expect(state.hasChecked, isTrue);
    });

    test('carries the difference, correction and saved provenance', () {
      const state = CorrectionState(
        target: _olive,
        currentMix: _mix,
        mixedSwatch: _swatch,
        difference: _difference,
        correction: _correction,
        savedProvenance: _confirmed,
      );
      expect(state.difference, _difference);
      expect(state.correction, _correction);
      expect(state.savedProvenance, _confirmed);
    });

    test('value equality over every field', () {
      const a = CorrectionState(
        target: _olive,
        currentMix: _mix,
        mixedSwatch: _swatch,
        difference: _difference,
        correction: _correction,
        savedProvenance: _confirmed,
      );
      const b = CorrectionState(
        target: _olive,
        currentMix: _mix,
        mixedSwatch: _swatch,
        difference: _difference,
        correction: _correction,
        savedProvenance: _confirmed,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any field differs', () {
      const base = CorrectionState(target: _olive, currentMix: _mix);
      expect(
        base,
        isNot(const CorrectionState(target: _swatch, currentMix: _mix)),
      );
      expect(
        base,
        isNot(const CorrectionState(
          target: _olive,
          currentMix: _mix,
          mixedSwatch: _swatch,
        )),
      );
      expect(base, isNot('not a state'));
    });

    test('toString reports checked/unchecked and the saved label', () {
      expect(
        const CorrectionState(target: _olive, currentMix: _mix).toString(),
        'CorrectionState(target: Deep Olive Green, unchecked)',
      );
      expect(
        const CorrectionState(
          target: _unnamed,
          currentMix: _mix,
          mixedSwatch: _swatch,
          savedProvenance: _confirmed,
        ).toString(),
        contains('(unnamed)'),
      );
      expect(
        const CorrectionState(
          target: _olive,
          currentMix: _mix,
          mixedSwatch: _swatch,
          savedProvenance: _confirmed,
        ).toString(),
        'CorrectionState(target: Deep Olive Green, checked, '
        'saved ${_confirmed.label})',
      );
    });
  });
}
