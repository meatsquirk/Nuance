# Module RECIPE — scaffold, controller, palette source, target & spoken output

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/recipes/palette.dart` (`PaintPalette`), `lib/recipes/palette_source.dart`
(`PaletteSource`, `InMemoryPaletteSource`), `lib/recipes/recipe_state.dart`, `lib/recipes/recipe_controller.dart`,
`lib/recipes/recipe_read_endpoint.dart`, `lib/recipes/recipe_speech.dart`; the recipes entry in
`lib/app/build_app.dart` (`recipesEntry`, `RecipesHomeScreen`, `AppDependencies.paletteSource`) and the
`AppRouter.toRecipes` body in `lib/app/router.dart` (replace `RecipesStubScreen`). The scaffold phase also
owns `integration_test/bs04/pending.dart`.
**Depends on:** bs-03 foundation (`Sample`, `SampleSource`, `buildApp`/`AppScope`/`AppDependencies`, `Speech`,
`AppRouter`), ENGINE (`Paint`, `MixingEngine`, `Recipe`) · **Blocks:** SCREEN, ITEST, every behaviour phase

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ⬜ Todo | | |
| 2 | shell | — | ⬜ Todo | | |
| 3 | behavior | AC-1, AC-2 | ⬜ Todo | | |
| 4 | behavior | AC-11, AC-12 | ⬜ Todo | | |

## Interface reconciliation

- **`PaletteSource`** (`List<PaintPalette> palettes()` + a selected palette) mirrors bs-03's `SampleSource`:
  a minimal read-only seam; `InMemoryPaletteSource` is the bs-04 default; **bs-06** supplies the persistent
  store behind the same interface. `PaintPalette` = `{name, List<Paint>}`.
- **Target** is a `Sample` — from the existing `SampleSource` saved samples (reused) or a manual CIELAB with
  validation. The controller holds `target`, `selectedPalette`, the ordered `List<Recipe>`, the wet/dry mode,
  and the manual-entry validation error.
- **Recipes entry** (D-6) is symmetric to bs-02's `captureSource` / bs-03's `comparisonEntry`: the
  `RecipesHomeScreen` owns the `RecipeController` and wraps its subtree in a `RecipeReadEndpoint`. The real
  screen replaces `RecipesStubScreen` behind `AppRouter.toRecipes` — callers unchanged; it must still render
  the target name so bs-01's AC-11 handoff test stays green.
- **Solving** is delegated to the injected `MixingEngine` (ENGINE); the controller never computes mixing math.

## Open gates

- **G-1 (approve the spec)** blocks RECIPE-1 (scaffold).
- **G-2 (approve the acceptance tests)** blocks RECIPE-3, RECIPE-4 (every behaviour phase).

## Phase 1 — Scaffold (RECIPE-1)

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1, G-3) · **Blocks:** ENGINE-1
- **Files:** `integration_test/bs04/pending.dart`; branch + baseline only (no `lib/**`).
- **Tasks:**
  1. Cut branch `feat/bs-04-mixing-recipes` from `main` @ `8518463`; record the baseline test run (unit + integration counts).
  2. Confirm the coverage gate: PASS on the clean tree, FAIL on a planted uncovered line (then revert the plant).
  3. Add `integration_test/bs04/pending.dart` (copy the bs-03 gate verbatim; flag `BS04_RUN_PENDING`; `pendingACs` **empty**; `behaviorPhases` = {RECIPE-3, RECIPE-4, ENGINE-2, ENGINE-3, ENGINE-4, ENGINE-5, ENGINE-6}).
- **Exit criteria:** branch exists; baseline recorded; the gate passes clean and fails on the planted gap; `BS04_RUN_PENDING` runner in place. No product code.
- **Acceptance gate:** *(scaffold — tooling works; baseline recorded)*

## Phase 2 — Palette source + controller + recipes entry (RECIPE-2)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** ENGINE-1 · **Blocks:** SCREEN-1
- **Files:** `lib/recipes/palette.dart`, `lib/recipes/palette_source.dart`, `lib/recipes/recipe_state.dart`,
  `lib/recipes/recipe_controller.dart`, `lib/recipes/recipe_read_endpoint.dart`; `lib/app/build_app.dart`
  (recipes entry + `AppDependencies.paletteSource`/`recipesEntry`); `lib/app/router.dart` (replace the stub).
- **Tasks:**
  1. `PaintPalette` + `PaletteSource`/`InMemoryPaletteSource` (default empty; the harness/behaviour seed it).
  2. `RecipeState` (target, selectedPalette, `List<Recipe>` empty, wet/dry mode = wet, manualError null) + `RecipeController` over `sampleSource`/`paletteSource`/`mixingEngine`/`speech`/`router` — **inert** (no selection, no solve, no speak behaviour yet).
  3. `RecipeReadEndpoint` (mirrors `ComparisonReadEndpoint`).
  4. `RecipesHomeScreen` + `recipesEntry` in `buildApp`; replace `RecipesStubScreen` behind `AppRouter.toRecipes` with `RecipesHomeScreen` carrying the target into the state (**still renders the target name** — keep bs-01 AC-11 green).
  5. Unit-test the state/controller/source/endpoint shape; keep behaviour unchanged.
- **Exit criteria:** `flutter analyze` clean; unit gate + 100% coverage touched; existing suites green **incl. bs-01's AC-11 handoff** on the real screen.
- **Acceptance gate:** *(shell — unit gate + existing suite green)*

## Phase 3 — Target selection (RECIPE-3)

- **Kind:** behavior
- **Target AC:** AC-1 (choose a saved sample as target), AC-2 (manual entry; impossible value refused, previous kept)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** ENGINE-2
- **Files:** `lib/recipes/recipe_controller.dart` (set-target from saved sample; manual entry + validation); the target region (E22) is SCREEN's `target_region.dart`.
- **Tasks:**
  1. The target selector (E22) lists `sampleSource.savedSamples()`; choosing one sets `state.target` (AC-1).
  2. Manual entry sets a CIELAB target with **range validation** — a lightness of 140 is refused (a `manualError`), and `state.target` is left unchanged (AC-2).
  3. Un-pend AC-1, AC-2; unit-test set-from-sample, valid manual entry, and the out-of-range rejection keeping the previous target.
- **Exit criteria:** AC-1/AC-2 green; default suite green; unit gate + 100% coverage touched.
- **Acceptance gate:** un-pend AC-1, AC-2; `flutter test integration_test/recipes_test.dart -d <udid>` green (`TestAC01_*`, `TestAC02_*`); grade gate passed.

## Phase 4 — Spoken target & recipe (RECIPE-4)

- **Kind:** behavior
- **Target AC:** AC-11 (speak the target: name + L, C, h), AC-12 (speak a recipe: each paint + its parts)
- **Depends on:** ENGINE-2 (a recipe exists to speak) · **Blocks:** SIGNOFF-1
- **Files:** `lib/recipes/recipe_speech.dart` (utterance builders), `lib/recipes/recipe_controller.dart` (speak methods); speak controls (E23/E25) are SCREEN's region widgets. **File-disjoint from the engine** (runs ∥ ENGINE-3..6).
- **Tasks:**
  1. Build the **target** utterance (name + L, C, h) and speak it once via the injected `Speech` (E23, AC-11).
  2. Build the **recipe** utterance (each paint + its parts; trace components as "a touch of") and speak it once (E25, AC-12).
  3. Un-pend AC-11, AC-12; unit-test both builders (exact content) and that each speak call emits exactly one utterance.
- **Exit criteria:** AC-11/AC-12 green; default suite green; unit gate + 100% coverage touched.
- **Acceptance gate:** un-pend AC-11, AC-12; suite green (`TestAC11_*`, `TestAC12_*`); grade gate passed.
