import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
);
const _blue = Paint(
  id: 'pb29',
  name: 'Ultramarine Blue',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 32, a: 12, b: -46),
);

const _myPaints = PaintPalette(name: 'My paints', paints: [_white, _blue]);
const _oils = PaintPalette(name: 'Studio oils', paints: [_white]);

void main() {
  group('InMemoryPaletteSource', () {
    test('defaults to an empty catalogue', () {
      expect(const InMemoryPaletteSource().palettes(), isEmpty);
    });

    test('lists the palettes it was seeded with, in order', () {
      const source = InMemoryPaletteSource(catalogue: [_myPaints, _oils]);
      expect(source.palettes(), [_myPaints, _oils]);
    });

    test('exposes the catalogue read-only (callers cannot mutate it)', () {
      const source = InMemoryPaletteSource(catalogue: [_myPaints]);
      expect(
        () => source.palettes().add(_oils),
        throwsUnsupportedError,
      );
    });
  });
}
