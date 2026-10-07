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

  group('compare (DIFF-1 shell placeholder)', () {
    test('returns a constructible Comparison from two samples', () {
      final result = compare(sampleA, sampleB);
      expect(result, isA<Comparison>());
    });

    test('placeholder fields are fixed (real math arrives in DIFF-2/DIFF-3)',
        () {
      final result = compare(sampleA, sampleB);
      expect(result.deltaE00, 0.0);
      expect(result.verdict, '');
      expect(result.lightness, '');
      expect(result.saturation, '');
      expect(result.hue, '');
    });
  });
}
