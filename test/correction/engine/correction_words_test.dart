import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/correction/engine/correction_words.dart';

void main() {
  group('verdictFor', () {
    test('reads a beyond-tolerance mix as "noticeably off"', () {
      for (final distance in <double>[2.1, 6, 10, 42]) {
        expect(verdictFor(distance), 'noticeably off');
      }
    });

    test('reads a within-tolerance mix as "very close" (CORRECT-4, G-4b)', () {
      for (final distance in <double>[0, 0.5, 1, 1.9]) {
        expect(verdictFor(distance), 'very close');
      }
    });

    test('splits exactly at the tolerance boundary (ΔE00 2 is still close)',
        () {
      // Just inside (≤ tolerance) is "very close"; a hair outside flips to off.
      expect(verdictFor(correctionToleranceDeltaE00), 'very close');
      expect(verdictFor(correctionToleranceDeltaE00 - 1e-9), 'very close');
      expect(verdictFor(correctionToleranceDeltaE00 + 1e-9), 'noticeably off');
    });
  });

  group('valueReadingFor', () {
    test('a darker mix (lower L*) reads "too dark by N"', () {
      expect(valueReadingFor(42, 36), 'too dark by 6');
      expect(valueReadingFor(42, 41.4), 'too dark by 1'); // 0.6 gap rounds up
    });

    test('a lighter mix (higher L*) reads "too light by N"', () {
      expect(valueReadingFor(36, 42), 'too light by 6');
    });

    test('a gap that rounds to zero reads "matched on value"', () {
      expect(valueReadingFor(42, 42), 'matched on value');
      expect(valueReadingFor(42, 41.7), 'matched on value'); // 0.3 gap → 0
      expect(valueReadingFor(42, 42.3), 'matched on value'); // −0.3 gap → 0
    });
  });

  group('hueReadingFor', () {
    test('a negligible shift reads "hue on target"', () {
      expect(hueReadingFor(100, 100), 'hue on target');
      expect(hueReadingFor(100.5, 100), 'hue on target'); // < 1° epsilon
    });

    test('a shift names the hue family the mix now reads as, each family', () {
      // mixed angle → expected family; target offset 20° so there is a shift.
      const cases = <({double mixedHue, String family})>[
        (mixedHue: 10, family: 'red'),
        (mixedHue: 40, family: 'orange'),
        (mixedHue: 70, family: 'yellow'),
        (mixedHue: 120, family: 'green'),
        (mixedHue: 180, family: 'teal'),
        (mixedHue: 230, family: 'blue'),
        (mixedHue: 280, family: 'purple'),
        (mixedHue: 330, family: 'magenta'),
      ];
      for (final c in cases) {
        expect(hueReadingFor(c.mixedHue, c.mixedHue - 20),
            'shifted toward ${c.family}');
      }
    });

    test('the signed delta wraps the hue circle (the far-arc branch)', () {
      // mixed 350°, target 10°: the short arc is −20° (clockwise), a real shift
      // into the red family — exercising the > 180° wrap of the signed delta.
      expect(hueReadingFor(350, 10), 'shifted toward red');
    });
  });
}
