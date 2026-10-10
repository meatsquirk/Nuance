import 'package:flutter_test/flutter_test.dart';
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
  group('SubtractiveCorrectionEngine (stub)', () {
    const engine = SubtractiveCorrectionEngine();

    test('is a CorrectionEngine', () {
      expect(engine, isA<CorrectionEngine>());
    });

    test('difference is inert — zero distance, empty readings, not in tolerance',
        () {
      final difference = engine.difference(_mixed, _target);
      expect(difference.deltaE00, 0);
      expect(difference.verdict, isEmpty);
      expect(difference.valueReading, isEmpty);
      expect(difference.hueReading, isEmpty);
      expect(difference.withinTolerance, isFalse);
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
