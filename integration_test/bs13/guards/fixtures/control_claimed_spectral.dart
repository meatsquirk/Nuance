// Planted control fixture for the bs-13 AC-4 no-claimed-value guard.
//
// Test-support only — NOT shipped in `lib/` (bs-12 D-7). This file deliberately
// declares a seed entry that carries **both** accepted metadata (`pigmentIndex`)
// **and** an LLM-claimed measured value (`spectralCurve`), which the AC-4
// invariant forbids being *stored*: metadata is kept, but a claimed spectral
// curve / ratio must be stripped. `noClaimedValueGuard`, pointed at this file
// via its `schemaFiles` override (GUARD-2), must list the claimed field — the
// discriminating control proving the guard catches a real offender.
//
// It is never under the guards' default `kLibRoots` (`lib/`) sweep, so it does
// not affect the shipped-code pass. The *ingest* facet of AC-4 (a raw record
// whose claimed fields are stripped by the loader) is exercised by ITEST-2 once
// the SEED-4 ingest rule exists.
// ignore_for_file: unreachable_from_main

/// A seed entry that illegally stores an LLM-claimed spectral curve alongside
/// its valid metadata.
class ControlClaimedSpectralEntry {
  const ControlClaimedSpectralEntry({
    required this.pigmentIndex,
    required this.spectralCurve,
  });

  /// Valid metadata — accepted and retained (AC-4).
  final String pigmentIndex;

  /// An LLM-claimed measured spectral reflectance curve — forbidden to store
  /// (AC-4): it must be stripped, never kept as if measured.
  final List<double> spectralCurve;
}
