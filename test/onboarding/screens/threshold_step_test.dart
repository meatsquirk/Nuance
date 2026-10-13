import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/engine/assessment_engine.dart';
import 'package:paint_color_assistant/onboarding/onboarding_controller.dart';
import 'package:paint_color_assistant/onboarding/screens/threshold_step.dart';

void main() {
  // Pumps the threshold step over a real controller using the production tiered
  // engine (so a scored severity is meaningful), rebuilding on notify the way
  // the onboarding host does, and returns the controller to observe.
  Future<OnboardingController> pumpStep(WidgetTester tester) async {
    final controller =
        OnboardingController(engine: const TieredAssessmentEngine());
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => ThresholdStep(controller: controller),
        ),
      ),
    ));
    return controller;
  }

  // Answers the current probe: taps "I can see it" (detected) or "I can't see
  // it" (missed). Exactly one such control is shown at a time.
  Future<void> answer(WidgetTester tester, {required bool detected}) async {
    await tester
        .tap(find.text(detected ? 'I can see it' : "I can't see it"));
    await tester.pump();
  }

  group('ThresholdStep (ENGINE-6, AC-9)', () {
    testWidgets('shows one probe control pair and scores nothing yet',
        (tester) async {
      final controller = await pumpStep(tester);

      expect(find.byKey(ThresholdStep.regionKey), findsOneWidget);
      expect(find.text('Threshold probing'), findsOneWidget);
      // One probe at a time.
      expect(find.text('I can see it'), findsOneWidget);
      expect(find.text("I can't see it"), findsOneWidget);
      expect(find.text('Probe 1 of ${ThresholdStep.contrastDeck.length}'),
          findsOneWidget);
      expect(controller.state.threshold, isNull);
    });

    testWidgets('detecting every probe scores a zero severity', (tester) async {
      final controller = await pumpStep(tester);

      for (var i = 0; i < ThresholdStep.contrastDeck.length; i++) {
        // Still unscored until the last probe is answered.
        expect(controller.state.threshold, isNull);
        await answer(tester, detected: true);
      }

      expect(controller.state.threshold, isNotNull);
      expect(controller.state.threshold!.severity, 0);
    });

    testWidgets('missing the low-contrast probes scores a positive severity',
        (tester) async {
      final controller = await pumpStep(tester);

      // Miss every probe but the highest contrast → severity is the highest
      // failed contrast (contrastDeck[length-2]).
      for (var i = 0; i < ThresholdStep.contrastDeck.length - 1; i++) {
        await answer(tester, detected: false);
      }
      await answer(tester, detected: true);

      expect(controller.state.threshold!.severity,
          ThresholdStep.contrastDeck[ThresholdStep.contrastDeck.length - 2]);
    });

    testWidgets('the probe controls are replaced by a completion label when done',
        (tester) async {
      await pumpStep(tester);

      for (var i = 0; i < ThresholdStep.contrastDeck.length; i++) {
        await answer(tester, detected: true);
      }

      expect(find.text('Threshold probing complete'), findsOneWidget);
      expect(find.text('I can see it'), findsNothing);
      expect(find.text("I can't see it"), findsNothing);
    });
  });
}
