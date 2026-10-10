import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/palette/paint_dataset.dart';
import 'package:paint_color_assistant/palette/palette_controller.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
);
const _blue = Paint(
  id: 'pb29',
  name: 'Ultramarine Blue',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 32, a: 18, b: -52),
);
const _myPaints = PaintPalette(name: 'My paints', paints: [_white, _blue]);
const _travel = PaintPalette(name: 'Travel set', paints: [_white]);

void main() {
  group('construction and default state', () {
    test('selects the first palette the source lists', () {
      final controller = PaletteController(
        source: const InMemoryPaletteSource(catalogue: [_myPaints, _travel]),
      );
      expect(controller.palettes, [_myPaints, _travel]);
      expect(controller.selectedPalette, _myPaints);
    });

    test('selects nothing when the catalogue is empty (shell default)', () {
      final controller =
          PaletteController(source: const InMemoryPaletteSource());
      expect(controller.palettes, isEmpty);
      expect(controller.selectedPalette, isNull);
      expect(controller.myPaints, isEmpty);
    });

    test('offers the shipped reviewed dataset by default', () {
      final controller =
          PaletteController(source: const InMemoryPaletteSource());
      expect(controller.reviewedDataset, same(kReviewedPaints));
    });

    test('offers an injected reviewed dataset (the harness fixture)', () {
      final controller = PaletteController(
        source: const InMemoryPaletteSource(),
        reviewedDataset: const [_white],
      );
      expect(controller.reviewedDataset, [_white]);
    });

    test('exposes palettes read-only', () {
      final controller = PaletteController(
        source: const InMemoryPaletteSource(catalogue: [_myPaints]),
      );
      expect(() => controller.palettes.add(_travel), throwsUnsupportedError);
    });
  });

  group('myPaints', () {
    test('returns the "My paints" palette paints when present', () {
      final controller = PaletteController(
        source: const InMemoryPaletteSource(catalogue: [_travel, _myPaints]),
      );
      expect(controller.myPaints, [_white, _blue]);
      expect(() => controller.myPaints.add(_white), throwsUnsupportedError);
    });

    test('is empty when there is no "My paints" palette', () {
      final controller = PaletteController(
        source: const InMemoryPaletteSource(catalogue: [_travel]),
      );
      expect(controller.myPaints, isEmpty);
    });
  });

  group('selectPalette', () {
    test('changes the active palette and notifies listeners', () {
      final controller = PaletteController(
        source: const InMemoryPaletteSource(catalogue: [_myPaints, _travel]),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectPalette(_travel);

      expect(controller.selectedPalette, _travel);
      expect(notifications, 1);
    });

    test('is a no-op when the palette is already selected', () {
      final controller = PaletteController(
        source: const InMemoryPaletteSource(catalogue: [_myPaints, _travel]),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectPalette(_myPaints); // already the first/selected one

      expect(controller.selectedPalette, _myPaints);
      expect(notifications, 0);
    });
  });
}
