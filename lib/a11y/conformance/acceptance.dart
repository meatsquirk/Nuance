/// The two pure verdicts over a [ConformanceResult] (bs-11).
///
/// Pure domain — no `flutter`/`flutter_test` import — so the gate's decision
/// and recorded level are testable without a widget tree and reusable by any
/// feature (D-3).
///
/// GATE-1 lands the **signatures only**: both functions throw
/// [UnimplementedError] until their behaviour phases implement them —
/// [acceptanceDecision] at GATE-3 (AC-9), [recordedLevel] at GATE-4 (AC-11).
/// Keeping them present-but-stubbed lets the acceptance tests compile against
/// the frozen signatures and fail on their Then at the red baseline.
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
/// Stubbed in GATE-1 — implemented in GATE-3.
AcceptanceDecision acceptanceDecision(ConformanceResult result) =>
    throw UnimplementedError('acceptanceDecision lands in GATE-3 (AC-9)');

/// The WCAG level [result] records (AC-11): `aa22` iff `result.passed`, else
/// `below`. The check's thresholds are the WCAG 2.2 AA constants (D-5); this
/// names the floor they encode.
///
/// Stubbed in GATE-1 — implemented in GATE-4.
WcagLevel recordedLevel(ConformanceResult result) =>
    throw UnimplementedError('recordedLevel lands in GATE-4 (AC-11)');
