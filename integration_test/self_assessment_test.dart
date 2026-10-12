// Acceptance suite for bs-07 CVD self-assessment (onboarding).
//
// ENGINE-1 (scaffold) landed the runner target with the pending-gate skeleton
// (`bs07/pending.dart`, all 14 ACs pending) and the integrity guards so the
// scaffold cannot pass vacuously. ITEST-1 adds the harness
// (`self_assessment_harness.dart` — Given/When/Then vocabulary + fixtures + the
// independent references), a never-pending **smoke test** proving the shells
// wire end to end (the real app boots, routes to the onboarding host via
// `AppRouter.toSelfAssessment()`, and renders every region with both read
// endpoints mounted), and **fixture guards** so a later AC test can rely on the
// fixtures (the intake answer matches a real button; the screening sets isolate
// a direction; the cap pool is a real reordering; the threshold sets separate
// mild from strong; the band reference matches the three example rows and the
// fixed pair discriminates the deutan severity against the shipped detector).
//
// ITEST-2/3 register one *pending* `acTestWidgets` per AC here; the behaviour
// phases un-pend each by deleting its row in `bs07/pending.dart`. Default
// `flutter test integration_test/self_assessment_test.dart -d <udid>` skips
// pending ACs; `--dart-define=BS07_RUN_PENDING=true` runs them (red baseline /
// un-pend run). A booted device udid is mandatory — without `-d` the run
// executes zero tests and still exits 0 (false green; carried flake).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/compare/difference.dart';
import 'package:paint_color_assistant/onboarding/cvd_profile_read_endpoint.dart';
import 'package:paint_color_assistant/onboarding/engine/severity_band.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';
import 'package:paint_color_assistant/onboarding/onboarding_read_endpoint.dart';
import 'package:paint_color_assistant/onboarding/onboarding_state.dart';
import 'package:paint_color_assistant/onboarding/screens/arrangement_step.dart';
import 'package:paint_color_assistant/onboarding/screens/intake_step.dart';
import 'package:paint_color_assistant/onboarding/screens/lighting_step.dart';
import 'package:paint_color_assistant/onboarding/screens/progress_region.dart';
import 'package:paint_color_assistant/onboarding/screens/result_step.dart';
import 'package:paint_color_assistant/onboarding/screens/screening_step.dart';
import 'package:paint_color_assistant/onboarding/screens/threshold_step.dart';
import 'package:paint_color_assistant/palette/self_assessment_entry_screen.dart';

import 'self_assessment_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------------------
  // Smoke: the shells wire end to end (never pending).
  // -------------------------------------------------------------------------

  testWidgets(
    'smoke: the assembled app routes to the onboarding host and renders every '
    'region with both read endpoints mounted',
    (tester) async {
      final harness = await givenSelfAssessment(tester);

      // Routed to the self-assessment behind its stable entry anchor, with both
      // read endpoints mounted.
      expect(find.byKey(SelfAssessmentEntryScreen.screenKey), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'CVD self-assessment'), findsOneWidget);
      expect(find.byKey(OnboardingReadEndpoint.endpointKey), findsOneWidget);
      expect(find.byKey(CvdProfileReadEndpoint.endpointKey), findsOneWidget);

      // Every keyed region the finders and behaviour phases anchor to is laid
      // out (the shell renders them all at once).
      expect(find.byKey(ProgressRegion.regionKey), findsOneWidget);
      expect(find.byKey(LightingStep.regionKey), findsOneWidget);
      expect(find.byKey(IntakeStep.regionKey), findsOneWidget);
      expect(find.byKey(ScreeningStep.regionKey), findsOneWidget);
      expect(find.byKey(ArrangementStep.regionKey), findsOneWidget);
      expect(find.byKey(ThresholdStep.regionKey), findsOneWidget);
      expect(find.byKey(ResultStep.regionKey), findsOneWidget);

      // The read endpoints respond with the pre-assessment default state.
      expect(harness.state, const OnboardingState());
      expect(harness.stepTotal, 4);
      expect(harness.stepIndex, 0);
      expect(harness.progressText, 'Step 1 of 4');
      expect(harness.testingStarted, isFalse);
      expect(harness.lightingConfirmed, isFalse);
      expect(harness.estimate, isNull);
      expect(harness.saved, isFalse);
      expect(await harness.profileCount, 0);
      expect(await harness.savedProfile, isNull);
    },
  );

  // -------------------------------------------------------------------------
  // Fixture guards (never pending) — a later AC test relies on these, so assert
  // the fixtures carry the shape their ACs assume. Non-vacuous: every guard
  // checks a concrete property, never just "is non-empty".
  // -------------------------------------------------------------------------

  group('bs-07 fixtures', () {
    test('intake answers drive a real button and cover Often/Never (AC-3)', () {
      // The "Often" answer's value is exactly the intake step's button label, so
      // whenAnswerIntake drives the real control.
      expect(intakeOften.value, 'Often');
      expect(intakeNever.value, 'Never');
      // All answers share the one confusion question (AC-3 is one question).
      expect(
        intakeAnswers.every((a) => a.questionId == intakeConfusionQuestionId),
        isTrue,
      );
      // Often and Never are present as the AC-3 case and its control.
      expect(intakeAnswers, contains(intakeOften));
      expect(intakeAnswers, contains(intakeNever));
    });

    test('screening sets isolate a direction and a no-deficiency control (AC-5)',
        () {
      final rgRed = screeningPlatesRedGreen
          .where((p) => p.axis == ScreeningDirection.redGreen);
      final rgBlue = screeningPlatesRedGreen
          .where((p) => p.axis == ScreeningDirection.blueYellow);
      // The red-green set actually has plates on both axes (so the .every checks
      // below are not vacuously true on an empty subset), misses every red-green
      // plate and reads the blue-yellow ones — a correct scorer reports present
      // along red-green.
      expect(rgRed.length, 3);
      expect(rgBlue.length, 2);
      expect(rgRed.every((p) => !p.correct), isTrue);
      expect(rgBlue.every((p) => p.correct), isTrue);

      // The blue-yellow set mirrors it (the direction control): red-green read
      // correctly, blue-yellow missed.
      final byRed = screeningPlatesBlueYellow
          .where((p) => p.axis == ScreeningDirection.redGreen);
      final byBlue = screeningPlatesBlueYellow
          .where((p) => p.axis == ScreeningDirection.blueYellow);
      expect(byRed.length, 3);
      expect(byBlue.length, 2);
      expect(byRed.every((p) => p.correct), isTrue);
      expect(byBlue.every((p) => !p.correct), isTrue);

      // The no-deficiency set has plates and reads every one correctly (the
      // presence control).
      expect(screeningPlatesNone.length, 4);
      expect(screeningPlatesNone.every((p) => p.correct), isTrue);

      // The main fixture is the red-green set.
      expect(screeningPlates, same(screeningPlatesRedGreen));
    });

    test('cap pool is a real reordering of distinct caps (AC-6/7/8)', () {
      // Distinct ids (placing one removes exactly it), and not already in order
      // (so "arrange in hue order" is a real reordering, not a no-op).
      expect(capPool.toSet().length, capPool.length);
      expect(capPool.length, greaterThanOrEqualTo(2));
      final sorted = [...capPool]..sort();
      expect(capPool, isNot(orderedEquals(sorted)));
    });

    test('threshold sets separate mild from strong (AC-9 control)', () {
      // Mild detects every probe; strong fails its low-contrast probes.
      expect(thresholdProbesMild.every((p) => p.detected), isTrue);
      expect(thresholdProbesStrong.any((p) => !p.detected), isTrue);
      // The lowest contrast strong detects is above the highest mild detects —
      // a monotone threshold scorer must return strong > mild.
      final mildMaxDetected = thresholdProbesMild
          .where((p) => p.detected)
          .map((p) => p.contrast)
          .reduce((a, b) => a > b ? a : b);
      final strongMinDetected = thresholdProbesStrong
          .where((p) => p.detected)
          .map((p) => p.contrast)
          .reduce((a, b) => a < b ? a : b);
      expect(strongMinDetected, greaterThan(mildMaxDetected));
      expect(thresholdProbe, same(thresholdProbesStrong));
    });

    test('referenceBand matches the three example rows and discriminates (AC-11)',
        () {
      // The AC-11 Scenario-Outline example rows (slider 30/60/90 → severity
      // 0.30/0.60/0.90) under the independent G-4 boundaries.
      expect(referenceBand(0.30), SeverityBand.mild);
      expect(referenceBand(0.60), SeverityBand.moderate);
      expect(referenceBand(0.90), SeverityBand.strong);
      // Boundaries (D-5 half-open intervals) and extremes.
      expect(referenceBand(0.0), SeverityBand.mild);
      expect(referenceBand(0.45), SeverityBand.moderate);
      expect(referenceBand(0.75), SeverityBand.strong);
      expect(referenceBand(1.0), SeverityBand.strong);
      // Three distinct outputs — the mapping is not constant (the AC-11 control).
      expect(
        {referenceBand(0.30), referenceBand(0.60), referenceBand(0.90)}.length,
        3,
      );
    });

    test('fixedPair discriminates deutan severity on the shipped detector (AC-13)',
        () {
      const check = DichromatConfusionCheck();
      // Clearly different to normal vision (so a confusion warning would be
      // truthful at all).
      expect(deltaE00(fixedPair.a, fixedPair.b), greaterThanOrEqualTo(10));
      // Confusable at a strong deutan profile, not at a moderate one — so saving
      // a measured profile changes the verdict on this pair (AC-13's pipeline
      // reconfiguration; ITEST-2/PROFILE-2 pin the injected default so the save
      // flips it).
      expect(
        check.confusable(
            fixedPair.a, fixedPair.b, const CvdProfile(type: CvdType.deutan)),
        isTrue,
      );
      expect(
        check.confusable(fixedPair.a, fixedPair.b,
            const CvdProfile(type: CvdType.deutan, severity: 0.6)),
        isFalse,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Pending-gate scaffold guards (ENGINE-1) — kept so the gate stays honest as
  // ACs land. While an AC is pending, guard 3 asserts it is skipped by default
  // and runs only when forced; as each behaviour phase deletes its row the
  // expected set below must shrink to match (non-vacuous).
  // -------------------------------------------------------------------------

  group('bs-07 pending gate (scaffold guard)', () {
    test('pending map is exactly the still-pending ACs (shrinks as they land)',
        () {
      // Seeded with AC-1..AC-14 (ENGINE-1); each behaviour phase deletes its
      // AC's row here as it un-pends it, so this set shrinks by one per
      // delivered AC. None delivered yet — all 14 are pending.
      const expected = <String>{
        'AC-1',
        'AC-2',
        'AC-3',
        'AC-4',
        'AC-5',
        'AC-6',
        'AC-7',
        'AC-8',
        'AC-9',
        'AC-10',
        'AC-11',
        'AC-12',
        'AC-13',
        'AC-14',
      };
      expect(pendingACs.keys.toSet(), expected);
    });

    test('every pending AC is owned by a real behaviour phase', () {
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} owner "${entry.value}" is not a bs-07 '
              'behaviour phase',
        );
      }
    });

    test('pendingSkipReason skips pending ACs by default and runs them forced',
        () {
      for (var i = 1; i <= 14; i++) {
        final ac = 'AC-$i';
        // Pending ⇒ skipped in the default pass…
        expect(pendingSkipReason(ac, forceRunPending: false), isNotNull,
            reason: '$ac is pending — it must be skipped in the default pass');
        // …but executes in the run-pending pass.
        expect(pendingSkipReason(ac, forceRunPending: true), isNull,
            reason: '$ac is pending — it must run in the run-pending pass');
      }
      // An id absent from the map always runs, in either mode.
      expect(pendingSkipReason('AC-999', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-999', forceRunPending: true), isNull);
    });
  });
}
