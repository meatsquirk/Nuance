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
// The earthy red that completes the acceptance "My paints" palette; the
// ENGINE-3 ordering group mirrors that five-paint palette.
const _venetian = Paint(
  id: 'pr101',
  name: 'Venetian Red',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 40, a: 32, b: 26),
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

  group('forward (dry prediction, AC-10 / D-11)', () {
    test('the dry prediction darkens the wet colour (the drying direction)', () {
      final wet = engine.forward({_ochreOil: 1.0});
      final dry = engine.forward({_ochreOil: 1.0}, dry: true);
      // Drying shifts darker: a real change, not a no-op.
      expect(dry, isNot(wet));
      expect(dry.lightness, lessThan(wet.lightness),
          reason: 'paint dries darker (D-11)');
      expect(deltaE00(dry, wet), greaterThan(0),
          reason: 'the wet→dry shift is a genuine colour change');
    });

    test('oil shifts less on drying than acrylic (D-11)', () {
      // Same wet masstone in each medium (white in acrylic vs. oil) so only the
      // per-medium drying factor differs.
      final wetAcrylic = engine.forward({_white: 1.0});
      final dryAcrylic = engine.forward({_white: 1.0}, dry: true);
      final wetOil = engine.forward({_whiteOil: 1.0});
      final dryOil = engine.forward({_whiteOil: 1.0}, dry: true);
      expect(deltaE00(dryOil, wetOil), greaterThan(0));
      expect(deltaE00(dryOil, wetOil), lessThan(deltaE00(dryAcrylic, wetAcrylic)),
          reason: 'oil shifts far less on its first-shot dry than acrylic');
    });

    test('the dry prediction is a pure function of the wet colour and medium',
        () {
      // Two mixes of the same oil paints at the same ratios (scaled volumes)
      // share a wet colour, so their dry predictions must match exactly — the
      // transform depends on nothing but the wet colour and the medium.
      final dryA = engine.forward({_whiteOil: 1.0, _ochreOil: 1.0}, dry: true);
      final dryB = engine.forward({_whiteOil: 3.0, _ochreOil: 3.0}, dry: true);
      expect(deltaE00(dryA, dryB), lessThan(1e-6));
    });

    test('a dry prediction needs a single-medium mix (recipes never span media)',
        () {
      expect(() => engine.forward({_white: 1.0, _whiteOil: 1.0}, dry: true),
          throwsArgumentError);
      // The same mixed-medium mix is fine wet — only the dry transform is
      // per-medium.
      expect(engine.forward({_white: 1.0, _whiteOil: 1.0}), isA<ColorCoordinates>());
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

      // Ordered best-first by the D-8 ranking (ENGINE-3): ΔE00 ascending, but
      // recipes within ~1 ΔE00 (a just-noticeable tie) are ordered toward fewer
      // paints. So for each adjacent pair, either the next recipe is a clear
      // step farther, or — at a tie — the earlier one uses no more paints.
      // (ENGINE-2's plain ascending-ΔE order is a special case of this.)
      const tieGrain = 1.0; // mirrors SubtractiveMixingEngine._tieGrain
      for (var i = 1; i < recipes.length; i++) {
        final prev = recipes[i - 1], next = recipes[i];
        if ((next.deltaE00 - prev.deltaE00).abs() <= tieGrain) {
          expect(prev.components.length, lessThanOrEqualTo(next.components.length),
              reason: 'at a tie the earlier recipe uses no more paints (D-8)');
        } else {
          expect(prev.deltaE00, lessThan(next.deltaE00),
              reason: 'beyond a tie the ranking is ascending ΔE00');
        }
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
        // ENGINE-3 now fills `verdict` with a non-empty plain band (see its
        // group); `muddying` is set by ENGINE-4. ENGINE-5 flags `outOfGamut`:
        // this `_target` is the pre-retarget olive (a* −8.65) the earthy palette
        // cannot reach within the ΔE00 ≤ 5 ceiling (best ≈ 9.3 — the G-5 limit),
        // so every offered mix is the nearest, not a match. The in-gamut flag
        // path (a reachable olive) is covered in the out-of-gamut group below.
        expect(recipe.verdict, isNotNull);
        expect(recipe.verdict, isNotEmpty);
        expect(recipe.outOfGamut, isTrue);
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

  group('verdict + ordering (ENGINE-3, AC-5 / AC-6 / D-7 / D-8)', () {
    // The retargeted reachable olive (ITEST-5 / G-5 (a)): the earthy palette's
    // best mix lands at ΔE00 ≈ 3.3 — inside the in-gamut range — so a "very
    // close" verdict is meaningful, and the top two mixes (a 3-paint and a
    // 2-paint) sit a hair apart, exercising the prefer-fewer tie-break.
    const olive = Sample(
      name: 'Deep Olive Green',
      coordinates: ColorCoordinates(lightness: 42, a: -1.2561, b: 23.9671),
      provenance: Provenance(ProvenanceTier.measured),
    );
    const myPaintsFull = PaintPalette(
      name: 'My paints',
      paints: [_white, _ochre, _black, _ultramarine, _venetian],
    );

    test('every recipe carries a non-empty verdict that tracks its distance',
        () {
      final recipes = engine.inverse(olive, myPaintsFull, const MixOptions());
      expect(recipes, isNotEmpty);
      for (final r in recipes) {
        expect(r.verdict, isNotNull);
        expect(r.verdict, isNotEmpty);
      }
      // The best mix is in gamut (ΔE00 ≤ 5) and reads the pinned "very close"
      // phrase (AC-5); the farthest returned mix reads a plainly different,
      // worse band — so the verdict is not a constant string (D-7).
      final best = recipes.first;
      expect(best.deltaE00, lessThanOrEqualTo(5.0));
      expect(best.verdict!.toLowerCase(), contains('very close'));
      final farthest =
          recipes.reduce((a, b) => a.deltaE00 >= b.deltaE00 ? a : b);
      expect(farthest.deltaE00, greaterThan(best.deltaE00));
      expect(farthest.verdict, isNot(best.verdict),
          reason: 'a farther mix reads a different, worse verdict band');
    });

    test('an almost-exact match reads the closest band (< 1 ΔE00)', () {
      // A target equal to a palette paint's own masstone: the 100%-of-that-paint
      // recipe reproduces it to well under 1 ΔE00 (forward self-consistency), so
      // it reads the closest verdict band — the sub-1 branch the olive solve,
      // whose best is ≈ 3.3, never reaches.
      const ochreItself = Sample(
        name: 'Yellow Ochre itself',
        coordinates: ColorCoordinates(lightness: 60, a: 12, b: 46),
        provenance: Provenance(ProvenanceTier.measured),
      );
      final recipes = engine.inverse(ochreItself, myPaintsFull, const MixOptions());
      final best = recipes.first;
      expect(best.deltaE00, lessThan(1.0));
      expect(best.verdict!.toLowerCase(), contains('almost'),
          reason: 'a sub-1 ΔE00 match reads the closest band');
    });

    test('prefers fewer paints at a near-tie: the 2-paint mix ranks above the '
        '3-paint mix the pure-ΔE order would have led with', () {
      final recipes = engine.inverse(olive, myPaintsFull, const MixOptions());
      int indexOfSet(Set<String> names) => recipes.indexWhere((r) =>
          r.components.length == names.length &&
          r.components.every((c) => names.contains(c.paint.name)));
      final twoPaint = indexOfSet({'Yellow Ochre', 'Ivory Black'});
      final threePaint =
          indexOfSet({'Titanium White', 'Yellow Ochre', 'Ivory Black'});
      expect(twoPaint, greaterThanOrEqualTo(0));
      expect(threePaint, greaterThanOrEqualTo(0));
      // A genuine near-tie (within the tie grain), and the 3-paint mix is in
      // fact the marginally lower ΔE00 — so ranking the 2-paint mix first is the
      // prefer-fewer tie-break at work, not a distance win.
      expect((recipes[twoPaint].deltaE00 - recipes[threePaint].deltaE00).abs(),
          lessThanOrEqualTo(1.0));
      expect(recipes[threePaint].deltaE00,
          lessThan(recipes[twoPaint].deltaE00),
          reason: 'the 3-paint mix has the marginally lower ΔE00');
      expect(twoPaint, lessThan(threePaint),
          reason: 'the cleaner 2-paint mix still ranks above it (D-8)');
      // The AC-6 invariant holds over the whole returned order.
      for (var i = 0; i < recipes.length; i++) {
        for (var j = i + 1; j < recipes.length; j++) {
          if ((recipes[i].deltaE00 - recipes[j].deltaE00).abs() <= 1.0) {
            expect(recipes[i].components.length,
                lessThanOrEqualTo(recipes[j].components.length));
          }
        }
      }
    });

    test('candidates tied on distance and paint count fall through to the finer '
        'tie-breaks, deterministically', () {
      // Two paints with the same masstone (distinct ids) each give a
      // 100%-of-one-paint recipe at the identical ΔE00 and colour, so the
      // ranking must compare them past the band and paint-count tie-breaks —
      // exercising the added-chroma and exact-ΔE fallbacks — and still return a
      // stable order.
      const twins = PaintPalette(name: 'twins', paints: [
        Paint(
            id: 'twin-a',
            name: 'Twin A',
            medium: PaintMedium.acrylic,
            masstone: ColorCoordinates(lightness: 55, a: 6, b: 20)),
        Paint(
            id: 'twin-b',
            name: 'Twin B',
            medium: PaintMedium.acrylic,
            masstone: ColorCoordinates(lightness: 55, a: 6, b: 20)),
      ]);
      final a = engine.inverse(_target, twins, const MixOptions());
      final b = engine.inverse(_target, twins, const MixOptions());
      expect(a, isNotEmpty);
      expect(a, b, reason: 'the ranking is deterministic even at a full tie');
    });
  });

  group('out of gamut (ENGINE-5, AC-9 / D-10)', () {
    const myPaintsFull = PaintPalette(
      name: 'My paints',
      paints: [_white, _ochre, _black, _ultramarine, _venetian],
    );
    // A strongly-green, high-chroma turquoise no earthy-palette paint sits near:
    // genuinely unreachable (best ΔE00 ≈ 21, well above the ceiling).
    const turquoise = Sample(
      name: 'Vivid Turquoise',
      coordinates: ColorCoordinates(lightness: 55, a: -35, b: -12),
      provenance: Provenance(ProvenanceTier.measured),
    );
    // The retargeted reachable olive (best ΔE00 ≈ 3.3 ≤ 5) — the in-gamut
    // control.
    const reachableOlive = Sample(
      name: 'Deep Olive Green',
      coordinates: ColorCoordinates(lightness: 42, a: -1.2561, b: 23.9671),
      provenance: Provenance(ProvenanceTier.measured),
    );

    double minDeltaE00(List<Recipe> recipes) =>
        recipes.map((r) => r.deltaE00).reduce((a, b) => a < b ? a : b);

    test('an unreachable target flags every offered mix out of gamut, each above '
        'the in-gamut ceiling, with no verdict claiming a match', () {
      const opts = MixOptions();
      final recipes = engine.inverse(turquoise, myPaintsFull, opts);
      expect(recipes, isNotEmpty,
          reason: 'even unreachable, the engine offers the nearest mix (AC-9)');
      expect(minDeltaE00(recipes), greaterThan(opts.gamutThreshold),
          reason: 'the best achievable mix exceeds the ΔE00 ≤ 5 ceiling');
      for (final r in recipes) {
        expect(r.outOfGamut, isTrue,
            reason: 'the nearest mix is offered as nearest, not a match');
        expect(r.deltaE00, greaterThan(opts.gamutThreshold));
        // The distance band at this range never reads as a match (AC-9): the
        // flag is the signal, and the verdict stays an honest, worse band.
        expect(r.verdict, isNotNull);
        expect(r.verdict!.toLowerCase(), isNot(contains('very close')));
        expect(r.verdict!.toLowerCase(), isNot(contains('almost')));
      }
    });

    test('a reachable target flags no recipe out of gamut (the in-gamut control)',
        () {
      final recipes =
          engine.inverse(reachableOlive, myPaintsFull, const MixOptions());
      expect(recipes, isNotEmpty);
      expect(minDeltaE00(recipes), lessThanOrEqualTo(5.0),
          reason: 'the reachable olive sits inside the in-gamut ceiling');
      for (final r in recipes) {
        expect(r.outOfGamut, isFalse,
            reason: 'an in-gamut recipe is a match, not a nearest-only');
      }
    });

    test('the flag is thresholded by MixOptions.gamutThreshold, not a hardcoded '
        'ceiling', () {
      // The same reachable olive (best ≈ 3.3) is out of gamut under a ceiling
      // below its best, and the same turquoise (best ≈ 21) is in gamut under a
      // ceiling above its best — so the boundary is the option, not a constant.
      final tight = engine.inverse(
          reachableOlive, myPaintsFull, const MixOptions(gamutThreshold: 1.0));
      expect(tight, isNotEmpty);
      expect(tight.every((r) => r.outOfGamut), isTrue,
          reason: 'under a 1.0 ceiling the ≈3.3 best mix is out of gamut');
      final loose = engine.inverse(
          turquoise, myPaintsFull, const MixOptions(gamutThreshold: 100.0));
      expect(loose, isNotEmpty);
      expect(loose.every((r) => !r.outOfGamut), isTrue,
          reason: 'under a 100 ceiling even the turquoise is within gamut');
    });
  });
}
