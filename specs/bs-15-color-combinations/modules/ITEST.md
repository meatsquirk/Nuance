# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/combinations_test.dart` · `integration_test/combinations_harness.dart` · `integration_test/bs15/pending.dart` (shared with LIB-1) · `integration_test/fakes/*` reuse (`FakeSpeech`) + a fixture `CombinationLibrary` and `InMemoryProjectSink`
**Depends on:** all shell phases (LIB-2, COMBO-1, SCREEN-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ⬜ Todo | | |
| 2 | acceptance-tests | AC-1,2,5,6,11,12 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-3,4,7,8,9,10 | ⬜ Todo | | |
| 4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the real app via `buildApp(deps)` with the combinations entry (D-11). Real: `CombinationLibrary`
  query, `ColorScience`, `deltaE00`, `ConfusionCheck`, controller, screen, routing. Faked (infrastructure only):
  `FakeSpeech`; a deterministic fixture `CombinationLibrary` (real-shape data) for ranking/confusion;
  `InMemoryProjectSink`. AC-3/AC-9 load the **real** shipped `sanzo_wada.json`.
- **Observation points:** the `CombinationReadEndpoint` (anchor, suggestions, selected, confusionFlags,
  browseResults, searchResults, lastSaved); the rendered widget tree; the `FakeSpeech` log (AC-6); the
  `InMemoryProjectSink` (AC-12). ΔE00 graded against the harness's independent `referenceDeltaE00`.
- **Pending gate:** `integration_test/bs15/pending.dart` + `--dart-define=BS15_RUN_PENDING=true`; un-pend = delete
  one pending entry (one AC).

## Open gates

- **G-2** (approve the acceptance tests) is decided at **ITEST-4** and blocks every behavior phase.
- **G-4** (the near-match threshold) is needed by **ITEST-3** so `TestAC01/02/04` assert against an agreed value.

## Phase 1 — Harness, fixtures, pending gate, smoke (ITEST-1)

- **Kind:** acceptance-tests
- **Depends on:** SCREEN-1 (and LIB-2, COMBO-1) · **Blocks:** ITEST-2, ITEST-3
- **Files:** `combinations_harness.dart`, `combinations_test.dart` (smoke only), `integration_test/bs15/pending.dart`, fixture library + `InMemoryProjectSink`
- **Tasks:**
  1. Harness: boot the app via `buildApp` with the combinations entry; inject `FakeSpeech`, the fixture library (+ a real-asset option), `PROFILE_DEUTAN_MOD`, `SampleSource` with `SAMPLE_STUDIO_BLUE`, `InMemoryProjectSink`.
  2. Define the fixtures table (master plan) incl. `referenceDeltaE00`.
  3. Wire the pending gate; add a smoke test (app boots to the Combinations route, endpoint readable).
- **Exit criteria:** suite green with every AC pending; smoke passes; `-d <udid>` documented.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — AC-1,2,5,6,11,12 (pending) + red baseline (ITEST-2)

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-3 (coordinate shared file edits)
- **Files:** `combinations_test.dart` (its catalogue rows), `bs15/pending.dart`
- **Tasks:** write `TestAC01_SampleAnchor`, `TestAC02_PaintAnchor`, `TestAC05_NamedWithValues`, `TestAC06_SpeakCombination`, `TestAC11_ReferenceProvenance`, `TestAC12_SaveToProject` to the catalogue (master plan), each pending; record the run-pending **red baseline** (each FAILs at its Then / Given).
- **Exit criteria:** suite green with these pending; red baseline recorded in the table below; grade gate (grade-A rows) passed.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — AC-3,4,7,8,9,10 (pending) + red baseline (ITEST-3)

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1, **G-4** (threshold) · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Files:** `combinations_test.dart` (its catalogue rows), `bs15/pending.dart`
- **Tasks:** write `TestAC03_BoundedToDictionary`, `TestAC04_RankByCloseness`, `TestAC07_ConfusionFlagged`, `TestAC08_NoConfusionNotFlagged`, `TestAC09_BrowseBySize`, `TestAC10_SearchColour`, each pending; AC-3/AC-9 against the real asset; record the red baseline.
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate passed.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — Test review (G-2) (ITEST-4)

- **Kind:** test-review
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase (G-2)
- **Tasks:** assemble the review packet (the catalogue, the red baseline, the grades, the fixtures, what is real vs faked, the augmentation plan) for a human to approve. Record G-2 via `--gate`.
- **Exit criteria:** a human has recorded the G-2 decision; on "changes requested", each item becomes an ITEST change phase before the behavior stage, then a fresh review.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_SampleAnchor | FAIL | Then: anchor/suggestions unset | COMBO-2 | — |
| AC-2 | TestAC02_PaintAnchor | FAIL | Given: owned-paint anchor unsupported (G-3) | COMBO-3 | — |
| AC-3 | TestAC03_BoundedToDictionary | FAIL | When: `suggestFor` unimplemented | LIB-3 | — |
| AC-4 | TestAC04_RankByCloseness | FAIL | Then: no ordering | LIB-3 | — |
| AC-5 | TestAC05_NamedWithValues | FAIL | Then: no per-colour readout | COMBO-4 | — |
| AC-6 | TestAC06_SpeakCombination | FAIL | Then: no utterance | COMBO-5 | — |
| AC-7 | TestAC07_ConfusionFlagged | FAIL | Then: no flag | COMBO-6 | — |
| AC-8 | TestAC08_NoConfusionNotFlagged | FAIL/green | Then: control (no flag) once COMBO-6 lands | COMBO-6 | — |
| AC-9 | TestAC09_BrowseBySize | FAIL | When: `browse` unimplemented | LIB-4 | — |
| AC-10 | TestAC10_SearchColour | FAIL | When: `search` unimplemented | LIB-4 | — |
| AC-11 | TestAC11_ReferenceProvenance | FAIL | Then: no reference label | COMBO-4 | — |
| AC-12 | TestAC12_SaveToProject | FAIL | Then: nothing saved | COMBO-7 | — |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| (none) | `FIXTURE_LIBRARY` carries both ranking comparators and the confusable/non-confusable pair, so no behavior-phase augmentation is pre-seeded | — | — | — |
