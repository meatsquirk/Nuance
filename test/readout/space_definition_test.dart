import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';
import 'package:paint_color_assistant/readout/space_definition.dart';
import 'package:paint_color_assistant/readout/space_selector.dart';

final _examplePattern = RegExp(r'e\.g\.|example|for instance');

Future<void> _pump(WidgetTester tester, ReadoutSpace space) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SpaceDefinition(space: space))),
    );

void main() {
  testWidgets('shows the space name as an openable label with the definition '
      'hidden (READOUT-6)', (tester) async {
    await _pump(tester, ReadoutSpace.munsell);

    // The tappable name anchor carries the space's label.
    expect(find.byKey(SpaceDefinition.nameKey(ReadoutSpace.munsell)),
        findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(SpaceDefinition.nameKey(ReadoutSpace.munsell)),
        matching: find.text(SpaceSelector.labelFor(ReadoutSpace.munsell)),
      ),
      findsOneWidget,
    );
    // The definition is hidden until the name is opened.
    expect(find.byKey(SpaceDefinition.definitionKey(ReadoutSpace.munsell)),
        findsNothing);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsNothing);
  });

  testWidgets('opening the name reveals the definition with an example, and '
      'closing it hides it again (READOUT-6)', (tester) async {
    await _pump(tester, ReadoutSpace.munsell);

    // Open.
    await tester.tap(find.byKey(SpaceDefinition.nameKey(ReadoutSpace.munsell)));
    await tester.pumpAndSettle();
    final definition =
        find.byKey(SpaceDefinition.definitionKey(ReadoutSpace.munsell));
    expect(definition, findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    final text = tester.widget<Text>(
        find.descendant(of: definition, matching: find.byType(Text)));
    expect(text.data, isNotEmpty);
    expect(text.data!.toLowerCase(), matches(_examplePattern));

    // Close again.
    await tester.tap(find.byKey(SpaceDefinition.nameKey(ReadoutSpace.munsell)));
    await tester.pumpAndSettle();
    expect(find.byKey(SpaceDefinition.definitionKey(ReadoutSpace.munsell)),
        findsNothing);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });

  test('every space has a non-empty plain-language definition with an example',
      () {
    // Covers definitionFor for all four spaces (the AC-5 copy, D-4).
    for (final space in ReadoutSpace.values) {
      final definition = SpaceDefinition.definitionFor(space);
      expect(definition.trim(), isNotEmpty,
          reason: '${space.name} definition must be non-empty');
      expect(definition.toLowerCase(), matches(_examplePattern),
          reason: '${space.name} definition must carry an example');
    }
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
