# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/mixplan_test.dart` · `integration_test/mixplan_harness.dart` · `integration_test/bs16/pending.dart` (shared with MIXPLAN-1) · reuse `FakeSpeech`, bs-04 palette fixtures, bs-15 `InMemoryProjectSink`
**Depends on:** all shell phases (MIXPLAN-2, SCREEN-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ⬜ Todo | | |
| 2 | acceptance-tests | AC-1,2,3,7,8 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-4,5,6 | ⬜ Todo | | |
| 4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the real app via `buildApp(deps)` with the mix-plan entry. Real: `MixingEngine` inverse + gamut,
  `Recipe`, `CombinationLibrary`, controller, screen, routing. Faked (infra only): `FakeSpeech`,
  `InMemoryProjectSink`, the injected `PaletteSource` (bs-04 `PALETTE_MY_PAINTS`/`PALETTE_TRAVEL`).
- **Observation points:** the `MixPlanReadEndpoint` (the plan, each `ColourMixResult`'s `best`/`outOfGamut`, the
  summary counts, the active palette, the last saved record); the rendered tree; `FakeSpeech` (AC-7); the sink
  (AC-8). ΔE00 graded against the independent `referenceDeltaE00`.
- **Pending gate:** `integration_test/bs16/pending.dart` + `--dart-define=BS16_RUN_PENDING=true`.

## Open gates

- **G-2** decided at ITEST-4, blocks every behavior phase.

## Phase 1 — Harness, fixtures, pending gate, smoke (ITEST-1)

- **Kind:** acceptance-tests
- **Depends on:** SCREEN-1 (and MIXPLAN-2) · **Blocks:** ITEST-2, ITEST-3
- **Files:** `mixplan_harness.dart`, `mixplan_test.dart` (smoke), `integration_test/bs16/pending.dart`
- **Tasks:** boot the app via `buildApp` with the mix-plan entry; inject `FakeSpeech`, the real `MixingEngine`, a `CombinationLibrary` serving `COMBO_THREE`/`COMBO_MIXED_GAMUT`, `PaletteSource` with `PALETTE_MY_PAINTS`/`PALETTE_TRAVEL`, `InMemoryProjectSink`; define `referenceDeltaE00`; wire the pending gate; smoke test (app boots to the mix-plan route, endpoint readable).
- **Exit criteria:** suite green with every AC pending; smoke passes; `-d <udid>` documented.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — AC-1,2,3,7,8 (pending) + red baseline (ITEST-2)

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-3
- **Files:** `mixplan_test.dart` (its catalogue rows), `bs16/pending.dart`
- **Tasks:** write `TestAC01_RecipePerColour`, `TestAC02_RecipeDetail`, `TestAC03_PaletteConstrained`, `TestAC07_SpeakPlan`, `TestAC08_SavePlan`, each pending; record the red baseline.
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate passed.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — AC-4,5,6 (pending) + red baseline (ITEST-3)

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Files:** `mixplan_test.dart` (its catalogue rows), `bs16/pending.dart`
- **Tasks:** write `TestAC04_ReSolveOnSwitch`, `TestAC05_ColourOutOfGamut`, `TestAC06_GamutSummary`, each pending; record the red baseline.
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate passed.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — Test review (G-2) (ITEST-4)

- **Kind:** test-review
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase (G-2)
- **Tasks:** assemble the review packet (catalogue, red baseline, grades, fixtures, real-vs-faked, augmentation plan) for a human to approve. Record G-2 via `--gate`.
- **Exit criteria:** a human has recorded G-2; "changes requested" → ITEST change phases then a fresh review.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_RecipePerColour | FAIL | When: solve unimplemented | MIXPLAN-3 | — |
| AC-2 | TestAC02_RecipeDetail | FAIL | Then: no recipe detail | MIXPLAN-3 | — |
| AC-3 | TestAC03_PaletteConstrained | FAIL | Then: no plan | MIXPLAN-3 | — |
| AC-4 | TestAC04_ReSolveOnSwitch | FAIL | Then: no re-solve | MIXPLAN-5 | — |
| AC-5 | TestAC05_ColourOutOfGamut | FAIL | Then: no OOG marker | MIXPLAN-4 | — |
| AC-6 | TestAC06_GamutSummary | FAIL | Then: no summary | MIXPLAN-4 | — |
| AC-7 | TestAC07_SpeakPlan | FAIL | Then: no utterance | MIXPLAN-6 | — |
| AC-8 | TestAC08_SavePlan | FAIL | Then: nothing saved | MIXPLAN-7 | — |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| (none) | `COMBO_MIXED_GAMUT` carries both in- and out-of-gamut colours, and AC-2's distance is graded against `referenceDeltaE00`, so no behavior-phase augmentation is pre-seeded | — | — | — |
