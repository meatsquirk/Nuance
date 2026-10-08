# Module SCREEN — mix-plan view

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/combinations/mixplan/screen/mix_plan_screen.dart` + per-region widgets: `colour_recipe_row.dart` (parts / predicted / ΔE00 / verdict / OUT OF GAMUT marker), `gamut_summary.dart`, `mix_plan_actions.dart` (speak + save)
**Depends on:** MIXPLAN (plan types + controller) · **Blocks:** ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `CombinationMixPlanScreen` (built by the `buildApp` mix-plan entry), bound to `MixPlanController`,
  reached from the bs-15 combination detail ("Mix from my paints"). Split per region so MIXPLAN-4
  (OOG/summary), MIXPLAN-6/7 (actions) each edit their own file.
- **Consumes:** `CombinationMixPlan` via the controller; reuses bs-04's recipe presentation widgets for the
  per-colour rows where possible (parts, predicted colour, verdict, OUT OF GAMUT) so presentation is consistent
  with the Recipes screen.
- **Reconciliation:** every colour row carries its name + numbers + verdict, never colour alone (SI label
  contract); the OUT OF GAMUT marker is text, not colour.

## Open gates

- none of its own.

## Phase 1 — Shell: mix-plan screen scaffold (SCREEN-1)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** MIXPLAN-2 · **Blocks:** ITEST-1
- **Files:** `mix_plan_screen.dart` + the per-region widget files above
- **Tasks:**
  1. Scaffold `CombinationMixPlanScreen` bound to the controller, reachable via `AppRouter.toCombinationMixPlan`.
  2. Render-only placeholders: a per-colour recipe row list, the gamut summary line, speak + save actions.
  3. Keep each region file-disjoint so later behaviour phases fill their own region.
  4. App still builds; existing suites green.
- **Exit criteria:** unit gate; existing suites green; screen renders placeholders bound to the controller.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
