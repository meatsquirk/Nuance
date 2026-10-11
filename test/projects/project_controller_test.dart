import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_controller.dart';
import 'package:paint_color_assistant/projects/project_source.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';
import 'package:paint_color_assistant/store/source_photo_store.dart';

const _harbor = Project(id: 'p-harbor', name: 'Harbor at Dusk');

const _sample = Sample(
  name: 'Mid Raw Umber',
  coordinates: ColorCoordinates(lightness: 42, a: 16, b: 18),
  provenance: Provenance(ProvenanceTier.measured),
);

const _recipe = Recipe(
  medium: PaintMedium.oil,
  components: [
    RecipeComponent(
      paint: Paint(
        id: 'py42',
        name: 'Yellow Ochre',
        medium: PaintMedium.oil,
        masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
      ),
      partsFraction: 1.0,
    ),
  ],
  predictedColor: ColorCoordinates(lightness: 60, a: 12, b: 46),
  deltaE00: 1.2,
  verdict: 'very close',
);

void main() {
  group('shell reads (PROJECT-1)', () {
    test('lists the projects the source holds', () {
      final controller = ProjectController(
        source: const InMemoryProjectSource(catalogue: [_harbor]),
      );
      expect(controller.projects, [_harbor]);
    });

    test('a fresh install lists no projects', () {
      final controller =
          ProjectController(source: const InMemoryProjectSource());
      expect(controller.projects, isEmpty);
    });

    test('the shell has no opened project, no confusion pairs and no export',
        () {
      final controller =
          ProjectController(source: const InMemoryProjectSource());
      expect(controller.openedProject, isNull);
      expect(controller.confusionPairs, isEmpty);
      expect(controller.lastExport, isNull);
    });

    test('exposes the projects list read-only', () {
      final controller = ProjectController(
        source: const InMemoryProjectSource(catalogue: [_harbor]),
      );
      expect(() => controller.projects.add(_harbor), throwsUnsupportedError);
    });
  });

  group('projectSummaries (PROJECT-3)', () {
    test('summarises each project in listing order (size, counts, last edit)',
        () {
      final harbor = Project(
        id: 'harbor-at-dusk',
        name: 'Harbor at Dusk',
        size: '24×30 in',
        samples: const [_sample, _sample, _sample],
        recipes: [_recipe, _recipe],
        lastEdited: DateTime.now(),
      );
      const study = Project(id: 'old-study', name: 'Old Study');
      final controller = ProjectController(
        source: InMemoryProjectSource(catalogue: [harbor, study]),
      );

      final summaries = controller.projectSummaries;
      expect(summaries.map((s) => s.id), ['harbor-at-dusk', 'old-study']);
      expect(summaries.first.size, '24×30 in');
      expect(summaries.first.sampleCountLabel, '3 samples');
      expect(summaries.first.recipeCountLabel, '2 recipes');
      expect(summaries.first.lastEditedLabel, 'Edited today');
      // The shelled second project (no size, no edits) summarises to its
      // zero-counts, null-size, never-edited form.
      expect(summaries.last.size, isNull);
      expect(summaries.last.sampleCountLabel, '0 samples');
      expect(summaries.last.lastEditedLabel, isNull);
    });

    test('a fresh install has no summaries', () {
      final controller =
          ProjectController(source: const InMemoryProjectSource());
      expect(controller.projectSummaries, isEmpty);
    });
  });

  group('createProject (PROJECT-2 enabler)', () {
    test(
        'creates a project, stamps it edited now, appends it and persists '
        'through the store', () async {
      final store = InMemoryPersistentStore();
      final source = PersistentProjectSource(store);
      await source.load();
      final controller = ProjectController(source: source);

      var notified = 0;
      controller.addListener(() => notified++);

      final created = await controller.createProject(
        id: 'harbor-at-dusk',
        name: 'Harbor at Dusk',
        size: '24×30 in',
      );

      expect(created.id, 'harbor-at-dusk');
      expect(created.name, 'Harbor at Dusk');
      expect(created.size, '24×30 in');
      expect(created.lastEdited, isNotNull);
      expect(DateTime.now().difference(created.lastEdited!).inMinutes, 0);
      expect(controller.projects.map((p) => p.id), ['harbor-at-dusk']);
      expect(notified, 1);

      // A fresh source over the same store proves it was persisted.
      final reloaded = PersistentProjectSource(store);
      await reloaded.load();
      expect(reloaded.projects().single.name, 'Harbor at Dusk');
      expect(reloaded.projects().single.size, '24×30 in');
    });

    test('a project created with no size has a null size', () async {
      final controller = ProjectController(
        source: PersistentProjectSource(InMemoryPersistentStore()),
      );
      final created =
          await controller.createProject(id: 'p1', name: 'Untitled');
      expect(created.size, isNull);
      expect(controller.projects.single.size, isNull);
    });
  });

  group('attach flows (PROJECT-2 enabler)', () {
    test('attachSamples appends samples and persists', () async {
      final store = InMemoryPersistentStore();
      final source = PersistentProjectSource(store);
      final controller = ProjectController(source: source);
      await controller.createProject(id: 'p1', name: 'Harbor');

      final updated = await controller.attachSamples('p1', const [_sample]);
      expect(updated.samples.map((s) => s.name), ['Mid Raw Umber']);
      expect(controller.projects.single.samples, hasLength(1));

      // A second attach adds rather than replaces.
      final again = await controller.attachSamples('p1', const [_sample]);
      expect(again.samples, hasLength(2));

      // Persisted: a fresh source over the store sees the samples.
      final reloaded = PersistentProjectSource(store);
      await reloaded.load();
      expect(reloaded.projects().single.samples, hasLength(2));
    });

    test('attachRecipes appends recipes and persists', () async {
      final store = InMemoryPersistentStore();
      final controller =
          ProjectController(source: PersistentProjectSource(store));
      await controller.createProject(id: 'p1', name: 'Harbor');

      final updated = await controller.attachRecipes('p1', const [_recipe]);
      expect(updated.recipes, hasLength(1));
      expect(updated.recipes.single.verdict, 'very close');

      final reloaded = PersistentProjectSource(store);
      await reloaded.load();
      expect(reloaded.projects().single.recipes, hasLength(1));
    });

    test('setSize sets the free-text size and persists', () async {
      final store = InMemoryPersistentStore();
      final controller =
          ProjectController(source: PersistentProjectSource(store));
      await controller.createProject(id: 'p1', name: 'Harbor');

      final updated = await controller.setSize('p1', '24×30 in');
      expect(updated.size, '24×30 in');

      final reloaded = PersistentProjectSource(store);
      await reloaded.load();
      expect(reloaded.projects().single.size, '24×30 in');
    });

    test('saveNote saves the note so it is retained on reload', () async {
      final store = InMemoryPersistentStore();
      final controller =
          ProjectController(source: PersistentProjectSource(store));
      await controller.createProject(id: 'p1', name: 'Harbor');

      const note = 'Keep the hull and wall values 2 steps apart.';
      final updated = await controller.saveNote('p1', note);
      expect(updated.note, note);

      final reloaded = PersistentProjectSource(store);
      await reloaded.load();
      expect(reloaded.projects().single.note, note);
    });

    test(
        'attachSourcePhoto stores the bytes, records the returned reference '
        'and round-trips through the photo store', () async {
      final store = InMemoryPersistentStore();
      final controller =
          ProjectController(source: PersistentProjectSource(store));
      await controller.createProject(id: 'p1', name: 'Harbor');

      final photos = InMemorySourcePhotoStore();
      final bytes = Uint8List.fromList(const [1, 2, 3, 4]);
      final updated = await controller.attachSourcePhoto('p1', photos, bytes);

      expect(updated.sourcePhotoRef, isNotNull);
      // The project keeps only the reference; the bytes live in the store.
      expect(await photos.read(updated.sourcePhotoRef!), bytes);

      final reloaded = PersistentProjectSource(store);
      await reloaded.load();
      expect(reloaded.projects().single.sourcePhotoRef, updated.sourcePhotoRef);
    });

    test(
        'an attach re-stamps last-edited and, over an in-memory source, keeps '
        'the change in memory only', () async {
      final old = DateTime.utc(2020, 1, 1);
      final seeded = Project(id: 'p1', name: 'Harbor', lastEdited: old);
      final controller = ProjectController(
        source: InMemoryProjectSource(catalogue: [seeded]),
      );

      var notified = 0;
      controller.addListener(() => notified++);

      final updated = await controller.setSize('p1', '12×16 in');
      expect(updated.size, '12×16 in');
      expect(updated.lastEdited!.isAfter(old), isTrue);
      expect(controller.projects.single.size, '12×16 in');
      expect(notified, 1);
    });

    test('attaching to an unknown project id throws a StateError', () async {
      final controller = ProjectController(
        source: PersistentProjectSource(InMemoryPersistentStore()),
      );
      expect(
        () => controller.attachSamples('missing', const [_sample]),
        throwsStateError,
      );
    });
  });
}
