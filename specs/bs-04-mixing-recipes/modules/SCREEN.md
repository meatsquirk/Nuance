# Module SCREEN — the Recipes screen UI

**Status:** ✅ Done — SCREEN-1 (shell) complete (module has only the scaffold phase)
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
| 1 | shell | — | ✅ Done | 7,144,050 | 15m 26s (15m 26s) |

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

### Result

Shell landed; the Recipes screen now composes its four keyed regions over the owned controller, all inert.

- **Added:** `lib/recipes/recipes_screen.dart` (`RecipesScreen` — a pure view over `RecipeController`: a
  "Recipes" `AppBar` over a `ListenableBuilder`/`ListView` of the regions, mirroring bs-03's `ComparisonScreen`);
  `lib/recipes/target_region.dart` (`TargetRegion`, key `recipes-target-region` — renders
  `Recipe target: <name>` + inert E22 "Choose target" / E23 "Speak target" `TextButton`s);
  `lib/recipes/controls_region.dart` (`ControlsRegion`, key `recipes-controls-region` — an E24 wet/dry
  `SegmentedButton<MixMode>` reflecting `state.mode`, disabled via a null `onSelectionChanged`);
  `lib/recipes/recipe_list_region.dart` (`RecipeListRegion`, key `recipes-list-region` — a "No recipes yet"
  empty-state placeholder + inert E25 "Speak recipe"); `lib/recipes/gamut_banner.dart` (`GamutBanner`, key
  `recipes-gamut-banner` — hidden `SizedBox.shrink` in the shell).
- **Changed:** `lib/app/build_app.dart` — `RecipesHomeScreen` now wraps `RecipesScreen(controller: _controller)`
  in its `RecipeReadEndpoint` (body was the inline `Scaffold`/`Text`); import added; docstring updated. Controller
  ownership + the read-endpoint wrapping stay in the home screen. No other `lib/**` touched.
- **bs-01 AC-11 kept green:** the "Recipes" app bar (now `AppBar`) and `Recipe target: <name>` render move into
  `TargetRegion`; the existing `build_app`/`router` widget tests (`find.text('Recipes')`,
  `'Recipe target: Deep Olive Green'`, `(unnamed)`, the `Scaffold`/endpoint lookups) and the readout AC-11
  handoff all still pass.
- **Region order:** `TargetRegion → ControlsRegion → GamutBanner → RecipeListRegion`. The gamut banner sits just
  above the recipe list (not first): a zero-extent `SizedBox.shrink` as the **leading** `ListView` child is not
  built by the lazy sliver, so `find.byKey` could not anchor it there; above the list it builds reliably and the
  position is also the natural one (the banner qualifies the list). bs-03's empty `ConfusionRegion` works only
  because it is never the leading child.
- **Gates:** `flutter analyze` clean; unit **517 green** (`flutter test --coverage`); coverage gate **100% on
  all 15 touched lib files** (vs `main`); integration **62 green** on iPhone 17 sim under the verify lock — incl.
  bs-01's AC-11 handoff rendering the real `RecipesScreen`.
- **Fix passes: 1/3** — first full `flutter test` failed one assertion: the gamut-banner key was missing when it
  was the leading `ListView` child (lazy sliver skips a zero-extent leader); reordered it above the list and the
  suite went green.
- **Tokens / Time:** 7,144,050 · 15m 26s (wall 15m 26s).

### Checkpoint / Handoff

- **Frozen for the behaviour phases (region seams):** each region is a `StatelessWidget({required controller})`
  with a static `regionKey` the acceptance suite finds it by —
  `TargetRegion.regionKey = ValueKey('recipes-target-region')` (E22 "Choose target" → RECIPE-3; E23 "Speak
  target" → RECIPE-4),
  `ControlsRegion.regionKey = ValueKey('recipes-controls-region')` (E24 `SegmentedButton<MixMode>` → ENGINE-6
  wires `onSelectionChanged` to `setMode`),
  `RecipeListRegion.regionKey = ValueKey('recipes-list-region')` (the recipe cards → ENGINE-2..6; E25 "Speak
  recipe" → RECIPE-4),
  `GamutBanner.regionKey = ValueKey('recipes-gamut-banner')` (→ ENGINE-5 renders "OUT OF GAMUT" from a
  state signal it adds). Each behaviour phase edits exactly one region file, so the windows stay file-disjoint.
- **`RecipesScreen(controller:)`** is the screen body `RecipesHomeScreen` owns; it holds no logic. Keep the
  "Recipes" `AppBar` and the `TargetRegion` target render so bs-01 AC-11 stays green. The `ListView` region order
  is `Target → Controls → GamutBanner → List`; keep `GamutBanner` non-leading.
- **Inert control idiom:** a disabled `TextButton` is `onPressed: null` (`.enabled == false`); the disabled
  toggle is `onSelectionChanged: null`. The behaviour phases swap the null for the controller action.
- **Verification commands** unchanged (RECIPE-2 handoff; `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under the
  lock on sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (always pass `-d <udid>`; no device ⇒ false green).
- **Next phase:** ITEST-1 (acceptance-tests) — the harness `integration_test/recipes_harness.dart` over the wired
  shells, the fixtures, the 12-AC pending seed in `integration_test/bs04/pending.dart`, and a smoke test. The
  acceptance stage can now begin (SCREEN-1 was the last shell). **G-4** and **G-2** remain open (G-4 before
  ITEST-3; G-2 at the ITEST-4 review).
- **Known gaps / notes:** no behaviour yet (every region control is inert; every controller action still throws).
  Carry-over const-constructor coverage flake stands (re-run `--coverage` once if the gate flags an untouched
  file). Untracked bs-05..bs-14 specs + `docs/` sit in the tree from a prior branch; not part of bs-04 and not
  committed by this phase.
