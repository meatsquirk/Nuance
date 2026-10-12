import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/onboarding_controller.dart';
import 'package:paint_color_assistant/onboarding/screens/lighting_step.dart';

void main() {
  // Pumps the lighting step over a real controller, rebuilding on notify the
  // way the onboarding host does, and returns the controller to observe.
  Future<OnboardingController> pumpStep(WidgetTester tester) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => LightingStep(controller: controller),
        ),
      ),
    ));
    return controller;
  }

  Finder tile(String title) =>
      find.widgetWithText(CheckboxListTile, title);

  const brightness = 'Screen brightness turned up';
  const nightLight = 'Night-light turned off';
  const daylight = 'In daylight';

  group('LightingStep (FLOW-3, AC-2)', () {
    testWidgets('renders the three checks unticked and a live Continue control',
        (tester) async {
      await pumpStep(tester);

      expect(find.byKey(LightingStep.regionKey), findsOneWidget);
      expect(find.text('Display and lighting setup'), findsOneWidget);
      expect(tile(brightness), findsOneWidget);
      expect(tile(nightLight), findsOneWidget);
      expect(tile(daylight), findsOneWidget);
      for (final t
          in tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile))) {
        expect(t.value, isFalse);
      }
      // FLOW-3 wires Continue (the gate lives in tryContinue, not a disabled
      // button), so it carries a handler.
      expect(
        tester.widget<TextButton>(find.byKey(LightingStep.continueKey)).onPressed,
        isNotNull,
      );
    });

    testWidgets('ticking each checkbox confirms its matching lighting check and '
        'renders the ticked state', (tester) async {
      final controller = await pumpStep(tester);

      await tester.tap(tile(brightness));
      await tester.pump();
      expect(controller.state.brightnessConfirmed, isTrue);
      expect(controller.state.nightLightConfirmed, isFalse);
      expect(controller.state.daylightConfirmed, isFalse);

      await tester.tap(tile(nightLight));
      await tester.pump();
      expect(controller.state.nightLightConfirmed, isTrue);

      await tester.tap(tile(daylight));
      await tester.pump();
      expect(controller.state.daylightConfirmed, isTrue);
      expect(controller.state.lightingConfirmed, isTrue);

      for (final t
          in tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile))) {
        expect(t.value, isTrue, reason: 'the confirmed state is rendered back');
      }
    });

    testWidgets('unticking a checkbox clears its lighting check', (tester) async {
      final controller = await pumpStep(tester);

      await tester.tap(tile(daylight));
      await tester.pump();
      expect(controller.state.daylightConfirmed, isTrue);

      await tester.tap(tile(daylight));
      await tester.pump();
      expect(controller.state.daylightConfirmed, isFalse);
    });

    testWidgets('Continue is a no-op until all three checks are confirmed',
        (tester) async {
      final controller = await pumpStep(tester);

      // Unconfirmed Continue is processed but does not begin testing.
      await tester.tap(find.byKey(LightingStep.continueKey));
      await tester.pump();
      expect(controller.state.stepIndex, 0);
      expect(controller.state.testingStarted, isFalse);

      await tester.tap(tile(brightness));
      await tester.tap(tile(nightLight));
      await tester.tap(tile(daylight));
      await tester.pump();

      await tester.tap(find.byKey(LightingStep.continueKey));
      await tester.pump();
      expect(controller.state.stepIndex, 1, reason: 'a confirmed Continue advances');
      expect(controller.state.testingStarted, isTrue);
    });
  });
}
