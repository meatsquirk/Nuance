/// The two pure verdicts over a [ConformanceResult] (bs-11).
///
/// Pure domain — no `flutter`/`flutter_test` import — so the gate's decision
/// and recorded level are testable without a widget tree and reusable by any
/// feature (D-3).
///
/// GATE-1 landed the **signatures only** (both threw [UnimplementedError]).
/// GATE-3 implements [acceptanceDecision] (AC-9); [recordedLevel] (AC-11) stays
/// stubbed until GATE-4 — keeping its frozen signature lets the AC-11 test
/// compile and fail on its Then at the red baseline.
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
/// `below`. The check's thresholds are the WCAG 2.2 AA constants (D-5); this
/// names the floor they encode.
///
/// Stubbed in GATE-1 — implemented in GATE-4.
WcagLevel recordedLevel(ConformanceResult result) =>
    throw UnimplementedError('recordedLevel lands in GATE-4 (AC-11)');
