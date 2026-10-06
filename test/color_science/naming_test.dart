import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/color_science/naming.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

ColorCoordinates _lab(double l, double a, double b) =>
    ColorCoordinates(lightness: l, a: a, b: b);

void main() {
  group('nearestColorName resolves the acceptance fixtures to their names', () {
    test('Warm Terracotta fixture (L58 a25.27 b22.75)', () {
      expect(nearestColorName(_lab(58, 25.27, 22.75)), 'Warm Terracotta');
    });

    test('Deep Olive Green fixture (L40 a-8 b24)', () {
      expect(nearestColorName(_lab(40, -8, 24)), 'Deep Olive Green');
    });

    test('Cool Periwinkle fixture (L55 a-11.63 b-31.95)', () {
      expect(nearestColorName(_lab(55, -11.63, -31.95)), 'Cool Periwinkle');
    });
  });

  group('nearestColorName picks the nearest entry, not a fixed one', () {
    test('an exact first-entry match stays the first entry (Black)', () {
      // Black is kNamedColors.first; nothing beats ΔE 0, so the nearest loop
      // never updates — the "no closer candidate" path.
      expect(nearestColorName(_lab(10, 0, 0)), 'Black');
    });

    test('a reading near terracotta still reads "Warm Terracotta"', () {
      expect(nearestColorName(_lab(60, 24, 24)), 'Warm Terracotta');
    });

    test('a neutral mid reading reads "Neutral Grey", not a chromatic name', () {
      final name = nearestColorName(_lab(50, 0, 0));
      expect(name, 'Neutral Grey');
      expect(name, isNot('Warm Terracotta'));
    });

    test('a blue reading reads "Royal Blue", not a warm name (control)', () {
      final name = nearestColorName(_lab(40, 15, -50));
      expect(name, 'Royal Blue');
      expect(name, isNot('Warm Terracotta'));
    });

    test('a reading nearest a late entry resolves to it (Cream)', () {
      // Exercises a nearest-match that updates to an entry well down the list.
      expect(nearestColorName(_lab(92, 1, 14)), 'Cream');
    });
  });
}
