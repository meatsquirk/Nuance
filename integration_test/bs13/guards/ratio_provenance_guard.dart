// bs-13 AC-3 guard — recipe ratios come only from the solver (GUARD-1 stub).
//
// Test-support only — no `lib/` product code (bs-12 D-7).
//
// AC-3 invariant (enforced for real at GUARD-2): the **only** producer of a
// recipe ratio (`RecipeComponent.partsFraction`) is `SubtractiveMixingEngine`,
// and the SEED schema (`SeedPaintEntry` / `SeedDataset` / `CandidateMapping`)
// carries **no** ratio field. A planted llm/seed-sourced ratio
// (`control_llmRatio`) must be listed.
//
// GUARD-1 lays this as a stub returning the [ruleNotYetEnforced] sentinel, so
// the pending AC-3 acceptance test fails on its "zero offenders" Then (the red
// baseline). GUARD-2 fills the real scan over [roots] (the `partsFraction`
// producer check) and [schemaFiles] (the no-ratio-field schema check).

import 'source_scan.dart';

/// Reports sites that break the AC-3 ratios-from-solver invariant (empty list =
/// pass).
///
/// [roots] is the source sweep (defaults to the shipped `lib/`); [schemaFiles]
/// is the SEED schema definition checked for a forbidden ratio field. An
/// acceptance test overrides them to point at a planted control and assert the
/// rule flags it.
///
/// GUARD-1 stub: returns the [ruleNotYetEnforced] sentinel regardless of input.
List<GuardOffender> ratioProvenanceGuard({
  Iterable<String> roots = kLibRoots,
  Iterable<String> schemaFiles = kSeedSchemaFiles,
}) =>
    notYetEnforced('ratioProvenanceGuard');
