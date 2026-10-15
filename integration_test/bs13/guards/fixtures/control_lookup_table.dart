// Planted control fixture for the bs-13 AC-1 no-lookup-table guard.
//
// Test-support only — NOT shipped in `lib/` (bs-12 D-7). This file deliberately
// declares a **target-colour → recipe answer mapping**, which the AC-1
// invariant forbids: the seed stores optical data the solver mixes over, never
// a stored answer a recipe could be retrieved from. `noLookupTableGuard`,
// pointed at this file via its `schemaFiles` override (GUARD-2), must therefore
// list it — the discriminating control that proves the guard catches a real
// offender rather than passing vacuously.
//
// It is never under the guards' default `kLibRoots` (`lib/`) sweep, so it does
// not affect the shipped-code pass.
// ignore_for_file: unreachable_from_main

/// A seed that illegally stores answers: a target descriptor mapped straight to
/// a finished recipe (the forbidden lookup table).
class ControlLookupTable {
  const ControlLookupTable();

  /// A target-colour → recipe answer map — forbidden (AC-1): no stored answers.
  static const Map<String, List<String>> targetToRecipe = {
    'warm grey': ['titanium-white:0.7', 'mars-black:0.3'],
  };
}
