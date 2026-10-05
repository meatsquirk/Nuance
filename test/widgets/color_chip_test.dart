import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/widgets/color_chip.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('always renders its text label', (tester) async {
    await _pump(tester, const ColorChip(label: 'Warm Terracotta'));
    expect(find.text('Warm Terracotta'), findsOneWidget);
  });

  testWidgets('renders a swatch when a colour is given', (tester) async {
    await _pump(
      tester,
      const ColorChip(label: 'Warm Terracotta', color: Color(0xFFBF5B3A)),
    );
    expect(find.text('Warm Terracotta'), findsOneWidget);
    expect(find.byType(Container), findsOneWidget);
  });

  testWidgets('renders no swatch when no colour is given', (tester) async {
    await _pump(tester, const ColorChip(label: 'Warm Terracotta'));
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('announces the label as a single semantics node', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const ColorChip(label: 'Warm Terracotta'));
    expect(
      tester.getSemantics(find.byType(ColorChip)).label,
      'Warm Terracotta',
    );
    handle.dispose();
  });

  test('rejects a colour-only construction (empty label)', () {
    expect(() => ColorChip(label: ''), throwsAssertionError);
  });
}
