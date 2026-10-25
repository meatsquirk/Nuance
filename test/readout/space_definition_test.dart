import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';
import 'package:paint_color_assistant/readout/space_definition.dart';

void main() {
  testWidgets('exposes the named-space anchor for the given space '
      '(READOUT-2 shell)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpaceDefinition(space: ReadoutSpace.munsell)),
      ),
    );
    expect(find.byKey(SpaceDefinition.nameKey(ReadoutSpace.munsell)),
        findsOneWidget);
  });

  test('derives a distinct name/definition anchor per space', () {
    // Every space's anchors are unique and distinct from one another, so the
    // AC-5 finders never collide across spaces.
    final nameKeys = <Key>{};
    final definitionKeys = <Key>{};
    for (final space in ReadoutSpace.values) {
      nameKeys.add(SpaceDefinition.nameKey(space));
      definitionKeys.add(SpaceDefinition.definitionKey(space));
      expect(SpaceDefinition.nameKey(space),
          isNot(SpaceDefinition.definitionKey(space)));
    }
    expect(nameKeys, hasLength(ReadoutSpace.values.length));
    expect(definitionKeys, hasLength(ReadoutSpace.values.length));
  });
}
