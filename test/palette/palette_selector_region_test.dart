import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/palette/palette_controller.dart';
import 'package:paint_color_assistant/palette/palette_selector_region.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
);
const _blue = Paint(
  id: 'pb29',
  name: 'Ultramarine Blue',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 32, a: 18, b: -52),
);
const _myPaints = PaintPalette(name: 'My paints', paints: [_white]);
const _travel = PaintPalette(name: 'Travel set', paints: [_blue]);

Future<PaletteController> _pump(
  WidgetTester tester, {
  List<PaintPalette> catalogue = const [],
}) async {
  final controller =
      PaletteController(source: InMemoryPaletteSource(catalogue: catalogue));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) =>
              PaletteSelectorRegion(controller: controller),
        ),
      ),
    ),
  );
  return controller;
}

void main() {
  testWidgets('shows a placeholder when there are no palettes', (tester) async {
    await _pump(tester);
    expect(find.text('No palettes yet'), findsOneWidget);
  });

  testWidgets('lists each palette, marking the active one', (tester) async {
    await _pump(tester, catalogue: const [_myPaints, _travel]);
    // The first listed palette is active to begin with.
    expect(find.text('My paints (active)'), findsOneWidget);
    expect(find.text('Travel set'), findsOneWidget);
    expect(
      find.byKey(PaletteSelectorRegion.optionKeyFor('Travel set')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a palette selects it and re-marks the active one',
      (tester) async {
    final controller = await _pump(tester, catalogue: const [_myPaints, _travel]);

    await tester.tap(
      find.byKey(PaletteSelectorRegion.optionKeyFor('Travel set')),
    );
    await tester.pump();

    expect(controller.selectedPalette, _travel);
    expect(find.text('Travel set (active)'), findsOneWidget);
    expect(find.text('My paints'), findsOneWidget);
  });
}
