import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/recipe_state.dart';

const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _unnamed = Sample(
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
);
const _palette = PaintPalette(name: 'My paints', paints: [_white]);
const _recipe = Recipe(
  medium: PaintMedium.acrylic,
  components: [RecipeComponent(paint: _white, partsFraction: 1)],
  predictedColor: ColorCoordinates(lightness: 96, a: 0, b: 2),
  deltaE00: 1.2,
);

void main() {
  group('RecipeState', () {
    test('defaults: no palette, no recipes, wet, no error', () {
      const state = RecipeState(target: _olive);
      expect(state.selectedPalette, isNull);
      expect(state.recipes, isEmpty);
      expect(state.mode, MixMode.wet);
      expect(state.manualError, isNull);
      expect(state.hasRecipes, isFalse);
    });

    test('hasRecipes is true once a recipe is present', () {
      const state = RecipeState(target: _olive, recipes: [_recipe]);
      expect(state.hasRecipes, isTrue);
    });

    test('value equality over every field', () {
      const base = RecipeState(
        target: _olive,
        selectedPalette: _palette,
        recipes: [_recipe],
        mode: MixMode.dry,
        manualError: 'bad',
      );
      const same = RecipeState(
        target: _olive,
        selectedPalette: _palette,
        recipes: [_recipe],
        mode: MixMode.dry,
        manualError: 'bad',
      );
      expect(base, same);
      expect(base.hashCode, same.hashCode);

      expect(base, isNot(const RecipeState(target: _unnamed,
          selectedPalette: _palette, recipes: [_recipe], mode: MixMode.dry,
          manualError: 'bad')));
      expect(base, isNot(const RecipeState(target: _olive,
          recipes: [_recipe], mode: MixMode.dry, manualError: 'bad')));
      expect(base, isNot(const RecipeState(target: _olive,
          selectedPalette: _palette, mode: MixMode.dry, manualError: 'bad')));
      expect(base, isNot(const RecipeState(target: _olive,
          selectedPalette: _palette, recipes: [_recipe], manualError: 'bad')));
      expect(base, isNot(const RecipeState(target: _olive,
          selectedPalette: _palette, recipes: [_recipe], mode: MixMode.dry)));
      expect(base, isNot('not a state'));
    });

    test('toString names the target, palette, count, mode and error', () {
      const withAll = RecipeState(
        target: _olive,
        selectedPalette: _palette,
        recipes: [_recipe],
        mode: MixMode.dry,
        manualError: 'out of range',
      );
      expect(
        withAll.toString(),
        'RecipeState(target: Deep Olive Green, palette: My paints, '
        '1 recipes, dry, error: out of range)',
      );
    });

    test('toString falls back for an unnamed target, no palette, no error', () {
      const bare = RecipeState(target: _unnamed);
      expect(
        bare.toString(),
        'RecipeState(target: (unnamed), palette: (none), 0 recipes, wet)',
      );
    });
  });
}
