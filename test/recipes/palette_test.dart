import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/recipes/palette.dart';

void main() {
  const white = Paint(
    id: 'tw',
    name: 'Titanium White',
    medium: PaintMedium.acrylic,
    masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
  );
  const ochre = Paint(
    id: 'yo',
    name: 'Yellow Ochre',
    medium: PaintMedium.acrylic,
    masstone: ColorCoordinates(lightness: 60, a: 12, b: 48),
  );

  group('construction', () {
    test('defaults to an empty paint list', () {
      expect(const PaintPalette(name: 'My paints').paints, isEmpty);
    });

    test('holds the paints it was built with, in order', () {
      const palette = PaintPalette(name: 'My paints', paints: [white, ochre]);
      expect(palette.name, 'My paints');
      expect(palette.paints, [white, ochre]);
    });
  });

  test('constructs at runtime (covers the const constructor line)', () {
    // ignore: prefer_const_constructors
    final palette = PaintPalette(name: 'My paints', paints: const [white]);
    expect(palette, isA<PaintPalette>());
  });

  group('equality and hashCode', () {
    test('equal when the name and the paints (in order) match', () {
      const a = PaintPalette(name: 'My paints', paints: [white, ochre]);
      const b = PaintPalette(name: 'My paints', paints: [white, ochre]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('unequal when the name differs', () {
      expect(
        const PaintPalette(name: 'My paints', paints: [white]),
        isNot(equals(const PaintPalette(name: 'Studio', paints: [white]))),
      );
    });

    test('unequal when the paints differ', () {
      expect(
        const PaintPalette(name: 'My paints', paints: [white, ochre]),
        isNot(equals(const PaintPalette(name: 'My paints', paints: [white]))),
      );
    });

    test('unequal when the paint order differs', () {
      expect(
        const PaintPalette(name: 'My paints', paints: [white, ochre]),
        isNot(equals(const PaintPalette(name: 'My paints', paints: [ochre, white]))),
      );
    });

    test('unequal to a non-PaintPalette object', () {
      // ignore: unrelated_type_equality_checks
      expect(const PaintPalette(name: 'My paints') == 'nope', isFalse);
    });
  });

  test('toString reports the name and the paint count', () {
    expect(
      const PaintPalette(name: 'My paints', paints: [white, ochre]).toString(),
      'PaintPalette("My paints", 2 paints)',
    );
  });
}
