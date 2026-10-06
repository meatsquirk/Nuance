import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/color_science/decomposition.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

const _terracotta = ColorCoordinates(lightness: 58, a: 25.27, b: 22.75);
const _periwinkle = ColorCoordinates(lightness: 55, a: -11.63, b: -31.95);

Sample _sample(ColorCoordinates c, {String? name}) =>
    Sample(coordinates: c, provenance: const Provenance(ProvenanceTier.measured), name: name);

void main() {
  group('decompose states every component AC-8 requires', () {
    test('the warm terracotta reading (L58 C34 h42)', () {
      final spoken = decompose(_sample(_terracotta, name: 'Warm Terracotta'));
      final lower = spoken.toLowerCase();

      expect(spoken, contains('Warm Terracotta')); // the name
      expect(spoken, contains('58')); // the value (lightness)
      // the temperature word, distinct from the name (which contains "warm")
      expect(lower.replaceAll('warm terracotta', ''), contains('warm'));
      // the hue in words (a warm family for h42)
      expect(lower, matches(RegExp(r'\b(orange|red)\b')));
      expect(spoken, contains('34')); // the chroma
      expect(spoken, contains('42')); // the hue angle
    });
  });

  group('decompose names the sample', () {
    test('uses the stored name when the sample has one', () {
      // The coordinates are blue, but the stored name wins over the derivation.
      final spoken = decompose(_sample(_periwinkle, name: 'My Custom Blue'));
      expect(spoken, contains('My Custom Blue'));
    });

    test('derives the nearest name when the sample is unnamed', () {
      final spoken = decompose(_sample(_terracotta));
      expect(spoken, contains('Warm Terracotta'));
    });
  });

  group('decompose handles temperature and the achromatic case', () {
    test('a cool, blue reading reads "cool" and "blue"', () {
      // Unnamed so the temperature word isn't masked by a name containing it.
      final spoken = decompose(_sample(_periwinkle)).toLowerCase();
      expect(spoken, contains('cool'));
      expect(spoken, contains('blue'));
      expect(spoken, contains('250')); // hue angle, from the negative a*/b*
      expect(spoken, contains('34')); // chroma
    });

    test('a near-neutral reading is spoken as a neutral grey, no hue angle', () {
      final spoken =
          decompose(_sample(const ColorCoordinates(lightness: 50, a: 0, b: 0)));
      expect(spoken, contains('neutral grey'));
      expect(spoken, contains('50')); // the value
      expect(spoken, contains('chroma 0'));
      expect(spoken, isNot(contains('degrees'))); // no hue stated for a neutral
    });
  });
}
