import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/onboarding/engine/cvd_estimate.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';
import 'package:paint_color_assistant/onboarding/onboarding_state.dart';

void main() {
  group('OnboardingState defaults', () {
    const state = OnboardingState();

    test('starts empty at step 0 with nothing confirmed or scored', () {
      expect(state.stepIndex, 0);
      expect(state.brightnessConfirmed, isFalse);
      expect(state.nightLightConfirmed, isFalse);
      expect(state.daylightConfirmed, isFalse);
      expect(state.testingStarted, isFalse);
      expect(state.prior, StartingPrior.none);
      expect(state.screening, isNull);
      expect(state.arrangementPool, isEmpty);
      expect(state.arrangedCaps, isEmpty);
      expect(state.arrangementSkipped, isFalse);
      expect(state.threshold, isNull);
      expect(state.estimate, isNull);
      expect(state.calibratedSeverity, isNull);
      expect(state.caveatShown, isFalse);
      expect(state.saved, isFalse);
    });

    test('lightingConfirmed is true only when all three checks are confirmed',
        () {
      expect(state.lightingConfirmed, isFalse);
      expect(
        const OnboardingState(
          brightnessConfirmed: true,
          nightLightConfirmed: true,
          daylightConfirmed: true,
        ).lightingConfirmed,
        isTrue,
      );
      expect(
        const OnboardingState(
          brightnessConfirmed: true,
          nightLightConfirmed: true,
        ).lightingConfirmed,
        isFalse,
      );
    });
  });

  group('OnboardingState equality', () {
    test('equal when every field matches', () {
      expect(const OnboardingState(), const OnboardingState());
      expect(
        const OnboardingState().hashCode,
        const OnboardingState().hashCode,
      );
    });

    test('differs on a scalar field', () {
      expect(
        const OnboardingState(stepIndex: 1),
        isNot(const OnboardingState()),
      );
      expect(const OnboardingState(), isNot(42));
    });

    test('differs on every scalar field', () {
      const base = OnboardingState();
      expect(base, isNot(const OnboardingState(brightnessConfirmed: true)));
      expect(base, isNot(const OnboardingState(nightLightConfirmed: true)));
      expect(base, isNot(const OnboardingState(daylightConfirmed: true)));
      expect(base, isNot(const OnboardingState(testingStarted: true)));
      expect(
        base,
        isNot(const OnboardingState(
            prior: StartingPrior(type: CvdType.deutan))),
      );
      expect(
        base,
        isNot(const OnboardingState(
          screening:
              ScreeningResult(present: true, direction: ScreeningDirection.redGreen),
        )),
      );
      expect(base, isNot(const OnboardingState(arrangementSkipped: true)));
      expect(
        base,
        isNot(const OnboardingState(threshold: ThresholdResult(severity: 0.5))),
      );
      expect(
        base,
        isNot(const OnboardingState(
          estimate: CvdEstimate(
            type: CvdType.deutan,
            severity: 0.5,
            prior: StartingPrior.none,
          ),
        )),
      );
      expect(base, isNot(const OnboardingState(calibratedSeverity: 0.5)));
      expect(base, isNot(const OnboardingState(caveatShown: true)));
      expect(base, isNot(const OnboardingState(saved: true)));
    });

    test('compares the arrangement lists element-wise', () {
      // Different length.
      expect(
        const OnboardingState(arrangementPool: [1]),
        isNot(const OnboardingState(arrangementPool: [1, 2])),
      );
      // Same length, different element.
      expect(
        const OnboardingState(arrangementPool: [1, 2]),
        isNot(const OnboardingState(arrangementPool: [1, 3])),
      );
      // Same contents.
      expect(
        const OnboardingState(arrangementPool: [1, 2]),
        const OnboardingState(arrangementPool: [1, 2]),
      );
      // The arranged list, too.
      expect(
        const OnboardingState(arrangedCaps: [1]),
        isNot(const OnboardingState(arrangedCaps: [2])),
      );
    });
  });

  test('toString names the step and the field summary', () {
    expect(const OnboardingState().toString(), contains('step: 0'));
    expect(const OnboardingState().toString(), contains('saved: false'));
  });
}
