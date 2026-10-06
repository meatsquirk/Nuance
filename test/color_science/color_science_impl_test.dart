import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

// The SAMPLE_TERRACOTTA fixture (CIELCh L58 C34 h42 → 10R 5.5/6), in canonical
// CIELAB. These are the frozen reference values the COLOR-2 conversions feed
// AC-1 / AC-5, so the impl is checked against them directly.
const _terracotta = ColorCoordinates(lightness: 58, a: 25.27, b: 22.75);
const _sample = Sample(
  coordinates: _terracotta,
  provenance: Provenance(ProvenanceTier.measured),
  name: 'Warm Terracotta',
);

void main() {
  const impl = ColorScienceImpl();

  test('is a ColorScience', () {
    expect(impl, isA<ColorScience>());
  });

  group('COLOR-2 conversions surface through the impl (SAMPLE_TERRACOTTA)', () {
    test('toCIELCh is the polar form: L 58, C 34, h 42', () {
      final lch = impl.toCIELCh(_terracotta);
      expect(lch.lightness, 58);
      expect(lch.chroma, closeTo(34.0, 0.05));
      expect(lch.hue, closeTo(42.0, 0.05));
    });

    test('toMunsell reads 10R 5.5/6', () {
      final m = impl.toMunsell(_terracotta);
      expect(m.hue, '10R');
      expect(m.value, 5.5);
      expect(m.chroma, 6.0);
      expect(m.notation, contains('10R 5.5/6'));
    });

    test('toCIELAB is the canonical identity', () {
      expect(impl.toCIELAB(_terracotta), _terracotta);
    });

    test('lightness is CIELAB L*', () {
      expect(impl.lightness(_terracotta), 58);
    });

    test('toSRGB / toHex give a warm reddish triplet and a #rrggbb hex', () {
      final rgb = impl.toSRGB(_terracotta);
      expect(rgb.red, greaterThan(rgb.green));
      expect(rgb.green, greaterThan(rgb.blue));
      expect(impl.toHex(_terracotta), matches(RegExp(r'^#[0-9a-f]{6}$')));
    });

    test('grayscaleOf is a neutral (equal channels) at the sample lightness',
        () {
      final gray = impl.grayscaleOf(_terracotta);
      expect(gray.green, gray.red);
      expect(gray.blue, gray.red);
      // Neutral of a mid-lightness sample is a mid grey, not black or white.
      expect(gray.red, inInclusiveRange(1, 254));
    });
  });

  group('COLOR-3 naming / words / decomposition surface through the impl', () {
    test('nearestName resolves the catalogue (terracotta → "Warm Terracotta")',
        () {
      expect(
        impl.nearestName(const ColorCoordinates(lightness: 58, a: 25.27, b: 22.75)),
        'Warm Terracotta',
      );
    });

    test('valueWord bands the lightness', () {
      expect(impl.valueWord(58).toLowerCase(), contains('middle'));
    });

    test('temperatureWord states the temperature in words', () {
      expect(impl.temperatureWord(42), 'warm');
      expect(impl.temperatureWord(250), 'cool');
    });

    test('decompose states the name, value, temperature, hue, chroma, angle',
        () {
      final spoken = impl.decompose(_sample);
      expect(spoken, contains('Warm Terracotta'));
      expect(spoken, contains('58'));
      expect(spoken.toLowerCase().replaceAll('warm terracotta', ''),
          contains('warm'));
    });
  });
}
