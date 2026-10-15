import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/dataset/dataset_read_endpoint.dart';
import 'package:paint_color_assistant/dataset/seed_dataset.dart';
import 'package:paint_color_assistant/dataset/seed_loader.dart';
import 'package:paint_color_assistant/dataset/seeded_palette_source.dart';
import 'package:paint_color_assistant/dataset/validation_manifest.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

const _masstone = ColorCoordinates(lightness: 95, a: -1, b: 2);

SeedPaintEntry _entry({
  String id = 'pw6',
  String name = 'Titanium White',
  String brand = 'Acme',
  PaintMedium medium = PaintMedium.oil,
  ColorCoordinates masstone = _masstone,
  String? pigmentIndex = 'PW6',
  double? opacity = 0.95,
  String? lightfastness = 'I',
  SeedOrigin origin = SeedOrigin.reviewedOptical,
}) =>
    SeedPaintEntry(
      id: id,
      name: name,
      brand: brand,
      medium: medium,
      masstone: masstone,
      pigmentIndex: pigmentIndex,
      opacity: opacity,
      lightfastness: lightfastness,
      origin: origin,
    );

SeedDataset _dataset({
  List<SeedPaintEntry>? entries,
  List<CandidateMapping>? mappings,
  ValidationManifest manifest = const ValidationManifest.empty(),
}) =>
    SeedDataset(
      brand: 'Acme',
      medium: PaintMedium.oil,
      entries: entries ?? [_entry()],
      candidateMappings: mappings ?? const [],
      manifest: manifest,
    );

void main() {
  group('SeedPaintEntry', () {
    test('maps to the frozen bs-04 Paint, dropping seed-only lightfastness', () {
      final paint = _entry().toPaint();
      expect(paint, isA<Paint>());
      expect(paint.id, 'pw6');
      expect(paint.name, 'Titanium White');
      expect(paint.medium, PaintMedium.oil);
      expect(paint.masstone, _masstone);
      expect(paint.pigmentIndex, 'PW6');
      expect(paint.opacity, 0.95);
      expect(paint.brand, 'Acme');
      // lightfastness is seed-only — Paint has no such field.
      expect(paint.line, isNull);
      expect(paint.provenance, ProvenanceTier.measured);
    });

    test('carries optional metadata as null when unknown', () {
      final paint = _entry(
        pigmentIndex: null,
        opacity: null,
        lightfastness: null,
      ).toPaint();
      expect(paint.pigmentIndex, isNull);
      expect(paint.opacity, isNull);
    });

    test('defaults origin to reviewed optical data', () {
      expect(_entry().origin, SeedOrigin.reviewedOptical);
    });

    test('is value-equal by content and hashes consistently', () {
      expect(_entry(), equals(_entry()));
      expect(_entry().hashCode, _entry().hashCode);
    });

    test('differs when any field differs', () {
      expect(_entry(id: 'a'), isNot(equals(_entry(id: 'b'))));
      expect(_entry(name: 'a'), isNot(equals(_entry(name: 'b'))));
      expect(_entry(brand: 'a'), isNot(equals(_entry(brand: 'b'))));
      expect(
        _entry(medium: PaintMedium.oil),
        isNot(equals(_entry(medium: PaintMedium.acrylic))),
      );
      expect(
        _entry(masstone: _masstone),
        isNot(equals(_entry(
          masstone: const ColorCoordinates(lightness: 0, a: 0, b: 0),
        ))),
      );
      expect(_entry(pigmentIndex: 'a'), isNot(equals(_entry(pigmentIndex: 'b'))));
      expect(_entry(opacity: 0.1), isNot(equals(_entry(opacity: 0.2))));
      expect(
        _entry(lightfastness: 'I'),
        isNot(equals(_entry(lightfastness: 'II'))),
      );
      expect(
        _entry(origin: SeedOrigin.reviewedOptical),
        isNot(equals(_entry(origin: SeedOrigin.llmSeed))),
      );
      // Non-SeedPaintEntry comparison.
      expect(_entry() == Object(), isFalse);
    });

    test('has a readable toString', () {
      expect(_entry().toString(), contains('Titanium White'));
    });
  });

  group('CandidateMapping', () {
    CandidateMapping mapping({
      String target = 'warm grey',
      List<String>? ids,
      SeedOrigin origin = SeedOrigin.llmSeed,
    }) =>
        CandidateMapping(
          targetDescriptor: target,
          candidatePaintIds: ids ?? const ['pw6', 'pbk9'],
          origin: origin,
        );

    test('defaults the origin to the LLM seed (the LLM proposes it)', () {
      expect(mapping().origin, SeedOrigin.llmSeed);
    });

    test('is value-equal and differs on any field', () {
      expect(mapping(), equals(mapping()));
      expect(mapping().hashCode, mapping().hashCode);
      expect(mapping(target: 'a'), isNot(equals(mapping(target: 'b'))));
      expect(
        mapping(ids: const ['a']),
        isNot(equals(mapping(ids: const ['b']))),
      );
      expect(
        mapping(origin: SeedOrigin.llmSeed),
        isNot(equals(mapping(origin: SeedOrigin.reviewedOptical))),
      );
      expect(mapping() == Object(), isFalse);
    });

    test('has a readable toString', () {
      expect(mapping().toString(), contains('warm grey'));
    });
  });

  group('ValidationManifest', () {
    const full = ValidationManifest(
      heldOutCount: 60,
      deltaE00Distribution: [1.0, 2.0, 3.0],
      hybridMeanDeltaE00: 1.5,
      llmAloneMeanDeltaE00: 4.0,
      usableThreshold: 2.5,
    );

    test('empty placeholder is zeroed and never shippable (shell)', () {
      const empty = ValidationManifest.empty();
      expect(empty.heldOutCount, 0);
      expect(empty.deltaE00Distribution, isEmpty);
      expect(empty.hybridMeanDeltaE00, 0);
      expect(empty.llmAloneMeanDeltaE00, 0);
      expect(empty.usableThreshold, 0);
      expect(empty.shippable, isFalse);
    });

    test('shippable is the shell placeholder (false) even when stats look good',
        () {
      // SEED-5 implements the real decision; the shell never ships.
      expect(full.shippable, isFalse);
    });

    test('is value-equal and differs on any field', () {
      expect(
        full,
        equals(const ValidationManifest(
          heldOutCount: 60,
          deltaE00Distribution: [1.0, 2.0, 3.0],
          hybridMeanDeltaE00: 1.5,
          llmAloneMeanDeltaE00: 4.0,
          usableThreshold: 2.5,
        )),
      );
      expect(full.hashCode, isA<int>());
      expect(full, isNot(equals(const ValidationManifest.empty())));
      expect(
        full,
        isNot(equals(const ValidationManifest(
          heldOutCount: 61,
          deltaE00Distribution: [1.0, 2.0, 3.0],
          hybridMeanDeltaE00: 1.5,
          llmAloneMeanDeltaE00: 4.0,
          usableThreshold: 2.5,
        ))),
      );
      expect(
        full,
        isNot(equals(const ValidationManifest(
          heldOutCount: 60,
          deltaE00Distribution: [9.0],
          hybridMeanDeltaE00: 1.5,
          llmAloneMeanDeltaE00: 4.0,
          usableThreshold: 2.5,
        ))),
      );
      expect(
        full,
        isNot(equals(const ValidationManifest(
          heldOutCount: 60,
          deltaE00Distribution: [1.0, 2.0, 3.0],
          hybridMeanDeltaE00: 9.0,
          llmAloneMeanDeltaE00: 4.0,
          usableThreshold: 2.5,
        ))),
      );
      expect(
        full,
        isNot(equals(const ValidationManifest(
          heldOutCount: 60,
          deltaE00Distribution: [1.0, 2.0, 3.0],
          hybridMeanDeltaE00: 1.5,
          llmAloneMeanDeltaE00: 9.0,
          usableThreshold: 2.5,
        ))),
      );
      expect(
        full,
        isNot(equals(const ValidationManifest(
          heldOutCount: 60,
          deltaE00Distribution: [1.0, 2.0, 3.0],
          hybridMeanDeltaE00: 1.5,
          llmAloneMeanDeltaE00: 4.0,
          usableThreshold: 9.0,
        ))),
      );
      expect(full == Object(), isFalse);
    });

    test('has a readable toString', () {
      expect(full.toString(), contains('heldOut 60'));
    });

    test('the primary constructor runs at runtime (coverage)', () {
      // ignore: prefer_const_constructors
      final m = ValidationManifest(
        heldOutCount: 1,
        deltaE00Distribution: const [0.5],
        hybridMeanDeltaE00: 1,
        llmAloneMeanDeltaE00: 2,
        usableThreshold: 3,
      );
      expect(m.heldOutCount, 1);
      expect(m.shippable, isFalse);
    });
  });

  group('SeedDataset', () {
    test('empty placeholder has no scope, entries or shippable manifest', () {
      const empty = SeedDataset.empty();
      expect(empty.brand, '');
      expect(empty.medium, isNull);
      expect(empty.entries, isEmpty);
      expect(empty.candidateMappings, isEmpty);
      expect(empty.manifest, const ValidationManifest.empty());
      expect(empty.isEmpty, isTrue);
    });

    test('a populated dataset is not empty', () {
      expect(_dataset().isEmpty, isFalse);
    });

    test('is value-equal and differs on any field', () {
      expect(_dataset(), equals(_dataset()));
      expect(_dataset().hashCode, _dataset().hashCode);
      expect(_dataset(), isNot(equals(const SeedDataset.empty())));
      expect(
        _dataset(entries: [_entry(id: 'a')]),
        isNot(equals(_dataset(entries: [_entry(id: 'b')]))),
      );
      expect(
        _dataset(mappings: const []),
        isNot(equals(_dataset(mappings: [
          const CandidateMapping(
            targetDescriptor: 't',
            candidatePaintIds: ['pw6'],
          ),
        ]))),
      );
      expect(
        _dataset(manifest: const ValidationManifest.empty()),
        isNot(equals(_dataset(
          manifest: const ValidationManifest(
            heldOutCount: 1,
            deltaE00Distribution: [],
            hybridMeanDeltaE00: 0,
            llmAloneMeanDeltaE00: 0,
            usableThreshold: 0,
          ),
        ))),
      );
      // brand / medium differences.
      expect(
        _dataset(),
        isNot(equals(SeedDataset(
          brand: 'Other',
          medium: PaintMedium.oil,
          entries: [_entry()],
          candidateMappings: const [],
          manifest: const ValidationManifest.empty(),
        ))),
      );
      expect(
        _dataset(),
        isNot(equals(SeedDataset(
          brand: 'Acme',
          medium: PaintMedium.acrylic,
          entries: [_entry()],
          candidateMappings: const [],
          manifest: const ValidationManifest.empty(),
        ))),
      );
      expect(_dataset() == Object(), isFalse);
    });

    test('has a readable toString', () {
      expect(_dataset().toString(), contains('Acme'));
    });
  });

  group('AssetSeedLoader', () {
    // SEED-3 replaced the shell's empty-placeholder load with a real parse of
    // the shipped asset; `load()` / `parseSeedDataset` are exercised in
    // `test/dataset/seed_loader_test.dart` (they need the asset bundle binding).

    test('exposes its asset path (default or overridden)', () {
      expect(const AssetSeedLoader().assetPath,
          AssetSeedLoader.defaultAssetPath);
      expect(
        const AssetSeedLoader(assetPath: 'assets/paints/x.json').assetPath,
        'assets/paints/x.json',
      );
    });

    test('is a SeedLoader', () {
      expect(const AssetSeedLoader(), isA<SeedLoader>());
    });

    test('the constructor runs at runtime (coverage)', () {
      // ignore: prefer_const_constructors
      final loader = AssetSeedLoader();
      expect(loader.assetPath, AssetSeedLoader.defaultAssetPath);
    });
  });

  group('SeededPaletteSource', () {
    test('an empty dataset lists no palette (behaviour-neutral shell)', () {
      const source = SeededPaletteSource(SeedDataset.empty());
      expect(source, isA<PaletteSource>());
      expect(source.palettes(), isEmpty);
    });

    test('a populated dataset lists one palette named "<brand> <medium>"', () {
      final source = SeededPaletteSource(_dataset(
        entries: [_entry(id: 'a'), _entry(id: 'b')],
      ));
      final palettes = source.palettes();
      expect(palettes, hasLength(1));
      expect(palettes.single.name, 'Acme oil');
      expect(palettes.single.paints, hasLength(2));
      expect(palettes.single.paints.first.id, 'a');
    });
  });

  group('CompositePaletteSource', () {
    test('concatenates its sources in order', () {
      const a = InMemoryPaletteSource(
        catalogue: [PaintPalette(name: 'A')],
      );
      const b = InMemoryPaletteSource(
        catalogue: [PaintPalette(name: 'B1'), PaintPalette(name: 'B2')],
      );
      const composite = CompositePaletteSource([a, b]);
      expect(
        composite.palettes().map((p) => p.name),
        ['A', 'B1', 'B2'],
      );
    });

    test('an empty seed composed with a user source lists only the user '
        'palettes (the shell composition)', () {
      const user = InMemoryPaletteSource(
        catalogue: [PaintPalette(name: 'My paints')],
      );
      const composite = CompositePaletteSource([
        SeededPaletteSource(SeedDataset.empty()),
        user,
      ]);
      expect(composite.palettes().map((p) => p.name), ['My paints']);
    });
  });

  group('DatasetReadEndpoint', () {
    testWidgets('of() exposes the dataset and manifest to descendants',
        (tester) async {
      final dataset = _dataset(
        manifest: const ValidationManifest(
          heldOutCount: 55,
          deltaE00Distribution: [1.0],
          hybridMeanDeltaE00: 1.0,
          llmAloneMeanDeltaE00: 2.0,
          usableThreshold: 2.0,
        ),
      );
      late SeedDataset seen;
      late DatasetReadEndpoint endpoint;
      await tester.pumpWidget(
        DatasetReadEndpoint(
          dataset: dataset,
          child: Builder(
            builder: (context) {
              seen = DatasetReadEndpoint.of(context);
              endpoint = context
                  .dependOnInheritedWidgetOfExactType<DatasetReadEndpoint>()!;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, same(dataset));
      expect(endpoint.manifest, dataset.manifest);
    });

    testWidgets('maybeOf returns the dataset when present and null when absent',
        (tester) async {
      await tester.pumpWidget(
        DatasetReadEndpoint(
          dataset: const SeedDataset.empty(),
          child: Builder(
            builder: (context) {
              expect(DatasetReadEndpoint.maybeOf(context),
                  const SeedDataset.empty());
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(DatasetReadEndpoint.maybeOf(context), isNull);
            return const SizedBox();
          },
        ),
      );
    });

    test('updateShouldNotify is true only when the dataset changes', () {
      final a = DatasetReadEndpoint(
        dataset: _dataset(),
        child: const SizedBox(),
      );
      final sameData = DatasetReadEndpoint(
        dataset: _dataset(),
        child: const SizedBox(),
      );
      final different = DatasetReadEndpoint(
        dataset: const SeedDataset.empty(),
        child: const SizedBox(),
      );
      expect(a.updateShouldNotify(sameData), isFalse);
      expect(a.updateShouldNotify(different), isTrue);
    });
  });
}
