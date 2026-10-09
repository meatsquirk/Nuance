import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/recipes/recipe_controller.dart';
import 'package:paint_color_assistant/recipes/recipe_state.dart';

const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
);
const _ochre = Paint(
  id: 'py43',
  name: 'Yellow Ochre',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
);
const _myPaints = PaintPalette(name: 'My paints', paints: [_white]);
const _oils = PaintPalette(name: 'Studio oils', paints: [_white]);
const _richPalette =
    PaintPalette(name: 'Studio', paints: [_white, _ochre]);
const _recipe = Recipe(
  medium: PaintMedium.acrylic,
  components: [RecipeComponent(paint: _white, partsFraction: 1)],
  predictedColor: ColorCoordinates(lightness: 96, a: 0, b: 2),
  deltaE00: 1.2,
);

RecipeController _controller({
  SampleSource? sampleSource,
  PaletteSource? paletteSource,
}) =>
    RecipeController(
      sampleSource: sampleSource ?? const InMemorySampleSource(),
      paletteSource: paletteSource ?? const InMemoryPaletteSource(),
      mixingEngine: const SubtractiveMixingEngine(),
      target: _olive,
    );

void main() {
  group('RecipeController', () {
    test('holds the injected seams', () {
      final controller = _controller();
      expect(controller.sampleSource, isA<InMemorySampleSource>());
      expect(controller.paletteSource, isA<InMemoryPaletteSource>());
      expect(controller.mixingEngine, isA<SubtractiveMixingEngine>());
      expect(controller.speech, isA<NoopSpeech>());
    });

    test('initial state: target set, no recipes, wet, no error', () {
      final state = _controller().state;
      expect(state.target, _olive);
      expect(state.recipes, isEmpty);
      expect(state.mode, MixMode.wet);
      expect(state.manualError, isNull);
    });

    test('defaults the selected palette to the first available one', () {
      final controller = _controller(
        paletteSource: const InMemoryPaletteSource(catalogue: [_myPaints, _oils]),
      );
      expect(controller.state.selectedPalette, _myPaints);
    });

    test('leaves the selected palette null when none are available', () {
      expect(_controller().state.selectedPalette, isNull);
    });

    test('savedSamples delegates to the sample source', () {
      final controller = _controller(
        sampleSource: const InMemorySampleSource(samples: [_olive]),
      );
      expect(controller.savedSamples, [_olive]);
    });

    test('palettes delegates to the palette source', () {
      final controller = _controller(
        paletteSource: const InMemoryPaletteSource(catalogue: [_myPaints]),
      );
      expect(controller.palettes, [_myPaints]);
    });

    group('actions are inert in the RECIPE-2 shell', () {
      final controller = _controller();

      test('selectTarget throws until RECIPE-3', () {
        expect(() => controller.selectTarget(_olive), throwsUnimplementedError);
      });
      test('enterManualTarget throws until RECIPE-3', () {
        expect(
          () => controller.enterManualTarget(
              const ColorCoordinates(lightness: 42, a: -5, b: 20)),
          throwsUnimplementedError,
        );
      });
      test('setMode throws until ENGINE-6', () {
        expect(() => controller.setMode(MixMode.dry), throwsUnimplementedError);
      });
      test('speakTarget throws until RECIPE-4', () {
        expect(() => controller.speakTarget(), throwsUnimplementedError);
      });
      test('speakRecipe throws until RECIPE-4', () {
        expect(() => controller.speakRecipe(_recipe), throwsUnimplementedError);
      });
    });

    group('solving (ENGINE-2)', () {
      test('solves over the default palette on open', () {
        final controller = _controller(
          paletteSource: const InMemoryPaletteSource(catalogue: [_richPalette]),
        );
        addTearDown(controller.dispose);
        final recipes = controller.state.recipes;
        expect(recipes, isNotEmpty);
        final paletteIds = _richPalette.paints.map((p) => p.id).toSet();
        for (final r in recipes) {
          for (final c in r.components) {
            expect(paletteIds, contains(c.paint.id));
          }
        }
      });

      test('no palette available ⇒ no solve on open', () {
        final controller = _controller();
        addTearDown(controller.dispose);
        expect(controller.state.selectedPalette, isNull);
        expect(controller.state.recipes, isEmpty);
      });

      test('selectPalette re-solves over the chosen palette and notifies', () {
        final controller = _controller(
          paletteSource:
              const InMemoryPaletteSource(catalogue: [_myPaints, _richPalette]),
        );
        addTearDown(controller.dispose);
        expect(controller.state.selectedPalette, _myPaints);

        var notified = 0;
        controller.addListener(() => notified++);
        controller.selectPalette(_richPalette);

        expect(notified, 1);
        expect(controller.state.selectedPalette, _richPalette);
        expect(controller.state.recipes, isNotEmpty);
        expect(controller.state.mode, MixMode.wet);
        expect(controller.state.manualError, isNull);
      });
    });
  });
}
