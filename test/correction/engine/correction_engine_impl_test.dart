import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/difference.dart' show deltaE00;
import 'package:paint_color_assistant/correction/engine/correction_engine.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine_impl.dart';
import 'package:paint_color_assistant/correction/engine/correction_words.dart'
    show correctionToleranceDeltaE00;
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';

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
const _venetian = Paint(
  id: 'pr101',
  name: 'Venetian Red',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 40, a: 32, b: 26),
);

const _palette = PaintPalette(
  name: 'My paints',
  paints: [_white, _ochre, _black, _ultramarine, _venetian],
);

// The current mix the search perturbs: an ochre-heavy olive with black and a
// little white (shares by volume summing to 1).
const _mix = Recipe(
  medium: PaintMedium.acrylic,
  components: [
    RecipeComponent(paint: _ochre, partsFraction: 0.55),
    RecipeComponent(paint: _black, partsFraction: 0.25),
    RecipeComponent(paint: _white, partsFraction: 0.20),
  ],
  predictedColor: ColorCoordinates(lightness: 31, a: 0, b: 8),
  deltaE00: 12,
);

const _target = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -1.2561, b: 23.9671),
  provenance: Provenance(ProvenanceTier.estimated),
);

Sample _swatch(ColorCoordinates c) => Sample(
      coordinates: c,
      provenance: const Provenance(ProvenanceTier.measured),
    );

// A swatch read too dark (L36 vs 42) and shifted toward green — ≈ ΔE00 10.
final _tooDark =
    _swatch(const ColorCoordinates(lightness: 35.97, a: -12.026, b: 27.427));
// A swatch matched on value but a little short of the target's yellow — ≈ ΔE00 2.9.
final _ochreTrace =
    _swatch(const ColorCoordinates(lightness: 42.056, a: -1.410, b: 18.375));
// A swatch read too light (L50 vs 42).
final _tooLight =
    _swatch(const ColorCoordinates(lightness: 50, a: -1.26, b: 24));
// A swatch within ΔE00 2 of the target (too light by only ~0.5).
final _withinTolerance =
    _swatch(const ColorCoordinates(lightness: 42.5, a: -1.0, b: 22.3));

const _engine = SubtractiveCorrectionEngine();
const _mixEngine = SubtractiveMixingEngine();

/// The real forward-predicted ΔE00 of [mix] (paint → parts) to the target — the
/// physical control the AC-4 acceptance test also uses.
double _forwardDistance(Map<Paint, double> mix) =>
    deltaE00(_mixEngine.forward(mix), _target.coordinates);

Map<Paint, double> _baseParts() => {
      for (final c in _mix.components) c.paint: c.partsFraction,
    };

void main() {
  group('SubtractiveCorrectionEngine', () {
    test('is a CorrectionEngine over the injected mixing engine', () {
      expect(_engine, isA<CorrectionEngine>());
      expect(_engine.mixingEngine, isA<SubtractiveMixingEngine>());
    });

    test(
        'difference reports the real ΔE00 distance (D-2), the off verdict and '
        'the value-leading decomposition (CORRECT-2)', () {
      final difference = _engine.difference(_tooDark, _target);
      expect(
        difference.deltaE00,
        deltaE00(_tooDark.coordinates, _target.coordinates),
        reason: 'the engine delegates its distance to the shipped bs-03 '
            'deltaE00 (D-2), not a hand-rolled copy',
      );
      expect(difference.deltaE00, greaterThan(0),
          reason: 'a real off-reading has a non-zero distance');
      expect(difference.verdict, 'noticeably off',
          reason: 'a beyond-tolerance mix reads "noticeably off" (G-4b)');
      expect(difference.valueReading, 'too dark by 6',
          reason: 'the value reading states the L* gap and its sign');
      expect(difference.hueReading, contains('green'),
          reason: 'the hue reading names the shifted-toward family');
      expect(difference.withinTolerance, isFalse,
          reason: 'a beyond-tolerance mix is not flagged within tolerance');
    });

    test(
        'difference flags a within-tolerance mix "very close" (CORRECT-4, AC-6)',
        () {
      final difference = _engine.difference(_withinTolerance, _target);
      expect(
          difference.deltaE00, lessThanOrEqualTo(correctionToleranceDeltaE00),
          reason: 'the fixture really sits within ΔE00 tolerance');
      expect(difference.withinTolerance, isTrue,
          reason: 'a mix at or within tolerance is flagged within tolerance');
      expect(difference.verdict, 'very close',
          reason: 'a within-tolerance mix reads "very close" (G-4b)');
    });

    group('correct (CORRECT-3, AC-4/AC-5)', () {
      test(
          'a too-dark mix is told to add the lightest paint, a measured amount '
          'that moves the forward prediction closer (AC-4)', () {
        final correction = _engine.correct(_tooDark, _target, _mix, _palette);

        expect(correction.isEmpty, isFalse,
            reason: 'a mix well beyond tolerance needs a correction');
        expect(correction.additions, hasLength(1),
            reason: 'the single addition that most closes the gap (D-3)');
        final addition = correction.additions.single;
        expect(addition.paint, _white,
            reason: 'value leads (D-5): lift a too-dark mix with white');
        expect(addition.parts, greaterThan(0),
            reason: 'a positive amount of white to add (AC-4)');
        expect(addition.isTrace, isFalse,
            reason: 'a mix this far off needs a measured part, not a touch');

        // Forward-model control (AC-4): adding the suggested white to the mix
        // moves the *real* forward prediction closer to the target.
        final adjusted = _baseParts();
        adjusted[addition.paint] =
            (adjusted[addition.paint] ?? 0) + addition.parts;
        expect(
          _forwardDistance(adjusted),
          lessThan(_forwardDistance(_baseParts())),
          reason: 'the addition reduces the forward-predicted ΔE00 — a real '
              'physical correction, not a darkening/ΔE-increasing paint',
        );
      });

      test(
          'a mix only a little short of the target\'s yellow is told to add a '
          'sub-trace touch of Yellow Ochre (AC-5)', () {
        final correction =
            _engine.correct(_ochreTrace, _target, _mix, _palette);

        expect(correction.isEmpty, isFalse);
        expect(correction.additions, hasLength(1));
        final addition = correction.additions.single;
        expect(addition.paint, _ochre,
            reason: 'value is matched, so the correction fixes the hue/chroma '
                'gap with the yellow earth');
        expect(addition.parts, lessThan(0.02),
            reason: 'a mix barely beyond tolerance needs only a touch — '
                'sub-trace (the 2%-by-volume threshold, G-4c)');
        expect(addition.isTrace, isTrue,
            reason: 'a sub-trace amount is flagged a trace');
        expect(addition.techniqueNote, isNotNull,
            reason: 'a trace carries its static technique note (D-7)');
      });

      test('a too-light mix is told to add the darkest paint', () {
        final correction = _engine.correct(_tooLight, _target, _mix, _palette);

        expect(correction.isEmpty, isFalse);
        final addition = correction.additions.single;
        expect(addition.paint, _black,
            reason: 'value leads: lower a too-light mix with the darkest paint');
        expect(addition.parts, greaterThan(0));
      });

      test('an empty palette offers no correction', () {
        final correction = _engine.correct(
            _tooDark, _target, _mix, const PaintPalette(name: 'empty'));
        expect(correction.isEmpty, isTrue);
        expect(correction.additions, isEmpty);
      });

      test(
          'a too-dark mix over a palette that can only darken it offers no '
          'correction (no amount improves)', () {
        const onlyBlack = PaintPalette(name: 'black only', paints: [_black]);
        final correction = _engine.correct(_tooDark, _target, _mix, onlyBlack);
        expect(correction.isEmpty, isTrue,
            reason: 'adding black cannot lift a too-dark mix, so the search '
                'finds no improving amount');
      });

      test('a mix within tolerance is offered no correction (the ramp is 0)',
          () {
        final correction =
            _engine.correct(_withinTolerance, _target, _mix, _palette);
        expect(correction.isEmpty, isTrue,
            reason: 'at or within tolerance the correction ramps to nothing '
                '(CORRECT-4 makes that an explicit "very close")');
      });

      test(
          'a mix already on the target (matched, no gap) offers no correction',
          () {
        final onTarget = _swatch(_target.coordinates);
        final correction = _engine.correct(onTarget, _target, _mix, _palette);
        expect(correction.isEmpty, isTrue,
            reason: 'value matched and no chroma addition improves on an exact '
                'match, so no paint is chosen');
      });
    });

    test('constructs at runtime (covers the const constructor line)', () {
      // ignore: prefer_const_constructors
      expect(SubtractiveCorrectionEngine(), isA<SubtractiveCorrectionEngine>());
    });
  });
}
