import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/recipes_stub.dart';

Sample _sample(String? name) => Sample(
      coordinates: const ColorCoordinates(lightness: 40, a: -5, b: 20),
      provenance: const Provenance(ProvenanceTier.measured),
      name: name,
    );

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(home: screen));
}

void main() {
  testWidgets('shows the named mixing target', (tester) async {
    await _pump(tester, RecipesStubScreen(target: _sample('Deep Olive Green')));
    expect(find.text('Recipe target: Deep Olive Green'), findsOneWidget);
  });

  testWidgets('shows (unnamed) for a target with no name', (tester) async {
    await _pump(tester, RecipesStubScreen(target: _sample(null)));
    expect(find.text('Recipe target: (unnamed)'), findsOneWidget);
  });
}
