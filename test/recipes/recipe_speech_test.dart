import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/recipe_speech.dart';

// Unit coverage of the spoken-output builders RECIPE-4 drives through the
// controller (AC-11 target, AC-12 recipe). The acceptance suite exercises them
// end to end against the real engine's top recipe; these pin the exact content
// each builder produces, with fixtures chosen so the rounding/normalisation is
// unambiguous.

/// "Deep Olive Green" at CIELCh L 42 / C 28 / h 108 (CIELAB 42, −8.65, 26.63).
const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -8.65, b: 26.63),
  provenance: Provenance(ProvenanceTier.measured),
);

/// A neutral grey (a*=b*=0): chroma 0, hue 0 — the achromatic edge.
const _grey = Sample(
  name: 'Neutral Grey',
  coordinates: ColorCoordinates(lightness: 50, a: 0, b: 0),
  provenance: Provenance(ProvenanceTier.measured),
);

const _ochre = Paint(
  id: 'py43',
  name: 'Yellow Ochre',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
);
const _black = Paint(
  id: 'pbk9',
  name: 'Ivory Black',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 16, a: 0, b: 1),
);
const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
);

Recipe _recipe(List<RecipeComponent> components) => Recipe(
      medium: PaintMedium.acrylic,
      components: components,
      predictedColor: const ColorCoordinates(lightness: 42, a: -5, b: 20),
      deltaE00: 2.0,
    );

void main() {
  group('targetSpeech (AC-11)', () {
    test('states the name and the CIELCh L, C and hue, each rounded', () {
      // L 42, C √(8.65²+26.63²) ≈ 28, h atan2(26.63, −8.65) ≈ 108°.
      expect(
        targetSpeech(_olive),
        'Deep Olive Green. Lightness 42, chroma 28, hue 108 degrees.',
      );
    });

    test('an unnamed target is spoken as "(unnamed)"', () {
      const unnamed = Sample(
        coordinates: ColorCoordinates(lightness: 70, a: 10, b: 0),
        provenance: Provenance(ProvenanceTier.measured),
      );
      // C 10, h atan2(0, 10) = 0°.
      expect(
        targetSpeech(unnamed),
        '(unnamed). Lightness 70, chroma 10, hue 0 degrees.',
      );
    });

    test('a neutral target states chroma 0 and hue 0', () {
      expect(
        targetSpeech(_grey),
        'Neutral Grey. Lightness 50, chroma 0, hue 0 degrees.',
      );
    });
  });

  group('recipeSpeech (AC-12)', () {
    test('states each measured paint with its parts, reduced to a small ratio', () {
      // 2:1 by volume ⇒ "2 parts … 1 part", not naive percentages.
      final spoken = recipeSpeech(_recipe([
        const RecipeComponent(paint: _ochre, partsFraction: 2 / 3),
        const RecipeComponent(paint: _black, partsFraction: 1 / 3),
      ]));
      expect(spoken, 'Recipe: Yellow Ochre 2 parts, Ivory Black 1 part.');
    });

    test('a trace paint is spoken as "a touch of", not a part (AC-7)', () {
      // Ochre 0.79 / black 0.20 (measured, 0.20 is the smallest) → 4:1 parts;
      // the 1% white is a trace, spoken as "a touch of" rather than a part.
      final spoken = recipeSpeech(_recipe([
        const RecipeComponent(paint: _ochre, partsFraction: 0.79),
        const RecipeComponent(paint: _black, partsFraction: 0.20),
        const RecipeComponent(
          paint: _white,
          partsFraction: 0.01,
          isTrace: true,
          techniqueNote: 'add a little at a time',
        ),
      ]));
      expect(
        spoken,
        'Recipe: Yellow Ochre 4 parts, Ivory Black 1 part, '
        'a touch of Titanium White.',
      );
    });

    test('a single-paint recipe states one part', () {
      final spoken = recipeSpeech(_recipe([
        const RecipeComponent(paint: _ochre, partsFraction: 1),
      ]));
      expect(spoken, 'Recipe: Yellow Ochre 1 part.');
    });
  });
}
