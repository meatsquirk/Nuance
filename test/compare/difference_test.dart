import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/difference.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

void main() {
  const measured = Provenance(ProvenanceTier.measured);
  const sampleA = Sample(
    coordinates: ColorCoordinates(lightness: 58, a: 24, b: 30),
    provenance: measured,
    name: 'Terracotta',
  );
  const sampleB = Sample(
    coordinates: ColorCoordinates(lightness: 70, a: 12, b: 24),
    provenance: measured,
    name: 'Sienna',
  );

  group('Comparison', () {
    test('equal fields are == and share a hashCode', () {
      // One built at runtime so the const constructor line is covered.
      // ignore: prefer_const_constructors
      final a = Comparison(
        deltaE00: 13.1,
        verdict: 'clearly different',
        lightness: 'Lighter by 12',
        saturation: 'Less saturated by 9',
        hue: 'Hue shifted 18 degrees toward yellow',
      );
      const b = Comparison(
        deltaE00: 13.1,
        verdict: 'clearly different',
        lightness: 'Lighter by 12',
        saturation: 'Less saturated by 9',
        hue: 'Hue shifted 18 degrees toward yellow',
      );
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differing fields are not equal', () {
      const base = Comparison(
        deltaE00: 13.1,
        verdict: 'clearly different',
        lightness: 'Lighter by 12',
        saturation: 'Less saturated by 9',
        hue: 'Hue shifted 18 degrees toward yellow',
      );
      expect(
          base ==
              const Comparison(
                deltaE00: 0,
                verdict: 'clearly different',
                lightness: 'Lighter by 12',
                saturation: 'Less saturated by 9',
                hue: 'Hue shifted 18 degrees toward yellow',
              ),
          isFalse);
      expect(
          base ==
              const Comparison(
                deltaE00: 13.1,
                verdict: 'identical',
                lightness: 'Lighter by 12',
                saturation: 'Less saturated by 9',
                hue: 'Hue shifted 18 degrees toward yellow',
              ),
          isFalse);
      expect(
          base ==
              const Comparison(
                deltaE00: 13.1,
                verdict: 'clearly different',
                lightness: 'Same lightness',
                saturation: 'Less saturated by 9',
                hue: 'Hue shifted 18 degrees toward yellow',
              ),
          isFalse);
      expect(
          base ==
              const Comparison(
                deltaE00: 13.1,
                verdict: 'clearly different',
                lightness: 'Lighter by 12',
                saturation: 'Same saturation',
                hue: 'Hue shifted 18 degrees toward yellow',
              ),
          isFalse);
      expect(
          base ==
              const Comparison(
                deltaE00: 13.1,
                verdict: 'clearly different',
                lightness: 'Lighter by 12',
                saturation: 'Less saturated by 9',
                hue: 'Same hue',
              ),
          isFalse);
    });

    test('is not equal to a non-Comparison object', () {
      const c = Comparison(
        deltaE00: 13.1,
        verdict: 'clearly different',
        lightness: 'Lighter by 12',
        saturation: 'Less saturated by 9',
        hue: 'Hue shifted 18 degrees toward yellow',
      );
      // ignore: unrelated_type_equality_checks
      final isEqual = c == 'x';
      expect(isEqual, isFalse);
    });

    test('exposes its fields and a readable toString', () {
      const c = Comparison(
        deltaE00: 13.1,
        verdict: 'clearly different',
        lightness: 'Lighter by 12',
        saturation: 'Less saturated by 9',
        hue: 'Hue shifted 18 degrees toward yellow',
      );
      expect(c.deltaE00, 13.1);
      expect(c.verdict, 'clearly different');
      expect(c.lightness, 'Lighter by 12');
      expect(c.saturation, 'Less saturated by 9');
      expect(c.hue, 'Hue shifted 18 degrees toward yellow');
      expect(
        c.toString(),
        'Comparison(ΔE00 13.1, clearly different; Lighter by 12, '
        'Less saturated by 9, Hue shifted 18 degrees toward yellow)',
      );
    });
  });

  group('compare', () {
    test('returns a constructible Comparison from two samples', () {
      final result = compare(sampleA, sampleB);
      expect(result, isA<Comparison>());
    });

    test('carries the overall difference (DIFF-2) and the three LCh lines '
        '(DIFF-3)', () {
      final result = compare(sampleA, sampleB);
      // CIEDE2000 ΔE00 for (58,24,30)→(70,12,24) ≈ 12.29.
      expect(result.deltaE00, closeTo(12.29, 0.01));
      expect(result.verdict, 'clearly different');
      // LCh deltas A→B: L 58→70 (+12); C 38.42→26.83 (−11.59 ≈ −12);
      // h 51.3°→63.4° (+12°, toward yellow).
      expect(result.lightness, 'Lighter by 12');
      expect(result.saturation, 'Less saturated by 12');
      expect(result.hue, 'Hue shifted 12 degrees toward yellow');
    });

    test('deltaE00 over coordinates is the same metric compare uses (CVD-2 '
        'reuse)', () {
      // The public coordinate-level ΔE00 the confusion detector reuses equals
      // what compare computes from the same two samples.
      expect(
        deltaE00(sampleA.coordinates, sampleB.coordinates),
        closeTo(compare(sampleA, sampleB).deltaE00, 1e-12),
      );
    });
  });

  // One Sample at the given CIELAB coordinates (the DIFF-2 math reads only the
  // coordinates; name/provenance are immaterial).
  Sample at(double l, double a, double b) => Sample(
        coordinates: ColorCoordinates(lightness: l, a: a, b: b),
        provenance: measured,
      );

  double delta(
    (double, double, double) x,
    (double, double, double) y,
  ) =>
      compare(at(x.$1, x.$2, x.$3), at(y.$1, y.$2, y.$3)).deltaE00;

  group('compare — ΔE00 is CIEDE2000 (DIFF-2)', () {
    // Each pair is checked against an independently computed CIEDE2000 value and
    // together they exercise every branch of the formula: the two chromatic
    // samples, the achromatic (C=0) short-circuits, the hue wrap-around on both
    // signs, and both mean-hue quadrant cases.
    test('two chromatic samples (no short-circuit, small hue difference)', () {
      expect(delta((58, 25.27, 22.75), (70, 12.50, 21.65)),
          closeTo(13.0517, 0.001));
    });

    test('both samples achromatic (C=0 short-circuits the hue terms)', () {
      expect(delta((50, 0, 0), (60, 0, 0)), closeTo(9.4706, 0.001));
    });

    test('one sample achromatic (one C=0, the other chromatic)', () {
      expect(delta((50, 0, 0), (60, 20, 10)), closeTo(20.5893, 0.001));
    });

    test('hue difference above +180 with the second hue wrapped past 360', () {
      // h1p ≈ 14°, h2p ≈ 346° (b<0 → atan2 negative, +360): diff +332 → −28.
      expect(delta((50, 19.40, 4.84), (50, 19.40, -4.84)),
          closeTo(6.4296, 0.001));
    });

    test('hue difference below −180 with the first hue wrapped past 360', () {
      // h1p ≈ 300° (b<0 → atan2 negative, +360), h2p ≈ 10°: diff −290 → +70.
      expect(delta((50, 10.0, -17.32), (50, 19.70, 3.47)),
          closeTo(16.1313, 0.001));
    });

    test('is symmetric in its two arguments', () {
      expect(delta((58, 25.27, 22.75), (70, 12.50, 21.65)),
          closeTo(delta((70, 12.50, 21.65), (58, 25.27, 22.75)), 1e-9));
    });
  });

  group('compare — the verdict band tracks the distance (DIFF-2)', () {
    String verdict(
      (double, double, double) x,
      (double, double, double) y,
    ) =>
        compare(at(x.$1, x.$2, x.$3), at(y.$1, y.$2, y.$3)).verdict;

    test('ΔE00 below 1 reads "no visible difference"', () {
      expect(verdict((50, 0, 0), (50.5, 0, 0)), 'no visible difference');
    });

    test('ΔE00 in [1, 3) reads "barely different"', () {
      expect(verdict((50, 0, 0), (52, 0, 0)), 'barely different');
    });

    test('ΔE00 in [3, 10) reads "slightly different"', () {
      expect(verdict((70, 12.50, 21.65), (70, 18.58, 16.73)),
          'slightly different');
    });

    test('ΔE00 in [10, 50) reads "clearly different"', () {
      expect(verdict((58, 25.27, 22.75), (70, 12.50, 21.65)),
          'clearly different');
    });

    test('ΔE00 at or above 50 reads "very different"', () {
      expect(verdict((10, 0, 0), (90, 0, 0)), 'very different');
    });
  });

  group('compare — LCh decomposition lines (DIFF-3)', () {
    Comparison compareAt(
      (double, double, double) x,
      (double, double, double) y,
    ) =>
        compare(at(x.$1, x.$2, x.$3), at(y.$1, y.$2, y.$3));

    group('lightness line — signed ΔL* from A to B (AC-5, AC-6)', () {
      test('B lighter than A reads "Lighter by n"', () {
        expect(compareAt((50, 10, 0), (60, 10, 0)).lightness, 'Lighter by 10');
      });
      test('B darker than A reads "Darker by n"', () {
        expect(compareAt((60, 10, 0), (50, 10, 0)).lightness, 'Darker by 10');
      });
      test('an unchanged lightness reads "Same lightness" (AC-6)', () {
        // Same L*, different chroma — only the lightness dimension is unchanged.
        expect(compareAt((50, 10, 0), (50, 20, 0)).lightness, 'Same lightness');
      });
    });

    group('saturation line — signed ΔC*ab from A to B (AC-5, AC-6)', () {
      test('B more saturated than A reads "More saturated by n"', () {
        expect(
            compareAt((50, 10, 0), (50, 20, 0)).saturation, 'More saturated by 10');
      });
      test('B less saturated than A reads "Less saturated by n"', () {
        expect(
            compareAt((50, 20, 0), (50, 10, 0)).saturation, 'Less saturated by 10');
      });
      test('an unchanged chroma reads "Same saturation" (AC-6)', () {
        // C*ab = 10 for both (a=10,b=0) and (a=0,b=10); only the hue differs.
        expect(
            compareAt((50, 10, 0), (50, 0, 10)).saturation, 'Same saturation');
      });
    });

    group('hue line — signed Δh° toward B\'s family (AC-5, AC-6)', () {
      test('a shift names the magnitude and B\'s hue family', () {
        // h 0° (red) → 90° (yellow): a +90° rotation toward yellow.
        expect(compareAt((50, 10, 0), (50, 0, 10)).hue,
            'Hue shifted 90 degrees toward yellow');
      });
      test('the shortest rotation wraps past 360° (the long-way fold)', () {
        // h 10° → 350°: the long way is +340°, folded to the shortest −20°; the
        // magnitude is 20° and B's hue (350°) is in the red family.
        expect(compareAt((50, 9.848, 1.736), (50, 9.848, -1.736)).hue,
            'Hue shifted 20 degrees toward red');
      });
      test('an unchanged hue reads "Same hue" (AC-6)', () {
        // Same hue angle (0°), different lightness — only the hue is unchanged.
        expect(compareAt((50, 10, 0), (60, 10, 0)).hue, 'Same hue');
      });
    });
  });
}
