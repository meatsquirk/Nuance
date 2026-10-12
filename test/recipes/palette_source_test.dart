import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

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

/// A fully-populated paint — brand, line, pigment index, opacity and a
/// non-default provenance — so the round-trip exercises every optional field.
const _full = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
  pigmentIndex: 'PW6',
  opacity: 0.95,
  brand: 'Winsor & Newton',
  line: "Artists' Oil",
  provenance: ProvenanceTier.confirmed,
);

const _myPaints = PaintPalette(name: 'My paints', paints: [_white, _blue]);
const _oils = PaintPalette(name: 'Studio oils', paints: [_white]);
// Mixes a fully-populated paint with a minimal one (null optionals).
const _mixed = PaintPalette(name: 'My paints', paints: [_full, _blue]);

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

  group('PersistentPaletteSource', () {
    test('lists nothing before anything is saved', () async {
      final source = PersistentPaletteSource(InMemoryPersistentStore());
      await source.load();
      expect(source.palettes(), isEmpty);
    });

    test('round-trips a saved palette through the store, every field intact',
        () async {
      final store = InMemoryPersistentStore();
      final source = PersistentPaletteSource(store);
      await source.savePalette(_mixed);

      // A fresh source over the same store proves it persisted (not cached).
      final reloaded = PersistentPaletteSource(store);
      await reloaded.load();
      expect(reloaded.palettes(), [_mixed]);
      final roundTripped = reloaded.palettes().single.paints.first;
      expect(roundTripped, _full); // brand/line/pigment/opacity/provenance kept
    });

    test('lists palettes in ascending name order and replaces by name',
        () async {
      final store = InMemoryPersistentStore();
      final source = PersistentPaletteSource(store);
      await source.savePalette(_oils); // "Studio oils"
      await source.savePalette(_myPaints); // "My paints"
      // Keyed by name → "My paints" sorts before "Studio oils".
      expect(source.palettes(), [_myPaints, _oils]);

      // Re-saving the same name replaces rather than duplicates.
      const edited = PaintPalette(name: 'My paints', paints: [_white]);
      await source.savePalette(edited);
      expect(source.palettes(), [edited, _oils]);
    });

    test('exposes the cache read-only (callers cannot mutate it)', () async {
      final source = PersistentPaletteSource(InMemoryPersistentStore());
      await source.savePalette(_oils);
      expect(() => source.palettes().add(_myPaints), throwsUnsupportedError);
    });

    test('exposes its store collection name', () {
      expect(PersistentPaletteSource.collection, 'palettes');
    });
  });
}
