import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/readout/all_spaces_region.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';
import 'package:paint_color_assistant/readout/space_definition.dart';

void main() {
  testWidgets('exposes the region anchor and one definition host per space '
      '(READOUT-2 shell)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AllSpacesRegion())),
    );

    expect(find.byKey(AllSpacesRegion.regionKey), findsOneWidget);
    // One SpaceDefinition host per colour space, each findable by its anchor.
    expect(find.byType(SpaceDefinition), findsNWidgets(ReadoutSpace.values.length));
    for (final space in ReadoutSpace.values) {
      expect(find.byKey(SpaceDefinition.nameKey(space)), findsOneWidget);
    }
  });

  testWidgets('renders no space values yet — behaviour unchanged',
      (tester) async {
    // The shell must not render any space reading (that lands in READOUT-3), so
    // the still-present selector keeps the one-at-a-time behaviour.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AllSpacesRegion())),
    );
    expect(find.text('CIELCh'), findsNothing);
    expect(find.text('Munsell'), findsNothing);
    expect(find.text('sRGB'), findsNothing);
    expect(find.text('CIELAB'), findsNothing);
  });
}
