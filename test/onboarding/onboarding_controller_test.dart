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

    test('confirmLightingCheck throws (FLOW-3)', () {
      expect(
        () => controller.confirmLightingCheck(LightingCheck.brightness),
        throwsUnimplementedError,
      );
    });

    test('tryContinue throws (FLOW-2/FLOW-3)', () {
      expect(controller.tryContinue, throwsUnimplementedError);
    });

    test('answerIntake throws (ENGINE-3)', () {
      expect(
        () => controller.answerIntake(
          const IntakeAnswer(questionId: 'q', value: 'Often'),
        ),
        throwsUnimplementedError,
      );
    });

    test('reportDiagnosis throws (ENGINE-4)', () {
      expect(
        () => controller.reportDiagnosis(CvdType.deutan),
        throwsUnimplementedError,
      );
    });

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
}
