import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/all_spaces_region.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';
import 'package:paint_color_assistant/readout/space_definition.dart';
import 'package:paint_color_assistant/readout/space_selector.dart';

// Warm terracotta (CIELAB L 58, a 25.27, b 22.75): the real engine reads it as
// Munsell 10R, so the four spaces carry mutually distinct signatures.
const _sample = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  provenance: Provenance(ProvenanceTier.measured),
);

ReadoutController _controller() => ReadoutController(
      sample: _sample,
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      router: const AppRouter(),
    );

Future<void> _pump(WidgetTester tester, ReadoutController controller) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AllSpacesRegion(controller: controller))),
    );

void main() {
  testWidgets('exposes the region anchor and one definition host per space',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    expect(find.byKey(AllSpacesRegion.regionKey), findsOneWidget);
    // One SpaceDefinition host per colour space, each findable by its anchor.
    expect(
        find.byType(SpaceDefinition), findsNWidgets(ReadoutSpace.values.length));
    for (final space in ReadoutSpace.values) {
      expect(find.byKey(SpaceDefinition.nameKey(space)), findsOneWidget);
    }
  });

  testWidgets('labels and shows every colour space together (AC-4)',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    // Every space's label is shown — the readout is no longer one at a time.
    for (final space in ReadoutSpace.values) {
      expect(find.text(SpaceSelector.labelFor(space)), findsOneWidget,
          reason: 'the ${SpaceSelector.labelFor(space)} label must be shown');
    }

    // Every space's values are rendered at once under the region, each carrying
    // its collision-safe signature.
    final shown = tester
        .widgetList<Text>(find.descendant(
            of: find.byKey(AllSpacesRegion.regionKey),
            matching: find.byType(Text)))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(shown, contains('°'), reason: 'CIELCh values (degree-marked hue)');
    expect(shown, contains('10R'), reason: 'Munsell notation');
    expect(shown, matches(RegExp(r'#[0-9a-fA-F]{6}')), reason: 'sRGB hex');
    expect(shown, matches(RegExp(r'\b\d{1,3},\s*\d{1,3},\s*\d{1,3}\b')),
        reason: 'sRGB triplet');
    expect(shown, contains('25.27'), reason: 'CIELAB a*');
    expect(shown, contains('22.75'), reason: 'CIELAB b*');
  });
}
