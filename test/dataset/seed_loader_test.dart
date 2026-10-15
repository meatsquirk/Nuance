import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/dataset/seed_dataset.dart';
import 'package:paint_color_assistant/dataset/seed_loader.dart';
import 'package:paint_color_assistant/dataset/validation_manifest.dart';
import 'package:paint_color_assistant/domain/paint.dart';

void main() {
  // `AssetSeedLoader.load()` reads a bundled asset through `rootBundle`, so the
  // test binding must be initialised before the asset bundle is available.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetSeedLoader.load (the shipped seed asset, SEED-3)', () {
    test('parses the shipped Winsor & Newton oil seed: one brand, one medium, '
        '~15 reviewed optical entries (AC-1/AC-11)', () async {
      final dataset = await const AssetSeedLoader().load();

      // Scope: one brand, one medium (AC-11).
      expect(dataset.brand, 'Winsor & Newton');
      expect(dataset.medium, PaintMedium.oil);
      expect(dataset.isEmpty, isFalse);
      expect(dataset.entries.length, inInclusiveRange(12, 18),
          reason: 'the shipped seed stays narrow (~15 paints)');

      // Every entry is stamped with the seed-wide brand and medium.
      expect(dataset.entries.every((e) => e.brand == 'Winsor & Newton'), isTrue);
      expect(dataset.entries.every((e) => e.medium == PaintMedium.oil), isTrue);

      // Each entry carries reviewed optical data (masstone) and LLM metadata,
      // and an origin of reviewed optical data (never a stored recipe answer).
      expect(dataset.entries.every((e) => e.masstone.lightness.isFinite), isTrue);
      expect(dataset.entries.every((e) => e.origin == SeedOrigin.reviewedOptical),
          isTrue);
      final white = dataset.entries.firstWhere((e) => e.id == 'pw6');
      expect(white.name, 'Titanium White');
      expect(white.pigmentIndex, 'PW6');
      expect(white.opacity, 0.95);
      expect(white.lightfastness, 'I');
      expect(white.masstone.lightness, 96.0);
      expect(white.masstone.a, 0.0);
      expect(white.masstone.b, 2.0);

      // SEED-3 ships optical entries only; candidates (SEED-4) and the ship
      // manifest (SEED-5) are not in the asset yet.
      expect(dataset.candidateMappings, isEmpty);
      expect(dataset.manifest, const ValidationManifest.empty());
      expect(dataset.manifest.shippable, isFalse);
    });

    test('the shipped-seed ids are unique (a palette keys the solver by id)',
        () async {
      final dataset = await const AssetSeedLoader().load();
      final ids = dataset.entries.map((e) => e.id).toSet();
      expect(ids.length, dataset.entries.length);
    });
  });

  group('parseSeedDataset', () {
    test('stamps the seed brand/medium onto each entry and parses integer and '
        'fractional CIELAB values', () {
      const source = '''
      {
        "brand": "Acme",
        "medium": "acrylic",
        "entries": [
          {
            "id": "a",
            "name": "Alpha",
            "pigmentIndex": "PX1",
            "opacity": 0.5,
            "lightfastness": "II",
            "origin": "reviewedOptical",
            "masstone": {"l": 50, "a": -12.5, "b": 24}
          }
        ]
      }
      ''';
      final dataset = parseSeedDataset(source);
      expect(dataset.brand, 'Acme');
      expect(dataset.medium, PaintMedium.acrylic);
      expect(dataset.entries, hasLength(1));
      final e = dataset.entries.single;
      expect(e.id, 'a');
      expect(e.name, 'Alpha');
      expect(e.brand, 'Acme');
      expect(e.medium, PaintMedium.acrylic);
      expect(e.pigmentIndex, 'PX1');
      expect(e.opacity, 0.5);
      expect(e.lightfastness, 'II');
      expect(e.origin, SeedOrigin.reviewedOptical);
      expect(e.masstone.lightness, 50.0); // integer JSON -> double
      expect(e.masstone.a, -12.5);
      expect(e.masstone.b, 24.0);
      // SEED-3 parser yields no candidate mappings and an empty manifest.
      expect(dataset.candidateMappings, isEmpty);
      expect(dataset.manifest, const ValidationManifest.empty());
    });

    test('an unknown medium name throws (a malformed seed is a build error)',
        () {
      const source = '''
      {"brand": "Acme", "medium": "gouache", "entries": []}
      ''';
      expect(() => parseSeedDataset(source), throwsArgumentError);
    });

    test('an unknown origin name throws (a malformed seed is a build error)',
        () {
      const source = '''
      {
        "brand": "Acme",
        "medium": "oil",
        "entries": [
          {
            "id": "a",
            "name": "Alpha",
            "pigmentIndex": "PX1",
            "opacity": 0.5,
            "lightfastness": "I",
            "origin": "handwavy",
            "masstone": {"l": 50, "a": 0, "b": 0}
          }
        ]
      }
      ''';
      expect(() => parseSeedDataset(source), throwsArgumentError);
    });
  });
}
