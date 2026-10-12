import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/onboarding/onboarding_read_endpoint.dart';
import 'package:paint_color_assistant/onboarding/screens/onboarding_host.dart';
import 'package:paint_color_assistant/onboarding/screens/onboarding_screen.dart';
import 'package:paint_color_assistant/onboarding/screens/result_step.dart';

void main() {
  group('OnboardingScreen — See my result (FLOW-5 enabler)', () {
    testWidgets('before advancing, no estimate and the result shows its '
        'placeholder', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingHost()));

      final controller = tester
          .widget<OnboardingReadEndpoint>(
              find.byKey(OnboardingReadEndpoint.endpointKey))
          .controller;
      expect(controller.state.estimate, isNull);
      expect(
        find.descendant(
            of: find.byKey(ResultStep.regionKey), matching: find.text('Result')),
        findsOneWidget,
      );
      // The control is present and live (it assembles the estimate — not inert).
      final button =
          tester.widget<TextButton>(find.byKey(OnboardingScreen.seeResultKey));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping it assembles the estimate and renders type + severity',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingHost()));

      final seeResult = find.byKey(OnboardingScreen.seeResultKey);
      await tester.ensureVisible(seeResult);
      await tester.tap(seeResult);
      await tester.pumpAndSettle();

      final controller = tester
          .widget<OnboardingReadEndpoint>(
              find.byKey(OnboardingReadEndpoint.endpointKey))
          .controller;
      final estimate = controller.state.estimate;
      // No tiers were run, so the empty prior assembles the red-green deutan
      // default at severity 0 — a result is reachable regardless (D-7).
      expect(estimate, isNotNull);
      expect(estimate!.type, CvdType.deutan);
      expect(estimate.severity, 0);

      // The result step now renders the estimated type and severity.
      final result = find.byKey(ResultStep.regionKey);
      expect(
        find.descendant(
            of: result, matching: find.text('Estimated type: deutan')),
        findsOneWidget,
      );
      expect(
        find.descendant(
            of: result, matching: find.text('Estimated severity: 0')),
        findsOneWidget,
      );
      // The severity slider reflects the estimate (0) and stays inert (FLOW-7).
      final slider =
          tester.widget<Slider>(find.byKey(ResultStep.severityKey));
      expect(slider.value, 0);
      expect(slider.onChanged, isNull);
    });
  });
}
