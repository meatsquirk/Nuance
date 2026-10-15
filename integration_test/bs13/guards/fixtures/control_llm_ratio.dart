// Planted control fixture for the bs-13 AC-3 ratio-provenance guard.
//
// Test-support only — NOT shipped in `lib/` (bs-12 D-7). This file deliberately
// declares a **recipe ratio stored on a seed record** (`partsFraction`), which
// the AC-3 invariant forbids: a mix ratio may originate only from
// `SubtractiveMixingEngine`, never from the seed/LLM. `ratioProvenanceGuard`,
// pointed at this file via its `roots` / `schemaFiles` override (GUARD-2), must
// therefore list it — the discriminating control that proves the guard catches
// a real offender rather than passing vacuously.
//
// It is never under the guards' default `kLibRoots` (`lib/`) sweep, so it does
// not affect the shipped-code pass.
// ignore_for_file: unreachable_from_main

/// A seed entry that illegally carries its own mix ratio (the forbidden field).
class ControlLlmRatioEntry {
  const ControlLlmRatioEntry({required this.partsFraction});

  /// A ratio stored on a seed record — forbidden (AC-3): ratios come only from
  /// the solver.
  final double partsFraction;
}
