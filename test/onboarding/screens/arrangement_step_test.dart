import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/onboarding_controller.dart';
import 'package:paint_color_assistant/onboarding/onboarding_state.dart';
import 'package:paint_color_assistant/onboarding/screens/arrangement_step.dart';

void main() {
  // Pumps the arrangement step over a real controller, rebuilding on notify the
  // way the onboarding host does, and returns the controller to observe.
  Future<OnboardingController> pumpStep(WidgetTester tester) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => ArrangementStep(controller: controller),
        ),
      ),
    ));
    return controller;
  }

  group('ArrangementStep (FLOW-4, AC-6/7/8)', () {
    testWidgets('renders a control for each pooled cap and the wired controls',
        (tester) async {
      await pumpStep(tester);

      expect(find.byKey(ArrangementStep.regionKey), findsOneWidget);
      expect(find.text('Arrange the colour caps in hue order'), findsOneWidget);
      // One tappable control per cap in the pool (the full set at the start).
      for (final capId in arrangementCaps) {
        expect(find.byKey(ArrangementStep.capKey(capId)), findsOneWidget);
      }
      expect(find.text('Arranged: 0'), findsOneWidget);
      // Start-over and skip now carry handlers (FLOW-4 wires them).
      expect(
        tester.widget<TextButton>(find.byKey(ArrangementStep.startOverKey))
            .onPressed,
        isNotNull,
      );
      expect(
        tester.widget<TextButton>(find.byKey(ArrangementStep.skipKey)).onPressed,
        isNotNull,
      );
    });

    testWidgets('tapping a cap places it and re-renders the arranged count',
        (tester) async {
      final controller = await pumpStep(tester);
      final first = controller.state.arrangementPool.first;

      await tester.tap(find.byKey(ArrangementStep.capKey(first)));
      await tester.pump();

      expect(controller.state.arrangedCaps, [first]);
      // The placed cap's control leaves the pool; the arranged count updates.
      expect(find.byKey(ArrangementStep.capKey(first)), findsNothing);
      expect(find.text('Arranged: 1'), findsOneWidget);
    });

    testWidgets('start over returns every placed cap to the pool',
        (tester) async {
      final controller = await pumpStep(tester);
      await tester.tap(find.byKey(
          ArrangementStep.capKey(controller.state.arrangementPool.first)));
      await tester.pump();
      expect(controller.state.arrangedCaps, hasLength(1));

      await tester.tap(find.byKey(ArrangementStep.startOverKey));
      await tester.pump();

      expect(controller.state.arrangedCaps, isEmpty);
      expect(controller.state.arrangementPool, arrangementCaps);
      expect(find.text('Arranged: 0'), findsOneWidget);
    });

    testWidgets('skip marks the arrangement skipped', (tester) async {
      final controller = await pumpStep(tester);

      await tester.tap(find.byKey(ArrangementStep.skipKey));
      await tester.pump();

      expect(controller.state.arrangementSkipped, isTrue);
    });
  });
}
