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
import 'package:paint_color_assistant/onboarding/onboarding_controller.dart';
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
  // AC tests — flow & result group (ITEST-2): AC-1, 2, 10, 11, 12, 13, 14.
  //
  // One *pending* `acTestWidgets` per AC (its behaviour phase un-pends it by
  // deleting the row in `bs07/pending.dart`). Givens are built only through the
  // public UI surface and asserted before the When. The result-step ACs (AC-1,
  // 10, 11, 12, 13) reach the result step only once FLOW-5 assembles the
  // estimate, and the shell exposes no advance-to-result control, so each
  // asserts that precondition explicitly (it fails at baseline naming FLOW-5)
  // rather than tapping an inert, not-yet-built control. The lighting (AC-2) and
  // progress (AC-14) tests build the Given through the real controls and fail at
  // baseline on a Then naming FLOW-3 / FLOW-2.
  // -------------------------------------------------------------------------

  group('bs-07 AC tests — flow & result group (ITEST-2)', () {
    acTestWidgets(
      'AC-1',
      'the estimate is labelled approximate and a clinical test is recommended',
      (tester) async {
        // Given: the painter completed the flow to the result step.
        final h = await givenSelfAssessment(tester);
        // The result step is reached only once FLOW-5 assembles an estimate.
        expect(h.estimate, isNotNull,
            reason: 'AC-1 needs the result step reached — FLOW-5 assembles the '
                'estimate');

        // Then: the result labels the estimate approximate AND recommends a
        // clinical anomaloscope test (both present; FLOW-8 fills the caveat).
        expect(h.caveatShown, isTrue,
            reason: 'the approximate-estimate caveat must be shown (FLOW-8)');
        final result = find.byKey(ResultStep.regionKey);
        expect(
          find.descendant(
              of: result, matching: find.textContaining('approximate estimate')),
          findsOneWidget,
          reason: 'the result must label the estimate an approximate estimate',
        );
        expect(
          find.descendant(
              of: result, matching: find.textContaining('anomaloscope')),
          findsOneWidget,
          reason: 'the result must recommend a clinical anomaloscope test',
        );
      },
    );

    acTestWidgets(
      'AC-2',
      'the lighting setup must be confirmed before testing begins',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: on the lighting step with the three checks not all confirmed,
        // and testing not started.
        expect(h.stepIndex, 0, reason: 'starts on the lighting step');
        expect(h.lightingConfirmed, isFalse,
            reason: 'no lighting check confirmed yet');
        expect(h.testingStarted, isFalse, reason: 'testing has not begun');

        // When: Continue (E43) is tapped with the checks unconfirmed.
        await h.whenContinue();

        // Then: testing does not begin — still on the lighting step.
        expect(h.stepIndex, 0, reason: 'an unconfirmed Continue must not advance');
        expect(h.testingStarted, isFalse,
            reason: 'testing must not begin until the checks are confirmed');

        // Control: confirm all three, then Continue advances past the gate — a
        // Continue that advances regardless of the checks fails the Then above,
        // and a gate that never opens fails here.
        await h.whenConfirmLightingCheck(LightingCheck.brightness);
        await h.whenConfirmLightingCheck(LightingCheck.nightLight);
        await h.whenConfirmLightingCheck(LightingCheck.daylight);
        expect(h.lightingConfirmed, isTrue,
            reason: 'confirming all three opens the continue gate (FLOW-3)');
        await h.whenContinue();
        expect(h.stepIndex, 1,
            reason: 'a confirmed Continue advances past lighting (FLOW-2/FLOW-3)');
        expect(h.testingStarted, isTrue,
            reason: 'testing begins once past the lighting gate');
      },
    );

    acTestWidgets(
      'AC-10',
      'the painter adjusts the estimated type by hand',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: the result step estimating deutan (FLOW-5 + deutan-leaning
        // inputs).
        expect(h.estimate, isNotNull,
            reason: 'AC-10 needs the result step reached — FLOW-5 assembles the '
                'estimate');
        expect(h.estimate!.type, CvdType.deutan,
            reason: 'the scenario reaches a deutan estimate before the override');

        // When: set the type to protan by hand (E40). FLOW-6 adds the type
        // choices this taps into.
        await h.whenAdjustType();
        // Then: the estimate type is protan.
        expect(h.estimate!.type, CvdType.protan,
            reason: 'the by-hand override must set the type to protan');
        // Control: setting it back reads the other type (the override is not
        // ignored — a control that keeps deutan fails the Then above).
        await h.whenAdjustType();
        expect(h.estimate!.type, CvdType.deutan,
            reason: 'the by-hand override is honoured both ways');
      },
    );

    acTestWidgets(
      'AC-11',
      'the severity value sets a plain-language band',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: on the result step (FLOW-5 assembled the estimate).
        expect(h.estimate, isNotNull,
            reason: 'AC-11 needs the result step reached — FLOW-5 assembles the '
                'estimate');

        final result = find.byKey(ResultStep.regionKey);
        // The three Scenario-Outline example rows: slider 30/60/90. The product
        // band is graded against the INDEPENDENT [referenceBand] on the slider's
        // actual value (robust to the tap-along-track approximation). A mapping
        // that returns one band for all values fails on the row that should read
        // a different band.
        for (final sliderValue in <double>[30, 60, 90]) {
          await h.whenSetSeverity(sliderValue);
          final actual =
              tester.widget<Slider>(find.byKey(ResultStep.severityKey)).value;
          final expectedBand = referenceBand(actual / 100);
          expect(
            find.descendant(
                of: result, matching: find.textContaining(expectedBand.label)),
            findsOneWidget,
            reason: 'severity ${actual.round()} must read "${expectedBand.label}"',
          );
        }
      },
    );

    acTestWidgets(
      'AC-12',
      'the severity slider doubles as subjective self-calibration',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: the result step shows the simulated/original pair with the
        // slider, and no calibration has been kept yet (FLOW-5 reached).
        expect(h.estimate, isNotNull,
            reason: 'AC-12 needs the result step reached — FLOW-5 assembles the '
                'estimate');
        expect(h.calibratedSeverity, isNull,
            reason: 'no self-calibration kept before the painter sets the slider');

        // When: set the slider until the pair stops looking different, keeping
        // that severity.
        await h.whenSetSeverity(70);
        final kept =
            tester.widget<Slider>(find.byKey(ResultStep.severityKey)).value;
        // Then: the chosen severity is kept as the subjective self-calibration
        // (0..1), read from the slider's actual value — not discarded or left at
        // a default.
        expect(h.calibratedSeverity, closeTo(kept / 100, 1e-9),
            reason: 'the kept calibration is exactly the slider value (0..1)');

        // Control: a different slider value is kept instead.
        await h.whenSetSeverity(40);
        final kept2 =
            tester.widget<Slider>(find.byKey(ResultStep.severityKey)).value;
        expect(kept2, isNot(kept), reason: 'the control sets a different value');
        expect(h.calibratedSeverity, closeTo(kept2 / 100, 1e-9),
            reason: 'the kept calibration tracks the new slider value');
      },
    );

    acTestWidgets(
      'AC-13',
      'saving the profile configures the pipeline',
      (tester) async {
        // The injected default profile is the shipped deutan@1.0, which confuses
        // the fixed pair; saving the measured deutan-moderate profile flips it.
        final h = await givenSelfAssessment(tester);
        const check = DichromatConfusionCheck();
        const injectedDefault = CvdProfile(type: CvdType.deutan); // severity 1.0

        // Given: the store is empty and the pipeline uses the default profile
        // (the fixed pair is confusable under it) — the control for "before save".
        expect(await h.profileCount, 0, reason: 'no profile persisted before save');
        expect(check.confusable(fixedPair.a, fixedPair.b, injectedDefault), isTrue,
            reason: 'control: the default profile confuses the fixed pair');
        // Given (cont.): a deutan, moderate result on the result step.
        expect(h.estimate, isNotNull,
            reason: 'AC-13 needs the result step reached — FLOW-5 assembles the '
                'estimate');
        expect(h.estimate!.type, CvdType.deutan,
            reason: 'the scenario assembles a deutan estimate');
        expect(referenceBand(h.estimate!.severity), SeverityBand.moderate,
            reason: 'the scenario assembles a moderate severity (ENGINE-7 band)');

        // When: save the profile (E43).
        await h.whenSave();

        // Then: exactly one profile is written {deutan, moderate}, and the
        // pipeline is reconfigured off the default — bs-03's confusion check on
        // the fixed pair now reflects the saved profile (the default confused the
        // pair; the measured one does not). Sim/daltonization are verified at the
        // shared seam only (D-8, known gap).
        expect(await h.profileCount, 1, reason: 'exactly one profile is written');
        final saved = await h.savedProfile;
        expect(saved, isNotNull);
        expect(saved!.type, CvdType.deutan);
        expect(referenceBand(saved.severity), SeverityBand.moderate);
        expect(check.confusable(fixedPair.a, fixedPair.b, saved), isFalse,
            reason: 'the saved deutan-moderate profile reconfigures the confusion '
                'check off the default');
      },
    );

    acTestWidgets(
      'AC-14',
      'the current step is shown against the total',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: a self-assessment of four steps; advance to the second step.
        // Advancing is built through the real controls (confirm the lighting
        // checks, then Continue) so the Given keeps holding once FLOW-3 adds the
        // lighting gate.
        expect(h.stepTotal, 4, reason: 'the onboarding has four top-level steps');
        expect(h.progressText, 'Step 1 of 4', reason: 'starts on the first step');
        await h.whenConfirmLightingCheck(LightingCheck.brightness);
        await h.whenConfirmLightingCheck(LightingCheck.nightLight);
        await h.whenConfirmLightingCheck(LightingCheck.daylight);
        await h.whenContinue();
        expect(h.stepIndex, 1,
            reason: 'the painter advanced to the second step — 0-based index 1 '
                '(FLOW-2; the rendered indicator is 1-based)');

        // Then: the indicator reads the second of four steps (the raw observable
        // the AC names).
        expect(h.progressText, 'Step 2 of 4',
            reason: 'the rendered indicator shows the second of four steps');

        // Control: advancing again reads the third of four — an indicator
        // hard-coded to a step, or showing the wrong total, fails here.
        await h.whenContinue();
        expect(h.stepIndex, 2, reason: 'advanced to the third step');
        expect(h.progressText, 'Step 3 of 4',
            reason: 'the indicator tracks the current step, not a hard-coded one');
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC tests — tiers & arrangement group (ITEST-3): AC-3, 4, 5, 6, 7, 8, 9.
  //
  // One *pending* `acTestWidgets` per AC (its behaviour phase un-pends it by
  // deleting the row in `bs07/pending.dart`). Givens are built only through the
  // public UI surface and asserted before the When; scoring ACs are graded
  // against the harness's INDEPENDENT fixture axes/ordering, never the product
  // scorer. At baseline every shell control is inert, so each tier test fails on
  // a Then naming its owning phase (the engine default never reaches state:
  // prior stays none, screening/threshold stay null). Where the shell exposes no
  // control to express the AC's specific value — the diagnosis type (AC-4), the
  // per-plate response (AC-5), a specific cap to place (AC-6/AC-7) — the test
  // asserts the precondition / skip path that fails cleanly naming the phase
  // that adds the control + driver argument, and carries a *B pending* grade with
  // a Test-augmentations row (exactly as AC-10 does for FLOW-6), rather than
  // tapping a not-yet-built control.
  // -------------------------------------------------------------------------

  group('bs-07 AC tests — tiers & arrangement group (ITEST-3)', () {
    acTestWidgets(
      'AC-3',
      'an intake answer contributes to the starting prior',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: the intake step asks the red-green confusion question and the
        // prior carries no bias before any answer.
        expect(
          find.descendant(
              of: find.byKey(IntakeStep.regionKey),
              matching: find.textContaining(
                  'Do reds, browns and greens get mixed up?')),
          findsOneWidget,
          reason: 'the Tier 1 confusion question is asked',
        );
        expect(h.prior, StartingPrior.none,
            reason: 'no intake answer folded into the prior yet');

        // When: answer "Often" through the real intake control (ENGINE-3 folds
        // it into the starting prior).
        await h.whenAnswerIntake(intakeOften.value);

        // Then: the answer is recorded toward the prior — it now leans red-green
        // with a non-zero weight (the "Often" contribution).
        expect(h.prior.direction, ScreeningDirection.redGreen,
            reason: 'an "Often" answer leans the prior toward red-green '
                '(ENGINE-3)');
        expect(h.prior.weight, greaterThan(0),
            reason: 'the recorded answer carries a non-zero bias');

        // Control: a fresh flow answering "Never" does NOT lean red-green. This
        // rejects both an intake that discards the answer (the Then above fails)
        // and one that always returns red-green regardless of the answer (fails
        // here).
        final control = await givenSelfAssessment(tester);
        await control.whenAnswerIntake(intakeNever.value);
        expect(control.prior.direction, isNot(ScreeningDirection.redGreen),
            reason: 'a "Never" answer must not lean the prior toward red-green');
      },
    );

    acTestWidgets(
      'AC-4',
      'a prior clinical diagnosis entered at intake seeds the prior',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: the intake step offers the prior-diagnosis entry and the prior
        // carries no type yet.
        expect(
          find.descendant(
              of: find.byKey(IntakeStep.regionKey),
              matching: find.widgetWithText(TextButton, 'I have a diagnosis')),
          findsOneWidget,
          reason: 'the prior-diagnosis entry is offered at intake',
        );
        expect(h.prior.type, isNull, reason: 'no diagnosis seeded yet');

        // When: report a prior clinical diagnosis of deutan (ENGINE-4 seeds the
        // prior through the engine).
        await h.whenReportDiagnosis();

        // Then: the starting prior is seeded as deutan.
        expect(h.prior.type, CvdType.deutan,
            reason: 'reporting a deutan diagnosis seeds the prior as deutan '
                '(ENGINE-4)');
        // Limited — B pending ENGINE-4: the frozen whenReportDiagnosis() only
        // opens the diagnosis entry and carries no type, so this cannot yet
        // reject "seeds the WRONG type" (a protan control). ENGINE-4 adds the
        // type picker + a type argument on the driver and the protan control
        // (see Test augmentations in modules/ITEST.md).
      },
    );

    acTestWidgets(
      'AC-5',
      'screening yields presence and the red-green versus blue-yellow direction',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: the screening step is shown and no screening result is scored
        // yet.
        expect(
          find.descendant(
              of: find.byKey(ScreeningStep.regionKey),
              matching: find.widgetWithText(TextButton, 'Read the plate')),
          findsOneWidget,
          reason: 'the plate screening control is shown',
        );
        expect(h.screening, isNull, reason: 'screening not scored yet');

        // When: complete the plate screening (ENGINE-5 scores the responses
        // into presence + direction).
        await h.whenReadPlate();

        // Then: the screening reports a deficiency present along the red-green
        // axis (the red-green–deficient fixture).
        expect(h.screening, isNotNull, reason: 'the screening is scored (ENGINE-5)');
        expect(h.screening!.present, isTrue,
            reason: 'the red-green–deficient fixture reports present');
        expect(h.screening!.direction, ScreeningDirection.redGreen,
            reason: 'the direction is red-green, graded against the independent '
                'fixture axis');
        // Limited — B pending ENGINE-5: the frozen whenReadPlate() taps a single
        // plate control and carries no plate-response fixture, so this cannot yet
        // feed the blue-yellow (→ blueYellow) and no-deficiency (→ present false)
        // controls that reject a scorer which always returns present+redGreen.
        // ENGINE-5 wires the per-plate responses + a fixture argument on the
        // driver; the direction stays graded against the fixture axes, never the
        // product scorer (see Test augmentations).
      },
    );

    acTestWidgets(
      'AC-6',
      'the painter places colour caps in hue order',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: the arrangement step shows a pool of unplaced caps and nothing
        // is arranged yet. The shell leaves the pool empty and exposes no
        // cap-selection control; FLOW-4 fills the pool and wires placing a cap.
        expect(find.byKey(ArrangementStep.regionKey), findsOneWidget);
        expect(h.arrangedCaps, isEmpty, reason: 'nothing placed yet');
        expect(h.arrangementPool, isNotEmpty,
            reason: 'AC-6 needs a populated cap pool to place from — FLOW-4 fills '
                'the pool and wires placeCap (no cap-selection control in the '
                'shell yet)');
        // Limited — B pending FLOW-4: once FLOW-4 adds the cap-selection control
        // + a whenPlaceCap(capId) driver, placing pool.first takes the next
        // arranged position (arranged.last == placed; length +1) and removes it
        // from the pool (length −1), rejecting a place at a wrong index, a
        // duplicate, or one that leaves the cap in the pool (see Test
        // augmentations).
      },
    );

    acTestWidgets(
      'AC-7',
      'starting over clears the arrangement',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: several caps placed (arranged ≥ 2, pool reduced). Placing caps
        // needs FLOW-4's cap-selection control, absent from the shell, so the
        // pool is empty and nothing is arranged yet.
        expect(find.byKey(ArrangementStep.startOverKey), findsOneWidget,
            reason: 'the start-over control (E39) is present');
        expect(h.arrangedCaps.length, greaterThanOrEqualTo(2),
            reason: 'AC-7 needs caps placed before starting over — FLOW-4 wires '
                'placing caps (no cap-selection control in the shell yet)');
        // Limited — B pending FLOW-4: once FLOW-4 lets caps be placed,
        // whenStartOver() returns ALL caps to the pool (arranged empty, pool ==
        // the full set), rejecting a reset that clears only the last placement or
        // leaves some arranged (see Test augmentations).
      },
    );

    acTestWidgets(
      'AC-8',
      'the painter skips the arrangement for now',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: on the arrangement step, not skipped yet.
        expect(find.byKey(ArrangementStep.skipKey), findsOneWidget,
            reason: 'the skip control (E43) is present');
        expect(h.arrangementSkipped, isFalse, reason: 'not skipped yet');

        // When: skip the arrangement through the real control (FLOW-4 continues
        // the flow without an arrangement result).
        await h.whenSkipArrangement();

        // Then: the flow is marked skipped, so it contributes no arrangement
        // result.
        expect(h.arrangementSkipped, isTrue,
            reason: 'skipping continues the flow without an arrangement result '
                '(FLOW-4)');
        // Limited — B pending FLOW-4: the catalogue control "completing the
        // arrangement instead records a result" needs the cap-selection control
        // FLOW-4 adds; this asserts only the skip path until then (see Test
        // augmentations).
      },
    );

    acTestWidgets(
      'AC-9',
      'threshold probing yields a severity along the confusion line',
      (tester) async {
        final h = await givenSelfAssessment(tester);
        // Given: the threshold step is shown and no threshold is scored yet.
        expect(
          find.descendant(
              of: find.byKey(ThresholdStep.regionKey),
              matching: find.widgetWithText(TextButton, 'I can see it')),
          findsOneWidget,
          reason: 'the probe controls are shown',
        );
        expect(h.threshold, isNull, reason: 'threshold not scored yet');

        // When: answer the probes as a painter who detects only HIGH contrast
        // (the "strong" fixture), through the real probe controls (ENGINE-6
        // scores the severity along the confusion line).
        for (final probe in thresholdProbesStrong) {
          await h.whenProbe(detected: probe.detected);
        }

        // Then: a severity on the confusion line is scored, in (0, 1].
        expect(h.threshold, isNotNull, reason: 'the threshold is scored (ENGINE-6)');
        final strongSeverity = h.threshold!.severity;
        expect(strongSeverity, inInclusiveRange(0, 1),
            reason: 'severity is a 0..1 value on the confusion line');
        expect(strongSeverity, greaterThan(0),
            reason: 'a painter who misses low contrast has a non-zero severity');

        // Control: a fresh flow where the painter detects EVEN low contrast (the
        // "mild" fixture) scores a LOWER severity — graded against the
        // independent fixture ordering (strong detects only high contrast),
        // rejecting a constant scorer or one not tied to the confusion line.
        final control = await givenSelfAssessment(tester);
        for (final probe in thresholdProbesMild) {
          await control.whenProbe(detected: probe.detected);
        }
        expect(control.threshold, isNotNull);
        expect(control.threshold!.severity, lessThan(strongSeverity),
            reason: 'detecting lower contrast yields a lower severity than the '
                'strong fixture');
      },
    );
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
      // delivered AC. Delivered: AC-2 (FLOW-3).
      const expected = <String>{
        'AC-1',
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
      for (final ac in pendingACs.keys) {
        // Pending ⇒ skipped in the default pass…
        expect(pendingSkipReason(ac, forceRunPending: false), isNotNull,
            reason: '$ac is pending — it must be skipped in the default pass');
        // …but executes in the run-pending pass.
        expect(pendingSkipReason(ac, forceRunPending: true), isNull,
            reason: '$ac is pending — it must run in the run-pending pass');
      }
      // An un-pended AC (AC-2, delivered by FLOW-3) always runs, in either mode.
      expect(pendingACs.containsKey('AC-2'), isFalse);
      expect(pendingSkipReason('AC-2', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-2', forceRunPending: true), isNull);
      // An id absent from the map always runs, in either mode.
      expect(pendingSkipReason('AC-999', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-999', forceRunPending: true), isNull);
    });
  });
}
