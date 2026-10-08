# Module ITEST — Acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/recipes_test.dart`, `integration_test/recipes_harness.dart`, `integration_test/bs04/pending.dart` (seeded), the fixtures; reuses bs-01 `integration_test/fakes/fake_speech.dart`
**Depends on:** all shell phases (RECIPES-1/2, MIX-1, SOLVER-1, SCREEN-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 (ITEST-1) | acceptance-tests | — (harness) | ⬜ Todo | | |
| 2 (ITEST-2) | acceptance-tests | AC-1,2,5,10,11,12 | ⬜ Todo | | |
| 3 (ITEST-3) | acceptance-tests | AC-3,4,6,7,8,9 | ⬜ Todo | | |
| 4 (ITEST-4) | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the assembled app via bs-01's production `buildApp(deps)` with the recipes entry (D-10),
  driven through the `RecipesScreen` with `WidgetTester`. Production wiring reused; the only fake is bs-01's
  `Speech` sink (`FakeSpeech`) — infrastructure. Engine (forward KM, inverse solver, muddying, gamut,
  wet/dry), `deltaE00`, verdict bands, sources, controller, screen and routing are all real.
- **Observation points:** rendered text (target readback; each recipe's parts incl. "a touch of"; predicted
  colour; ΔE00 + verdict; muddying flag; OUT OF GAMUT + nearest; the E24 toggle); the `RecipesReadEndpoint`
  (target, recipe list, each recipe's parts/predicted/ΔE00/verdict/muddying/outOfGamut, wet/dry mode); the
  `FakeSpeech` log; the current route.
- **Pending gate:** `integration_test/bs04/pending.dart`, `pendingACs` map (AC → owning phase) keyed to
  `BS04_RUN_PENDING`; un-pend = delete one row. Default run skips pending ACs; run-pending executes them.

## Open gates

- **G-4** blocks ITEST-1 (the `PALETTE_MY_PAINTS` fixture needs the paint K/S data source).
- **G-3** blocks ITEST-3 (AC-4's 3–5 recipe literals / AC-5 ΔE00 referenced in the catalogue; AC-10 handled
  in ITEST-2 — its dry value is pinned via G-3 too, so ITEST-2 carries the G-3 dependency for AC-10).
- **G-2** is this module's output (ITEST-4's gate), blocking every behavior phase.

## Phase 1 (ITEST-1) — Harness, fixtures, pending gate, smoke

- **Kind:** acceptance-tests
- **Target AC:** — · **Depends on:** all shells; **needs G-4** · **Blocks:** ITEST-2, ITEST-3
- **Tasks:** build `recipes_harness.dart` (Given/When/Then vocabulary over the recipes entry + fixtures);
  seed `pendingACs` with all 12 ACs; default + run-pending targets; a never-pending smoke test proving the
  shells are wired end to end (open Recipes, assert the screen + empty read endpoint). Grade the scaffold
  tests (no vacuous passes; every pending key names a real phase).
- **Exit criteria:** acceptance suite green with all 12 pending; smoke green; grid all A.

## Phase 2 (ITEST-2) — AC-1,2,5,10,11,12 (pending) + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-5, AC-10, AC-11, AC-12 (the target/selection/verdict/wet-dry/speak side)
- **Depends on:** ITEST-1; **needs G-3** (AC-10 dry value) · **Blocks:** ITEST-4 · ∥ ITEST-3
- **Tasks:** one *pending* test per AC per the master catalogue; run the run-pending mode; fill the red
  baseline rows; grade all A (or *B pending <phase>* with an augmentation row).

## Phase 3 (ITEST-3) — AC-3,4,6,7,8,9 (pending) + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-3, AC-4, AC-6, AC-7, AC-8, AC-9 (the solver/engine side)
- **Depends on:** ITEST-1; **needs G-3** (AC-4 literals) · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Tasks:** one *pending* test per AC; confirm/seed the `TestAC04`/`TestAC06`/`TestAC07`/`TestAC08`
  augmentation rows (the solver doesn't exist yet, so these inspect recipes that can't be produced through
  public flows — assert via a Given-precondition naming SOLVER-2/SOLVER-4); run-pending; red baseline; grade.

## Phase 4 (ITEST-4) — Test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase (G-2)
- **Tasks:** assemble the packet (per AC: test name, Given checks, When, Then + Rejects; the red-baseline
  summary; the augmentations scheduled + closing phase; the grid path + counts); regression green (unit +
  acceptance with all 12 pending); set the phase `⏸ Awaiting review` and G-2 *awaiting decision*; stop with
  `/feature-next-phase --gate bs-04-mixing-recipes G-2 approved | "<changes>"`.

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_ChooseSavedTarget | _pending ITEST-2_ | | RECIPES-3 | |
| AC-2 | TestAC02_ManualTargetRefused | _pending ITEST-2_ | | RECIPES-3 | |
| AC-3 | TestAC03_PaletteOnly | _pending ITEST-3_ | | SOLVER-2 | |
| AC-4 | TestAC04_TopRecipes | _pending ITEST-3_ | | SOLVER-2 | |
| AC-5 | TestAC05_CloseVerdict | _pending ITEST-2_ | | MIX-2 | |
| AC-6 | TestAC06_PreferFewer | _pending ITEST-3_ | | SOLVER-2 | |
| AC-7 | TestAC07_TraceTouchOf | _pending ITEST-3_ | | SCREEN-2 | |
| AC-8 | TestAC08_MuddyingFlag | _pending ITEST-3_ | | SOLVER-4 | |
| AC-9 | TestAC09_OutOfGamut | _pending ITEST-3_ | | SOLVER-3 | |
| AC-10 | TestAC10_WetDry | _pending ITEST-2_ | | MIX-3 | |
| AC-11 | TestAC11_SpeakTarget | _pending ITEST-2_ | | RECIPES-4 | |
| AC-12 | TestAC12_SpeakRecipe | _pending ITEST-2_ | | RECIPES-4 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC04 | the solver doesn't exist yet, so the 3–5 recipes can't be produced through public flows | SOLVER-2 | list length ∈ [3,5]; each recipe has non-empty parts + a non-null predicted colour | ⬜ Open |
| TestAC05 | one recipe can't show the verdict tracks distance | MIX-2 | a clearly-distant recipe for the same target reads a **different** verdict band | ⬜ Open |
| TestAC06 | the solver doesn't exist yet, so the 2-paint/4-paint pair can't be produced | SOLVER-2 | at similar ΔE00, the 2-paint recipe's list index < the 4-paint's | ⬜ Open |
| TestAC07 | the solver doesn't exist yet, so a real trace-component recipe can't be produced | SOLVER-2 (fixture) / SCREEN-2 (render) | finalize `TRACE_RECIPE` from a real solved recipe; assert "a touch of" + note, no numeric part for the trace | ⬜ Open |
| TestAC08 | the solver doesn't exist yet, so a complementary-crossing recipe can't be produced | SOLVER-4 | `muddying == true` for the crossing recipe; `false` for the same-family control | ⬜ Open |

## Phase 1–4 Results  <!-- filled on completion -->
