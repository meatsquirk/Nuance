import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/compare_stub.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

Sample _sample(String? name) => Sample(
      coordinates: const ColorCoordinates(lightness: 58, a: 24, b: 30),
      provenance: const Provenance(ProvenanceTier.measured),
      name: name,
    );

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(home: screen));
}

void main() {
  testWidgets('shows the slot A sample name and an empty slot B', (tester) async {
    await _pump(tester, ComparisonStubScreen(sampleA: _sample('Warm Terracotta')));
    expect(find.text('Slot A: Warm Terracotta'), findsOneWidget);
    expect(find.text('Slot B: (empty)'), findsOneWidget);
  });

  testWidgets('shows the slot B sample name and an empty slot A', (tester) async {
    await _pump(tester, ComparisonStubScreen(sampleB: _sample('Warm Terracotta')));
    expect(find.text('Slot B: Warm Terracotta'), findsOneWidget);
    expect(find.text('Slot A: (empty)'), findsOneWidget);
  });

  testWidgets('renders (empty) for a carried sample that has no name',
      (tester) async {
    await _pump(tester, ComparisonStubScreen(sampleA: _sample(null)));
    expect(find.text('Slot A: (empty)'), findsOneWidget);
  });

  testWidgets('both slots empty when no samples are carried', (tester) async {
    await _pump(tester, const ComparisonStubScreen());
    expect(find.text('Slot A: (empty)'), findsOneWidget);
    expect(find.text('Slot B: (empty)'), findsOneWidget);
  });
}
