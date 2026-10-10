import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';

void main() {
  const base = Paint(
    id: 'tw',
    name: 'Titanium White',
    medium: PaintMedium.acrylic,
    masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
    pigmentIndex: 'PW6',
    opacity: 0.95,
  );

  group('PaintMedium', () {
    test('has exactly acrylic and oil', () {
      expect(PaintMedium.values, [PaintMedium.acrylic, PaintMedium.oil]);
    });

    test('names are the plain-language medium', () {
      expect(PaintMedium.acrylic.name, 'acrylic');
      expect(PaintMedium.oil.name, 'oil');
    });
  });

  group('equality and hashCode', () {
    test('equal when every field matches', () {
      const same = Paint(
        id: 'tw',
        name: 'Titanium White',
        medium: PaintMedium.acrylic,
        masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
        pigmentIndex: 'PW6',
        opacity: 0.95,
      );
      expect(base, equals(same));
      expect(base.hashCode, equals(same.hashCode));
    });

    test('unequal when the id differs', () {
      expect(
        base,
        isNot(equals(const Paint(
          id: 'other',
          name: 'Titanium White',
          medium: PaintMedium.acrylic,
          masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
          pigmentIndex: 'PW6',
          opacity: 0.95,
        ))),
      );
    });

    test('unequal when the name differs', () {
      expect(
        base,
        isNot(equals(const Paint(
          id: 'tw',
          name: 'Zinc White',
          medium: PaintMedium.acrylic,
          masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
          pigmentIndex: 'PW6',
          opacity: 0.95,
        ))),
      );
    });

    test('unequal when the medium differs', () {
      expect(
        base,
        isNot(equals(const Paint(
          id: 'tw',
          name: 'Titanium White',
          medium: PaintMedium.oil,
          masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
          pigmentIndex: 'PW6',
          opacity: 0.95,
        ))),
      );
    });

    test('unequal when the masstone differs', () {
      expect(
        base,
        isNot(equals(const Paint(
          id: 'tw',
          name: 'Titanium White',
          medium: PaintMedium.acrylic,
          masstone: ColorCoordinates(lightness: 95, a: -0.5, b: 2.5),
          pigmentIndex: 'PW6',
          opacity: 0.95,
        ))),
      );
    });

    test('unequal when the pigment index differs', () {
      expect(
        base,
        isNot(equals(const Paint(
          id: 'tw',
          name: 'Titanium White',
          medium: PaintMedium.acrylic,
          masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
          pigmentIndex: 'PW4',
          opacity: 0.95,
        ))),
      );
    });

    test('unequal when the opacity differs', () {
      expect(
        base,
        isNot(equals(const Paint(
          id: 'tw',
          name: 'Titanium White',
          medium: PaintMedium.acrylic,
          masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
          pigmentIndex: 'PW6',
          opacity: 0.5,
        ))),
      );
    });

    test('unequal to a non-Paint object', () {
      // ignore: unrelated_type_equality_checks
      expect(base == 'nope', isFalse);
    });
  });

  test('constructs at runtime (covers the const constructor line)', () {
    // A non-const invocation so the constructor executes at runtime; the const
    // uses above are canonicalised at compile time.
    // ignore: prefer_const_constructors
    final paint = Paint(
      id: 'ib',
      name: 'Ivory Black',
      medium: PaintMedium.oil,
      // ignore: prefer_const_constructors
      masstone: ColorCoordinates(lightness: 16, a: 0.2, b: 0.8),
    );
    expect(paint, isA<Paint>());
  });

  group('optional fields', () {
    test('default to null when omitted', () {
      const minimal = Paint(
        id: 'ib',
        name: 'Ivory Black',
        medium: PaintMedium.oil,
        masstone: ColorCoordinates(lightness: 16, a: 0.2, b: 0.8),
      );
      expect(minimal.pigmentIndex, isNull);
      expect(minimal.opacity, isNull);
    });
  });

  group('bs-06 identity and provenance (D-2)', () {
    const minimal = Paint(
      id: 'ib',
      name: 'Ivory Black',
      medium: PaintMedium.oil,
      masstone: ColorCoordinates(lightness: 16, a: 0.2, b: 0.8),
    );

    test('brand/line default to null and provenance to measured', () {
      expect(minimal.brand, isNull);
      expect(minimal.line, isNull);
      expect(minimal.provenance, ProvenanceTier.measured);
    });

    test('carry the brand, line and provenance when given', () {
      const identified = Paint(
        id: 'pw6',
        name: 'Titanium White',
        medium: PaintMedium.oil,
        masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
        brand: 'Winsor & Newton',
        line: "Artists' Oil",
        provenance: ProvenanceTier.confirmed,
      );
      expect(identified.brand, 'Winsor & Newton');
      expect(identified.line, "Artists' Oil");
      expect(identified.provenance, ProvenanceTier.confirmed);
    });

    test('unequal when the brand differs', () {
      expect(
        minimal,
        isNot(equals(const Paint(
          id: 'ib',
          name: 'Ivory Black',
          medium: PaintMedium.oil,
          masstone: ColorCoordinates(lightness: 16, a: 0.2, b: 0.8),
          brand: 'Gamblin',
        ))),
      );
    });

    test('unequal when the line differs', () {
      expect(
        minimal,
        isNot(equals(const Paint(
          id: 'ib',
          name: 'Ivory Black',
          medium: PaintMedium.oil,
          masstone: ColorCoordinates(lightness: 16, a: 0.2, b: 0.8),
          line: 'Studio',
        ))),
      );
    });

    test('unequal when the provenance differs', () {
      expect(
        minimal,
        isNot(equals(const Paint(
          id: 'ib',
          name: 'Ivory Black',
          medium: PaintMedium.oil,
          masstone: ColorCoordinates(lightness: 16, a: 0.2, b: 0.8),
          provenance: ProvenanceTier.estimated,
        ))),
      );
      expect(
        minimal.hashCode,
        isNot(equals(const Paint(
          id: 'ib',
          name: 'Ivory Black',
          medium: PaintMedium.oil,
          masstone: ColorCoordinates(lightness: 16, a: 0.2, b: 0.8),
          provenance: ProvenanceTier.estimated,
        ).hashCode)),
      );
    });
  });

  test('toString reports id, name, medium and masstone', () {
    expect(
      base.toString(),
      'Paint(tw "Titanium White", acrylic, '
      'ColorCoordinates(L 96.0, a -0.5, b 2.5))',
    );
  });
}
