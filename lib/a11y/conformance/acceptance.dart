/// The two pure verdicts over a [ConformanceResult] (bs-11).
///
/// Pure domain — no `flutter`/`flutter_test` import — so the gate's decision
/// and recorded level are testable without a widget tree and reusable by any
/// feature (D-3).
///
/// GATE-1 landed the **signatures only** (both threw [UnimplementedError]).
/// GATE-3 implemented [acceptanceDecision] (AC-9). GATE-4 implements
/// [recordedLevel] (AC-11) and pins the WCAG 2.2 AA threshold constants
/// ([WcagThresholds], D-5) — the numeric floor the `aa22` level encodes and that
/// the per-rule check rules must evaluate against.
library;

import 'conformance_result.dart';

/// Whether an automated conformance run accepts the build (AC-9).
enum AcceptanceDecision {
  /// Every automated rule passed — the build is accepted.
  accepted,

  /// At least one rule failed (or did not run) — the build is not accepted.
  notAccepted,
}

/// The WCAG level an accepted run records (AC-11).
enum WcagLevel {
  /// Below the AA 2.2 floor — the run did not meet conformance.
  below,

  /// WCAG 2.2 level AA — the floor this feature targets (D-5).
  aa22,
}

/// The WCAG 2.2 level AA numeric thresholds the conformance check evaluates
/// against — the floor the [WcagLevel.aa22] level records (AC-11, D-5).
///
/// Pure data, pinned here in the domain so the recorded floor and the values the
/// per-rule check rules enforce are **one** source of truth: the check rules
/// (which run under `flutter_test`) must evaluate against exactly these numbers,
/// and the AC-11 test asserts that correspondence — `checks/scaling.dart`
/// references [minSupportedTextScale] directly, while the contrast and
/// tap-target rules delegate to Flutter's own guidelines, whose thresholds the
/// test pins equal to [minTextContrastRatioNormalText] /
/// [minTextContrastRatioLargeText] / [minTapTargetDip]. A drift between the
/// WCAG 2.2 AA floor and what the rules enforce then fails the gate rather than
/// silently lowering the bar.
abstract final class WcagThresholds {
  /// Minimum contrast ratio for normal-size text against its background
  /// (WCAG 2.2 SC 1.4.3, level AA): 4.5:1.
  static const double minTextContrastRatioNormalText = 4.5;

  /// Minimum contrast ratio for large-scale text (WCAG 2.2 SC 1.4.3, level AA):
  /// 3:1.
  static const double minTextContrastRatioLargeText = 3.0;

  /// Minimum interactive target size, in logical pixels (WCAG 2.2 SC 2.5.8
  /// Target Size (Minimum) is 24dp, but this feature pins the stricter 48dp
  /// platform floor, D-5): 48.0.
  static const double minTapTargetDip = 48.0;

  /// The system text scale a screen must survive without loss of content or
  /// function (WCAG 2.2 SC 1.4.4 Resize Text, level AA — 200%): 2.0.
  static const double minSupportedTextScale = 2.0;
}

/// The acceptance verdict for [result] (AC-9): `accepted` iff
/// `result.passed`, else `notAccepted`.
///
/// A build is accepted only when the automated check passed — every
/// [ConformanceRuleId] ran and held ([ConformanceResult.passed]). Any failing
/// rule, or a result that did not run every rule (a partial or empty result),
/// is `notAccepted`: the gate never accepts a feature that failed the check
/// (AC-9). The whole verdict rides on [ConformanceResult.passed], so it inspects
/// the complete result, never a single rule.
AcceptanceDecision acceptanceDecision(ConformanceResult result) =>
    result.passed ? AcceptanceDecision.accepted : AcceptanceDecision.notAccepted;

/// The WCAG level [result] records (AC-11): `aa22` iff `result.passed`, else
/// `below`.
///
/// A run records the WCAG 2.2 AA floor only when the automated check passed —
/// every [ConformanceRuleId] ran and held ([ConformanceResult.passed]). Any
/// failing rule, or a partial or empty result, records [WcagLevel.below]: the
/// feature never claims AA for a build that did not clear every rule. The check
/// rules those rules run are evaluated against the [WcagThresholds] constants,
/// so `aa22` is exactly the WCAG 2.2 AA floor those thresholds encode (D-5).
/// Like [acceptanceDecision], the verdict rides on [ConformanceResult.passed],
/// never a single rule.
WcagLevel recordedLevel(ConformanceResult result) =>
    result.passed ? WcagLevel.aa22 : WcagLevel.below;
