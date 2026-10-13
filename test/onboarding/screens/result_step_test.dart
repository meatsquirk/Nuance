import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/onboarding/engine/assessment_engine.dart';
import 'package:paint_color_assistant/onboarding/engine/severity_band.dart';
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

  // Reaches the result step with {deutan, 0.6 moderate}: a deutan diagnosis and
  // a moderate measured threshold, assembled and advanced (FLOW-5).
  OnboardingController deutanModerate() {
    final controller =
        OnboardingController(engine: const TieredAssessmentEngine());
    controller.reportDiagnosis(CvdType.deutan);
    controller.scoreThreshold(const [
      ThresholdProbe(contrast: 0.6, detected: false),
    ]);
    controller.advanceToResult();
    return controller;
  }

  testWidgets('with no estimate shows the placeholder, a zeroed inert slider '
      'and no band', (tester) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    expect(find.text('Result'), findsOneWidget);
    expect(find.textContaining('Estimated type'), findsNothing);
    expect(find.textContaining('Severity band'), findsNothing);
    final slider = tester.widget<Slider>(find.byKey(ResultStep.severityKey));
    expect(slider.value, 0);
    expect(slider.onChanged, isNull);
  });

  testWidgets('renders the assembled type and severity, with the slider live '
      'and the band for the assembled severity (AC-11)', (tester) async {
    final controller = deutanModerate();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    expect(find.text('Estimated type: deutan'), findsOneWidget);
    expect(find.text('Estimated severity: 60'), findsOneWidget);
    // Severity 0.6 → 60 on the slider's 0..100 scale; ENGINE-7 makes it live.
    final slider = tester.widget<Slider>(find.byKey(ResultStep.severityKey));
    expect(slider.value, 60);
    expect(slider.onChanged, isNotNull);
    // 0.6 reads back "moderate" (G-4) before the painter moves the slider.
    expect(find.text('Severity band: moderate'), findsOneWidget);
  });

  testWidgets('moving the severity slider re-renders the band (AC-11)',
      (tester) async {
    final controller = deutanModerate();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    final sliderFinder = find.byKey(ResultStep.severityKey);
    final box = tester.getRect(sliderFinder);
    // Tap low / mid / high along the track; the band is graded against the
    // slider's actual value, so the tap approximation is robust. Three distinct
    // bands fall out — a constant mapping would fail one of the rows.
    final bands = <SeverityBand>{};
    for (final fraction in <double>[0.2, 0.5, 0.95]) {
      await tester
          .tapAt(Offset(box.left + box.width * fraction, box.center.dy));
      await tester.pump();
      final value = tester.widget<Slider>(sliderFinder).value;
      final expected = SeverityBand.forSeverity(value / 100);
      bands.add(expected);
      expect(
        find.descendant(
          of: find.byKey(ResultStep.regionKey),
          matching: find.text('Severity band: ${expected.label}'),
        ),
        findsOneWidget,
        reason: 'severity ${value.round()} must read "${expected.label}"',
      );
    }
    expect(bands.length, 3, reason: 'the three taps span three distinct bands');
  });

  testWidgets('reading the slider back as a band does not persist a calibration '
      '(that is FLOW-7)', (tester) async {
    // ENGINE-7 owns only the band readout (AC-11); keeping the chosen severity
    // as calibratedSeverity is AC-12/FLOW-7, so moving the slider must not set
    // it here.
    final controller = deutanModerate();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    expect(controller.state.calibratedSeverity, isNull);
    final box = tester.getRect(find.byKey(ResultStep.severityKey));
    await tester.tapAt(Offset(box.left + box.width * 0.2, box.center.dy));
    await tester.pump();
    expect(controller.state.calibratedSeverity, isNull);
  });
}
