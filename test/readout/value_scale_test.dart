import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/readout/value_scale.dart';

void main() {
  Future<void> pumpScale(WidgetTester tester, double value) =>
      tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ValueScale(value: value))),
      );

  testWidgets('exposes the findable scale anchor', (tester) async {
    await pumpScale(tester, 2);
    expect(find.byKey(ValueScale.scaleKey), findsOneWidget);
  });

  testWidgets('renders the eleven labelled steps 0..10', (tester) async {
    await pumpScale(tester, 2);
    final scale = find.byKey(ValueScale.scaleKey);
    for (var n = 0; n <= 10; n++) {
      expect(find.descendant(of: scale, matching: find.text('$n')), findsWidgets,
          reason: 'step $n must be labelled');
    }
  });

  testWidgets('marks exactly the step nearest the sample value', (tester) async {
    await pumpScale(tester, 1.98); // rounds to 2
    final scale = find.byKey(ValueScale.scaleKey);
    final marked = find.descendant(
      of: scale,
      matching: find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.selected ?? false)),
    );
    expect(marked, findsOneWidget);
    expect(tester.widget<Semantics>(marked).properties.label, contains('2'));
  });

  testWidgets('clamps an out-of-range value to an end step', (tester) async {
    await pumpScale(tester, 42);
    final scale = find.byKey(ValueScale.scaleKey);
    final marked = find.descendant(
      of: scale,
      matching: find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.selected ?? false)),
    );
    expect(marked, findsOneWidget);
    expect(tester.widget<Semantics>(marked).properties.label, contains('10'));
  });

  testWidgets('marks the darkest step for value 0', (tester) async {
    await pumpScale(tester, 0);
    final scale = find.byKey(ValueScale.scaleKey);
    final marked = find.descendant(
      of: scale,
      matching: find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.selected ?? false)),
    );
    expect(marked, findsOneWidget);
    expect(tester.widget<Semantics>(marked).properties.label, contains('0'));
  });
}
