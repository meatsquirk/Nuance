import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/controls_region.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/gamut_banner.dart';
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

RecipeController _controller({Sample target = _olive}) => RecipeController(
      sampleSource: const InMemorySampleSource(),
      paletteSource: const InMemoryPaletteSource(),
      mixingEngine: const SubtractiveMixingEngine(),
      target: target,
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
    testWidgets('shows the named target with inert selector and speak controls',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpRegion(tester, TargetRegion(controller: controller));

      expect(find.text('Recipe target: Deep Olive Green'), findsOneWidget);
      // E22 and E23 are present but inert until RECIPE-3 / RECIPE-4.
      expect(_enabled(tester, 'Choose target'), isFalse,
          reason: 'E22 target selector is not wired in SCREEN-1');
      expect(_enabled(tester, 'Speak target'), isFalse,
          reason: 'E23 speak target is not wired in SCREEN-1');
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
    testWidgets('shows the empty-state placeholder and an inert speak control',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpRegion(tester, RecipeListRegion(controller: controller));

      expect(find.text('No recipes yet'), findsOneWidget);
      // E25 speak recipe is present but inert until RECIPE-4.
      expect(_enabled(tester, 'Speak recipe'), isFalse,
          reason: 'E25 speak recipe is not wired in SCREEN-1');
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
