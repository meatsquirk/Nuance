import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_source.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

/// A fully-populated paint (every optional field set).
const _paint = Paint(
  id: 'pb29',
  name: 'Ultramarine Blue',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 32, a: 12, b: -46),
  pigmentIndex: 'PB29',
  opacity: 0.4,
  brand: 'Winsor & Newton',
  line: "Artists' Oil",
  provenance: ProvenanceTier.confirmed,
);

/// A recipe with a trace component (exercises every recipe/component field).
const _recipe = Recipe(
  medium: PaintMedium.oil,
  components: [
    RecipeComponent(
      paint: _paint,
      partsFraction: 0.98,
      isTrace: true,
      techniqueNote: 'a touch of blue',
    ),
  ],
  predictedColor: ColorCoordinates(lightness: 33, a: 11, b: -44),
  deltaE00: 1.2,
  verdict: 'very close',
  outOfGamut: true,
  muddying: true,
);

/// A fully-populated sample (name, capture, accuracy, note, evidence).
const _fullSample = Sample(
  name: 'Ultramarine Shadow',
  coordinates: ColorCoordinates(lightness: 30, a: 8, b: -40),
  provenance: Provenance(ProvenanceTier.confirmed, note: 'you measured this'),
  justCaptured: true,
  accuracy: CaptureAccuracy.calibrated,
  evidence: [
    EvidencePoint(
      coordinates: ColorCoordinates(lightness: 30.1, a: 7.9, b: -40.1),
      source: 'spectro-01',
    ),
  ],
);

/// A minimal sample (null/empty optionals).
const _minimalSample = Sample(
  name: 'Mid Raw Umber',
  coordinates: ColorCoordinates(lightness: 40, a: 6, b: 18),
  provenance: Provenance(ProvenanceTier.measured),
);

final _harbor = Project(
  id: 'p-harbor',
  name: 'Harbor at Dusk',
  size: '24×30 in',
  samples: const [_fullSample, _minimalSample],
  recipes: const [_recipe],
  note: 'Keep the hull and wall values 2 steps apart.',
  sourcePhotoRef: 'photos/harbor.jpg',
  lastEdited: DateTime.utc(2026, 10, 10, 13, 30),
);

const _bare = Project(id: 'p-bare', name: 'Untitled');

void _expectSameSample(Sample got, Sample want) {
  expect(got.coordinates, want.coordinates);
  expect(got.provenance, want.provenance);
  expect(got.name, want.name);
  expect(got.justCaptured, want.justCaptured);
  expect(got.accuracy, want.accuracy);
  expect(got.evidence, want.evidence);
}

void _expectSameProject(Project got, Project want) {
  expect(got.id, want.id);
  expect(got.name, want.name);
  expect(got.size, want.size);
  expect(got.note, want.note);
  expect(got.sourcePhotoRef, want.sourcePhotoRef);
  expect(got.lastEdited, want.lastEdited);
  expect(got.recipes, want.recipes); // Recipe is value-equal
  expect(got.samples, hasLength(want.samples.length));
  for (var i = 0; i < want.samples.length; i++) {
    _expectSameSample(got.samples[i], want.samples[i]);
  }
}

void main() {
  group('InMemoryProjectSource', () {
    test('defaults to an empty catalogue', () {
      expect(const InMemoryProjectSource().projects(), isEmpty);
    });

    test('lists the projects it was seeded with, in order', () {
      final source = InMemoryProjectSource(catalogue: [_harbor, _bare]);
      expect(source.projects(), [_harbor, _bare]);
    });

    test('exposes the catalogue read-only (callers cannot mutate it)', () {
      final source = InMemoryProjectSource(catalogue: [_bare]);
      expect(() => source.projects().add(_harbor), throwsUnsupportedError);
    });
  });

  group('PersistentProjectSource', () {
    test('lists nothing before anything is saved', () async {
      final source = PersistentProjectSource(InMemoryPersistentStore());
      await source.load();
      expect(source.projects(), isEmpty);
    });

    test(
        'round-trips a fully-populated project through the store, '
        'every field intact', () async {
      final store = InMemoryPersistentStore();
      final source = PersistentProjectSource(store);
      await source.saveProject(_harbor);

      // A fresh source over the same store proves it persisted (not cached).
      final reloaded = PersistentProjectSource(store);
      await reloaded.load();
      expect(reloaded.projects(), hasLength(1));
      _expectSameProject(reloaded.projects().single, _harbor);
    });

    test('round-trips a bare project (null optionals, empty collections)',
        () async {
      final store = InMemoryPersistentStore();
      final source = PersistentProjectSource(store);
      await source.saveProject(_bare);
      final reloaded = PersistentProjectSource(store);
      await reloaded.load();
      _expectSameProject(reloaded.projects().single, _bare);
    });

    test('lists projects in ascending id order and replaces by id', () async {
      final store = InMemoryPersistentStore();
      final source = PersistentProjectSource(store);
      await source.saveProject(_harbor); // "p-harbor"
      await source.saveProject(_bare); // "p-bare" sorts first
      expect(source.projects().map((p) => p.id), ['p-bare', 'p-harbor']);

      // Re-saving the same id replaces rather than duplicates.
      final renamed = _harbor.copyWith(name: 'Harbor at Dawn');
      await source.saveProject(renamed);
      expect(source.projects(), hasLength(2));
      expect(
        source.projects().firstWhere((p) => p.id == 'p-harbor').name,
        'Harbor at Dawn',
      );
    });

    test('exposes the cache read-only (callers cannot mutate it)', () async {
      final source = PersistentProjectSource(InMemoryPersistentStore());
      await source.saveProject(_bare);
      expect(() => source.projects().add(_harbor), throwsUnsupportedError);
    });

    test('exposes its store collection name', () {
      expect(PersistentProjectSource.collection, 'projects');
    });
  });
}
