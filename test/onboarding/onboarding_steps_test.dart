import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/onboarding_steps.dart';

void main() {
  group('OnboardingStep', () {
    test('carries its title', () {
      expect(const OnboardingStep('Lighting').title, 'Lighting');
    });

    test('value equality by title', () {
      expect(const OnboardingStep('Lighting'), const OnboardingStep('Lighting'));
      expect(
        const OnboardingStep('Lighting'),
        isNot(const OnboardingStep('Intake')),
      );
      expect(const OnboardingStep('Lighting'), isNot(42));
    });

    test('hashCode follows the title', () {
      expect(
        const OnboardingStep('Lighting').hashCode,
        const OnboardingStep('Lighting').hashCode,
      );
    });

    test('toString names the step', () {
      expect(const OnboardingStep('Result').toString(), 'OnboardingStep(Result)');
    });
  });

  group('defaultOnboardingSteps (pinned at FLOW-2, G-5 ✅)', () {
    test('is the four confirmed top-level steps', () {
      // G-5 (2026-10-13, D-4 confirmed): Lighting (T0), Intake (T1), Vision
      // tests (Tiers 2–4 nested), Result.
      expect(
        defaultOnboardingSteps.map((s) => s.title).toList(),
        ['Lighting', 'Intake', 'Vision tests', 'Result'],
      );
    });

    test('has four steps — the total AC-14 counts the current step against', () {
      expect(defaultOnboardingSteps, hasLength(4));
    });
  });
}
