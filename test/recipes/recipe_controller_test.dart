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
const _myPaints = PaintPalette(name: 'My paints', paints: [_white]);
const _oils = PaintPalette(name: 'Studio oils', paints: [_white]);
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

    group('target selection (RECIPE-3)', () {
      const warmSand = Sample(
        name: 'Warm Sand',
        coordinates: ColorCoordinates(lightness: 78, a: 4, b: 23),
        provenance: Provenance(ProvenanceTier.measured),
      );

      test('selectTarget moves the target to the chosen saved sample', () {
        final controller = _controller();
        var notified = 0;
        controller.addListener(() => notified++);

        controller.selectTarget(warmSand);

        expect(controller.state.target, same(warmSand));
        expect(notified, 1, reason: 'the state change notifies listeners once');
      });

      test('selectTarget carries the palette, recipes and mode unchanged', () {
        final controller = _controller(
          paletteSource: const InMemoryPaletteSource(catalogue: [_myPaints]),
        );
        controller.selectTarget(warmSand);

        expect(controller.state.selectedPalette, _myPaints);
        expect(controller.state.recipes, isEmpty);
        expect(controller.state.mode, MixMode.wet);
      });

      test('selectTarget clears a prior manual error', () {
        final controller = _controller();
        controller.enterManualTarget(
            const ColorCoordinates(lightness: 140, a: 0, b: 0));
        expect(controller.state.manualError, isNotNull);

        controller.selectTarget(warmSand);
        expect(controller.state.manualError, isNull);
      });

      test('a valid manual entry becomes the target and clears any error', () {
        final controller = _controller();
        controller.enterManualTarget(
            const ColorCoordinates(lightness: 50, a: 0, b: 0));

        expect(controller.state.manualError, isNull);
        expect(controller.state.target.coordinates,
            const ColorCoordinates(lightness: 50, a: 0, b: 0));
        expect(controller.state.target.provenance.tier,
            ProvenanceTier.confirmed);
        expect(controller.state.target, isNot(same(_olive)));
      });

      test('an out-of-range lightness is refused and the target is kept', () {
        final controller = _controller();
        final before = controller.state.target;

        controller.enterManualTarget(
            const ColorCoordinates(lightness: 140, a: 0, b: 0));

        expect(controller.state.manualError, isNotNull);
        expect(controller.state.target, same(before));
      });

      test('a below-range lightness is refused', () {
        final controller = _controller();
        controller.enterManualTarget(
            const ColorCoordinates(lightness: -1, a: 0, b: 0));
        expect(controller.state.manualError, isNotNull);
      });

      test('a non-finite coordinate is refused (unparseable manual field)', () {
        final controller = _controller();
        controller.enterManualTarget(
            ColorCoordinates(lightness: double.nan, a: 0, b: 0));
        expect(controller.state.manualError, isNotNull);
      });

      test('an out-of-range a* or b* is refused (L* in range)', () {
        final controller = _controller();
        controller.enterManualTarget(
            const ColorCoordinates(lightness: 50, a: 200, b: 0));
        expect(controller.state.manualError, isNotNull);

        controller.enterManualTarget(
            const ColorCoordinates(lightness: 50, a: 0, b: -200));
        expect(controller.state.manualError, isNotNull);
      });

      test('the range boundaries (L* 0 and 100) are accepted', () {
        final controller = _controller();
        controller.enterManualTarget(
            const ColorCoordinates(lightness: 0, a: -128, b: 127));
        expect(controller.state.manualError, isNull);
        controller.enterManualTarget(
            const ColorCoordinates(lightness: 100, a: 0, b: 0));
        expect(controller.state.manualError, isNull);
      });
    });

    group('actions are inert in the RECIPE-2 shell', () {
      final controller = _controller();

      test('selectPalette throws until ENGINE-2', () {
        expect(() => controller.selectPalette(_myPaints),
            throwsUnimplementedError);
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
  });
}
