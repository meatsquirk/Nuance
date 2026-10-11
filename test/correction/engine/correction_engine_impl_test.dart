import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/difference.dart' show deltaE00;
import 'package:paint_color_assistant/correction/engine/correction_engine.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';

const _white = Paint(
  id: 'tw',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
);

const _mixed = Sample(
  coordinates: ColorCoordinates(lightness: 36, a: -4, b: 18),
  provenance: Provenance(ProvenanceTier.measured),
);
const _target = Sample(
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _palette = PaintPalette(name: 'Studio', paints: [_white]);
const _currentMix = Recipe(
  medium: PaintMedium.acrylic,
  components: [RecipeComponent(paint: _white, partsFraction: 1)],
  predictedColor: ColorCoordinates(lightness: 36, a: -4, b: 18),
  deltaE00: 6,
);

void main() {
  group('SubtractiveCorrectionEngine', () {
    const engine = SubtractiveCorrectionEngine();

    test('is a CorrectionEngine', () {
      expect(engine, isA<CorrectionEngine>());
    });

    test(
        'difference reports the real ΔE00 distance (LOOP-3); verdict / readings '
        'still empty until CORRECT-2 / CORRECT-4', () {
      final difference = engine.difference(_mixed, _target);
      expect(
        difference.deltaE00,
        deltaE00(_mixed.coordinates, _target.coordinates),
        reason: 'the engine delegates its distance to the shipped bs-03 '
            'deltaE00 (D-2), not a hand-rolled copy',
      );
      expect(difference.deltaE00, greaterThan(0),
          reason: 'a real off-reading has a non-zero distance');
      expect(difference.verdict, isEmpty); // CORRECT-2
      expect(difference.valueReading, isEmpty); // CORRECT-2
      expect(difference.hueReading, isEmpty); // CORRECT-2
      expect(difference.withinTolerance, isFalse); // CORRECT-4
    });

    test('correct returns an empty correction', () {
      final correction =
          engine.correct(_mixed, _target, _currentMix, _palette);
      expect(correction.isEmpty, isTrue);
      expect(correction.additions, isEmpty);
    });

    test('constructs at runtime (covers the const constructor line)', () {
      // ignore: prefer_const_constructors
      expect(SubtractiveCorrectionEngine(), isA<SubtractiveCorrectionEngine>());
    });
  });
}
