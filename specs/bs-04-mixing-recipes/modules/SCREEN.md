# Module SCREEN — Recipes screen UI

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/recipes/recipes_screen.dart` + per-region widgets: `target_region.dart` (E22, filled by RECIPES-3), `recipe_list_region.dart` (parts / predicted colour / ΔE00 + verdict / muddying flag / OUT OF GAMUT), `wet_dry_toggle.dart` (E24, filled by MIX-3), `actions_bar.dart` (E23/E25, filled by RECIPES-4), `parts_format.dart` (trace "a touch of")
**Depends on:** RECIPES (controller + read endpoint), MIX/SOLVER (recipe fields to render) · **Blocks:** ITEST (the screen under test)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 (SCREEN-1) | shell | — | ⬜ Todo | | |
| 2 (SCREEN-2) | behavior | AC-7 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `RecipesScreen(controller)` composing keyed regions, each driven by `RecipesState`/the read
  endpoint. The recipe-list region is **data-driven**: it renders each recipe's parts, predicted colour,
  ΔE00 + verdict, muddying flag and the OUT OF GAMUT / nearest wording from the recipe's fields, so the
  behavior phases that populate those fields (MIX/SOLVER) need not edit the screen — SCREEN-2 is only the
  trace "a touch of" formatting (AC-7).
- **Consumes:** `RecipesController`/`RecipesReadEndpoint`, `Recipe`.
- **Reconciliation:** regions are split per element so RECIPES-3 (target), MIX-3 (wet/dry toggle), RECIPES-4
  (speak) and SCREEN-2 (trace) edit disjoint files.

## Open gates

- **G-2** blocks SCREEN-2 (behavior).

## Phase 1 (SCREEN-1) — Recipes screen scaffold

- **Kind:** shell
- **Target AC:** —
- **Depends on:** RECIPES-2 (controller to bind) · **Blocks:** ITEST-1, RECIPES-3 (E22 region), MIX-3 (E24), RECIPES-4 (E23/E25)
- **Files:** `lib/recipes/recipes_screen.dart`, `target_region.dart`, `recipe_list_region.dart`,
  `wet_dry_toggle.dart`, `actions_bar.dart`
- **Tasks:**
  1. Build `RecipesScreen` with keyed region widgets for E22–E25 and the recipe-list body — placeholders and
     disabled controls, bound to the controller but inert.
  2. Make the recipe-list region data-driven over `Recipe` (renders parts, predicted colour, ΔE00 + verdict,
     muddying flag, OUT OF GAMUT when the fields are present; empty while the list is empty).
- **Exit criteria:** screen renders under the recipes entry; keys/labels findable; unit green; 100% coverage
  on the new files; integration suite green.
- **Acceptance gate:** *(n/a — shell)*

## Phase 2 (SCREEN-2) — Trace "a touch of" (AC-7)

- **Kind:** behavior
- **Target AC:** AC-7 (full)
- **Depends on:** SOLVER-2 (a solved recipe with a trace component); **needs G-2** · **Blocks:** SIGNOFF-1 · ∥ SOLVER-3/4, RECIPES-4, MIX-3
- **Files:** `lib/recipes/parts_format.dart`, `lib/recipes/recipe_list_region.dart`
- **Tasks:**
  1. Render a component under ~2% by volume (SOLVER `traceComponents`, D-7) as "a touch of <paint>" with a
     technique note, not a measured part; a ≥2% component still shows a numeric part (control).
- **Exit criteria:** the trace fixture renders "a touch of" + note; non-trace components render numeric parts.
- **Acceptance gate:** un-pend AC-7; `flutter test integration_test/recipes_test.dart` green with
  `TestAC07_TraceTouchOf` passing; later/other ACs as pending.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
