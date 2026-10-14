# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs13/dataset_harness.dart`, `integration_test/bs13/dataset_test.dart`, `integration_test/bs13/pending.dart` (consumes the SEED/PROV surfaces and the GUARD guards; writes no product code).
**Depends on:** SEED-2, PROV-1, GUARD-1 (all shells wired) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ⬜ Todo | | |
| 2 | acceptance-tests | AC-1,2,3,4,5,6,11 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-7,8,9,10 | ⬜ Todo | | |
| 4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the real `AssetSeedLoader` over the real shipped seed asset, the real bs-04 `SubtractiveMixingEngine`, the real `ColorScience`/`deltaE00`, and the real provenance/evidence model, all assembled through `buildApp(deps)`. Observed through `DatasetReadEndpoint` (seed entries, origins, manifest) and `ProvenanceReadEndpoint` (derived tier + evidence list). The guards (`integration_test/bs13/guards/`) are the mechanism for AC-1/3/4's structural facets. Faked only: the deliberate **control** fixtures.
- **Observation points:** AC-1/2/4/5/6/11 → `DatasetReadEndpoint`; AC-1/3/4 structural → guard offender lists; AC-7/8/9/10 → `ProvenanceReadEndpoint` + the pure `ProvenanceDerivation.tierFor` / append-only add.
- **Pending gate:** `integration_test/bs13/pending.dart` holds the pending-AC set; a test guarded `pending('AC-n')` is skipped by default and run under `--dart-define=BS13_RUN_PENDING=true` (or env `BS13_RUN_PENDING=1`). Un-pending = delete the AC's row from the pending set. A `-d flutter-tester` device is mandatory (host; no iOS sim, no device lane).

## Open gates

- **G-1** (spec) blocks the feature. **G-2** (approve these tests — ITEST-4's packet) blocks every behavior phase (SEED-3..5, PROV-2..3, GUARD-2).

## Phase 1 — Harness, fixtures, pending gate, smoke test

- **Kind:** acceptance-tests
- **Target AC:** — · **Depends on:** SEED-2, PROV-1, GUARD-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/bs13/dataset_harness.dart`, `dataset_test.dart`, `pending.dart`
- **Tasks:**
  1. Harness vocabulary over `buildApp`: load the seed via `AssetSeedLoader`, reach `DatasetReadEndpoint` + `ProvenanceReadEndpoint`, import the guards, build the fixtures (`shippedSeed`, `realEngine`, `heldOutManifest`, the `ev*` evidence points, and the control fixtures).
  2. Pending-gate mechanism + a smoke test (harness assembles; seed loads — empty in the shell is fine; endpoints reachable).
- **Exit criteria:** smoke test green by default; `-d flutter-tester` confirmed to run tests (not zero).

## Phase 2 — AC-1,2,3,4,5,6,11 (pending) + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-11 (all pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · **(run before ITEST-3 — shared runner)**
- **Files:** `integration_test/bs13/dataset_test.dart`, `pending.dart`
- **Tasks:** write one pending test per AC per the master catalogue (grade-A: each Given built + checked, the When, each Then's exact assertion, the control). Record the run-pending red baseline in the table below.
- **Exit criteria:** suite green by default (all seven pending/skipped); each fails cleanly under run-pending at the documented Then/precondition; grade gate passed.

## Phase 3 — AC-7,8,9,10 (pending) + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-7, AC-8, AC-9, AC-10 (all pending) · **Depends on:** ITEST-1 (after ITEST-2 — shared `dataset_test.dart`/`pending.dart`) · **Blocks:** ITEST-4
- **Files:** `integration_test/bs13/dataset_test.dart`, `pending.dart`
- **Tasks:** one pending test per AC per the catalogue; record the red baseline.
- **Exit criteria:** suite green by default (pending skipped); each fails cleanly under run-pending; grade gate passed.

## Phase 4 — Test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet — the catalogue, each test's red baseline + grade, the fixtures and controls, the pre-seeded augmentations, and the named D-5/G-3 gap. Set the G-2 gate; a human approves before any behavior phase.
- **Exit criteria:** packet assembled; G-2 recorded by a human (approved → ITEST-4 done; changes → change phases + a fresh review).

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_RecipesSolvedFromOpticalData | FAIL (empty seed) | Given: seed has entries / Then: solved from optical data | SEED-3 (+GUARD-2) | A / B pending GUARD-2 |
| AC-2 | TestAC02_CandidatesFromLlm | FAIL | Then: candidate origin = llmSeed | SEED-4 | A |
| AC-3 | TestAC03_RatiosFromSolverNeverLlm | FAIL (guard stub) | Then: zero offenders + control listed | GUARD-2 | A |
| AC-4 | TestAC04_MetadataAcceptedClaimedValuesRejected | FAIL | Then: metadata kept, claimed stripped | SEED-4 (+GUARD-2) | A / B pending GUARD-2 |
| AC-5 | TestAC05_HeldOutValidationRecorded | FAIL | Then: count 50–100 + distribution present | SEED-5 | A |
| AC-6 | TestAC06_SeedShipsOnlyOnEvidence | FAIL | Then: shippable iff threshold ∧ beats-LLM; controls not shippable | SEED-5 | A |
| AC-7 | TestAC07_EnforcedProvenanceTierByOrigin | FAIL (derivation stub) | Then: each origin → its tier | PROV-2 | A |
| AC-8 | TestAC08_EvidenceAppendOnly | FAIL | Then: appended + earlier retained | PROV-2 | A |
| AC-9 | TestAC09_PromotedOnlyByMeasuredSwatch | FAIL | Then: Estimated→Confirmed on swatch | PROV-3 | A / B pending PROV-3 |
| AC-10 | TestAC10_OpinionsNeverPromote | FAIL | Then: opinion → stays Estimated | PROV-3 | A |
| AC-11 | TestAC11_ShippedSeedStaysNarrow | FAIL (empty seed) | Then: one brand/medium/~15 paints | SEED-3 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC01 | the no-lookup-table structural guard doesn't exist until GUARD-2 | GUARD-2 | the no-lookup assertion + `control_lookupTable` is listed | ⬜ Open |
| TestAC04 | the schema no-claimed-value guard doesn't exist until GUARD-2 | GUARD-2 | assert no stored entry carries a claimed spectral/ratio field + planted-entry control | ⬜ Open |
| TestAC09 | promotion can't be exercised until the PROV-3 rule exists | PROV-3 | the Estimated→Confirmed transition on a swatch evidence point | ⬜ Open |
