import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/conversions.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

const _terracotta = ColorCoordinates(lightness: 58, a: 25.27, b: 22.75);

void main() {
  group('labToSrgb', () {
    test('CIELAB white → 255,255,255', () {
      final rgb = labToSrgb(const ColorCoordinates(lightness: 100, a: 0, b: 0));
      expect(rgb, const SRGBColor(red: 255, green: 255, blue: 255));
    });

    test('CIELAB black → 0,0,0', () {
      final rgb = labToSrgb(const ColorCoordinates(lightness: 0, a: 0, b: 0));
      expect(rgb, const SRGBColor(red: 0, green: 0, blue: 0));
    });

    test('terracotta is a warm red-orange (red > green > blue)', () {
      final rgb = labToSrgb(_terracotta);
      expect(rgb.red, greaterThan(rgb.green));
      expect(rgb.green, greaterThan(rgb.blue));
    });

    test('an out-of-gamut CIELAB clamps every channel to 0–255', () {
      final rgb = labToSrgb(const ColorCoordinates(lightness: 60, a: -128, b: 127));
      expect(rgb.red, inInclusiveRange(0, 255));
      expect(rgb.green, inInclusiveRange(0, 255));
      expect(rgb.blue, inInclusiveRange(0, 255));
    });
  });

  group('labToHex', () {
    test('white → #ffffff, black → #000000', () {
      expect(labToHex(const ColorCoordinates(lightness: 100, a: 0, b: 0)),
          '#ffffff');
      expect(
          labToHex(const ColorCoordinates(lightness: 0, a: 0, b: 0)), '#000000');
    });

    test('is always a lowercase 6-digit hex', () {
      expect(labToHex(_terracotta), matches(RegExp(r'^#[0-9a-f]{6}$')));
    });
  });

  group('labToCielch', () {
    test('terracotta → L 58, C 34, h 42', () {
      final lch = labToCielch(_terracotta);
      expect(lch.lightness, 58);
      expect(lch.chroma, closeTo(34.0, 0.05));
      expect(lch.hue, closeTo(42.0, 0.05));
    });

    test('a negative a*b* angle is normalised into 0–360', () {
      // a>0, b<0 → atan2 returns a negative angle; expect it wrapped to ~315°.
      final lch = labToCielch(const ColorCoordinates(lightness: 50, a: 10, b: -10));
      expect(lch.hue, closeTo(315.0, 0.05));
    });
  });

  test('labToCielab returns the canonical coordinates unchanged', () {
    expect(labToCielab(_terracotta), same(_terracotta));
  });

  test('lightnessOf returns CIELAB L*', () {
    expect(lightnessOf(_terracotta), 58);
  });

  group('grayscaleOf', () {
    test('is a neutral (equal channels) at the sample lightness', () {
      final gray = grayscaleOf(_terracotta);
      expect(gray.green, gray.red);
      expect(gray.blue, gray.red);
      expect(gray.red, inInclusiveRange(1, 254));
    });

    test('clamps lightness above 100 to white and below 0 to black', () {
      expect(grayscaleOf(const ColorCoordinates(lightness: 150, a: 0, b: 0)),
          const SRGBColor(red: 255, green: 255, blue: 255));
      expect(grayscaleOf(const ColorCoordinates(lightness: -10, a: 0, b: 0)),
          const SRGBColor(red: 0, green: 0, blue: 0));
    });
  });

  group('munsellValueFromLightness', () {
    test('L* 58 → value ≈ 5.69 (rounds to the 5.5 notation step)', () {
      expect(munsellValueFromLightness(58), closeTo(5.69, 0.02));
    });

    test('endpoints: L* 0 → 0, L* 100 → 10', () {
      expect(munsellValueFromLightness(0), closeTo(0.0, 0.01));
      expect(munsellValueFromLightness(100), closeTo(10.0, 0.01));
    });

    test('a dark L* (≤ 8) uses the linear luminance branch', () {
      final v = munsellValueFromLightness(4);
      expect(v, greaterThan(0.0));
      expect(v, lessThan(1.5));
    });

    test('out-of-range lightness is clamped to 0–100', () {
      expect(munsellValueFromLightness(150), closeTo(10.0, 0.01));
      expect(munsellValueFromLightness(-10), closeTo(0.0, 0.01));
    });
  });

  group('labToMunsell', () {
    test('terracotta → 10R 5.5/6', () {
      final m = labToMunsell(_terracotta);
      expect(m.hue, '10R');
      expect(m.value, 5.5);
      expect(m.chroma, 6.0);
      expect(m.notation, contains('10R 5.5/6'));
    });

    test('a fully neutral sample is Munsell N with chroma 0', () {
      final m = labToMunsell(const ColorCoordinates(lightness: 50, a: 0, b: 0));
      expect(m.hue, kMunsellNeutralHue);
      expect(m.chroma, 0.0);
    });

    test('a trace chroma that rounds below one step is treated as neutral', () {
      final m = labToMunsell(const ColorCoordinates(lightness: 50, a: 1, b: 0));
      expect(m.hue, kMunsellNeutralHue);
      expect(m.chroma, 0.0);
    });

    test('a blue-violet sample snaps to a PB/B hue, not a red one', () {
      // SAMPLE_COOL: CIELCh h ≈ 250°.
      final m = labToMunsell(
          const ColorCoordinates(lightness: 55, a: -11.63, b: -31.95));
      expect(m.hue, anyOf(endsWith('B'), endsWith('PB')));
      expect(m.hue, isNot(endsWith('R')));
    });
  });

  group('kMunsellHueAnchors', () {
    test('covers the 40 principal hue steps and pins 10R at 42°', () {
      expect(kMunsellHueAnchors, hasLength(40));
      final tenR = kMunsellHueAnchors.firstWhere((a) => a.hue == '10R');
      expect(tenR.angleDeg, 42.0);
    });
  });
}
