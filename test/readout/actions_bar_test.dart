import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/actions_bar.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';

const _sample = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 36, b: 34),
  provenance: Provenance(ProvenanceTier.measured),
);

ReadoutController _controller() => ReadoutController(
      sample: _sample,
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      router: const AppRouter(),
    );

// The bar needs a Navigator ancestor to push its handoff routes.
Future<void> _pumpBar(WidgetTester tester, ReadoutController controller) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ActionsBar(controller: controller))),
    );

void main() {
  testWidgets('"Compare as A" pushes the Comparison screen with the reading '
      'in slot A (AC-9)', (tester) async {
    await _pumpBar(tester, _controller());

    await tester.tap(find.byKey(ActionsBar.compareAKey));
    await tester.pumpAndSettle();

    expect(find.text('Comparison'), findsOneWidget);
    expect(find.text('Slot A: Warm Terracotta'), findsOneWidget);
    expect(find.text('Slot B: (empty)'), findsOneWidget);
  });

  testWidgets('"Compare as B" pushes the Comparison screen with the reading '
      'in slot B (AC-10)', (tester) async {
    await _pumpBar(tester, _controller());

    await tester.tap(find.byKey(ActionsBar.compareBKey));
    await tester.pumpAndSettle();

    expect(find.text('Comparison'), findsOneWidget);
    expect(find.text('Slot B: Warm Terracotta'), findsOneWidget);
    expect(find.text('Slot A: (empty)'), findsOneWidget);
  });

  testWidgets('"Find mixing recipes" pushes the Recipes screen with the '
      'reading as the target (AC-11)', (tester) async {
    await _pumpBar(tester, _controller());

    await tester.tap(find.byKey(ActionsBar.recipesKey));
    await tester.pumpAndSettle();

    expect(find.text('Recipes'), findsOneWidget);
    expect(find.text('Recipe target: Warm Terracotta'), findsOneWidget);
  });
}
