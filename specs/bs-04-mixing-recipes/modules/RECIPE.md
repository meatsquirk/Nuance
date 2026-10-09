# Module RECIPE — scaffold, controller, palette source, target & spoken output

**Status:** In progress — RECIPE-3 (target selection) done; next RECIPE-4 (speak, after ENGINE-2)
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
| 1 | scaffold | — | ✅ Done | 3,103,321 | 16m 10s |
| 2 | shell | — | ✅ Done | 14,660,317 | 44m 03s |
| 3 | behavior | AC-1, AC-2 | ✅ Done | 18,470,473 | 46m 17s |
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

- **G-1 (approve the spec)** ✅ Resolved 2026-10-08 12:57 EDT — spec approved as-is by Matt Quirk; `.feature` first line stamped. RECIPE-1 unblocked.
- **G-2 (approve the acceptance tests)** ✅ Resolved 2026-10-09 by Matt Quirk — the 12 pending AC tests
  accepted as the acceptance contract. Behaviour stage open; RECIPE-3 done, RECIPE-4 awaits ENGINE-2.

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

### Result

Scaffold complete; no product code (`lib/**`) touched (only `integration_test/bs04/pending.dart` added).

- **Branch:** `feat/bs-04-mixing-recipes` cut from `main` @ `ac3bd09` (the current main tip). The plan names
  `8518463` as the base; `ac3bd09` is two plan-only commits later (`8b720cb` PLAN, `ac3bd09` GATE-DECISION G-1)
  with **no `lib/` delta** between them (`git diff 8518463 ac3bd09 -- lib/` empty), so the lib base is identical
  and the branch carries the current plan + G-1 decision. A stale pre-existing `feat/bs-04-mixing-recipes`
  (tip `ed5bcdc`, a superseded "18 phases/5 modules" plan draft on an old bs-01-only base, missing the
  bs-02/03 merges) was **renamed** to `feat/bs-04-mixing-recipes-stale-plan-ed5bcdc` (preserved, not deleted).
- **Baseline (Flutter 3.47.6 stable, iPhone 17 sim `5AB9D06D…`):** `flutter analyze` clean; unit **430 green**
  (`flutter test --coverage`); integration **62 green** (`flutter test integration_test/ -d <sim>` — bs-01
  readout/harness + bs-02 capture + bs-03 comparison). Existing suites green.
- **Coverage gate proven both ways:** `dart run tool/coverage_gate.dart main` — PASS clean ("no touched
  lib/**.dart files", exit 0); FAIL on a planted untracked `lib/_gate_probe.dart` ("NO COVERAGE DATA", exit 1);
  probe removed.
- **BS04 pending runner:** `integration_test/bs04/pending.dart` added, copied verbatim from `bs03/pending.dart`
  — mechanism only (`pendingACs` **empty**; ITEST-1 seeds the 12 ACs), `behaviorPhases` = the 7 bs-04 behaviour
  phases {RECIPE-3, RECIPE-4, ENGINE-2, ENGINE-3, ENGINE-4, ENGINE-5, ENGINE-6}, keyed to `BS04_RUN_PENDING`
  (env var or `--dart-define`). Analyze clean with it present.
- Coverage gate: no `lib` touched ⇒ nothing to gate, PASS. Fix passes: 0/3 (passed first run).
- **Tokens / Time:** 3,103,321 · 16m 10s.

### Checkpoint / Handoff

- **Frozen for shells:** pending-gate API — `pendingACs`, `behaviorPhases`, `runPending`,
  `pendingSkipReason(acId, {forceRunPending})`, `acTestWidgets(acId, description, body)` in
  `integration_test/bs04/pending.dart`. Un-pend flag `BS04_RUN_PENDING`; bs-04 integration test file will be
  `integration_test/recipes_test.dart` (ITEST-1/2/3), harness `integration_test/recipes_harness.dart`.
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` (base = `main`;
  equivalently `ac3bd09`, no lib delta) · integration on the iOS sim under the verify lock:
  `$C with-lock bs-04-mixing-recipes <PHASE> --wait 900 -- bash -c "export PATH=…; cd <repo> && flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685"`.
  Run-pending (on-device): `flutter test integration_test/recipes_test.dart -d <sim> --dart-define=BS04_RUN_PENDING=true`.
- **Next phase:** ENGINE-1 (shell) — `Paint`/`PaintMedium`, `MixingEngine` interface, `Recipe`/`RecipeComponent`,
  stub engine wired into `AppDependencies`. RECIPE-2 (this module's shell) follows ENGINE-1.
- **Known gaps / notes:** no product code yet. Carry-over flake (master plan *Known flakes*): a `const`
  constructor line can intermittently read uncovered on `flutter test --coverage` — re-run once if the gate
  flags an untouched file. Always pass `-d <booted-udid>` to the integration suite (no device ⇒ zero tests,
  false green). Untracked bs-05..bs-14 specs + `docs/` sit in the tree from a prior branch; not part of bs-04
  and not committed by this phase.

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

### Result

Shell landed; the Recipes feature now assembles end-to-end with inert behaviour.

- **Added:** `lib/recipes/palette_source.dart` (`PaletteSource` + empty-default `InMemoryPaletteSource`,
  mirroring bs-03's `SampleSource`; method `palettes()`, field `catalogue`); `lib/recipes/recipe_state.dart`
  (`MixMode {wet,dry}` + immutable value-equal `RecipeState` {target, selectedPalette, recipes=[], mode=wet,
  manualError=null} + `hasRecipes`); `lib/recipes/recipe_controller.dart` (`RecipeController` ChangeNotifier
  over sampleSource/paletteSource/mixingEngine/speech/router, `state`/`savedSamples`/`palettes` getters,
  initial selected palette = first available; **inert** actions `selectTarget`/`enterManualTarget`/
  `selectPalette`/`setMode`/`speakTarget`/`speakRecipe` throw `UnimplementedError` naming their phase);
  `lib/recipes/recipe_read_endpoint.dart` (`RecipeReadEndpoint`, mirrors `ComparisonReadEndpoint`).
- **Wired:** `build_app.dart` — `RecipesEntry {target}`, `AppDependencies.paletteSource`
  (empty default) + `recipesEntry`, `RecipesHomeScreen` (owns the controller, wraps subtree in the read
  endpoint, renders "Recipes" app bar + the target name), and the `buildApp` recipes-entry branch.
  `router.dart` — `AppRouter.toRecipes` now routes to `RecipesHomeScreen` (callers unchanged). **Removed**
  `lib/recipes/recipes_stub.dart` + its test (replaced).
- **`PaintPalette` not recreated** (ENGINE-1 owns it); only the source seam was added over it.
- **Gates:** `flutter analyze` clean; unit **510 green** (`flutter test --coverage`); coverage gate **100% on
  all 10 touched lib files** (vs `main`); integration **62 green** on the iOS sim under the verify lock —
  incl. bs-01's AC-11 "Finding recipes…" handoff now rendering the real `RecipesHomeScreen`.
- **Fix passes: 1/3** — first `flutter analyze` flagged a leftover `emit` test reference (removed with the
  method) + a `prefer_final_fields` info on `_state` (ignored — behaviour phases reassign it); re-ran clean.
- **Tokens / Time:** 14,660,317 · 44m 03s.

### Checkpoint / Handoff

- **Frozen for SCREEN-1 and the behaviour phases:**
  - `RecipeController({required sampleSource, paletteSource, mixingEngine, target, speech, router})` —
    `state` getter → `RecipeState`; `savedSamples` / `palettes` getters; actions throw until filled
    (`selectTarget`/`enterManualTarget` → RECIPE-3, `selectPalette` → ENGINE-2, `setMode` → ENGINE-6,
    `speakTarget`/`speakRecipe` → RECIPE-4). The first behaviour phase to mutate adds the private emit/notify
    path these route through.
  - `RecipeState {target, selectedPalette, recipes, mode (MixMode.wet/dry), manualError}` — immutable,
    value-equal, `const`-constructible; reconstruct (no `copyWith`) and notify, as bs-03 does.
  - `PaletteSource.palettes()` / `InMemoryPaletteSource(catalogue: […])` (empty default) — the ITEST harness
    seeds `PALETTE_MY_PAINTS` here.
  - `RecipeReadEndpoint` (`endpointKey = Key('recipe-read-endpoint')`, `.of(context)`) — the acceptance
    observation seam.
  - `AppDependencies.paletteSource` + `recipesEntry` (`RecipesEntry {target}`); `buildApp` opens on
    `RecipesHomeScreen` when `recipesEntry` is set (ITEST entry).
- **SCREEN-1** replaces `RecipesHomeScreen`'s shell body (`Scaffold`/`Text`) with the real recipes regions
  (E22–E25 + list + gamut banner) over the owned controller — **keep the "Recipes" app bar and a rendering of
  the target name so bs-01 AC-11 stays green.** Controller ownership + the read-endpoint wrapping stay in the
  home screen.
- **Verification commands** unchanged (RECIPE-1 handoff): `flutter analyze` · `flutter test --coverage` ·
  `dart run tool/coverage_gate.dart main` · integration under the lock on sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`. Always pass `-d <udid>` (no device ⇒ false green).
- **Known gaps / notes:** no behaviour yet (every action throws). Carry-over const-constructor coverage flake
  stands (re-run `--coverage` once if the gate flags an untouched file). Untracked bs-05..bs-14 specs +
  `docs/` sit in the tree from a prior branch; not part of bs-04 and not committed by this phase.

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

### Result

Target selection landed; AC-1 and AC-2 are un-pended and green. The controller sets the target from a saved
sample and from a range-validated manual CIELAB entry; the E22 selector sheet wires both.

- **Controller (`recipe_controller.dart`):** `selectTarget(sample)` emits a new state with the chosen target
  (palette/recipes/mode carried, `manualError` cleared); `enterManualTarget(coordinates)` validates CIELAB
  range (L\* 0–100, a\*/b\* within ±128, all finite) — out of range raises `manualError` and keeps the previous
  target **instance** unchanged, in range becomes a `confirmed` / "Entered by hand" target. Added the single
  `_emit` mutation path (reconstruct + notify, mirrors bs-03) and dropped the shell's `prefer_final_fields`
  ignore now `_state` is reassigned.
- **Target region (`target_region.dart`):** the inert "Choose target" button now opens a modal
  `_TargetSelectorSheet` listing `savedSamples` (tap → `selectTarget`) and a by-hand L\*/a\*/b\* form (submit →
  `enterManualTarget`; an unparseable field → `NaN`, refused); the manual error renders under the selector
  (`manualErrorKey`). "Speak target" stays inert (RECIPE-4).
- **Un-pended:** AC-1, AC-2 removed from `integration_test/bs04/pending.dart`; added to the guard's `unpended`
  set in `recipes_test.dart`. Flipped the E22 inert assertion in `recipes_screen_test.dart`; added
  `test/recipes/target_region_test.dart` (picker, valid/rejected/unparseable manual entry).
- **Gates:** `flutter analyze` clean; unit **529 green** (`flutter test --coverage`); coverage gate **100% on
  all 15 touched lib files** (`recipe_controller.dart` + `target_region.dart` changed). Integration **green on
  the iPhone 17 sim (`5AB9D06D…`) under the verify lock** — full suite `+75 ~10` (the 10 skips are the still
  pending AC-3..12); `TestAC01_ChooseSavedTarget` and `TestAC02_ManualTargetRefused` run and pass.
- **Grade gate:** an independent grader (fresh context) re-graded AC-1 and AC-2 against the implemented
  behaviour — **2×A, 0×B — PASS**; section appended to `behavior-test-completeness-bs-04-mixing-recipes.md`.
  No augmentations owned by RECIPE-3.
- **Fix passes: 2/3** (pass 1: missing `provenance` import + a test import + a double-underscore lint; pass 2:
  two uncovered per-field `onSubmitted` closures → one shared callback).
- **Tokens / Time:** 18,470,473 · 46m 17s active (46m 18s wall; 1 grader subagent included).

### Checkpoint / Handoff

- **Frozen for the behaviour phases:**
  - `RecipeController.selectTarget(Sample)` and `enterManualTarget(ColorCoordinates)` are live, routing through
    the private `_emit(RecipeState)` path (reconstruct + notify; no `copyWith`). **ENGINE-2**'s solve-on-change
    should call its solve inside/after `selectTarget` (and `selectPalette`); RECIPE-3 carries `recipes`
    unchanged for now (it does not solve).
  - Manual validation: `_inLabRange` (L\* 0–100, a\*/b\* ±128, finite). Out of range → `RecipeState.manualError`
    set and the target **instance** kept (AC-2 asserts identity); in range → a `Sample` named 'Manual target'
    with `Provenance(ProvenanceTier.confirmed, note: 'Entered by hand')`.
  - `TargetRegion` opens `_TargetSelectorSheet` (a modal bottom sheet) from the now-enabled "Choose target"
    button; `TargetRegion.manualErrorKey` anchors the error line. "Speak target" is still inert → **RECIPE-4**
    wires it in this same file (file-shared with RECIPE-4).
- **Parallel / merge note:** RECIPE-3 edited `recipe_controller.dart`, `target_region.dart`, `bs04/pending.dart`,
  `recipes_test.dart` (guard `unpended`), `recipes_screen_test.dart`, the grade grid, + added
  `test/recipes/target_region_test.dart`. **ENGINE-2 also edits `recipe_controller.dart`, `bs04/pending.dart`
  and the `recipes_test.dart` guard** — merge-risky, but the controller edits sit in disjoint method regions
  (`selectTarget`/`enterManualTarget` vs `selectPalette`/solve) and the pending/guard edits are disjoint AC rows,
  so a 3-way merge is clean when both anchor minimally.
- **Verification commands** unchanged (`export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` ·
  `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under the verify lock on sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (always `-d <udid>`; no device ⇒ false green). Run the integration
  suite from the worktree.
- **Known gaps / notes:** RECIPE-4 (speak) depends on ENGINE-2 (a recipe to speak); RECIPE-3 does not solve.
  Carry-over const-constructor coverage flake stands. Untracked bs-05..bs-14 specs + `docs/` are not part of
  bs-04.

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
