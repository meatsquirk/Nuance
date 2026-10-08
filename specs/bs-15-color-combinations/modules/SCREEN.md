# Module SCREEN — Combinations screen UI

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/combinations/screen/combinations_screen.dart` + per-region widgets: `anchor_selector.dart`, `suggestion_list.dart`, `combination_detail.dart` (per-colour rows + confusion flag + provenance), `browse_search_bar.dart`, `combination_actions.dart` (speak + save)
**Depends on:** COMBO (controller + state), LIB (types) · **Blocks:** ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `CombinationsHomeScreen` (built by the `buildApp` combinations entry) bound to the
  `CombinationController`. Split into per-region widget files so each behaviour phase (COMBO-4 detail rows,
  COMBO-6 confusion flag, LIB-4 browse/search, COMBO-5/7 actions) edits its **own** region, file-disjoint.
- **Consumes:** `CombinationState` via the controller; renders names/L/C/h/warm-cool, flags and the reference
  label supplied by the COMBO behaviour phases (the shell renders placeholders only).
- **Reconciliation:** uses the shared accessible widgets (`ColorChip` takes text; status never a bare dot) per
  the SI label contract — every colour row carries its name + numbers, never colour alone (AC-5).

## Open gates

- none of its own (consumes COMBO/LIB outputs; the gates live on those phases).

## Phase 1 — Shell: Combinations screen scaffold (SCREEN-1)

- **Kind:** shell
- **Target AC:** — (the observable surface the acceptance tests drive)
- **Depends on:** COMBO-1 · **Blocks:** ITEST-1
- **Files:** `lib/combinations/screen/combinations_screen.dart` + the per-region widget files above
- **Tasks:**
  1. Scaffold `CombinationsHomeScreen` bound to the controller, reachable via `AppRouter.toCombinations`.
  2. Lay out the regions as **render-only placeholders**: anchor selector (saved samples; owned paints when a
     `PaletteSource` is present), suggestion list, combination detail (per-colour rows, confusion-flag slot,
     provenance slot), browse/search bar, speak + save actions.
  3. Keep each region in its own widget file so later behaviour phases fill their own region without collisions.
  4. Ensure the app still builds and the existing suites stay green.
- **Exit criteria:** unit gate; existing suites green; the screen renders placeholders bound to the controller;
  each region is file-disjoint.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
