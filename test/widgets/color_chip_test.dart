import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_scope.dart';
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

  testWidgets(
      'reads the display settings from a DisplayScope and renders the swatch '
      '(shell: identity)', (tester) async {
    final controller = DisplayController()..setSimulationType(CvdType.deutan);
    addTearDown(controller.dispose);
    const original = Color(0xFFBF5B3A);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisplayScope(
            controller: controller,
            child: const ColorChip(label: 'Warm Terracotta', color: original),
          ),
        ),
      ),
    );
    // The chip reads the scope; the shell transform is identity, so the swatch
    // keeps its true colour and exactly one swatch is drawn.
    expect(find.text('Warm Terracotta'), findsOneWidget);
    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, original);
  });
}
