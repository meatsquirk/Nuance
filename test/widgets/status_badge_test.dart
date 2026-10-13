import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/widgets/status_badge.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('always renders its text label', (tester) async {
    await _pump(tester, const StatusBadge(label: 'Measured'));
    expect(find.text('Measured'), findsOneWidget);
  });

  testWidgets('renders an icon (not a swatch) when an icon is given',
      (tester) async {
    await _pump(
      tester,
      const StatusBadge(
        label: 'Measured',
        icon: Icons.check_circle,
        color: Color(0xFF2E7D32),
      ),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(Container), findsNothing);
    expect(
      tester.widget<Icon>(find.byType(Icon)).color,
      const Color(0xFF2E7D32),
      reason: 'the colour tints the icon decoratively',
    );
  });

  testWidgets('renders a decorative swatch when a colour but no icon is given',
      (tester) async {
    await _pump(
      tester,
      const StatusBadge(label: 'Estimated', color: Color(0xFFBF5B3A)),
    );
    expect(find.text('Estimated'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    final decoration = tester
        .widget<Container>(find.byType(Container))
        .decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFBF5B3A));
  });

  testWidgets('renders neither icon nor swatch when label only', (tester) async {
    await _pump(tester, const StatusBadge(label: 'Estimated'));
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('announces the label as a single semantics node', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const StatusBadge(label: 'Measured'));
    expect(
      tester.getSemantics(find.byType(StatusBadge)).label,
      'Measured',
    );
    handle.dispose();
  });

  testWidgets('a long label wraps within a narrow width without overflowing',
      (tester) async {
    await _pump(
      tester,
      const SizedBox(
        width: 120,
        child: StatusBadge(
          label: 'Estimated from a low-confidence single-point reading',
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('rejects a colour-only construction (empty label)', () {
    expect(() => StatusBadge(label: ''), throwsAssertionError);
  });
}
