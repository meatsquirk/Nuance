// bs-13 AC-3 guard — recipe ratios come only from the solver (GUARD-2).
//
// Test-support only — no `lib/` product code (bs-12 D-7).
//
// AC-3 invariant: the **only** producer of a recipe ratio
// (`RecipeComponent.partsFraction`) is the physics solver, and the SEED schema
// (`SeedPaintEntry` / `SeedDataset` / `CandidateMapping`) carries **no** ratio
// field — so no shipped ratio can be an LLM/seed hallucination. A planted
// llm/seed-sourced ratio (`control_llmRatio`) must be listed.
//
// Two facets (their offenders are concatenated):
//   1. a **source scan** over [roots] for a `partsFraction:` named-argument — the
//      construction of a recipe ratio — outside the authorities permitted to
//      originate or rehydrate one; and
//   2. a **schema check** over [schemaFiles] for a declared ratio field.
//
// Empty list = pass. GUARD-1 laid this as a stub; GUARD-2 fills the real scans.

import 'source_scan.dart';

/// The `lib/` files permitted to set a `RecipeComponent.partsFraction`.
///
/// The physics solver (`SubtractiveMixingEngine`) **originates** every ratio;
/// the project persistence layer (`ProjectSource`) **rehydrates** a recipe that
/// the solver produced earlier and a painter saved — so it reloads a
/// solver-produced ratio, never an LLM/seed one. Both are therefore authorities
/// for the construct; any other site constructing a ratio is an offender (AC-3).
const List<String> kRatioProducerAuthorities = <String>[
  'lib/recipes/engine/subtractive_engine.dart',
  'lib/projects/project_source.dart',
];

/// Matches a `partsFraction:` **named argument** — i.e. a site that *produces* a
/// `RecipeComponent` ratio. A field declaration (`final double partsFraction;`)
/// or constructor binding (`this.partsFraction`) has no `:` after the name, and
/// a map key (`'partsFraction':`) is a string literal the scanner masks, so this
/// matches only a real ratio production.
final RegExp _ratioProduction = RegExp(r'\bpartsFraction\s*:');

/// Matches a declared ratio field/parameter name in a schema type — the thing
/// the seed must never carry (AC-3).
final RegExp _ratioField = RegExp(r'\b(?:partsFraction|ratio|ratios|parts)\b');

/// Reports sites that break the AC-3 ratios-from-solver invariant (empty list =
/// pass).
///
/// [roots] is the source sweep (defaults to the shipped `lib/`); [schemaFiles]
/// is the SEED schema definition checked for a forbidden ratio field. An
/// acceptance test overrides them to point at a planted control and assert the
/// rule flags it.
List<GuardOffender> ratioProvenanceGuard({
  Iterable<String> roots = kLibRoots,
  Iterable<String> schemaFiles = kSeedSchemaFiles,
}) {
  final offenders = <GuardOffender>[];

  // Facet 1 — a recipe ratio is produced only by an authorised site.
  for (final match in scanDartSources(
    roots: roots,
    patterns: [_ratioProduction],
    isAllowed: (path) => kRatioProducerAuthorities.any(path.endsWith),
  )) {
    offenders.add(GuardOffender(
      rule: 'ratio-from-non-solver',
      detail: 'a recipe ratio (partsFraction) is produced outside the solver / '
          'project-reload authorities: ${match.snippet}',
      path: match.path,
      line: match.line,
    ));
  }

  // Facet 2 — the seed schema declares no ratio field.
  for (final match in scanSchema(
    schemaFiles: schemaFiles,
    fieldPatterns: [_ratioField],
  )) {
    offenders.add(GuardOffender(
      rule: 'seed-carries-ratio-field',
      detail: 'the seed schema declares a ratio field — ratios come from the '
          'solver, never stored: ${match.snippet}',
      path: match.path,
      line: match.line,
    ));
  }

  return offenders;
}
