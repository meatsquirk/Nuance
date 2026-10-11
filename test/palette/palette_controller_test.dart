import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/palette/paint_dataset.dart';
import 'package:paint_color_assistant/palette/palette_controller.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

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
// A non-measured dataset paint, so "provenance preserved" is distinguishable
// from a hardcoded-measured add.
const _ochre = Paint(
  id: 'py42',
  name: 'Yellow Ochre',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
  provenance: ProvenanceTier.estimated,
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

  group('addPaintFromDataset (AC-4)', () {
    test('appends the exact dataset paint to "My paints" and notifies',
        () async {
      final controller = PaletteController(
        source: const InMemoryPaletteSource(
          catalogue: [PaintPalette(name: 'My paints')],
        ),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.addPaintFromDataset(_ochre);

      // The exact dataset paint is added — provenance tier preserved, not a
      // default/blanked value (the dataset's own `estimated`, not `measured`).
      expect(controller.myPaints, [_ochre]);
      expect(controller.myPaints.single.provenance, ProvenanceTier.estimated);
      expect(notifications, 1);
    });

    test('persists through a PersistentPaletteSource so the add survives reload',
        () async {
      final store = InMemoryPersistentStore();
      final source = PersistentPaletteSource(store);
      await source.savePalette(const PaintPalette(name: 'My paints'));
      await source.load();
      final controller = PaletteController(source: source);

      await controller.addPaintFromDataset(_ochre);

      expect(controller.myPaints, [_ochre]);
      // A fresh source over the same store reads the persisted paint back.
      final reloaded = PersistentPaletteSource(store);
      await reloaded.load();
      final myPaints =
          reloaded.palettes().firstWhere((p) => p.name == 'My paints');
      expect(myPaints.paints, [_ochre],
          reason: 'the add was saved through the persistent source');
    });

    test('creates a "My paints" palette when there is none yet', () async {
      final controller = PaletteController(
        source: const InMemoryPaletteSource(catalogue: [_travel]),
      );
      expect(controller.myPaints, isEmpty);

      await controller.addPaintFromDataset(_white);

      expect(controller.myPaints, [_white]);
      expect(controller.palettes.map((p) => p.name),
          containsAll(<String>['Travel set', 'My paints']));
      // Travel set was the active palette and stays active (not re-pointed).
      expect(controller.selectedPalette, _travel);
    });

    test('selects the new "My paints" palette when nothing was selected',
        () async {
      final controller =
          PaletteController(source: const InMemoryPaletteSource());
      expect(controller.selectedPalette, isNull);

      await controller.addPaintFromDataset(_white);

      expect(controller.selectedPalette?.name, 'My paints');
      expect(controller.selectedPalette?.paints, [_white]);
    });

    test('keeps the active "My paints" pointed at the updated palette',
        () async {
      final controller = PaletteController(
        source: const InMemoryPaletteSource(
          catalogue: [PaintPalette(name: 'My paints'), _travel],
        ),
      );
      expect(controller.selectedPalette?.name, 'My paints');

      await controller.addPaintFromDataset(_blue);

      // The active palette follows the updated "My paints" (now holding _blue),
      // not the stale empty instance.
      expect(controller.selectedPalette?.name, 'My paints');
      expect(controller.selectedPalette?.paints, [_blue]);
    });
  });
}
