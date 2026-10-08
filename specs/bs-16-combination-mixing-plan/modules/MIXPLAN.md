# Module MIXPLAN — per-colour solve orchestration

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/combinations/mixplan/combination_mix_plan.dart` (`CombinationMixPlan`/`ColourMixResult`) · `mix_plan_controller.dart` · `mix_plan_state.dart` · `mix_plan_read_endpoint.dart` · `mix_plan_speech.dart` · `lib/app/build_app.dart` (mix-plan entry) · `lib/app/router.dart` (`toCombinationMixPlan`) · scaffold: branch, `integration_test/bs16/pending.dart`
**Depends on:** bs-04 `MixingEngine`/`Recipe`/`PaintPalette`/`PaletteSource`, bs-15 `ColorCombination`/`WadaColor`/`ProjectSink`, bs-01 `Speech` · **Blocks:** SCREEN, ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ⬜ Next | | |
| 2 | shell | — | ⬜ Todo | | |
| 3 | behavior | AC-1, AC-2, AC-3 | ⬜ Todo | | |
| 4 | behavior | AC-5, AC-6 | ⬜ Todo | | |
| 5 | behavior | AC-4 | ⬜ Todo | | |
| 6 | behavior | AC-7 | ⬜ Todo | | |
| 7 | behavior | AC-8 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `CombinationMixPlan {ColorCombination source; List<ColourMixResult> results; int inGamut; int outOfGamut; String paletteName}`; `ColourMixResult {WadaColor colour; Recipe? best; bool outOfGamut}`; `MixPlanController` over `{MixingEngine, CombinationLibrary?, PaletteSource, Speech, ProjectSink, AppRouter}`; `MixPlanReadEndpoint`.
- **Consumes:** bs-04 `MixingEngine.inverse(target, PaintPalette, MixOptions)` → `List<Recipe>` with out-of-gamut; `Recipe` (parts/predicted/ΔE00/verdict); bs-15 `ColorCombination`/`WadaColor`, `ProjectSink.save`.
- **Reconciliation:** each `WadaColor.lab` is adapted to the engine's target type (a `Sample`/`ColorCoordinates`, whichever bs-04's `inverse` takes); the adapter is the only glue — no mixing logic is re-implemented. The `ProjectRecord` gains a mix-plan variant (bs-15 owns the base type; coordinate the shared `project_sink.dart` change).

## Open gates

- **G-3** (bs-04 merged) and **G-4** (bs-15 merged) block **MIXPLAN-1** and therefore every phase.

## Phase 1 — Scaffold (MIXPLAN-1)

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** G-1, G-3, G-4 · **Blocks:** MIXPLAN-2
- **Files:** branch `feat/bs-16-combination-mixing-plan` from `main` (post bs-04 + bs-15 merge); `integration_test/bs16/pending.dart` (8-AC pending runner); no product code
- **Tasks:**
  1. Branch from `main` once bs-04 and bs-15 are merged (verify both present).
  2. Record the baseline (unit + integ counts); confirm the coverage gate both ways.
  3. Add `integration_test/bs16/pending.dart` + `BS16_RUN_PENDING` plumbing (AC-1..8).
- **Exit criteria:** baseline recorded; gate proven; BS16 pending runner present; no `lib/` change.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — Shell: plan types, controller, entry (MIXPLAN-2)

- **Kind:** shell
- **Target AC:** — (read endpoint the tests observe)
- **Depends on:** MIXPLAN-1 · **Blocks:** SCREEN-1, ITEST-1
- **Files:** `combination_mix_plan.dart`, `mix_plan_controller.dart`, `mix_plan_state.dart`, `mix_plan_read_endpoint.dart`, `lib/app/build_app.dart` (mix-plan entry), `lib/app/router.dart` (`toCombinationMixPlan`), `project_sink.dart` (add the mix-plan `ProjectRecord` variant — coordinate with bs-15)
- **Tasks:**
  1. `CombinationMixPlan`/`ColourMixResult` (empty/null until solved); the adapter from `WadaColor` to the engine target.
  2. `MixPlanController`/state + `MixPlanReadEndpoint`; the solve/re-solve/speak/save methods **pend** behaviour.
  3. `buildApp` mix-plan entry behind `AppRouter.toCombinationMixPlan`, reached from the bs-15 combination detail.
- **Exit criteria:** unit gate; existing suites green; app builds with the route; endpoint readable; no behaviour.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — Behaviour: per-colour solve, palette-constrained, recipe detail (MIXPLAN-3)

- **Kind:** behavior
- **Target AC:** AC-1 (one recipe per colour), AC-2 (parts/predicted/ΔE00/verdict), AC-3 (only the selected palette)
- **Depends on:** ITEST-4 (G-2), MIXPLAN-2 · **Blocks:** MIXPLAN-4/5/6/7
- **Files:** `mix_plan_controller.dart`, `combination_mix_plan.dart`
- **Tasks:**
  1. For each `WadaColor`, call `MixingEngine.inverse(colour, selectedPalette, opts)`; take the best `Recipe` into a `ColourMixResult`; assemble the `CombinationMixPlan`.
  2. Carry the reused `Recipe`'s parts/predicted/ΔE00/verdict through to the result (AC-2) and ensure every recipe is palette-constrained (AC-3, reused from bs-04).
  3. Unit-test plan size = colour count, non-null best per reachable colour, palette constraint.
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-1, AC-2, AC-3; `TestAC01_RecipePerColour`, `TestAC02_RecipeDetail`, `TestAC03_PaletteConstrained` green.
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — Behaviour: out-of-gamut per colour + summary (MIXPLAN-4)

- **Kind:** behavior
- **Target AC:** AC-5 (unreachable colour marked OUT OF GAMUT), AC-6 (in/out summary)
- **Depends on:** MIXPLAN-3 · **Blocks:** SIGNOFF-1
- **Files:** `mix_plan_controller.dart`, `combination_mix_plan.dart`, SCREEN OOG/summary region
- **Tasks:**
  1. Apply bs-04's out-of-gamut rule per colour → `ColourMixResult.outOfGamut`; keep the nearest *as nearest*.
  2. Compute `inGamut`/`outOfGamut` counts on the plan (AC-6).
  3. Unit-test the mixed-gamut combination: the right colour flagged, correct counts.
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-5, AC-6; `TestAC05_ColourOutOfGamut`, `TestAC06_GamutSummary` green.
- **Augments:** none (fixture carries in- and out-of-gamut colours).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 5 — Behaviour: re-solve on palette switch (MIXPLAN-5)

- **Kind:** behavior
- **Target AC:** AC-4
- **Depends on:** MIXPLAN-3 · **Blocks:** SIGNOFF-1
- **Files:** `mix_plan_controller.dart`
- **Tasks:**
  1. On a `PaletteSource` active-selection change, re-run the whole plan against the new palette.
  2. Unit-test that every recipe references only the new palette after the switch.
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-4; `TestAC04_ReSolveOnSwitch` green.
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 6 — Behaviour: speak the plan (MIXPLAN-6)

- **Kind:** behavior
- **Target AC:** AC-7
- **Depends on:** MIXPLAN-3 · **Blocks:** SIGNOFF-1
- **Files:** `mix_plan_speech.dart`, `mix_plan_controller.dart`
- **Tasks:**
  1. Build one utterance over the plan: each colour's name + its recipe (paints + parts), reusing bs-04 recipe phrasing; speak via `Speech`.
  2. Unit-test the utterance + exactly-one.
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-7; `TestAC07_SpeakPlan` green.
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 7 — Behaviour: save the plan with its palette (MIXPLAN-7)

- **Kind:** behavior
- **Target AC:** AC-8
- **Depends on:** MIXPLAN-3 · **Blocks:** SIGNOFF-1
- **Files:** `mix_plan_controller.dart`, `project_sink.dart`
- **Tasks:**
  1. Save a mix-plan `ProjectRecord` (per-colour recipes + the palette name) to the open project via `ProjectSink`.
  2. Unit-test the saved record content incl. the palette name.
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-8; `TestAC08_SavePlan` green.
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
