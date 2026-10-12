import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/onboarding/engine/assessment_engine.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';
import 'package:paint_color_assistant/onboarding/onboarding_controller.dart';
import 'package:paint_color_assistant/onboarding/screens/result_step.dart';

void main() {
  Future<void> pumpResult(WidgetTester tester, OnboardingController c) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: c,
            builder: (context, _) => ResultStep(controller: c),
          ),
        ),
      ));

  testWidgets('with no estimate shows the placeholder and a zeroed slider',
      (tester) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    expect(find.text('Result'), findsOneWidget);
    expect(find.textContaining('Estimated type'), findsNothing);
    expect(tester.widget<Slider>(find.byKey(ResultStep.severityKey)).value, 0);
  });

  testWidgets('renders the assembled type and severity, reflected on the slider',
      (tester) async {
    final controller =
        OnboardingController(engine: const TieredAssessmentEngine());
    addTearDown(controller.dispose);
    // A deutan diagnosis and a moderate measured threshold → {deutan, 0.6}.
    controller.reportDiagnosis(CvdType.deutan);
    controller.scoreThreshold(const [
      ThresholdProbe(contrast: 0.6, detected: false),
    ]);
    controller.advanceToResult();

    await pumpResult(tester, controller);

    expect(find.text('Estimated type: deutan'), findsOneWidget);
    expect(find.text('Estimated severity: 60'), findsOneWidget);
    // Severity 0.6 → 60 on the slider's 0..100 scale; inert until FLOW-7.
    final slider = tester.widget<Slider>(find.byKey(ResultStep.severityKey));
    expect(slider.value, 60);
    expect(slider.onChanged, isNull);
  });
}
