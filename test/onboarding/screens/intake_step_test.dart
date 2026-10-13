import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/engine/assessment_engine.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';
import 'package:paint_color_assistant/onboarding/onboarding_controller.dart';
import 'package:paint_color_assistant/onboarding/screens/intake_step.dart';

void main() {
  // Pumps the intake step over a real controller on the tiered engine (as the
  // production host injects), rebuilding on notify the way the host does, and
  // returns the controller to observe.
  Future<OnboardingController> pumpStep(WidgetTester tester) async {
    final controller = OnboardingController(engine: const TieredAssessmentEngine());
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => IntakeStep(controller: controller),
        ),
      ),
    ));
    return controller;
  }

  Finder answer(String label) => find.widgetWithText(TextButton, label);

  group('IntakeStep (ENGINE-3, AC-3)', () {
    testWidgets('renders the confusion question, live answers and a live '
        'diagnosis entry (picker closed until opened)', (tester) async {
      await pumpStep(tester);

      expect(find.byKey(IntakeStep.regionKey), findsOneWidget);
      expect(
          find.text('Do reds, browns and greens get mixed up?'), findsOneWidget);
      for (final label in IntakeStep.confusionAnswers) {
        expect(
          tester.widget<TextButton>(answer(label)).onPressed,
          isNotNull,
          reason: '$label records an intake answer',
        );
      }
      // The prior-diagnosis entry is live (ENGINE-4) and the type picker is
      // hidden until it is opened.
      expect(
        tester.widget<TextButton>(answer('I have a diagnosis')).onPressed,
        isNotNull,
      );
      for (final label in IntakeStep.diagnosisTypeLabels.values) {
        expect(answer(label), findsNothing,
            reason: '$label stays hidden until the entry is opened');
      }
    });

    testWidgets('tapping "Often" records an answer that leans the prior red-green',
        (tester) async {
      final controller = await pumpStep(tester);

      await tester.tap(answer('Often'));
      await tester.pump();

      expect(controller.state.prior.direction, ScreeningDirection.redGreen);
      expect(controller.state.prior.weight, greaterThan(0));
    });

    testWidgets('tapping "Never" records an answer that leaves the prior empty',
        (tester) async {
      final controller = await pumpStep(tester);

      await tester.tap(answer('Never'));
      await tester.pump();

      expect(controller.state.prior, StartingPrior.none);
    });
  });

  group('IntakeStep prior-diagnosis picker (ENGINE-4, AC-4)', () {
    testWidgets('"I have a diagnosis" reveals a button per diagnosable type',
        (tester) async {
      await pumpStep(tester);

      await tester.tap(answer('I have a diagnosis'));
      await tester.pumpAndSettle();

      for (final label in IntakeStep.diagnosisTypeLabels.values) {
        expect(answer(label), findsOneWidget,
            reason: '$label is offered once the entry is opened');
      }
    });

    for (final entry in IntakeStep.diagnosisTypeLabels.entries) {
      testWidgets('picking "${entry.value}" seeds the prior as ${entry.key.name}',
          (tester) async {
        final controller = await pumpStep(tester);

        await tester.tap(answer('I have a diagnosis'));
        await tester.pumpAndSettle();
        await tester.tap(answer(entry.value));
        await tester.pump();

        expect(controller.state.prior.type, entry.key);
        expect(controller.state.prior.weight, 1.0);
      });
    }
  });
}
