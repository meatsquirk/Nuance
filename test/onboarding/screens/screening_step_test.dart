import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/engine/assessment_engine.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';
import 'package:paint_color_assistant/onboarding/onboarding_controller.dart';
import 'package:paint_color_assistant/onboarding/screens/screening_step.dart';

void main() {
  // Pumps the screening step over a real controller using the production tiered
  // engine (so a scored result is meaningful), rebuilding on notify the way the
  // onboarding host does, and returns the controller to observe.
  Future<OnboardingController> pumpStep(WidgetTester tester) async {
    final controller =
        OnboardingController(engine: const TieredAssessmentEngine());
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => ScreeningStep(controller: controller),
        ),
      ),
    ));
    return controller;
  }

  // Taps the read / can't-read control for the plate at [index].
  Future<void> answer(WidgetTester tester, int index,
      {required bool correct}) async {
    await tester.tap(find.byKey(
        correct ? ScreeningStep.readKey(index) : ScreeningStep.cantReadKey(index)));
    await tester.pump();
  }

  group('ScreeningStep (ENGINE-5, AC-5)', () {
    testWidgets('renders a read / can\'t-read control for each deck plate',
        (tester) async {
      final controller = await pumpStep(tester);

      expect(find.byKey(ScreeningStep.regionKey), findsOneWidget);
      expect(find.text('Plate screening'), findsOneWidget);
      for (var i = 0; i < ScreeningStep.plateDeck.length; i++) {
        expect(find.byKey(ScreeningStep.readKey(i)), findsOneWidget);
        expect(find.byKey(ScreeningStep.cantReadKey(i)), findsOneWidget);
      }
      // Nothing scored until every plate is answered.
      expect(controller.state.screening, isNull);
    });

    testWidgets('reading every plate correctly scores no deficiency',
        (tester) async {
      final controller = await pumpStep(tester);

      for (var i = 0; i < ScreeningStep.plateDeck.length; i++) {
        // Still unscored until the last plate is answered.
        expect(controller.state.screening, isNull);
        await answer(tester, i, correct: true);
      }

      expect(controller.state.screening, isNotNull);
      expect(controller.state.screening!.present, isFalse);
    });

    testWidgets('failing the red-green plates scores present along red-green',
        (tester) async {
      final controller = await pumpStep(tester);

      for (var i = 0; i < ScreeningStep.plateDeck.length; i++) {
        // Misread the red-green plates, read the blue-yellow ones.
        await answer(tester, i,
            correct: ScreeningStep.plateDeck[i] != ScreeningDirection.redGreen);
      }

      expect(controller.state.screening!.present, isTrue);
      expect(
          controller.state.screening!.direction, ScreeningDirection.redGreen);
    });

    testWidgets('an answered plate\'s controls go inert', (tester) async {
      await pumpStep(tester);

      await answer(tester, 0, correct: true);

      // The plate just answered no longer accepts a response...
      expect(
        tester.widget<TextButton>(find.byKey(ScreeningStep.readKey(0))).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(ScreeningStep.cantReadKey(0)))
            .onPressed,
        isNull,
      );
      // ...while an unanswered plate still does.
      expect(
        tester.widget<TextButton>(find.byKey(ScreeningStep.readKey(1))).onPressed,
        isNotNull,
      );
    });
  });
}
