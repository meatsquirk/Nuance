import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

void main() {
  const base = ColorCoordinates(lightness: 58, a: 24, b: 30);

  group('equality and hashCode', () {
    test('equal when all coordinates match', () {
      const same = ColorCoordinates(lightness: 58, a: 24, b: 30);
      expect(base, equals(same));
      expect(base.hashCode, equals(same.hashCode));
    });

    test('unequal when lightness differs', () {
      expect(
        base,
        isNot(equals(const ColorCoordinates(lightness: 59, a: 24, b: 30))),
      );
    });

    test('unequal when a differs', () {
      expect(
        base,
        isNot(equals(const ColorCoordinates(lightness: 58, a: 25, b: 30))),
      );
    });

    test('unequal when b differs', () {
      expect(
        base,
        isNot(equals(const ColorCoordinates(lightness: 58, a: 24, b: 31))),
      );
    });

    test('unequal to a non-ColorCoordinates object', () {
      // ignore: unrelated_type_equality_checks
      expect(base == 'nope', isFalse);
    });
  });

  test('toString reports the canonical CIELAB values', () {
    expect(base.toString(), 'ColorCoordinates(L 58.0, a 24.0, b 30.0)');
  });
}
