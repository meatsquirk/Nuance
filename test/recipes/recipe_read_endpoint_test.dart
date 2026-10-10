import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/recipes/recipe_controller.dart';
import 'package:paint_color_assistant/recipes/recipe_read_endpoint.dart';

const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);

RecipeController _controller() => RecipeController(
      sampleSource: const InMemorySampleSource(),
      paletteSource: const InMemoryPaletteSource(),
      mixingEngine: const SubtractiveMixingEngine(),
      target: _olive,
    );

void main() {
  testWidgets('of() returns the controller exposed above a descendant',
      (tester) async {
    final controller = _controller();
    late RecipeController seen;
    await tester.pumpWidget(
      RecipeReadEndpoint(
        controller: controller,
        child: Builder(
          builder: (context) {
            seen = RecipeReadEndpoint.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(seen, controller), isTrue);
  });

  testWidgets('is findable by its stable endpoint key', (tester) async {
    await tester.pumpWidget(
      RecipeReadEndpoint(
        key: RecipeReadEndpoint.endpointKey,
        controller: _controller(),
        child: const SizedBox(),
      ),
    );
    expect(find.byKey(RecipeReadEndpoint.endpointKey), findsOneWidget);
  });

  test('updateShouldNotify tracks whether the controller changed', () {
    final a = RecipeReadEndpoint(controller: _controller(), child: const SizedBox());
    final b = RecipeReadEndpoint(controller: _controller(), child: const SizedBox());
    final shared = _controller();
    final c = RecipeReadEndpoint(controller: shared, child: const SizedBox());
    final d = RecipeReadEndpoint(controller: shared, child: const SizedBox());
    expect(a.updateShouldNotify(b), isTrue);
    expect(c.updateShouldNotify(d), isFalse);
  });
}
