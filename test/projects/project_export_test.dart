import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_export.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';

const _umber = Sample(
  name: 'Mid Raw Umber',
  coordinates: ColorCoordinates(lightness: 42, a: 16, b: 18),
  provenance: Provenance(ProvenanceTier.measured),
);

const _anon = Sample(
  coordinates: ColorCoordinates(lightness: 58, a: 4, b: -2),
  provenance: Provenance(ProvenanceTier.estimated),
);

Recipe _recipe({String? verdict}) => Recipe(
      medium: PaintMedium.oil,
      components: const [
        RecipeComponent(
          paint: Paint(
            id: 'py42',
            name: 'Yellow Ochre',
            medium: PaintMedium.oil,
            masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
          ),
          partsFraction: 0.6,
        ),
        RecipeComponent(
          paint: Paint(
            id: 'pbk9',
            name: 'Ivory Black',
            medium: PaintMedium.oil,
            masstone: ColorCoordinates(lightness: 12, a: 0, b: 1),
          ),
          partsFraction: 0.4,
        ),
      ],
      predictedColor: const ColorCoordinates(lightness: 42, a: 16, b: 18),
      deltaE00: 1.8,
      verdict: verdict,
    );

void main() {
  group('sampleStudioLabel', () {
    test('uses the sample name when it has one', () {
      expect(sampleStudioLabel(_umber), 'Mid Raw Umber');
    });

    test('falls back to a CIELAB label for an unnamed sample', () {
      expect(sampleStudioLabel(_anon), 'Lab 58/4/-2');
    });
  });

  group('recipe labels', () {
    test('recipePaintList joins the component paints with " + "', () {
      expect(recipePaintList(_recipe()), 'Yellow Ochre + Ivory Black');
    });

    test('recipeStudioLabel appends the verdict when present', () {
      expect(recipeStudioLabel(_recipe(verdict: 'very close')),
          'Yellow Ochre + Ivory Black (very close)');
    });

    test('recipeStudioLabel omits the verdict when absent', () {
      expect(recipeStudioLabel(_recipe()), 'Yellow Ochre + Ivory Black');
    });
  });

  group('buildProjectStudioSheet', () {
    test('produces a PDF that references the project, its samples and recipes',
        () async {
      final project = Project(
        id: 'p-harbor',
        name: 'Harbor at Dusk',
        size: '24×30 in',
        samples: const [_umber, _anon],
        recipes: [_recipe(verdict: 'very close')],
      );

      final bytes = await buildProjectStudioSheet(project);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

      final document = String.fromCharCodes(bytes);
      expect(document, contains('Harbor at Dusk'));
      expect(document, contains('Mid Raw Umber'));
      // The unnamed sample appears by its CIELAB fallback label.
      expect(document, contains('Lab 58/4/-2'));
      // Each recipe is referenced by its component paint list.
      expect(document, contains('Yellow Ochre + Ivory Black'));
    });

    test('produces a PDF for a project with no size, samples or recipes',
        () async {
      // Exercises the no-size branch and the empty sample/recipe loops.
      final bytes = await buildProjectStudioSheet(
        const Project(id: 'empty', name: 'Blank Canvas'),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(String.fromCharCodes(bytes), contains('Blank Canvas'));
    });
  });
}
