import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/onboarding/cvd_profile_read_endpoint.dart';
import 'package:paint_color_assistant/onboarding/onboarding_read_endpoint.dart';
import 'package:paint_color_assistant/onboarding/onboarding_state.dart';
import 'package:paint_color_assistant/onboarding/screens/arrangement_step.dart';
import 'package:paint_color_assistant/onboarding/screens/intake_step.dart';
import 'package:paint_color_assistant/onboarding/screens/lighting_step.dart';
import 'package:paint_color_assistant/onboarding/screens/onboarding_host.dart';
import 'package:paint_color_assistant/onboarding/screens/progress_region.dart';
import 'package:paint_color_assistant/onboarding/screens/result_step.dart';
import 'package:paint_color_assistant/onboarding/screens/screening_step.dart';
import 'package:paint_color_assistant/onboarding/screens/threshold_step.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

void main() {
  group('OnboardingHost (FLOW-1 shell)', () {
    testWidgets('boots the onboarding flow and mounts both read endpoints',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingHost()));

      // Both acceptance observation seams are mounted over the host.
      expect(find.byType(CvdProfileReadEndpoint), findsOneWidget);
      expect(find.byType(OnboardingReadEndpoint), findsOneWidget);
      expect(find.byKey(CvdProfileReadEndpoint.endpointKey), findsOneWidget);
      expect(find.byKey(OnboardingReadEndpoint.endpointKey), findsOneWidget);

      // The onboarding surface and its progress indicator render.
      expect(find.widgetWithText(AppBar, 'CVD self-assessment'), findsOneWidget);
      expect(find.byKey(ProgressRegion.regionKey), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
    });

    testWidgets('lays out every keyed step region as a stable anchor',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingHost()));

      expect(find.byKey(LightingStep.regionKey), findsOneWidget);
      expect(find.byKey(LightingStep.continueKey), findsOneWidget);
      expect(find.byKey(IntakeStep.regionKey), findsOneWidget);
      expect(find.byKey(ScreeningStep.regionKey), findsOneWidget);
      expect(find.byKey(ArrangementStep.regionKey), findsOneWidget);
      expect(find.byKey(ArrangementStep.poolKey), findsOneWidget);
      expect(find.byKey(ArrangementStep.arrangedKey), findsOneWidget);
      expect(find.byKey(ArrangementStep.startOverKey), findsOneWidget);
      expect(find.byKey(ArrangementStep.skipKey), findsOneWidget);
      expect(find.byKey(ThresholdStep.regionKey), findsOneWidget);
      expect(find.byKey(ResultStep.regionKey), findsOneWidget);
      expect(find.byKey(ResultStep.typeKey), findsOneWidget);
      expect(find.byKey(ResultStep.severityKey), findsOneWidget);
      expect(find.byKey(ResultStep.caveatKey), findsOneWidget);
      expect(find.byKey(ResultStep.saveKey), findsOneWidget);
    });

    testWidgets('its not-yet-wired controls are inert in the shell', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingHost()));

      // Controls whose behaviour phase has not run yet carry no handler. (The
      // lighting continue is wired by FLOW-3 and the arrangement by FLOW-4, so
      // they are no longer inert.)
      expect(
        tester.widget<TextButton>(find.byKey(ResultStep.saveKey)).onPressed,
        isNull,
      );
      expect(
        tester.widget<Slider>(find.byKey(ResultStep.severityKey)).onChanged,
        isNull,
      );
      // The arrangement step is wired (FLOW-4): the pool shows a control per
      // cap and nothing is arranged yet.
      expect(find.byKey(ArrangementStep.poolKey), findsOneWidget);
      expect(find.byKey(ArrangementStep.capKey(arrangementCaps.first)),
          findsOneWidget);
      expect(find.text('Arranged: 0'), findsOneWidget);
    });

    testWidgets('reads the profile store from the enclosing AppScope',
        (tester) async {
      await tester.pumpWidget(
        AppScope(
          dependencies: AppDependencies(
            colorScience: const ColorScienceImpl(),
            speech: const NoopSpeech(),
            haptics: const NoopHaptics(),
            store: InMemoryPersistentStore(),
          ),
          child: const MaterialApp(home: OnboardingHost()),
        ),
      );

      expect(find.byType(CvdProfileReadEndpoint), findsOneWidget);
      // No profile saved yet (the save is inert until PROFILE-2).
      final store = tester
          .widget<CvdProfileReadEndpoint>(
            find.byKey(CvdProfileReadEndpoint.endpointKey),
          )
          .store;
      expect(await store.count(), 0);
      expect(await store.load(), isNull);
    });
  });
}
