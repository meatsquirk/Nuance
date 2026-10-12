import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/screens/onboarding_host.dart';
import 'package:paint_color_assistant/onboarding/screens/progress_region.dart';
import 'package:paint_color_assistant/palette/self_assessment_entry_screen.dart';

void main() {
  testWidgets(
      'builds the bs-07 onboarding host behind the stable entry anchor',
      (tester) async {
    // No AppScope above it (the bs-06 router/card push this under a bare
    // MaterialApp); the host falls back to an in-memory profile store.
    await tester.pumpWidget(
      const MaterialApp(home: SelfAssessmentEntryScreen()),
    );

    // The stable anchor bs-06's card navigation and acceptance test observe is
    // preserved, now on the onboarding host's scaffold.
    expect(find.byKey(SelfAssessmentEntryScreen.screenKey), findsOneWidget);
    expect(find.byType(OnboardingHost), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'CVD self-assessment'), findsOneWidget);
    expect(find.byKey(ProgressRegion.regionKey), findsOneWidget);
  });
}
