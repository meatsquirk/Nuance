import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/palette/paint_list_region.dart';
import 'package:paint_color_assistant/palette/palette_controller.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/widgets/color_chip.dart';
import 'package:paint_color_assistant/widgets/paint_row.dart';
import 'package:paint_color_assistant/widgets/swatch_caption.dart';

const Paint _paint = Paint(
  id: 'pg7',
  name: 'Phthalo Green',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 40, a: -40, b: 10),
);

PaletteController _controllerWith(List<Paint> paints) => PaletteController(
      source: InMemoryPaletteSource(
        catalogue: [
          PaintPalette(name: PaletteController.myPaintsName, paints: paints),
        ],
      ),
    );

/// Pumps the region bare (no enclosing scope) or inside an [AppScope] carrying a
/// real colour science — the two states the region renders differently.
Future<void> _pump(
  WidgetTester tester,
  PaletteController controller, {
  bool withScope = false,
}) {
  final region = PaintListRegion(controller: controller);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: withScope
            ? AppScope(
                dependencies: const AppDependencies(
                  colorScience: ColorScienceImpl(),
                  speech: NoopSpeech(),
                  haptics: NoopHaptics(),
                ),
                child: region,
              )
            : region,
      ),
    ),
  );
}

void main() {
  group('PaintListRegion', () {
    testWidgets('shows the empty placeholder and no paint rows when empty',
        (tester) async {
      final controller = _controllerWith(const []);
      addTearDown(controller.dispose);
      await _pump(tester, controller);

      expect(find.text('No paints yet'), findsOneWidget);
      expect(find.byType(PaintRow), findsNothing);
    });

    testWidgets(
        'with no enclosing AppScope a paint renders without a masstone swatch '
        '(name as plain text)', (tester) async {
      final controller = _controllerWith(const [_paint]);
      addTearDown(controller.dispose);
      await _pump(tester, controller);

      // The row renders, but with no scope to remap through there is no swatch.
      expect(find.byKey(PaintRow.rowKeyFor('pg7')), findsOneWidget);
      expect(find.byKey(PaintRow.swatchKeyFor('pg7')), findsNothing);
      final row = tester.widget<PaintRow>(find.byType(PaintRow));
      expect(row.swatchColor, isNull);
      // The name is still shown (as plain text).
      expect(find.text('Phthalo Green'), findsOneWidget);
    });

    testWidgets(
        'under an AppScope a paint renders its masstone swatch through ColorChip',
        (tester) async {
      final controller = _controllerWith(const [_paint]);
      addTearDown(controller.dispose);
      await _pump(tester, controller, withScope: true);

      // The swatch chip is present and carries the paint name as its label.
      final chipFinder = find.byKey(PaintRow.swatchKeyFor('pg7'));
      expect(chipFinder, findsOneWidget);
      final chip = tester.widget<ColorChip>(chipFinder);
      expect(chip.label, 'Phthalo Green');

      // The swatch colour is the masstone rendered to sRGB by the scope's
      // colour science — the input ColorChip then routes through the chokepoint.
      final SRGBColor expected =
          const ColorScienceImpl().toSRGB(_paint.masstone);
      expect(
        chip.color,
        Color.fromARGB(255, expected.red, expected.green, expected.blue),
      );
    });

    testWidgets('carries the swatch approximation caption once, only when it '
        'renders swatches (AC-15)', (tester) async {
      final controller = _controllerWith(const [_paint]);
      addTearDown(controller.dispose);

      // Swatches rendered (paints + a scope to remap through) → one caption.
      await _pump(tester, controller, withScope: true);
      expect(find.byType(SwatchCaption), findsOneWidget);

      // No scope → bare names, no swatch → no caption.
      await _pump(tester, controller);
      expect(find.byType(SwatchCaption), findsNothing);

      // No paints → no swatch → no caption even under a scope.
      final empty = _controllerWith(const []);
      addTearDown(empty.dispose);
      await _pump(tester, empty, withScope: true);
      expect(find.byType(SwatchCaption), findsNothing);
    });
  });
}
