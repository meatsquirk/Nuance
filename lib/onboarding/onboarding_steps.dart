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
/// FLOW-1 (shell) built the list generically and rendered the count; FLOW-2
/// pinned the concrete four and which tiers they group, once **G-5 resolved**
/// (2026-10-13, D-4 confirmed) — [defaultOnboardingSteps] below is that fixed
/// grouping.
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

/// The four top-level steps the progress indicator counts (D-4, G-5 ✅).
///
/// Lighting (Tier 0 lighting setup), Intake (Tier 1), Vision tests (Tiers 2–4:
/// screening, arrangement, threshold — all nested inside this one step; they do
/// not advance the step counter) and Result. Pinned at FLOW-2 after **G-5**
/// resolved (2026-10-13, D-4 confirmed): the count of these four is what AC-14
/// shows the current step against ("… of four").
const List<OnboardingStep> defaultOnboardingSteps = [
  OnboardingStep('Lighting'),
  OnboardingStep('Intake'),
  OnboardingStep('Vision tests'),
  OnboardingStep('Result'),
];
