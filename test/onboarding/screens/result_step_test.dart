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
    // The caveat belongs to the shown result, so the placeholder carries none.
    expect(find.textContaining('approximate estimate'), findsNothing);
    expect(find.textContaining('anomaloscope'), findsNothing);
  });

  testWidgets('shows the approximate-estimate caveat and the clinical '
      'anomaloscope recommendation on the result (FLOW-8, AC-1)',
      (tester) async {
    final controller = deutanModerate();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    // The caveat sits within the result step's caveat area…
    final caveat = find.byKey(ResultStep.caveatKey);
    expect(caveat, findsOneWidget);
    // …labelling the estimate approximate (it estimates, it does not diagnose)…
    expect(
      find.descendant(
          of: caveat, matching: find.textContaining('approximate estimate')),
      findsOneWidget,
      reason: 'the result labels the estimate an approximate estimate',
    );
    // …and recommending a clinical anomaloscope test for ground truth.
    expect(
      find.descendant(
          of: caveat, matching: find.textContaining('anomaloscope')),
      findsOneWidget,
      reason: 'the result recommends a clinical anomaloscope test',
    );
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

  testWidgets('moving the slider keeps the chosen severity as the calibration '
      '(AC-12, FLOW-7)', (tester) async {
    // FLOW-7 routes the now-live ENGINE-7 slider through the controller: moving
    // it keeps the chosen severity as calibratedSeverity (= the value that
    // becomes the profile severity, D-6).
    final controller = deutanModerate();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    // Nothing kept before the painter moves the slider; the slider sits at the
    // assembled estimate (0.6 → 60).
    expect(controller.state.calibratedSeverity, isNull);
    expect(tester.widget<Slider>(find.byKey(ResultStep.severityKey)).value, 60);

    final box = tester.getRect(find.byKey(ResultStep.severityKey));
    await tester.tapAt(Offset(box.left + box.width * 0.2, box.center.dy));
    await tester.pumpAndSettle();

    // The kept calibration is exactly the slider's resulting value (0..1), and
    // the slider now reflects the kept value rather than the estimate's 0.6.
    final kept = tester.widget<Slider>(find.byKey(ResultStep.severityKey)).value;
    expect(controller.state.calibratedSeverity, closeTo(kept / 100, 1e-9));
    expect(kept, isNot(60), reason: 'the control moved the slider off 0.6');

    // Control: a second tap keeps a different value instead.
    await tester.tapAt(Offset(box.left + box.width * 0.9, box.center.dy));
    await tester.pumpAndSettle();
    final kept2 =
        tester.widget<Slider>(find.byKey(ResultStep.severityKey)).value;
    expect(kept2, isNot(kept), reason: 'the control sets a different value');
    expect(controller.state.calibratedSeverity, closeTo(kept2 / 100, 1e-9));
  });

  testWidgets('releasing the slider without moving it keeps the estimate '
      'severity (AC-12, FLOW-7)', (tester) async {
    // A Slider tap fires onChangeEnd, which confirms the calibration; with no
    // prior move the estimate's own severity (0.6) is kept (D-6).
    final controller = deutanModerate();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    final box = tester.getRect(find.byKey(ResultStep.severityKey));
    // Tap exactly on the current thumb position (60%) so the value does not move.
    await tester.tapAt(Offset(box.left + box.width * 0.6, box.center.dy));
    await tester.pumpAndSettle();
    expect(controller.state.calibratedSeverity, closeTo(0.6, 0.02),
        reason: 'confirming an unmoved slider keeps the estimate severity');
  });

  testWidgets('shows the simulated/original pair, which re-renders with the '
      'slider (AC-12, FLOW-7)', (tester) async {
    final controller = deutanModerate();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    // Both swatches are shown beside the slider.
    expect(find.byKey(ResultStep.pairKey), findsOneWidget);
    Color simColour() => tester
        .widget<Container>(find.byKey(ResultStep.pairSimulatedKey))
        .color!;
    Color origColour() => tester
        .widget<Container>(find.byKey(ResultStep.pairOriginalKey))
        .color!;

    final originalBefore = origColour();
    final simAtEstimate = simColour();

    // Raising the severity collapses the simulated swatch toward the original,
    // so the pair re-renders as the painter moves the slider.
    final box = tester.getRect(find.byKey(ResultStep.severityKey));
    await tester.tapAt(Offset(box.left + box.width * 0.98, box.center.dy));
    await tester.pumpAndSettle();
    final simAtHigh = simColour();

    expect(simAtHigh, isNot(simAtEstimate),
        reason: 'the simulated swatch tracks the slider');
    expect(origColour(), originalBefore,
        reason: 'the original swatch is fixed — it is the reference');
  });

  testWidgets('the pair is absent before an estimate is assembled',
      (tester) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    expect(find.byKey(ResultStep.pairKey), findsNothing,
        reason: 'nothing to simulate without an estimate');
  });

  testWidgets('the by-hand type picker overrides the estimated type when a '
      'choice is tapped (AC-10, FLOW-6)', (tester) async {
    final controller = deutanModerate();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    // The picker renders a live choice per CvdType under the group key.
    expect(find.byKey(ResultStep.typeKey), findsOneWidget);
    for (final type in CvdType.values) {
      final choice = tester
          .widget<TextButton>(find.byKey(ResultStep.typeChoiceKey(type)));
      expect(choice.onPressed, isNotNull, reason: '${type.name} is tappable');
    }
    expect(find.text('Estimated type: deutan'), findsOneWidget);

    // Tapping protan overrides the computed deutan and re-renders.
    await tester.tap(find.byKey(ResultStep.typeChoiceKey(CvdType.protan)));
    await tester.pump();
    expect(controller.state.estimate!.type, CvdType.protan);
    expect(find.text('Estimated type: protan'), findsOneWidget);

    // Tapping deutan sets it back (the override is honoured both ways).
    await tester.tap(find.byKey(ResultStep.typeChoiceKey(CvdType.deutan)));
    await tester.pump();
    expect(controller.state.estimate!.type, CvdType.deutan);
    expect(find.text('Estimated type: deutan'), findsOneWidget);
  });

  testWidgets('the type choices are inert before an estimate is assembled',
      (tester) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    await pumpResult(tester, controller);

    // The placeholder still carries the picker group, but the choices are inert.
    expect(find.byKey(ResultStep.typeKey), findsOneWidget);
    for (final type in CvdType.values) {
      final choice = tester
          .widget<TextButton>(find.byKey(ResultStep.typeChoiceKey(type)));
      expect(choice.onPressed, isNull,
          reason: '${type.name} is inert without an estimate');
    }
  });
}
