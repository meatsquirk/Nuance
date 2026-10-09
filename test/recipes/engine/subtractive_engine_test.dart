import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/difference.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';

// Masstone CIELAB fixtures mirror the acceptance palette so the unit tests
// exercise the same subtractive behaviour the ACs assert.
const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
);
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
const _ultramarine = Paint(
  id: 'pb29',
  name: 'Ultramarine Blue',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 30, a: 18, b: -52),
);
// Oil paints so a mixed-medium palette can prove recipes never span media.
const _whiteOil = Paint(
  id: 'pw6-oil',
  name: 'Titanium White',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
);
const _ochreOil = Paint(
  id: 'py43-oil',
  name: 'Yellow Ochre',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
);

const _myPaints = PaintPalette(
  name: 'My paints',
  paints: [_white, _ochre, _black, _ultramarine],
);

const _target = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -8.65, b: 26.63),
  provenance: Provenance(ProvenanceTier.measured),
);

bool _inLabRange(ColorCoordinates c) =>
    c.lightness > 0 && c.lightness <= 100 && c.a.abs() < 150 && c.b.abs() < 150;

void main() {
  const engine = SubtractiveMixingEngine();

  test('is a MixingEngine and const-canonicalises', () {
    expect(engine, isA<MixingEngine>());
    expect(identical(engine, const SubtractiveMixingEngine()), isTrue);
    // A non-const construction runs the const constructor body at runtime (the
    // const-canonicalisation coverage quirk — master-plan Known flakes).
    // ignore: prefer_const_constructors
    expect(SubtractiveMixingEngine(), isA<SubtractiveMixingEngine>());
  });

  group('forward (wet prediction)', () {
    test('a single paint predicts (close to) its own masstone', () {
      final predicted = engine.forward({_ochre: 1.0});
      // The reflectance reconstruction renders back to the masstone (self-
      // consistent), so one paint reproduces itself within a small ΔE00.
      expect(deltaE00(predicted, _ochre.masstone), lessThan(1.0));
    });

    test('mixing a yellow and a blue darkens toward green (subtractive)', () {
      final mix = engine.forward({_ochre: 1.0, _ultramarine: 1.0});
      // Not a Lab average: the mix is darker than the lighter paint and its a*
      // sits below the yellow's (pulled toward green) — the subtractive sign of
      // K/S mixing, impossible under linear averaging.
      expect(mix.lightness, lessThan(_ochre.masstone.lightness));
      expect(mix.a, lessThan(_ochre.masstone.a));
      expect(_inLabRange(mix), isTrue);
    });

    test('volumes are ratios — scaling all parts leaves the colour unchanged',
        () {
      final a = engine.forward({_ochre: 1.0, _white: 1.0});
      final b = engine.forward({_ochre: 3.0, _white: 3.0});
      expect(deltaE00(a, b), lessThan(1e-6));
    });

    test('dry prediction is deferred to ENGINE-6', () {
      expect(() => engine.forward({_white: 1.0}, dry: true),
          throwsUnimplementedError);
    });

    test('an empty mix is rejected', () {
      expect(() => engine.forward(const {}), throwsArgumentError);
    });

    test('a negative part is rejected', () {
      expect(() => engine.forward({_white: -0.2, _ochre: 1.0}),
          throwsArgumentError);
    });

    test('a zero-volume mix is rejected', () {
      expect(() => engine.forward({_white: 0.0}), throwsArgumentError);
    });
  });

  group('inverse (palette-constrained solver)', () {
    test('an empty palette yields no recipes', () {
      expect(
        engine.inverse(
            _target, const PaintPalette(name: 'empty'), const MixOptions()),
        isEmpty,
      );
    });

    test('returns the top distinct recipes, best-first, within topK', () {
      final recipes = engine.inverse(_target, _myPaints, const MixOptions());

      expect(recipes.length, inInclusiveRange(3, 5));
      expect(recipes.length, lessThanOrEqualTo(const MixOptions().topK));

      // Ordered by ascending ΔE00 (ENGINE-2 ordering).
      for (var i = 1; i < recipes.length; i++) {
        expect(recipes[i - 1].deltaE00, lessThanOrEqualTo(recipes[i].deltaE00));
      }

      // Distinct by the set of paints each uses.
      final keys = recipes
          .map((r) =>
              (r.components.map((c) => c.paint.id).toList()..sort()).join('+'))
          .toList();
      expect(keys.toSet().length, keys.length);
    });

    test(
        'every recipe uses only palette paints, with positive parts summing to '
        'one (AC-3 / AC-4 properties)', () {
      final recipes = engine.inverse(_target, _myPaints, const MixOptions());
      final paletteIds = _myPaints.paints.map((p) => p.id).toSet();
      for (final recipe in recipes) {
        expect(recipe.components, isNotEmpty);
        expect(recipe.medium, PaintMedium.acrylic);
        var sum = 0.0;
        for (final c in recipe.components) {
          expect(paletteIds, contains(c.paint.id));
          expect(c.partsFraction, greaterThan(0));
          sum += c.partsFraction;
        }
        expect(sum, closeTo(1.0, 1e-9));
        expect(_inLabRange(recipe.predictedColor), isTrue);
        // ENGINE-3 (verdict) and ENGINE-5 (out-of-gamut) still leave these at
        // their defaults; `muddying` is now set by ENGINE-4 (see its group).
        expect(recipe.verdict, isNull);
        expect(recipe.outOfGamut, isFalse);
        // deltaE00 is the shipped metric over the recipe's own predicted colour.
        expect(recipe.deltaE00,
            closeTo(deltaE00(recipe.predictedColor, _target.coordinates), 1e-9));
      }
    });

    test('honours maxPaints and topK', () {
      final recipes = engine.inverse(
        _target,
        _myPaints,
        const MixOptions(maxPaints: 2, topK: 2),
      );
      expect(recipes.length, lessThanOrEqualTo(2));
      for (final recipe in recipes) {
        expect(recipe.components.length, lessThanOrEqualTo(2));
      }
    });

    test('a single-paint palette returns that one mix (fewer than topK)', () {
      final recipes = engine.inverse(
        _target,
        const PaintPalette(name: 'one', paints: [_white]),
        const MixOptions(),
      );
      expect(recipes, hasLength(1));
      expect(recipes.single.components.single.paint, _white);
      expect(recipes.single.components.single.partsFraction, closeTo(1.0, 1e-9));
    });

    test('recipes never span media', () {
      const mixed = PaintPalette(
        name: 'mixed media',
        paints: [_white, _ochre, _whiteOil, _ochreOil],
      );
      final recipes = engine.inverse(_target, mixed, const MixOptions());
      expect(recipes, isNotEmpty);
      for (final recipe in recipes) {
        final media = recipe.components.map((c) => c.paint.medium).toSet();
        expect(media, hasLength(1),
            reason: 'a recipe mixes paints of one medium only');
        expect(media.single, recipe.medium);
      }
    });

    test('is deterministic', () {
      final a = engine.inverse(_target, _myPaints, const MixOptions());
      final b = engine.inverse(_target, _myPaints, const MixOptions());
      expect(a, b);
    });
  });

  group('trace "a touch of" (ENGINE-4, AC-7 / D-12)', () {
    // A target whose best mix needs only a touch of Titanium White: the top
    // recipe over My paints is White ≈ 1.4% + Yellow Ochre + Ivory Black.
    const traceTarget = Sample(
      name: 'Deep Umber',
      coordinates: ColorCoordinates(lightness: 33, a: 0, b: 12),
      provenance: Provenance(ProvenanceTier.measured),
    );

    test(
        'a sub-threshold share is a trace with a static note; a measured share '
        'is not', () {
      const opts = MixOptions();
      final recipes = engine.inverse(traceTarget, _myPaints, opts);
      var sawTrace = false;
      var sawMeasured = false;
      for (final recipe in recipes) {
        for (final c in recipe.components) {
          if (c.partsFraction < opts.traceThreshold) {
            sawTrace = true;
            expect(c.isTrace, isTrue,
                reason: '${c.paint.name} at ${c.partsFraction} is a trace');
            expect(c.techniqueNote, isNotNull);
            expect(c.techniqueNote, isNotEmpty);
          } else {
            sawMeasured = true;
            expect(c.isTrace, isFalse);
            expect(c.techniqueNote, isNull);
          }
        }
      }
      expect(sawTrace, isTrue,
          reason: 'the target must yield a sub-2% component to exercise the rule');
      expect(sawMeasured, isTrue, reason: 'the non-trace control must be present');
    });

    test('the flag tracks MixOptions.traceThreshold — zero flags nothing', () {
      final recipes =
          engine.inverse(traceTarget, _myPaints, const MixOptions(traceThreshold: 0));
      for (final recipe in recipes) {
        for (final c in recipe.components) {
          expect(c.isTrace, isFalse);
          expect(c.techniqueNote, isNull);
        }
      }
    });

    test('a single-paint mix is never a trace (100% of one paint)', () {
      final recipes = engine.inverse(
        _target,
        const PaintPalette(name: 'one', paints: [_ochre]),
        const MixOptions(),
      );
      expect(recipes.single.components.single.isTrace, isFalse);
      expect(recipes.single.components.single.techniqueNote, isNull);
    });
  });

  group('muddying flag (ENGINE-4, AC-8 / D-9)', () {
    test('a warm + cool crossing is muddying; a single-temperature mix is not',
        () {
      final recipes = engine.inverse(_target, _myPaints, const MixOptions());
      // Deep Olive over My paints returns a Yellow Ochre (warm) + Ultramarine
      // (cool) crossing and clean single-temperature mixes.
      final crossing = recipes.where((r) =>
          r.components.any((c) => c.paint.id == _ochre.id) &&
          r.components.any((c) => c.paint.id == _ultramarine.id));
      final warmOnly = recipes.where((r) =>
          r.components.any((c) => c.paint.id == _ochre.id) &&
          r.components.every((c) => c.paint.id != _ultramarine.id));
      expect(crossing, isNotEmpty,
          reason: 'a warm+cool crossing recipe must be present');
      for (final r in crossing) {
        expect(r.muddying, isTrue, reason: 'ochre + ultramarine crosses complements');
      }
      expect(warmOnly, isNotEmpty, reason: 'a clean control must be present');
      for (final r in warmOnly) {
        expect(r.muddying, isFalse, reason: 'a single-temperature mix is clean');
      }
    });

    test('a cool-only mix is not muddying (achromatic paints are ignored)', () {
      final recipes = engine.inverse(
        const Sample(
          name: 'dusty blue',
          coordinates: ColorCoordinates(lightness: 40, a: 5, b: -30),
          provenance: Provenance(ProvenanceTier.measured),
        ),
        const PaintPalette(name: 'cool', paints: [_white, _ultramarine]),
        const MixOptions(),
      );
      expect(recipes, isNotEmpty);
      for (final r in recipes) {
        expect(r.muddying, isFalse,
            reason: 'white is achromatic, so ultramarine alone is not a crossing');
      }
    });

    test('a temperature-neutral chromatic paint does not cross', () {
      // A green masstone is chromatic but reads neither warm nor cool (the
      // neutral axis), so mixing it with a warm paint is not a crossing.
      const green = Paint(
        id: 'pg7',
        name: 'Phthalo Green',
        medium: PaintMedium.acrylic,
        masstone: ColorCoordinates(lightness: 45, a: -40, b: 10),
      );
      final recipes = engine.inverse(
        const Sample(
          name: 'muted green',
          coordinates: ColorCoordinates(lightness: 45, a: -12, b: 22),
          provenance: Provenance(ProvenanceTier.measured),
        ),
        const PaintPalette(name: 'greens', paints: [green, _ochre]),
        const MixOptions(),
      );
      expect(recipes, isNotEmpty);
      for (final r in recipes) {
        expect(r.muddying, isFalse,
            reason: 'warm + temperature-neutral is not a complementary crossing');
      }
    });
  });
}
