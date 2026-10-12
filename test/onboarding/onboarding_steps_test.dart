import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/onboarding_steps.dart';

void main() {
  group('OnboardingStep', () {
    test('carries its title', () {
      expect(const OnboardingStep('Setup').title, 'Setup');
    });

    test('value equality by title', () {
      expect(const OnboardingStep('Setup'), const OnboardingStep('Setup'));
      expect(
        const OnboardingStep('Setup'),
        isNot(const OnboardingStep('Intake')),
      );
      expect(const OnboardingStep('Setup'), isNot(42));
    });

    test('hashCode follows the title', () {
      expect(
        const OnboardingStep('Setup').hashCode,
        const OnboardingStep('Setup').hashCode,
      );
    });

    test('toString names the step', () {
      expect(const OnboardingStep('Result').toString(), 'OnboardingStep(Result)');
    });
  });

  group('defaultOnboardingSteps (provisional, G-5)', () {
    test('is the four proposed top-level steps', () {
      expect(
        defaultOnboardingSteps.map((s) => s.title).toList(),
        ['Setup', 'Intake', 'Vision tests', 'Result'],
      );
    });
  });
}
