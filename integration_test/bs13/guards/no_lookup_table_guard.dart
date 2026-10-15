// bs-13 AC-1 augment guard — the seed holds no answer lookup table (GUARD-2).
//
// Test-support only — no `lib/` product code (bs-12 D-7).
//
// AC-1 structural invariant: the seed carries **no** target-colour→recipe answer
// mapping. A `CandidateMapping` carries a paint-id set + origin only — never
// ratios or finished recipes; recipes come from `engine.inverse` over the stored
// optical data. A planted answer table (`control_lookupTable`) must be listed.
//
// Enforced as a **schema check** over [schemaFiles] for a construct that maps a
// target descriptor straight to a recipe/answer (by the names such a table
// carries — `…ToRecipe`, `lookupTable`, `answerTable`, `…ToAnswer`,
// `recipeLookup`, `recipeFor`). The legitimate `CandidateMapping`
// (`targetDescriptor` → `candidatePaintIds`) matches none of these. Empty list =
// pass. GUARD-1 laid this as a stub; GUARD-2 fills the real scan.

import 'source_scan.dart';

/// Matches the name of a stored target→recipe/answer mapping — the forbidden
/// lookup table (AC-1). Case-insensitive so a class name (`ControlLookupTable`)
/// and a field name (`targetToRecipe`) are both caught; the seed's
/// `candidatePaintIds` / `candidateMappings` / `targetDescriptor` match none.
final RegExp _answerLookup = RegExp(
  r'(?:lookupTable|toRecipe|recipeFor|recipeLookup|answerTable|answerFor|answerLookup|toAnswer)',
  caseSensitive: false,
);

/// Reports sites that break the AC-1 no-answer-lookup invariant (empty list =
/// pass).
///
/// [schemaFiles] is the SEED schema definition checked for a forbidden
/// target→recipe answer mapping. An acceptance test overrides it to point at a
/// planted control and assert the rule flags it.
List<GuardOffender> noLookupTableGuard({
  Iterable<String> schemaFiles = kSeedSchemaFiles,
}) =>
    [
      for (final match in scanSchema(
        schemaFiles: schemaFiles,
        fieldPatterns: [_answerLookup],
      ))
        GuardOffender(
          rule: 'seed-answer-lookup-table',
          detail: 'the seed declares a target→recipe answer mapping — recipes '
              'are solved, never looked up: ${match.snippet}',
          path: match.path,
          line: match.line,
        ),
    ];
