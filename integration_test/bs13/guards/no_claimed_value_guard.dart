// bs-13 AC-4 augment guard — no stored claimed spectral/ratio value (GUARD-1 stub).
//
// Test-support only — no `lib/` product code (bs-12 D-7).
//
// AC-4 structural invariant (enforced for real at GUARD-2): no stored
// `SeedPaintEntry` carries a claimed spectral curve / ratio field — at the
// schema level (the definition declares no such field) and over an ingested
// dataset (`control_claimedSpectral`'s claimed fields are absent after ingest).
// A planted stored claimed-value entry must be listed.
//
// GUARD-1 lays this as a stub returning the [ruleNotYetEnforced] sentinel so the
// pending AC-4 augmentation fails on its "zero offenders" Then (red baseline).
// GUARD-2 fills the real check over [schemaFiles] and the ingested [entries].

import 'source_scan.dart';

/// Reports sites that break the AC-4 no-claimed-value invariant (empty list =
/// pass).
///
/// [schemaFiles] is the SEED schema definition checked for a forbidden claimed
/// spectral/ratio field. GUARD-2 also inspects an ingested dataset's entries; the
/// stub ignores both. An acceptance test overrides [schemaFiles] to point at a
/// planted control and assert the rule flags it.
///
/// GUARD-1 stub: returns the [ruleNotYetEnforced] sentinel regardless of input.
List<GuardOffender> noClaimedValueGuard({
  Iterable<String> schemaFiles = kSeedSchemaFiles,
}) =>
    notYetEnforced('noClaimedValueGuard');
