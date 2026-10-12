import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/onboarding/engine/assessment_engine.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';
import 'package:paint_color_assistant/onboarding/onboarding_controller.dart';
import 'package:paint_color_assistant/onboarding/onboarding_state.dart';
import 'package:paint_color_assistant/onboarding/onboarding_steps.dart';
import 'package:paint_color_assistant/store/cvd_profile_store.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

void main() {
  group('OnboardingController construction', () {
    test('starts in the empty state with the default engine and steps', () {
      final controller = OnboardingController();
      addTearDown(controller.dispose);

      expect(controller.state, const OnboardingState());
      expect(controller.engine, isA<ShellAssessmentEngine>());
      expect(controller.profileStore, isNull);
      expect(controller.steps, defaultOnboardingSteps);
      expect(controller.stepTotal, 4);
    });

    test('holds the injected engine, store and steps', () {
      final store = CvdProfileStore(InMemoryPersistentStore());
      const engine = ShellAssessmentEngine();
      final controller = OnboardingController(
        engine: engine,
        profileStore: store,
        steps: const [OnboardingStep('Only')],
      );
      addTearDown(controller.dispose);

      expect(controller.engine, same(engine));
      expect(controller.profileStore, same(store));
      expect(controller.stepTotal, 1);
    });
  });

  group('OnboardingController actions are deferred to their behaviour phase', () {
    late OnboardingController controller;

    setUp(() => controller = OnboardingController());
    tearDown(() => controller.dispose());

    test('scoreScreening throws (ENGINE-5)', () {
      expect(
        () => controller.scoreScreening(const []),
        throwsUnimplementedError,
      );
    });

    test('placeCap throws (FLOW-4)', () {
      expect(() => controller.placeCap(0), throwsUnimplementedError);
    });

    test('startOver throws (FLOW-4)', () {
      expect(controller.startOver, throwsUnimplementedError);
    });

    test('skipArrangement throws (FLOW-4)', () {
      expect(controller.skipArrangement, throwsUnimplementedError);
    });

    test('scoreThreshold throws (ENGINE-6)', () {
      expect(
        () => controller.scoreThreshold(const []),
        throwsUnimplementedError,
      );
    });

    test('advanceToResult throws (FLOW-5)', () {
      expect(controller.advanceToResult, throwsUnimplementedError);
    });

    test('setType throws (FLOW-6)', () {
      expect(
        () => controller.setType(CvdType.protan),
        throwsUnimplementedError,
      );
    });

    test('setSeverity throws (FLOW-7)', () {
      expect(() => controller.setSeverity(0.5), throwsUnimplementedError);
    });

    test('confirmCalibration throws (FLOW-7)', () {
      expect(controller.confirmCalibration, throwsUnimplementedError);
    });

    test('save throws (PROFILE-2)', () {
      expect(controller.save, throwsUnimplementedError);
    });
  });

  group('OnboardingController intake (ENGINE-3, AC-3)', () {
    late OnboardingController controller;
    late int notifications;

    setUp(() {
      // The real tiered engine (as the production host injects), so the recorded
      // answer actually moves the prior.
      controller = OnboardingController(engine: const TieredAssessmentEngine());
      notifications = 0;
      controller.addListener(() => notifications++);
    });
    tearDown(() => controller.dispose());

    test('an "Often" answer leans the prior red-green and notifies', () {
      controller.answerIntake(
        const IntakeAnswer(questionId: rgConfusionQuestionId, value: 'Often'),
      );
      expect(controller.state.prior.direction, ScreeningDirection.redGreen);
      expect(controller.state.prior.weight, greaterThan(0));
      expect(notifications, 1);
    });

    test('a "Never" answer leaves the prior empty', () {
      controller.answerIntake(
        const IntakeAnswer(questionId: rgConfusionQuestionId, value: 'Never'),
      );
      expect(controller.state.prior, StartingPrior.none);
      expect(notifications, 1);
    });

    test('re-answering the same question replaces the earlier answer', () {
      controller.answerIntake(
        const IntakeAnswer(questionId: rgConfusionQuestionId, value: 'Often'),
      );
      expect(controller.state.prior.direction, ScreeningDirection.redGreen);

      // Change the mind to "Never": the prior reverts to empty rather than
      // keeping the first answer's lean.
      controller.answerIntake(
        const IntakeAnswer(questionId: rgConfusionQuestionId, value: 'Never'),
      );
      expect(controller.state.prior, StartingPrior.none);
      expect(notifications, 2);
    });
  });

  group('OnboardingController prior diagnosis (ENGINE-4, AC-4)', () {
    late OnboardingController controller;
    late int notifications;

    setUp(() {
      controller = OnboardingController(engine: const TieredAssessmentEngine());
      notifications = 0;
      controller.addListener(() => notifications++);
    });
    tearDown(() => controller.dispose());

    test('reportDiagnosis seeds the prior as the reported type and notifies', () {
      controller.reportDiagnosis(CvdType.deutan);
      expect(controller.state.prior.type, CvdType.deutan);
      expect(controller.state.prior.direction, ScreeningDirection.redGreen);
      expect(controller.state.prior.weight, 1.0);
      expect(notifications, 1);
    });

    test('a reported diagnosis overrides a lean the intake had formed', () {
      // An intake answer first leans the prior red-green with no type...
      controller.answerIntake(
        const IntakeAnswer(questionId: rgConfusionQuestionId, value: 'Often'),
      );
      expect(controller.state.prior.type, isNull);

      // ...then a reported tritan diagnosis replaces the whole prior.
      controller.reportDiagnosis(CvdType.tritan);
      expect(controller.state.prior.type, CvdType.tritan);
      expect(controller.state.prior.direction, ScreeningDirection.blueYellow);
      expect(notifications, 2);
    });
  });

  group('OnboardingController lighting gate (FLOW-3, AC-2)', () {
    late OnboardingController controller;
    late int notifications;

    setUp(() {
      controller = OnboardingController();
      notifications = 0;
      controller.addListener(() => notifications++);
    });
    tearDown(() => controller.dispose());

    test('confirmLightingCheck sets the matching flag and notifies', () {
      controller.confirmLightingCheck(LightingCheck.brightness);
      expect(controller.state.brightnessConfirmed, isTrue);
      expect(controller.state.nightLightConfirmed, isFalse);
      expect(controller.state.daylightConfirmed, isFalse);

      controller.confirmLightingCheck(LightingCheck.nightLight);
      expect(controller.state.nightLightConfirmed, isTrue);

      controller.confirmLightingCheck(LightingCheck.daylight);
      expect(controller.state.daylightConfirmed, isTrue);
      expect(controller.state.lightingConfirmed, isTrue);
      expect(notifications, 3);
    });

    test('confirmLightingCheck can clear a check with confirmed: false', () {
      controller.confirmLightingCheck(LightingCheck.daylight);
      expect(controller.state.daylightConfirmed, isTrue);
      controller.confirmLightingCheck(LightingCheck.daylight, confirmed: false);
      expect(controller.state.daylightConfirmed, isFalse);
      expect(controller.state.lightingConfirmed, isFalse);
    });

    test('tryContinue does not advance while the checks are unconfirmed', () {
      // Two of three confirmed — the gate stays shut.
      controller.confirmLightingCheck(LightingCheck.brightness);
      controller.confirmLightingCheck(LightingCheck.nightLight);
      notifications = 0;

      controller.tryContinue();
      expect(controller.state.stepIndex, 0, reason: 'still on the lighting step');
      expect(controller.state.testingStarted, isFalse,
          reason: 'testing must not begin until all three are confirmed');
      expect(notifications, 0, reason: 'a declined continue notifies nothing');
    });

    test('tryContinue advances and starts testing once all three confirmed', () {
      controller.confirmLightingCheck(LightingCheck.brightness);
      controller.confirmLightingCheck(LightingCheck.nightLight);
      controller.confirmLightingCheck(LightingCheck.daylight);
      notifications = 0;

      controller.tryContinue();
      expect(controller.state.stepIndex, 1, reason: 'advanced past lighting');
      expect(controller.state.testingStarted, isTrue,
          reason: 'testing begins once past the gate');
      expect(notifications, 1);
    });

    test('tryContinue does not advance past the last step', () {
      // A single-step onboarding: confirming and continuing cannot overrun.
      final single = OnboardingController(steps: const [OnboardingStep('Only')]);
      addTearDown(single.dispose);
      single.confirmLightingCheck(LightingCheck.brightness);
      single.confirmLightingCheck(LightingCheck.nightLight);
      single.confirmLightingCheck(LightingCheck.daylight);

      single.tryContinue();
      expect(single.state.stepIndex, 0,
          reason: 'stepIndex is clamped to the last step');
      expect(single.state.testingStarted, isTrue,
          reason: 'testing still begins even at the last step');
    });
  });
}
