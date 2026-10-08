# Module RECIPES — Controller, sources, wiring, speech

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** scaffold + `lib/recipes/recipes_controller.dart`, `recipes_state.dart`, `palette_source.dart`, `target_source.dart`, `recipes_read_endpoint.dart`; the recipes entry + `RecipesHomeScreen` in `lib/app/build_app.dart`; `lib/app/router.dart` (replace the stub route); the BS04 pending plumbing `integration_test/bs04/pending.dart`
**Depends on:** bs-01 domain/router/`Speech`, MIX (engine types) · **Blocks:** SCREEN (controller), ITEST (wiring)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 (RECIPES-1) | scaffold | — | ⬜ Todo | | |
| 2 (RECIPES-2) | shell | — | ⬜ Todo | | |
| 3 (RECIPES-3) | behavior | AC-1, AC-2 | ⬜ Todo | | |
| 4 (RECIPES-4) | behavior | AC-11, AC-12 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `RecipesController` (set target from a saved sample / manual LCh entry with validation, hold
  the solved recipe list + wet/dry mode, speak target/recipe via `Speech`); `PaletteSource` +
  `InMemoryPaletteSource` (D-3, bs-06 later persists); `TargetSource` + `InMemoryTargetSource` (the bs-03
  `SampleSource` pattern); `RecipesReadEndpoint` (target, recipe list, each recipe's fields, wet/dry mode);
  a `RecipesEntry` + `RecipesHomeScreen` in `buildApp` (D-10), replacing `RecipesStubScreen` behind
  `AppRouter.toRecipes`.
- **Consumes:** MIX `MixingEngine` (injected, default `SpectralEngine`), `Paint`/`Recipe`; bs-01 `Sample`,
  `Speech`, `AppRouter`, `AppScope`/`AppDependencies`.
- **Reconciliation:** `AppDependencies` gains `paletteSource`, `targetSource`, `mixingEngine`, `recipesEntry`
  (symmetric to bs-03's `comparisonEntry`); `main.dart` and the harness build through the one `buildApp`.

## Open gates

- **G-1** blocks RECIPES-1 (the whole build) — approve the spec.
- **G-2** blocks RECIPES-3 / RECIPES-4 (every behavior phase).

## Phase 1 (RECIPES-1) — Scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1) · **Blocks:** MIX-1 and all shells
- **Files:** branch `feat/bs-04-mixing-recipes` from `main` @ b3bcc38; `integration_test/bs04/pending.dart`
  (mechanism only, `pendingACs` empty)
- **Tasks:**
  1. Cut the branch; record the baseline (`flutter analyze`; `flutter test`; the existing
     `integration_test` run) — all green.
  2. Confirm the coverage gate (`tool/coverage_gate.dart`) PASSes on the clean tree and FAILs on a planted
     uncovered line; revert the plant.
  3. Add the BS04 pending plumbing keyed to `BS04_RUN_PENDING` (mirror `integration_test/bs03/pending.dart`),
     `pendingACs` empty.
- **Exit criteria:** baseline recorded; the gate passes clean and fails on the planted gap; no product code.
- **Acceptance gate:** *(n/a — scaffold)*

## Phase 2 (RECIPES-2) — Controller, sources, read endpoint, wiring

- **Kind:** shell
- **Target AC:** —
- **Depends on:** MIX-1 (engine types) · **Blocks:** SCREEN-1, ITEST-1 · ∥ SOLVER-1
- **Files:** `lib/recipes/recipes_controller.dart`, `recipes_state.dart`, `palette_source.dart`,
  `target_source.dart`, `recipes_read_endpoint.dart`; `lib/app/build_app.dart` (recipes entry +
  `RecipesHomeScreen`); `lib/app/router.dart` (replace `RecipesStubScreen`)
- **Tasks:**
  1. `PaletteSource`/`InMemoryPaletteSource` and `TargetSource`/`InMemoryTargetSource` (empty defaults).
  2. `RecipesController`/`RecipesState`: a target slot, a recipe list, a wet/dry mode — all inert (no
     solving, no validation) in the shell; `set target`, `speak*` as no-op hooks.
  3. `RecipesReadEndpoint` (InheritedWidget) exposing the state for the acceptance suite.
  4. `AppDependencies` + `buildApp` recipes entry → `RecipesHomeScreen` owning the controller (over the
     injected engine/palette/target), wrapped in the read endpoint; replace `toRecipes`'s
     `RecipesStubScreen` with the real `RecipesScreen` placeholder (SCREEN-1 fills it).
- **Exit criteria:** app assembles through the recipes entry; `toRecipes` reaches the real screen; unit
  green; 100% coverage on touched files; the existing integration suite stays green (bs-01 recipes-handoff
  test now lands on the real screen rendering the target name).
- **Acceptance gate:** *(n/a — shell)*

## Phase 3 (RECIPES-3) — Target selection: saved + manual (AC-1, AC-2)

- **Kind:** behavior
- **Target AC:** AC-1 (full), AC-2 (full)
- **Depends on:** RECIPES-2, SCREEN-1 (the E22 selector shell); **needs G-2** · **Blocks:** MIX-2, SOLVER-2
- **Files:** `lib/recipes/recipes_controller.dart` (set-target + validation), `lib/recipes/target_region.dart`
  (E22 selector + manual entry — the SCREEN-1 region)
- **Tasks:**
  1. Choosing a saved sample from the `TargetSource` sets the target; the readback shows its L/C/h (AC-1).
  2. Manual CIELCh entry validated to L∈[0,100], C≥0, h∈[0,360); an out-of-range value (L 140) is refused
     with a findable rejection and the **previous target is kept** (AC-2).
- **Exit criteria:** target set is observable via the read endpoint and the rendered L/C/h; a rejected entry
  leaves the prior target intact.
- **Acceptance gate:** un-pend AC-1, AC-2; `flutter test integration_test/recipes_test.dart` green with
  `TestAC01`/`TestAC02` passing; later ACs pending.

## Phase 4 (RECIPES-4) — Speak target / speak recipe (AC-11, AC-12)

- **Kind:** behavior
- **Target AC:** AC-11 (full), AC-12 (full)
- **Depends on:** RECIPES-3 (a target), SOLVER-2 (a recipe to speak) · **Blocks:** SIGNOFF-1 · ∥ SOLVER-3/4, SCREEN-2, MIX-3
- **Files:** `lib/recipes/recipes_controller.dart` (utterance builders), `lib/recipes/actions_bar.dart`
  (E23 speak-target + E25 speak-recipe controls — the SCREEN-1 region)
- **Tasks:**
  1. Speak target (E23): one `Speech` utterance stating the target name + its L, C and hue (AC-11).
  2. Speak recipe (E25): one utterance stating each paint and its parts (AC-12).
- **Exit criteria:** exactly one utterance per action with the stated content; via the bs-01 `Speech` seam.
- **Acceptance gate:** un-pend AC-11, AC-12; suite green with `TestAC11`/`TestAC12` passing.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
