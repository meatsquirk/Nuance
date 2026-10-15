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

      // SEED-4 ships the LLM candidate combinations.
      expect(dataset.candidateMappings, isNotEmpty);

      // SEED-5 ships the held-out validation manifest (AC-5/AC-6): a recorded
      // held-out run (50–100 recipes, one ΔE00 each) whose hybrid clears the
      // usable threshold and beats the LLM alone, so the seed is shippable.
      final manifest = dataset.manifest;
      expect(manifest, isNot(const ValidationManifest.empty()));
      expect(manifest.heldOutCount, inInclusiveRange(50, 100));
      expect(manifest.deltaE00Distribution.length, manifest.heldOutCount,
          reason: 'one recorded ΔE00 per held-out recipe (AC-5)');
      expect(manifest.deltaE00Distribution.every((d) => d.isFinite && d >= 0),
          isTrue);
      expect(manifest.hybridMeanDeltaE00, lessThan(manifest.usableThreshold));
      expect(manifest.hybridMeanDeltaE00,
          lessThan(manifest.llmAloneMeanDeltaE00));
      expect(manifest.shippable, isTrue,
          reason: 'the shipped seed ships only on its recorded evidence (AC-6)');
    });

    test('the shipped-seed ids are unique (a palette keys the solver by id)',
        () async {
      final dataset = await const AssetSeedLoader().load();
      final ids = dataset.entries.map((e) => e.id).toSet();
      expect(ids.length, dataset.entries.length);
    });

    test('the shipped candidate combinations are LLM-seeded and grounded in '
        'shipped entries (AC-2)', () async {
      final dataset = await const AssetSeedLoader().load();
      final seedIds = {for (final e in dataset.entries) e.id};
      // The loader stamps every candidate combination llmSeed regardless of the
      // asset — a candidate set is an LLM proposal of which paints to mix.
      expect(
          dataset.candidateMappings.every((m) => m.origin == SeedOrigin.llmSeed),
          isTrue);
      // Every candidate paint id references a real shipped entry (no fabricated
      // id), and each combination carries a non-empty paint-id set with no
      // ratio (ratios are the solver's, AC-3).
      for (final m in dataset.candidateMappings) {
        expect(m.candidatePaintIds, isNotEmpty);
        expect(m.candidatePaintIds.every(seedIds.contains), isTrue,
            reason: '${m.targetDescriptor} references an unknown paint id');
      }
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
      // A seed with no `manifest` section yields the empty (non-shippable)
      // manifest — the null branch of the manifest parse (AC-6: no run, no ship).
      expect(dataset.candidateMappings, isEmpty);
      expect(dataset.manifest, const ValidationManifest.empty());
      expect(dataset.manifest.shippable, isFalse);
    });

    test('parses a held-out validation manifest section verbatim (AC-5/AC-6)',
        () {
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
        ],
        "manifest": {
          "heldOutCount": 3,
          "hybridMeanDeltaE00": 2,
          "llmAloneMeanDeltaE00": 4.5,
          "usableThreshold": 3,
          "deltaE00Distribution": [1.5, 2, 2.5]
        }
      }
      ''';
      final manifest = parseSeedDataset(source).manifest;
      // Read verbatim: integer JSON (heldOutCount, hybrid mean, threshold) and
      // fractional values parse to the recorded fields.
      expect(manifest.heldOutCount, 3);
      expect(manifest.deltaE00Distribution, [1.5, 2.0, 2.5]);
      expect(manifest.hybridMeanDeltaE00, 2.0);
      expect(manifest.llmAloneMeanDeltaE00, 4.5);
      expect(manifest.usableThreshold, 3.0);
      // Clears the threshold (2 < 3) and beats the LLM alone (2 < 4.5) → ships.
      expect(manifest.shippable, isTrue);
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

    test('parses candidate combinations, stamping llmSeed regardless of the '
        'asset origin (AC-2)', () {
      const source = '''
      {
        "brand": "Acme",
        "medium": "oil",
        "entries": [],
        "candidateMappings": [
          {"targetDescriptor": "warm grey",
           "candidatePaintIds": ["a", "b"],
           "origin": "reviewedOptical"}
        ]
      }
      ''';
      final dataset = parseSeedDataset(source);
      final mapping = dataset.candidateMappings.single;
      expect(mapping.targetDescriptor, 'warm grey');
      expect(mapping.candidatePaintIds, ['a', 'b']);
      // The asset said reviewedOptical; the loader stamps llmSeed anyway — a
      // candidate combination is always an LLM proposal (AC-2), never a
      // measured-origin claim.
      expect(mapping.origin, SeedOrigin.llmSeed);
    });
  });

  group('ingestEntryRecord (the AC-4 accept-metadata / reject-claimed rule)',
      () {
    test('keeps accepted metadata + measured masstone and strips every claimed '
        'spectral curve / ratio field', () {
      final raw = <String, dynamic>{
        'id': 'a',
        'name': 'Alpha',
        'pigmentIndex': 'PX1',
        'opacity': 0.5,
        'lightfastness': 'I',
        'origin': 'reviewedOptical',
        'masstone': {'l': 50, 'a': 0, 'b': 0},
        // LLM-claimed values that must not enter the dataset:
        'spectralCurve': [0.1, 0.2, 0.3],
        'reflectanceCurve': [0.4],
        'spectral': 'bogus',
        'ratio': 0.42,
        'ratios': [1, 2],
        'parts': 3,
        'partsFraction': 0.25,
      };
      final accepted = ingestEntryRecord(raw);
      // Accepted metadata + optical data retained.
      expect(accepted['pigmentIndex'], 'PX1');
      expect(accepted['opacity'], 0.5);
      expect(accepted['lightfastness'], 'I');
      expect(accepted['masstone'], {'l': 50, 'a': 0, 'b': 0});
      // Every claimed field stripped.
      for (final claimed in kRejectedClaimedFields) {
        expect(accepted.containsKey(claimed), isFalse,
            reason: '$claimed must be rejected');
      }
    });

    test('parsing a record carrying claimed values yields the same stored entry '
        'as the clean record (claimed values have no effect)', () {
      const withClaimed = '''
      {
        "brand": "Acme",
        "medium": "oil",
        "entries": [
          {
            "id": "a", "name": "Alpha", "pigmentIndex": "PX1", "opacity": 0.5,
            "lightfastness": "I", "origin": "reviewedOptical",
            "masstone": {"l": 50, "a": 0, "b": 0},
            "spectralCurve": [0.1, 0.2], "ratio": 0.42
          }
        ]
      }
      ''';
      const clean = '''
      {
        "brand": "Acme",
        "medium": "oil",
        "entries": [
          {
            "id": "a", "name": "Alpha", "pigmentIndex": "PX1", "opacity": 0.5,
            "lightfastness": "I", "origin": "reviewedOptical",
            "masstone": {"l": 50, "a": 0, "b": 0}
          }
        ]
      }
      ''';
      final fromClaimed = parseSeedDataset(withClaimed).entries.single;
      final fromClean = parseSeedDataset(clean).entries.single;
      // The claimed spectral curve / ratio made no difference to the stored
      // entry — the metadata was accepted, the claimed values dropped.
      expect(fromClaimed, fromClean);
      expect(fromClaimed.pigmentIndex, 'PX1');

      // Control: a genuine metadata difference DOES change the stored entry, so
      // the ingest is not vacuously dropping everything.
      const differentMetadata = '''
      {
        "brand": "Acme",
        "medium": "oil",
        "entries": [
          {
            "id": "a", "name": "Alpha", "pigmentIndex": "PX2", "opacity": 0.5,
            "lightfastness": "I", "origin": "reviewedOptical",
            "masstone": {"l": 50, "a": 0, "b": 0}
          }
        ]
      }
      ''';
      expect(parseSeedDataset(differentMetadata).entries.single,
          isNot(fromClean));
    });
  });
}
