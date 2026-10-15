// bs-13 AC-1 augment guard — the seed holds no answer lookup table (GUARD-1 stub).
//
// Test-support only — no `lib/` product code (bs-12 D-7).
//
// AC-1 structural invariant (enforced for real at GUARD-2): the seed carries
// **no** target-colour→recipe answer mapping. A `CandidateMapping` carries a
// paint-id set + origin only — never ratios or answers; recipes come from
// `engine.inverse`. A planted answer table (`control_lookupTable`) must be
// listed.
//
// GUARD-1 lays this as a stub returning the [ruleNotYetEnforced] sentinel so the
// pending AC-1 augmentation fails on its "zero offenders" Then (red baseline).
// GUARD-2 fills the real schema check over [schemaFiles].

import 'source_scan.dart';

/// Reports sites that break the AC-1 no-answer-lookup invariant (empty list =
/// pass).
///
/// [schemaFiles] is the SEED schema definition checked for a forbidden
/// target→recipe answer mapping. An acceptance test overrides it to point at a
/// planted control and assert the rule flags it.
///
/// GUARD-1 stub: returns the [ruleNotYetEnforced] sentinel regardless of input.
List<GuardOffender> noLookupTableGuard({
  Iterable<String> schemaFiles = kSeedSchemaFiles,
}) =>
    notYetEnforced('noLookupTableGuard');
