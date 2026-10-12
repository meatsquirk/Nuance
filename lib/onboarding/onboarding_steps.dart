/// The top-level steps the onboarding progress indicator counts (bs-07, AC-14).
///
/// The progress model is deliberately a plain ordered [List] of
/// [OnboardingStep] with a current index held on `OnboardingState.stepIndex`:
/// the **count** of these top-level steps is what AC-14 asserts ("the second of
/// four steps"). The tiered battery has more *screens* than counted steps — the
/// Tier 2 screening, the Tier 3 arrangement and the Tier 4 threshold probing all
/// sit inside a single "Vision tests" step (D-4) — so the keyed step widgets
/// under `screens/` and this progress list are different granularities.
///
/// FLOW-1 (shell) builds the list generically and renders the count; the
/// concrete four and which tiers they group are **fixed at FLOW-2 once G-5
/// resolves** — [defaultOnboardingSteps] below is the proposed grouping (D-4)
/// and is provisional until then.
library;

/// One top-level step shown in the onboarding progress indicator (AC-14).
///
/// Carries only the [title] the indicator reads back; the per-tier scoring lives
/// on the `AssessmentEngine` and the keyed step widgets, not here.
class OnboardingStep {
  /// Creates a step labelled [title].
  const OnboardingStep(this.title);

  /// The plain-language name of the step (shown as text, never position alone).
  final String title;

  @override
  bool operator ==(Object other) =>
      other is OnboardingStep && other.title == title;

  @override
  int get hashCode => title.hashCode;

  @override
  String toString() => 'OnboardingStep($title)';
}

/// The provisional four top-level steps (D-4, the G-5 proposal).
///
/// Setup (Tier 0 lighting), Intake (Tier 1), Vision tests (Tiers 2–4:
/// screening, arrangement, threshold) and Result. **Provisional:** FLOW-2 pins
/// the concrete four — and which tiers each groups — once **G-5** resolves; this
/// list exists so the FLOW-1 shell can render a real step count against the
/// progress indicator.
const List<OnboardingStep> defaultOnboardingSteps = [
  OnboardingStep('Setup'),
  OnboardingStep('Intake'),
  OnboardingStep('Vision tests'),
  OnboardingStep('Result'),
];
