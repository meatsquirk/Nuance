import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/color_simulation.dart';
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

  testWidgets('a long label wraps within a narrow width without overflowing',
      (tester) async {
    // A multi-point reading label (position + full colour value) in a width
    // narrower than its natural extent: it must wrap, raising no RenderFlex
    // overflow (the failure a bare, unflexed Text produced).
    await _pump(
      tester,
      const SizedBox(
        width: 120,
        child: ColorChip(
          label: 'Point (32, 50): L 96.538472 a -20.113847 b 93.884219',
        ),
      ),
    );
    expect(tester.takeException(), isNull,
        reason: 'the long label wraps instead of overflowing the row');
    expect(
      find.text('Point (32, 50): L 96.538472 a -20.113847 b 93.884219'),
      findsOneWidget,
    );
  });

  test('rejects a colour-only construction (empty label)', () {
    expect(() => ColorChip(label: ''), throwsAssertionError);
  });

  testWidgets(
      'with simulation off, reads the scope and draws one identity swatch '
      '(the true colour)', (tester) async {
    final controller = DisplayController(); // no simulation type → off
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
    // Simulation off: the identity path — exactly one swatch, its true colour.
    expect(find.text('Warm Terracotta'), findsOneWidget);
    final decoration =
        tester.widget<Container>(find.byType(Container)).decoration!
            as BoxDecoration;
    expect(decoration.color, original);
  });

  testWidgets(
      'with a simulation on, draws the simulated swatch alongside the original '
      '(AC-3)', (tester) async {
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
    // Two swatches render: the deutan projection and the untouched original.
    final swatches = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    expect(swatches, hasLength(2),
        reason: 'the simulated swatch is shown alongside the original');
    final simulated = simulateColor(original, controller.settings);
    expect(swatches, contains(original),
        reason: 'the original colour is shown alongside');
    expect(swatches, contains(simulated),
        reason: 'the displayed swatch is the deutan projection');
    expect(simulated, isNot(original),
        reason: 'deutan projection actually shifts this colour '
            '(control: a no-op projection would fail here)');
  });
}
