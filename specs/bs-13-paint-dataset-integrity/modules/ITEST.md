# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-2 ✅ (AC-1,2,3,4,5,6,11 pending + red baseline, grade 5 A / 2 A-core·B-pending-GUARD-2); next ITEST-3 (AC-7,8,9,10)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs13/dataset_harness.dart`, `integration_test/bs13/dataset_test.dart`, `integration_test/bs13/pending.dart` (consumes the SEED/PROV surfaces and the GUARD guards; writes no product code).
**Depends on:** SEED-2, PROV-1, GUARD-1 (all shells wired) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ✅ Done | 8,665,269 | 16m 33s |
| 2 | acceptance-tests | AC-1,2,3,4,5,6,11 | ✅ Done | 6,237,768 | 14m 50s |
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

### Result (ITEST-1) ✅

Landed the bs-13 acceptance scaffold — **test-support only, no `lib/` product code** (6 new files under `integration_test/bs13/`):

- **`dataset_harness.dart`** — the Given/When/Then vocabulary + fixtures over the real wired model. `givenTheDatasetApp(tester, {seed})` boots the real app through `buildApp` (real `ColorScienceImpl`, faked `FakeSpeech`/`FakeHaptics`) and returns a `DatasetAppHarness` observing the seed through the wired `DatasetReadEndpoint`; `loadShippedSeed()` loads via the real `AssetSeedLoader`; `sampleWithEvidence`/`provenanceOf`/`solveRecipes` reach the provenance model and the real `SubtractiveMixingEngine`. Fixtures: `realEngine`, `AC1_TARGET`/`AC1_OPTIONS`, `heldOutManifest` (count 72, deterministic non-empty ΔE00 distribution, hybrid 2.4 < llm 5.1 & < threshold 3.0), `control_manifestFailThreshold` / `control_manifestFailBeatsLlm`, the five `ev*` evidence points (one per `EvidenceKind`), `control_opinionOnly`, and the three guard-control source-file path consts. Re-exports the pending gate, guards and domain/dataset types so an AC test imports only this file. ΔE00 is the shipped `deltaE00` (no second copy).
- **`pending.dart`** — the pending gate, **all 11 ACs seeded** → owning phase (AC-1/11→SEED-3, AC-2/4→SEED-4, AC-5/6→SEED-5, AC-7/8→PROV-2, AC-9/10→PROV-3, AC-3→GUARD-2), `behaviorPhases`/`allACs` cross-checks, `pendingSkipReason` (+ `forceRunPending` override), and both `acTestWidgets` (widget-observed ACs) and `acTest` (pure-Dart ACs) registrars. Keyed `BS13_RUN_PENDING` (dart-define + host env).
- **`dataset_test.dart`** — the runner: a never-pending **smoke test** (the assembled app surfaces an injected non-empty seed through the endpoint; loader resolves; provenance seam + guards reachable — all facts a behaviour phase will change asserted by type/shape so the scaffold is stable), plus non-vacuous gate/fixture/control guard tests (pending map == exactly the 11 ACs each owned by a real phase; fakes actually record; each manifest/evidence control encodes its intended condition; the planted guard-control files exist, size-asserted).
- **`guards/fixtures/control_{llm_ratio,lookup_table,claimed_spectral}.dart`** — three planted source files each carrying the forbidden construct GUARD-2's real scan targets (a seed-record `partsFraction`; a `targetToRecipe` answer map; a `spectralCurve` beside valid metadata); test-support, outside `kLibRoots`.

**Verification:** `flutter analyze integration_test/bs13` clean; **`flutter test integration_test/bs13/dataset_test.dart -d flutter-tester` = 8/8 green by default** and **8/8 green under `--dart-define=BS13_RUN_PENDING=true`** (run confirmed, not zero tests); unit suite **1332/0** unchanged (no `lib/` touched). **Coverage gate:** no in-scope source files (all six files are test-support) — satisfied, same as GUARD-1. **Grade gate:** fresh independent grader over the scaffold → **A on every row** (9 rows: smoke, both pending-gate tests, fakes-record, four fixture/control guards, harness/gate modules); no behaviour-phase facts pinned; one hardening nit (size-assert the planted-file loop) applied. **Fix passes:** 0/3 (green on the first full run; the grader nit was a strengthening, not a gate failure). No AC tests yet (ITEST-2/3) → no red baseline this phase.

### Checkpoint / Handoff (ITEST-1 → ITEST-2)

- **Frozen for the AC tests:** import only `integration_test/bs13/dataset_harness.dart` (it re-exports the pending gate, guards, ΔE00 and the domain/dataset types). Register AC tests with `acTestWidgets('AC-n', …)` for the widget-observed ACs (AC-1/2/4/5/6/11 — observe via `givenTheDatasetApp(tester).dataset` / `.manifest`) and `acTest('AC-n', …)` for the pure-Dart ACs (AC-3 guard scan; AC-7/8/9/10 via `provenanceOf`/`derivation`/`sampleWithEvidence`). Un-pend = delete the AC's row from `pendingACs`.
- **Verification commands:** default `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester`; red baseline / run-pending add `--dart-define=BS13_RUN_PENDING=true`. **`-d flutter-tester` is mandatory** (no `-d` ⇒ zero tests, false green). flutter is at `~/development/flutter/bin` (prepend to PATH on non-interactive shells). Guards read the repo tree via `dart:io`, so the cwd must be the repo/worktree root (it is, under `flutter-tester`).
- **Red-baseline expectation (ITEST-2/3):** each pending AC must fail cleanly under run-pending on a Then (or a Given precondition naming its owning phase) — the shell state makes this natural: the shipped seed is empty (AssetSeedLoader shell), the guards return the `ruleNotYetEnforced` sentinel (not zero offenders), `ValidationManifest.shippable` is the `false` placeholder, and `ProvenanceDerivation.tierFor` returns the fallback (no tier-by-origin yet). Record one row per test in the module's *Red baseline* table and the per-test grade.
- **Pre-seeded augmentations** (module table) stand: TestAC01 (no-lookup) + TestAC04 (no-claimed-value) → GUARD-2; TestAC09 (promotion) → PROV-3. The AC-test phases confirm or amend them.
- **ITEST-2 ∥ ITEST-3 share `dataset_test.dart` + `pending.dart` → run sequentially** (ITEST-2 first).

## Phase 2 — AC-1,2,3,4,5,6,11 (pending) + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-11 (all pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · **(run before ITEST-3 — shared runner)**
- **Files:** `integration_test/bs13/dataset_test.dart`, `pending.dart`
- **Tasks:** write one pending test per AC per the master catalogue (grade-A: each Given built + checked, the When, each Then's exact assertion, the control). Record the run-pending red baseline in the table below.
- **Exit criteria:** suite green by default (all seven pending/skipped); each fails cleanly under run-pending at the documented Then/precondition; grade gate passed.

### Result (ITEST-2) ✅

Added one *pending* acceptance test per AC for **AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-11** to `integration_test/bs13/dataset_test.dart` (new group `bs-13 dataset acceptance criteria`; **test-support only, no `lib/` touched**). AC-1/2/4/5/6/11 via `acTestWidgets` (observed through the wired `DatasetReadEndpoint` — `.dataset` / `.manifest`); AC-3 via `acTest` (the `ratioProvenanceGuard` source scan). Each reads only `dataset_harness.dart`. Highlights:

- **AC-1** solves `realEngine.inverse(AC1_TARGET, palette-from-seed-entries)` and asserts every top-recipe component is a seed optical paint **and** `predictedColor ≈ realEngine.forward(components)` (within 1.0 ΔLab) — a stored answer need not be forward-consistent, so this rejects a lookup. The source-level no-lookup guard control is the GUARD-2 augmentation (→ *B pending GUARD-2*).
- **AC-2** asserts every `CandidateMapping.origin == llmSeed`, each candidate id is grounded in a shipped entry, and (no runtime LLM) two `AssetSeedLoader` loads return identical mappings + boot drives no speech.
- **AC-3** asserts `ratioProvenanceGuard()` zero offenders over `lib/` + schema; **control:** re-pointed at `control_llmRatio` it lists the planted file.
- **AC-4** asserts accepted metadata (pigment index, masstone) is retained and survives `toPaint()`; the claimed-value strip + schema guard control is the GUARD-2 augmentation (→ *B pending GUARD-2*).
- **AC-5** asserts the shipped `manifest.heldOutCount` ∈ [50,100], a non-empty distribution, one ΔE00 per recipe, all finite ≥ 0.
- **AC-6** asserts the passing `heldOutManifest.shippable` (and the shipped seed) is true and both single-condition controls are not shippable (isolates each half of the threshold ∧ beats-LLM AND).
- **AC-11** asserts one brand, one medium (every entry checked) and ~15 paints (count ∈ [12,18]).

**Verification:** `flutter analyze integration_test/bs13` clean. **Default run (pending skipped): `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester` = 8 passed / 7 skipped, green.** **Run-pending red baseline (`--dart-define=BS13_RUN_PENDING=true`): 8 passed / 7 failed** — each of the seven fails cleanly at the documented Then or at a Given precondition naming its owning phase (no compile/harness errors); see the *Red baseline* table. **Unit suite 1332/0** unchanged (no `lib/` touched). **Coverage gate:** no in-scope source files (test-support only) — satisfied, same as ITEST-1/GUARD-1. **Grade gate:** fresh independent grader over the 7 tests (G1–G6) → **5 A, 2 A-core / B-pending-GUARD-2 (AC-1, AC-4), 0 below A** — matches the pre-seeded expectations; no downgrade, no fix needed. **Fix passes:** 0/3 (green on the first full run). The 3 pre-seeded augmentations (TestAC01 no-lookup → GUARD-2; TestAC04 no-claimed-value → GUARD-2; TestAC09 promotion → PROV-3) stand unchanged.

### Checkpoint / Handoff (ITEST-2 → ITEST-3)

- **ITEST-3 adds AC-7,8,9,10** to the **same `dataset_test.dart`** (append to the `bs-13 dataset acceptance criteria` group, or a sibling group) — all pure-Dart `acTest` over `sampleWithEvidence` / `provenanceOf` / `derivation` (no widget). **ITEST-2 and ITEST-3 share `dataset_test.dart` → run sequentially; ITEST-2 is done, ITEST-3 next.**
- **Red-baseline expectation (ITEST-3):** at the shell `ProvenanceDerivation.tierFor` returns the fallback and the append-only add is a stub — so AC-7 (each origin → its tier), AC-8 (append + retain), AC-9 (Estimated→Confirmed on swatch, *B pending PROV-3*), AC-10 (opinion stays Estimated) each fail cleanly under run-pending on a Then (or a Given precondition naming PROV-2/PROV-3). Record one row per test in the *Red baseline* table (AC-7..10 rows are pre-seeded) and grade with a fresh grader.
- **Verification commands (unchanged):** default `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester`; red baseline adds `--dart-define=BS13_RUN_PENDING=true`. **`-d flutter-tester` mandatory** (no `-d` ⇒ zero tests, false green). flutter at `~/development/flutter/bin`; cwd = the worktree root (`/Users/matthew.quirk/Nuance-bs13`).
- **Pattern to mirror** (grade-A): check every Given through the public surface *before* the When; make the pending test fail at a Then or a Given precondition naming its owning phase; pair a negative Then with a control. AC-3's control (re-point the guard at a planted fixture, assert it lists it) is the reusable template.

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
| AC-1 | TestAC01_RecipesSolvedFromOpticalData | FAIL ✓ (empty seed) | Given precondition `seed carries optical entries (SEED-3)` — `Actual: []` | SEED-3 (+GUARD-2) | A / B pending GUARD-2 |
| AC-2 | TestAC02_CandidatesFromLlm | FAIL ✓ | Given precondition `candidate combinations (SEED-4)` — `Actual: []` | SEED-4 | A |
| AC-3 | TestAC03_RatiosFromSolverNeverLlm | FAIL ✓ (guard stub) | Then `zero offenders` — stub returns the `not-yet-enforced` sentinel | GUARD-2 | A |
| AC-4 | TestAC04_MetadataAcceptedClaimedValuesRejected | FAIL ✓ | Given precondition `ingested entries (SEED-4)` — `Actual: []` | SEED-4 (+GUARD-2) | A / B pending GUARD-2 |
| AC-5 | TestAC05_HeldOutValidationRecorded | FAIL ✓ | Then `heldOutCount in [50,100]` — `Actual: <0>` (empty manifest) | SEED-5 | A |
| AC-6 | TestAC06_SeedShipsOnlyOnEvidence | FAIL ✓ | Then `heldOutManifest.shippable == true` — `Actual: <false>` (placeholder) | SEED-5 | A |
| AC-7 | TestAC07_EnforcedProvenanceTierByOrigin | FAIL (derivation stub) | Then: each origin → its tier | PROV-2 | A |
| AC-8 | TestAC08_EvidenceAppendOnly | FAIL | Then: appended + earlier retained | PROV-2 | A |
| AC-9 | TestAC09_PromotedOnlyByMeasuredSwatch | FAIL | Then: Estimated→Confirmed on swatch | PROV-3 | A / B pending PROV-3 |
| AC-10 | TestAC10_OpinionsNeverPromote | FAIL | Then: opinion → stays Estimated | PROV-3 | A |
| AC-11 | TestAC11_ShippedSeedStaysNarrow | FAIL ✓ (empty seed) | Given precondition `seed carries entries (SEED-3)` — `Actual: []` | SEED-3 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC01 | the no-lookup-table structural guard doesn't exist until GUARD-2 | GUARD-2 | the no-lookup assertion + `control_lookupTable` is listed | ⬜ Open |
| TestAC04 | the schema no-claimed-value guard doesn't exist until GUARD-2 | GUARD-2 | assert no stored entry carries a claimed spectral/ratio field + planted-entry control | ⬜ Open |
| TestAC09 | promotion can't be exercised until the PROV-3 rule exists | PROV-3 | the Estimated→Confirmed transition on a swatch evidence point | ⬜ Open |
