# Module GUARD — reusable integrity guards

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs13/guards/` (reusable test-support — **no product code**): `ratio_provenance_guard.dart`, `no_lookup_table_guard.dart`, `no_claimed_value_guard.dart`, and a small `source_scan.dart`/schema-check helper.
**Depends on:** the bs-04 engine (`lib/recipes/engine/`) and SEED's `SeedDataset` schema (for the schema checks) · **Blocks:** ITEST-1 (consumes the guards)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-3 (+ AC-1/AC-4 structural augments) | ⬜ Todo | | |

## Interface reconciliation

- **Guards are test-support (bs-12 D-7), not product.** They live under `integration_test/` and are consumed by the bs-13 acceptance suite; they never ship in `lib/`. Each returns a list of offenders (empty = pass), so the acceptance tests assert "zero offenders" and the controls assert the planted violation is listed.
- **`ratioProvenanceGuard` (AC-3):** a source scan proving the **only** producer of a recipe ratio (`RecipeComponent.partsFraction`) is `SubtractiveMixingEngine`, plus a schema check that `SeedPaintEntry`/`SeedDataset`/`CandidateMapping` carry **no** ratio field. A planted llm/seed-sourced ratio (`control_llmRatio`) is listed.
- **`noLookupTableGuard` (AC-1 augment):** a schema check that the seed carries **no** target-colour→recipe answer mapping (candidate mappings carry paint-id sets + origin only, never ratios/answers); recipes come from `engine.inverse`. `control_lookupTable` is listed.
- **`noClaimedValueGuard` (AC-4 augment):** a check that **no** stored `SeedPaintEntry` carries a claimed spectral curve / ratio field (reinforces the SEED-4 ingest rule at the schema level). `control_claimedSpectral`'s claimed fields are absent after ingest; a planted stored claimed-value entry is listed.

## Open gates

- **G-1** (spec) blocks the feature; **G-2** (tests) blocks GUARD-2.

## Phase 1 — Shell: reusable guard harness

- **Kind:** shell
- **Target AC:** —
- **Depends on:** SEED-1 · **Blocks:** ITEST-1
- **Files:** `integration_test/bs13/guards/source_scan.dart` (+ empty `ratio_provenance_guard.dart`, `no_lookup_table_guard.dart`, `no_claimed_value_guard.dart` scaffolds)
- **Tasks:**
  1. A small source-scan helper (reads `lib/` files, returns matches) and a schema-check helper over the SEED types.
  2. Each guard present as a **stub returning "not yet enforced"** (so the ITEST baseline tests fail on the Then, as pre-seeded) — no rule logic yet.
- **Exit criteria:** the guards compile and are importable by the acceptance harness; no product code; existing suites green. (Guards live in `integration_test/`, outside the coverage-gate scope — note any justified exclusion.)
- **Acceptance gate:** —
- **Augments:** —

## Phase 2 — AC-3: ratios-from-solver guard (+ AC-1/AC-4 structural augments)

- **Kind:** behavior
- **Target AC:** AC-3 (full); augments AC-1 (no-lookup) and AC-4 (no-claimed-value)
- **Depends on:** GUARD-1, SEED-3 (needs the shipped seed to inspect), ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/bs13/guards/ratio_provenance_guard.dart`, `no_lookup_table_guard.dart`, `no_claimed_value_guard.dart`
- **Tasks:**
  1. `ratioProvenanceGuard`: enforce that `RecipeComponent.partsFraction` is produced only by `SubtractiveMixingEngine` and the seed schema carries no ratio field — zero offenders; `control_llmRatio` listed (AC-3).
  2. `noLookupTableGuard`: enforce the no-answer-mapping invariant; `control_lookupTable` listed (augments `TestAC01`).
  3. `noClaimedValueGuard`: enforce no stored entry carries a claimed spectral/ratio field; a planted one is listed (augments `TestAC04`).
- **Exit criteria:** unit/guard gate; acceptance gate below.
- **Acceptance gate:** un-pend AC-3; `TestAC03_RatiosFromSolverNeverLlm` green with the `control_llmRatio` discrimination; add the pre-seeded augmentations to `TestAC01` (no-lookup + `control_lookupTable`) and `TestAC04` (no stored claimed value) and keep them green (and all earlier ACs).
- **Augments made here:** `TestAC01` (no-lookup structural + control), `TestAC04` (schema no-claimed-value + control).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
