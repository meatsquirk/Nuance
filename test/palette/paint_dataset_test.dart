import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/palette/paint_dataset.dart';

void main() {
  group('parseReviewedPaints', () {
    test('parses data rows, skipping comments, blanks and the header', () {
      const csv = '''
# a comment line

id,name,brand,line,medium,pigment_index,provenance,cielab_l,cielab_a,cielab_b
pw6,Titanium White,Winsor & Newton,Artists' Oil,oil,PW6,measured,96,0,2
pb29,Ultramarine Blue,Winsor & Newton,Artists' Oil,oil,PB29,confirmed,32,18,-52
''';
      final paints = parseReviewedPaints(csv);

      expect(paints, hasLength(2));
      expect(
        paints.first,
        const Paint(
          id: 'pw6',
          name: 'Titanium White',
          brand: 'Winsor & Newton',
          line: "Artists' Oil",
          medium: PaintMedium.oil,
          pigmentIndex: 'PW6',
          provenance: ProvenanceTier.measured,
          masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
        ),
      );
      expect(paints[1].provenance, ProvenanceTier.confirmed);
      expect(paints[1].masstone.b, -52);
    });

    test('maps empty optional columns (brand, line, pigment) to null', () {
      const csv =
          'id,name,brand,line,medium,pigment_index,provenance,cielab_l,'
          'cielab_a,cielab_b\n'
          'mix,House Mix,,,acrylic,,estimated,50,0,0';
      final paints = parseReviewedPaints(csv);

      expect(paints, hasLength(1));
      expect(paints.single.brand, isNull);
      expect(paints.single.line, isNull);
      expect(paints.single.pigmentIndex, isNull);
      expect(paints.single.medium, PaintMedium.acrylic);
      expect(paints.single.provenance, ProvenanceTier.estimated);
    });

    test('throws on an unknown medium name', () {
      const csv =
          'id,name,brand,line,medium,pigment_index,provenance,cielab_l,'
          'cielab_a,cielab_b\n'
          'x,X,,,gouache,,measured,50,0,0';
      expect(() => parseReviewedPaints(csv), throwsArgumentError);
    });

    test('throws on an unknown provenance tier name', () {
      const csv =
          'id,name,brand,line,medium,pigment_index,provenance,cielab_l,'
          'cielab_a,cielab_b\n'
          'x,X,,,oil,,guessed,50,0,0';
      expect(() => parseReviewedPaints(csv), throwsArgumentError);
    });
  });

  group('kReviewedPaints', () {
    test('includes Titanium White with full reviewed identity', () {
      final white = kReviewedPaints.firstWhere((p) => p.id == 'pw6');
      expect(white.name, 'Titanium White');
      expect(white.brand, 'Winsor & Newton');
      expect(white.line, "Artists' Oil");
      expect(white.medium, PaintMedium.oil);
      expect(white.pigmentIndex, 'PW6');
      expect(white.provenance, ProvenanceTier.measured);
    });

    test('includes Ultramarine Blue (the AC-4 add target)', () {
      expect(
        kReviewedPaints.any((p) => p.name == 'Ultramarine Blue'),
        isTrue,
      );
    });

    test('ships at least three reviewed paints, all measured', () {
      expect(kReviewedPaints.length, greaterThanOrEqualTo(3));
      expect(
        kReviewedPaints.every((p) => p.provenance == ProvenanceTier.measured),
        isTrue,
      );
    });
  });
}
