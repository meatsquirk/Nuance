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
import 'package:paint_color_assistant/recipes/recipe_speech.dart';
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

class _RecordingSpeech implements Speech {
  final List<String> utterances = [];

  @override
  Future<void> speak(String utterance) async => utterances.add(utterance);
}

RecipeController _controller({
  SampleSource? sampleSource,
  PaletteSource? paletteSource,
  Speech? speech,
}) =>
    RecipeController(
      sampleSource: sampleSource ?? const InMemorySampleSource(),
      paletteSource: paletteSource ?? const InMemoryPaletteSource(),
      mixingEngine: const SubtractiveMixingEngine(),
      target: _olive,
      speech: speech ?? const NoopSpeech(),
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
        // ENGINE-2 solves the recipes on open, so the controller already holds
        // the mixes for the initial target; selectTarget does not re-solve
        // (the re-solve on a new target is a later concern), so the recipes are
        // carried over as-is.
        final recipesBefore = controller.state.recipes;
        controller.selectTarget(warmSand);

        expect(controller.state.selectedPalette, _myPaints);
        expect(controller.state.recipes, same(recipesBefore));
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

    group('spoken output (RECIPE-4, AC-11/AC-12)', () {
      test('speakTarget speaks the target builder once and does not notify', () async {
        final speech = _RecordingSpeech();
        final controller = _controller(speech: speech);
        addTearDown(controller.dispose);
        var notified = 0;
        controller.addListener(() => notified++);

        await controller.speakTarget();

        // Exactly one utterance, carrying the target builder's text for the
        // current target; speaking is read-only, so no listener fires.
        expect(speech.utterances, [targetSpeech(controller.state.target)]);
        expect(notified, 0);
      });

      test('speakRecipe speaks the recipe builder once and does not notify', () async {
        final speech = _RecordingSpeech();
        final controller = _controller(speech: speech);
        addTearDown(controller.dispose);
        var notified = 0;
        controller.addListener(() => notified++);

        await controller.speakRecipe(_recipe);

        expect(speech.utterances, [recipeSpeech(_recipe)]);
        expect(notified, 0);
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

    group('wet/dry toggle (ENGINE-6, AC-10)', () {
      RecipeController solvingController() => _controller(
            paletteSource:
                const InMemoryPaletteSource(catalogue: [_richPalette]),
          );

      test('setMode(dry) re-predicts each recipe and notifies', () {
        final controller = solvingController();
        addTearDown(controller.dispose);
        final wet = controller.state.recipes;
        expect(wet, isNotEmpty);
        expect(controller.state.mode, MixMode.wet);

        var notified = 0;
        controller.addListener(() => notified++);
        controller.setMode(MixMode.dry);

        expect(notified, 1);
        expect(controller.state.mode, MixMode.dry);
        final dry = controller.state.recipes;
        // Same recipes (parts, distance, order), but each predicted colour moved
        // to the dry prediction — a real shift, not a relabel.
        expect(dry.length, wet.length);
        for (var i = 0; i < dry.length; i++) {
          expect(dry[i].predictedColor, isNot(wet[i].predictedColor),
              reason: 'recipe $i must predict a different dry colour');
          expect(dry[i].components, wet[i].components);
          expect(dry[i].deltaE00, wet[i].deltaE00);
        }
      });

      test('toggling back to wet restores the wet prediction exactly', () {
        final controller = solvingController();
        addTearDown(controller.dispose);
        final wet = controller.state.recipes;

        controller.setMode(MixMode.dry);
        controller.setMode(MixMode.wet);

        expect(controller.state.mode, MixMode.wet);
        expect(controller.state.recipes, wet,
            reason: 're-rendering wet reproduces the original prediction');
      });

      test('setMode with no palette solved leaves the recipes empty', () {
        final controller = _controller();
        addTearDown(controller.dispose);
        expect(controller.state.recipes, isEmpty);

        controller.setMode(MixMode.dry);

        expect(controller.state.mode, MixMode.dry);
        expect(controller.state.recipes, isEmpty);
      });
    });
  });
}
