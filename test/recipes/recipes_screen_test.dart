import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/controls_region.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/gamut_banner.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/recipes/recipe_controller.dart';
import 'package:paint_color_assistant/recipes/recipe_list_region.dart';
import 'package:paint_color_assistant/recipes/recipe_state.dart';
import 'package:paint_color_assistant/recipes/recipes_screen.dart';
import 'package:paint_color_assistant/recipes/target_region.dart';

const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _unnamed = Sample(
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);

RecipeController _controller({
  Sample target = _olive,
  PaletteSource paletteSource = const InMemoryPaletteSource(),
}) =>
    RecipeController(
      sampleSource: const InMemorySampleSource(),
      paletteSource: paletteSource,
      mixingEngine: const SubtractiveMixingEngine(),
      target: target,
    );

const _ochre = Paint(
  id: 'py43',
  name: 'Yellow Ochre',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
);
const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
);
const _black = Paint(
  id: 'pbk9',
  name: 'Ivory Black',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 16, a: 0, b: 1),
);
const _ultramarine = Paint(
  id: 'pb29',
  name: 'Ultramarine Blue',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 30, a: 18, b: -52),
);
const _studioPalette = PaintPalette(name: 'Studio', paints: [_ochre]);

// A target whose best mix over an earthy palette needs only a touch of white.
const _umber = Sample(
  name: 'Deep Umber',
  coordinates: ColorCoordinates(lightness: 33, a: 0, b: 12),
  provenance: Provenance(ProvenanceTier.measured),
);

/// Pumps [child] under a Material scaffold so the regions render in isolation.
Future<void> _pumpRegion(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

bool _enabled(WidgetTester tester, String label) => tester
    .widget<TextButton>(find.widgetWithText(TextButton, label))
    .enabled;

void main() {
  group('RecipesScreen', () {
    testWidgets('renders one Recipes scaffold with all four regions',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(home: RecipesScreen(controller: controller)));

      expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
      expect(find.byKey(GamutBanner.regionKey), findsOneWidget);
      expect(find.byKey(TargetRegion.regionKey), findsOneWidget);
      expect(find.byKey(ControlsRegion.regionKey), findsOneWidget);
      expect(find.byKey(RecipeListRegion.regionKey), findsOneWidget);
    });

    testWidgets('renders the named target and the empty recipe placeholder',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(home: RecipesScreen(controller: controller)));

      expect(find.text('Recipe target: Deep Olive Green'), findsOneWidget);
      expect(find.text('No recipes yet'), findsOneWidget);
      // The gamut banner stays hidden (no "OUT OF GAMUT" text) in the shell.
      expect(find.text('OUT OF GAMUT'), findsNothing);
    });
  });

  group('TargetRegion', () {
    testWidgets('shows the named target with a wired selector and inert speak',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpRegion(tester, TargetRegion(controller: controller));

      expect(find.text('Recipe target: Deep Olive Green'), findsOneWidget);
      // E22 is wired by RECIPE-3; E23 stays inert until RECIPE-4.
      expect(_enabled(tester, 'Choose target'), isTrue,
          reason: 'E22 target selector is wired in RECIPE-3');
      expect(_enabled(tester, 'Speak target'), isFalse,
          reason: 'E23 speak target is not wired until RECIPE-4');
    });

    testWidgets('falls back to (unnamed) for a target with no name',
        (tester) async {
      final controller = _controller(target: _unnamed);
      addTearDown(controller.dispose);
      await _pumpRegion(tester, TargetRegion(controller: controller));

      expect(find.text('Recipe target: (unnamed)'), findsOneWidget);
    });
  });

  group('ControlsRegion', () {
    testWidgets('shows the wet/dry toggle reflecting the current mode, inert',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpRegion(tester, ControlsRegion(controller: controller));

      expect(find.text('Wet or dry:'), findsOneWidget);
      expect(find.text('Wet'), findsOneWidget);
      expect(find.text('Dry'), findsOneWidget);
      // E24 is inert until ENGINE-6: a null onSelectionChanged disables it, and
      // the controller still starts in wet mode.
      final toggle = tester.widget<SegmentedButton<MixMode>>(
        find.byType(SegmentedButton<MixMode>),
      );
      expect(toggle.onSelectionChanged, isNull);
      expect(toggle.selected, {MixMode.wet});
    });
  });

  group('RecipeListRegion', () {
    testWidgets('shows the empty-state placeholder when nothing is solved',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpRegion(tester, RecipeListRegion(controller: controller));

      expect(find.text('No recipes yet'), findsOneWidget);
      // No recipe cards ⇒ no speak-recipe control yet (ENGINE-2 renders the
      // card; RECIPE-4 wires its speak control).
      expect(find.widgetWithText(TextButton, 'Speak recipe'), findsNothing);
    });

    testWidgets('renders a card per solved recipe with paints, parts and the '
        'predicted colour (AC-4)', (tester) async {
      final controller =
          _controller(paletteSource: const InMemoryPaletteSource(catalogue: [_studioPalette]));
      addTearDown(controller.dispose);
      expect(controller.state.recipes, isNotEmpty);

      await _pumpRegion(tester, RecipeListRegion(controller: controller));

      expect(find.text('No recipes yet'), findsNothing);
      expect(find.byType(Card), findsWidgets);
      // The single-paint palette's recipe names Yellow Ochre at 100%.
      expect(find.textContaining('Yellow Ochre'), findsWidgets);
      expect(find.textContaining('Predicted colour:'), findsWidgets);
      // E25 speak recipe is present per card but inert until RECIPE-4.
      expect(_enabled(tester, 'Speak recipe'), isFalse,
          reason: 'E25 speak recipe is not wired until RECIPE-4');
    });

    testWidgets('expresses a trace component as "a touch of" with its technique '
        'note rather than a measured part (ENGINE-4, AC-7)', (tester) async {
      const earth = PaintPalette(name: 'Earth', paints: [_white, _ochre, _black]);
      final controller = _controller(
        target: _umber,
        paletteSource: const InMemoryPaletteSource(catalogue: [earth]),
      );
      addTearDown(controller.dispose);
      // The solve returns a recipe with a genuine sub-2% trace component.
      expect(
        controller.state.recipes.any((r) => r.components.any((c) => c.isTrace)),
        isTrue,
      );

      // Wrap in a scroll view (as the Recipes screen's ListView does) so the
      // full card stack lays out; cards past the viewport are offstage.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecipeListRegion(controller: controller),
          ),
        ),
      ));

      // The trace renders as "a touch of" plus its static technique note (the
      // cards past the viewport are offstage, so the finder spans them).
      expect(find.textContaining('a touch of', skipOffstage: false), findsWidgets);
      expect(find.textContaining('add a little at a time', skipOffstage: false),
          findsWidgets);
      // A measured (non-trace) part still renders as a percentage.
      expect(find.textContaining('%', skipOffstage: false), findsWidgets);
    });

    testWidgets('flags a muddying mix as liable to muddy (ENGINE-4, AC-8)',
        (tester) async {
      const crossing = PaintPalette(name: 'Cross', paints: [_ochre, _ultramarine]);
      final controller = _controller(
        target: _olive,
        paletteSource: const InMemoryPaletteSource(catalogue: [crossing]),
      );
      addTearDown(controller.dispose);
      expect(controller.state.recipes.any((r) => r.muddying), isTrue);

      await _pumpRegion(tester, RecipeListRegion(controller: controller));

      expect(find.textContaining('Liable to muddy', skipOffstage: false),
          findsWidgets);
    });
  });

  group('GamutBanner', () {
    testWidgets('keeps its anchor but shows no banner in the shell',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpRegion(tester, GamutBanner(controller: controller));

      expect(find.byKey(GamutBanner.regionKey), findsOneWidget);
      expect(find.text('OUT OF GAMUT'), findsNothing);
    });
  });
}
