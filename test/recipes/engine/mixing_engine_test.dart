import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';

const _white = Paint(
  id: 'tw',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
);
const _ochre = Paint(
  id: 'yo',
  name: 'Yellow Ochre',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 48),
);
const _predicted = ColorCoordinates(lightness: 62, a: 8, b: 30);

void main() {
  group('MixOptions', () {
    test('defaults encode the D-decisions', () {
      const opts = MixOptions();
      expect(opts.maxPaints, 4);
      expect(opts.topK, 5);
      expect(opts.gamutThreshold, 5.0);
      expect(opts.traceThreshold, 0.02);
    });

    test('equal when every field matches; unequal per field', () {
      const base = MixOptions();
      expect(base, equals(const MixOptions()));
      expect(base.hashCode, equals(const MixOptions().hashCode));
      expect(base, isNot(equals(const MixOptions(maxPaints: 3))));
      expect(base, isNot(equals(const MixOptions(topK: 4))));
      expect(base, isNot(equals(const MixOptions(gamutThreshold: 6))));
      expect(base, isNot(equals(const MixOptions(traceThreshold: 0.05))));
      // ignore: unrelated_type_equality_checks
      expect(base == 'nope', isFalse);
    });

    test('toString reports the knobs', () {
      expect(
        const MixOptions().toString(),
        'MixOptions(maxPaints 4, topK 5, gamut 5.0, trace 0.02)',
      );
    });

    test('constructs at runtime (covers the const constructor line)', () {
      // ignore: prefer_const_constructors
      expect(MixOptions(), isA<MixOptions>());
    });
  });

  group('RecipeComponent', () {
    const base = RecipeComponent(paint: _ochre, partsFraction: 0.75);

    test('defaults isTrace false and techniqueNote null', () {
      expect(base.isTrace, isFalse);
      expect(base.techniqueNote, isNull);
    });

    test('equal when every field matches; unequal per field', () {
      expect(
        base,
        equals(const RecipeComponent(paint: _ochre, partsFraction: 0.75)),
      );
      expect(
        base.hashCode,
        equals(const RecipeComponent(paint: _ochre, partsFraction: 0.75).hashCode),
      );
      expect(
        base,
        isNot(equals(const RecipeComponent(paint: _white, partsFraction: 0.75))),
      );
      expect(
        base,
        isNot(equals(const RecipeComponent(paint: _ochre, partsFraction: 0.5))),
      );
      expect(
        base,
        isNot(equals(const RecipeComponent(
          paint: _ochre,
          partsFraction: 0.75,
          isTrace: true,
        ))),
      );
      expect(
        base,
        isNot(equals(const RecipeComponent(
          paint: _ochre,
          partsFraction: 0.75,
          techniqueNote: 'glaze it in',
        ))),
      );
      // ignore: unrelated_type_equality_checks
      expect(base == 'nope', isFalse);
    });

    test('toString omits the trace tag for a measured part', () {
      expect(base.toString(), 'RecipeComponent(Yellow Ochre 75.0%)');
    });

    test('toString marks a trace component', () {
      const trace = RecipeComponent(
        paint: _white,
        partsFraction: 0.01,
        isTrace: true,
        techniqueNote: 'a touch on a dry brush',
      );
      expect(trace.toString(), 'RecipeComponent(Titanium White 1.0%, trace)');
    });

    test('constructs at runtime (covers the const constructor line)', () {
      // ignore: prefer_const_constructors
      expect(RecipeComponent(paint: _ochre, partsFraction: 1), isA<RecipeComponent>());
    });
  });

  group('Recipe', () {
    const base = Recipe(
      medium: PaintMedium.acrylic,
      components: [
        RecipeComponent(paint: _ochre, partsFraction: 0.75),
        RecipeComponent(paint: _white, partsFraction: 0.25),
      ],
      predictedColor: _predicted,
      deltaE00: 1.2,
    );

    test('defaults verdict null and the flags false', () {
      expect(base.verdict, isNull);
      expect(base.outOfGamut, isFalse);
      expect(base.muddying, isFalse);
    });

    test('equal when every field matches', () {
      const same = Recipe(
        medium: PaintMedium.acrylic,
        components: [
          RecipeComponent(paint: _ochre, partsFraction: 0.75),
          RecipeComponent(paint: _white, partsFraction: 0.25),
        ],
        predictedColor: _predicted,
        deltaE00: 1.2,
      );
      expect(base, equals(same));
      expect(base.hashCode, equals(same.hashCode));
    });

    test('unequal when the medium differs', () {
      expect(
        base,
        isNot(equals(const Recipe(
          medium: PaintMedium.oil,
          components: [
            RecipeComponent(paint: _ochre, partsFraction: 0.75),
            RecipeComponent(paint: _white, partsFraction: 0.25),
          ],
          predictedColor: _predicted,
          deltaE00: 1.2,
        ))),
      );
    });

    test('unequal when the components differ', () {
      expect(
        base,
        isNot(equals(const Recipe(
          medium: PaintMedium.acrylic,
          components: [RecipeComponent(paint: _ochre, partsFraction: 1)],
          predictedColor: _predicted,
          deltaE00: 1.2,
        ))),
      );
    });

    test('unequal when the predicted colour differs', () {
      expect(
        base,
        isNot(equals(const Recipe(
          medium: PaintMedium.acrylic,
          components: [
            RecipeComponent(paint: _ochre, partsFraction: 0.75),
            RecipeComponent(paint: _white, partsFraction: 0.25),
          ],
          predictedColor: ColorCoordinates(lightness: 1, a: 2, b: 3),
          deltaE00: 1.2,
        ))),
      );
    });

    test('unequal when the delta-E differs', () {
      expect(
        base,
        isNot(equals(const Recipe(
          medium: PaintMedium.acrylic,
          components: [
            RecipeComponent(paint: _ochre, partsFraction: 0.75),
            RecipeComponent(paint: _white, partsFraction: 0.25),
          ],
          predictedColor: _predicted,
          deltaE00: 9.9,
        ))),
      );
    });

    test('unequal when the verdict differs', () {
      expect(
        base,
        isNot(equals(const Recipe(
          medium: PaintMedium.acrylic,
          components: [
            RecipeComponent(paint: _ochre, partsFraction: 0.75),
            RecipeComponent(paint: _white, partsFraction: 0.25),
          ],
          predictedColor: _predicted,
          deltaE00: 1.2,
          verdict: 'very close',
        ))),
      );
    });

    test('unequal when the out-of-gamut flag differs', () {
      expect(
        base,
        isNot(equals(const Recipe(
          medium: PaintMedium.acrylic,
          components: [
            RecipeComponent(paint: _ochre, partsFraction: 0.75),
            RecipeComponent(paint: _white, partsFraction: 0.25),
          ],
          predictedColor: _predicted,
          deltaE00: 1.2,
          outOfGamut: true,
        ))),
      );
    });

    test('unequal when the muddying flag differs', () {
      expect(
        base,
        isNot(equals(const Recipe(
          medium: PaintMedium.acrylic,
          components: [
            RecipeComponent(paint: _ochre, partsFraction: 0.75),
            RecipeComponent(paint: _white, partsFraction: 0.25),
          ],
          predictedColor: _predicted,
          deltaE00: 1.2,
          muddying: true,
        ))),
      );
    });

    test('unequal to a non-Recipe object', () {
      // ignore: unrelated_type_equality_checks
      expect(base == 'nope', isFalse);
    });

    test('toString omits verdict and the flags when unset', () {
      expect(base.toString(), 'Recipe(acrylic, 2 paints, ΔE00 1.2)');
    });

    test('toString reports the verdict and the flags when set', () {
      const flagged = Recipe(
        medium: PaintMedium.oil,
        components: [RecipeComponent(paint: _ochre, partsFraction: 1)],
        predictedColor: _predicted,
        deltaE00: 7.4,
        verdict: 'noticeably off',
        outOfGamut: true,
        muddying: true,
      );
      expect(
        flagged.toString(),
        'Recipe(oil, 1 paints, ΔE00 7.4 noticeably off, out-of-gamut, muddying)',
      );
    });

    test('constructs at runtime (covers the const constructor line)', () {
      // ignore: prefer_const_constructors
      final recipe = Recipe(
        medium: PaintMedium.acrylic,
        components: const [RecipeComponent(paint: _ochre, partsFraction: 1)],
        predictedColor: _predicted,
        deltaE00: 1.2,
      );
      expect(recipe, isA<Recipe>());
    });

    test('withPredictedColor replaces only the colour (AC-10 re-render)', () {
      const flagged = Recipe(
        medium: PaintMedium.oil,
        components: [RecipeComponent(paint: _ochre, partsFraction: 1)],
        predictedColor: _predicted,
        deltaE00: 7.4,
        verdict: 'noticeably off',
        outOfGamut: true,
        muddying: true,
      );
      const dry = ColorCoordinates(lightness: 41, a: 2, b: 19);
      final rendered = flagged.withPredictedColor(dry);
      expect(rendered.predictedColor, dry);
      // Every other field is carried unchanged — the parts, distance and flags
      // do not move with the wet/dry mode.
      expect(rendered.medium, flagged.medium);
      expect(rendered.components, flagged.components);
      expect(rendered.deltaE00, flagged.deltaE00);
      expect(rendered.verdict, flagged.verdict);
      expect(rendered.outOfGamut, flagged.outOfGamut);
      expect(rendered.muddying, flagged.muddying);
    });
  });
}
