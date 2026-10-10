import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/recipes/recipe_controller.dart';
import 'package:paint_color_assistant/recipes/target_region.dart';

// Widget-level coverage of the E22 target selector the RECIPE-3 behaviour wires
// (AC-1 saved-sample pick; AC-2 by-hand entry with range validation). The
// acceptance suite drives the same affordances end to end
// (`integration_test/recipes_test.dart`); these isolate the region's own
// branches for the unit/coverage gate.

const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _warmSand = Sample(
  name: 'Warm Sand',
  coordinates: ColorCoordinates(lightness: 78, a: 4, b: 23),
  provenance: Provenance(ProvenanceTier.measured),
);
const _unnamed = Sample(
  coordinates: ColorCoordinates(lightness: 50, a: 0, b: 0),
  provenance: Provenance(ProvenanceTier.measured),
);

RecipeController _controller({List<Sample> samples = const [_olive, _warmSand]}) =>
    RecipeController(
      sampleSource: InMemorySampleSource(samples: samples),
      paletteSource: const InMemoryPaletteSource(),
      mixingEngine: const SubtractiveMixingEngine(),
      target: _olive,
    );

/// Pumps [TargetRegion] in a Material host so the selector sheet can open, and
/// rebuilds it when the controller notifies (as the real screen does).
Future<void> _pump(WidgetTester tester, RecipeController controller) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ListenableBuilder(
        listenable: controller,
        builder: (_, child) => TargetRegion(controller: controller),
      ),
    ),
  ));
}

Future<void> _openSelector(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Choose target'));
  await tester.pumpAndSettle();
}

Future<void> _enterManual(WidgetTester tester, String l, String a, String b) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), l);
  await tester.enterText(fields.at(1), a);
  await tester.enterText(fields.at(2), b);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  group('TargetRegion selector (E22)', () {
    testWidgets('choosing a saved sample sets it as the target and closes',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pump(tester, controller);

      await _openSelector(tester);
      await tester.tap(find.text('Warm Sand').last);
      await tester.pumpAndSettle();

      expect(controller.state.target, same(_warmSand));
      expect(find.text('Recipe target: Warm Sand'), findsOneWidget);
      // The sheet dismissed (its by-hand fields are gone).
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('lists an unnamed saved sample as "(unnamed)"', (tester) async {
      final controller = _controller(samples: const [_unnamed]);
      addTearDown(controller.dispose);
      await _pump(tester, controller);

      await _openSelector(tester);
      expect(find.text('(unnamed)'), findsOneWidget);
    });

    testWidgets('a valid by-hand CIELAB entry becomes the target', (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pump(tester, controller);

      await _openSelector(tester);
      await _enterManual(tester, '55', '2', '-3');

      expect(controller.state.manualError, isNull);
      expect(controller.state.target.coordinates,
          const ColorCoordinates(lightness: 55, a: 2, b: -3));
      expect(find.byKey(TargetRegion.manualErrorKey), findsNothing);
    });

    testWidgets('an out-of-range lightness is refused and shows the error',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pump(tester, controller);
      final before = controller.state.target;

      await _openSelector(tester);
      await _enterManual(tester, '140', '0', '0');

      expect(controller.state.target, same(before));
      expect(controller.state.manualError, isNotNull);
      expect(find.byKey(TargetRegion.manualErrorKey), findsOneWidget);
    });

    testWidgets('an unparseable field is refused (NaN out of range)',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pump(tester, controller);
      final before = controller.state.target;

      await _openSelector(tester);
      await _enterManual(tester, 'abc', '0', '0');

      expect(controller.state.target, same(before));
      expect(controller.state.manualError, isNotNull);
    });
  });
}
