import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_summary.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';

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
  group('ProjectSummary.of', () {
    test('projects the id, name, size and counts of the project', () {
      final summary = ProjectSummary.of(
        Project(
          id: 'harbor-at-dusk',
          name: 'Harbor at Dusk',
          size: '24×30 in',
          samples: const [_sample, _sample, _sample],
          recipes: [_recipe, _recipe],
          lastEdited: DateTime(2026, 10, 11, 9),
        ),
        now: DateTime(2026, 10, 11, 18),
      );

      expect(summary.id, 'harbor-at-dusk');
      expect(summary.name, 'Harbor at Dusk');
      expect(summary.size, '24×30 in');
      expect(summary.sampleCount, 3);
      expect(summary.recipeCount, 2);
    });

    test('a project with no size carries a null size', () {
      final summary = ProjectSummary.of(
        const Project(id: 'p1', name: 'Untitled'),
        now: DateTime(2026, 10, 11),
      );
      expect(summary.size, isNull);
    });
  });

  group('count labels (pluralisation)', () {
    test('pluralises a count other than one', () {
      final summary = ProjectSummary.of(
        Project(
          id: 'p1',
          name: 'Many',
          samples: const [_sample, _sample, _sample, _sample, _sample, _sample],
          recipes: [_recipe, _recipe, _recipe],
        ),
      );
      expect(summary.sampleCountLabel, '6 samples');
      expect(summary.recipeCountLabel, '3 recipes');
    });

    test('a count of zero is still pluralised', () {
      final summary = ProjectSummary.of(const Project(id: 'p1', name: 'Empty'));
      expect(summary.sampleCountLabel, '0 samples');
      expect(summary.recipeCountLabel, '0 recipes');
    });

    test('a count of one is singular', () {
      final summary = ProjectSummary.of(
        Project(
          id: 'p1',
          name: 'One',
          samples: const [_sample],
          recipes: [_recipe],
        ),
      );
      expect(summary.sampleCountLabel, '1 sample');
      expect(summary.recipeCountLabel, '1 recipe');
    });
  });

  group('last-edited label (relative, calendar-day granularity)', () {
    ProjectSummary summaryEdited(DateTime? lastEdited, {required DateTime now}) =>
        ProjectSummary.of(
          Project(id: 'p1', name: 'P', lastEdited: lastEdited),
          now: now,
        );

    test('a project never edited has no label', () {
      expect(summaryEdited(null, now: DateTime(2026, 10, 11)).lastEditedLabel,
          isNull);
    });

    test('edited earlier today reads "Edited today"', () {
      final label = summaryEdited(
        DateTime(2026, 10, 11, 1),
        now: DateTime(2026, 10, 11, 23),
      ).lastEditedLabel;
      expect(label, 'Edited today');
    });

    test('edited later in the day than "now" still reads "today"', () {
      // Guards the days <= 0 branch: a clock that reads behind the edit time.
      final label = summaryEdited(
        DateTime(2026, 10, 11, 20),
        now: DateTime(2026, 10, 11, 8),
      ).lastEditedLabel;
      expect(label, 'Edited today');
    });

    test('edited the previous calendar day reads "Edited yesterday"', () {
      final label = summaryEdited(
        DateTime(2026, 10, 10, 23),
        now: DateTime(2026, 10, 11, 1),
      ).lastEditedLabel;
      expect(label, 'Edited yesterday');
    });

    test('edited several days ago reads "Edited N days ago"', () {
      final label = summaryEdited(
        DateTime(2026, 10, 8, 9),
        now: DateTime(2026, 10, 11, 9),
      ).lastEditedLabel;
      expect(label, 'Edited 3 days ago');
    });
  });
}
