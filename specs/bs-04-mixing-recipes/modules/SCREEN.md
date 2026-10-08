# Module SCREEN — the Recipes screen UI

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/recipes/recipes_screen.dart` and its per-region widgets —
`lib/recipes/target_region.dart` (E22 target selector + E23 speak-target), `lib/recipes/controls_region.dart`
(E24 wet/dry toggle), `lib/recipes/recipe_list_region.dart` (the recipe list; per-recipe card with parts,
predicted colour, ΔE00, verdict, "a touch of", muddying, and E25 speak-recipe), `lib/recipes/gamut_banner.dart`
("OUT OF GAMUT").
**Depends on:** RECIPE (controller/state/endpoint), ENGINE (`Recipe`) · **Blocks:** ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |

(The screen's behaviour is filled by the ENGINE/RECIPE behaviour phases, each editing its own region widget;
SCREEN has only the scaffold phase of its own.)

## Interface reconciliation

- The screen is bound to the `RecipeController` owned by `RecipesHomeScreen` (RECIPE-2), mirroring bs-03's
  `ComparisonScreen` over `ComparisonController`. It reads state and dispatches controller actions; it holds
  no mixing or colour logic.
- Split into **per-region keyed widgets** so each behaviour phase edits exactly one region and the parallel
  windows stay file-disjoint: `TargetRegion` (E22/E23), `ControlsRegion` (E24), `RecipeListRegion` (the list +
  E25 per card), `GamutBanner`. Each region exposes a stable `regionKey` the acceptance suite finds it by.

## Open gates

- Inherits **G-2** (approve the acceptance tests) via the behaviour phases that fill the regions.

## Phase 1 — Recipes screen scaffold (SCREEN-1)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** RECIPE-2 · **Blocks:** ITEST-1
- **Files:** `lib/recipes/recipes_screen.dart`, `lib/recipes/target_region.dart`,
  `lib/recipes/controls_region.dart`, `lib/recipes/recipe_list_region.dart`, `lib/recipes/gamut_banner.dart`.
- **Tasks:**
  1. `RecipesScreen` composing the four keyed region widgets over the injected controller, with an app bar titled "Recipes" (so the handoff route still reads as Recipes).
  2. Each region is an **inert placeholder**: `TargetRegion` shows the current target name (keeping the bs-01 handoff render) + a disabled target-picker affordance (E22) and a disabled speak-target control (E23); `ControlsRegion` a disabled wet/dry toggle (E24); `RecipeListRegion` an empty list placeholder with a disabled speak-recipe control (E25); `GamutBanner` hidden.
  3. Unit-test that every region key renders and controls are present-but-inert.
- **Exit criteria:** `flutter analyze` clean; unit gate + 100% coverage on the new files; existing suites green (incl. bs-01 AC-11 handoff rendering the target).
- **Acceptance gate:** *(shell — unit gate + existing suite green; all region keys render)*
