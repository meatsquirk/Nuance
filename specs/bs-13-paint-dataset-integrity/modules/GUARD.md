# Module GUARD — reusable integrity guards

**Status:** 🔄 In progress — GUARD-1 ✅ (shell harness landed, behaviour-neutral); GUARD-2 (AC-3 + AC-1/AC-4 augments) is the remaining behavior phase (gated on G-2 + SEED-3)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs13/guards/` (reusable test-support — **no product code**): `ratio_provenance_guard.dart`, `no_lookup_table_guard.dart`, `no_claimed_value_guard.dart`, and a small `source_scan.dart`/schema-check helper.
**Depends on:** the bs-04 engine (`lib/recipes/engine/`) and SEED's `SeedDataset` schema (for the schema checks) · **Blocks:** ITEST-1 (consumes the guards)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 6,687,969 | 2h 01m |
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

### Result — GUARD-1  <!-- 2026-10-14 -->

Shell: the reusable guard harness is laid under `integration_test/bs13/guards/` (test-support, **no `lib/` product code** — D-4). New files:
- `source_scan.dart` — the shared machinery: `SourceMatch` (path/line/snippet); `scanDartSources({roots, patterns, isAllowed})` walks `.dart` files under dir-or-file roots, masks comments/strings via the ported `maskCommentsAndStrings`, returns one match per matching line; `scanSchema({schemaFiles, fieldPatterns})` points the same scanner at the SEED definition file; `GuardOffender` (the guard result type, empty list = pass); `ruleNotYetEnforced` + `notYetEnforced(name)` sentinel; `kLibRoots` / `kSeedSchemaFiles` constants.
- `ratio_provenance_guard.dart` / `no_lookup_table_guard.dart` / `no_claimed_value_guard.dart` — each a **stub returning the `ruleNotYetEnforced` sentinel** (one offender), so a pending AC test's "zero offenders" Then fails as the red baseline (ITEST-2/3); no rule logic yet (lands at GUARD-2). Signatures carry the overridable `roots`/`schemaFiles` the real scans and controls will use.

**Verification:** `flutter analyze` → **No issues found**; full unit suite **1332/0** (+ `test/bs13/guards_shell_test.dart`, 11 cases: each stub returns the sentinel; `maskCommentsAndStrings` blanks a token in a comment/string; `scanDartSources` locates `class SubtractiveMixingEngine` with real path/line, honours `isAllowed`, skips a missing root; `scanSchema` finds `CandidateMapping` and yields nothing for a ratio/spectral field the schema lacks); coverage gate **100% on all touched files** (`COVERAGE_GATE_BASE=7015390`) — GUARD-1 touched **no** `lib/` file, so no new coverage obligation (guards live in `integration_test/`, outside the gate scope — justified exclusion). **Full cross-feature regression (last shell): 222/0 on the iPhone 17 sim** under `coord.sh with-lock` (whole `integration_test/` dir), == the SEED-2/PROV-1 baseline — GUARD-1 adds no `lib/` change and no edit to any existing test, so behaviour is unchanged. Fix passes: 0/3 (clean first run). Tokens 6,687,969 · Time 2h 01m.

### Checkpoint / Handoff — GUARD-1

- **Frozen for ITEST-1 (consumer) and GUARD-2 (filler):**
  - `source_scan.dart` API: `scanDartSources({Iterable<String> roots = kLibRoots, required List<RegExp> patterns, bool Function(String)? isAllowed}) → List<SourceMatch>`; `scanSchema({Iterable<String> schemaFiles = kSeedSchemaFiles, required List<RegExp> fieldPatterns}) → List<SourceMatch>`; `maskCommentsAndStrings(String)`; `SourceMatch{path,line,snippet}`.
  - Guard API (what ITEST binds to): `ratioProvenanceGuard({roots, schemaFiles})`, `noLookupTableGuard({schemaFiles})`, `noClaimedValueGuard({schemaFiles})` each → `List<GuardOffender>` (empty = pass). A GUARD-1 stub returns one offender tagged `ruleNotYetEnforced`.
  - `kLibRoots = ['lib']`, `kSeedSchemaFiles = ['lib/dataset/seed_dataset.dart']`.
- **GUARD-2 fills** the three stub bodies: `ratioProvenanceGuard` = `partsFraction` producer scan (only `SubtractiveMixingEngine`, line 386 of `lib/recipes/engine/subtractive_engine.dart`) + no-ratio-field schema check; `noLookupTableGuard` = no target→recipe answer-mapping schema check; `noClaimedValueGuard` = no claimed spectral/ratio field (schema + ingested entries). Each then returns empty over `lib/` and lists the planted control fixture. GUARD-2 depends on SEED-3 (needs the shipped seed) and ITEST-4/G-2.
- **Scans run host-side** (`dart:io`, cwd = repo root). bs-13's own suite is pure-Dart (`flutter-tester`); the guard smoke test is in `test/` and runs with the unit suite.
- **Known gaps:** none introduced; behaviour unchanged. The stubs deliberately report "not yet enforced" so the ITEST red baseline is red until GUARD-2.

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
