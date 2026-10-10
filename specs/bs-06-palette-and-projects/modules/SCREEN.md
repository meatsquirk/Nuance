# Module SCREEN — Palette screen

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/palette/palette_screen.dart` + its region widgets, `lib/app/build_app.dart` (PaletteScreen entry marker + home selection), `lib/app/router.dart` (route to bs-07 entry placeholder)
**Depends on:** PALETTE (controller + read endpoint), PROJECT (controller + read endpoint), bs-03/07 `CvdProfile` · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-1 | ⬜ Todo | | |
| 3 | behavior | AC-11 | ⬜ Todo | | |

## Interface reconciliation

- The Palette screen is selected by a new entry marker on `AppDependencies` (same priority-ordered pattern as `captureSource`/`comparisonEntry`/`recipesEntry` in `buildApp`).
- Keyed regions (stable `static Key`s) for the paint list, provenance legend, palette selector, projects list and vision-profile card, so the ITEST harness can find them; read endpoints from PALETTE/PROJECT are mounted here.
- AC-11 reads the injected `CvdProfile` (D-7) and routes to a **bs-07 self-assessment entry placeholder** — bs-07 is unbuilt; the route target is a placeholder this module owns, replaced when bs-07 lands.

## Open gates

- **G-2** blocks Phases 2–3 (behavior). Phase 1 (shell) depends only on PALETTE-1/PROJECT-1.

## Phase 1 — Shell: screen, regions, controls, nav

- **Kind:** shell · **Target AC:** — · **Depends on:** PALETTE-1, PROJECT-1 · **Blocks:** ITEST-1, SCREEN-2, SCREEN-3
- **Files:** `lib/palette/palette_screen.dart`, region widgets in `lib/palette/` / `lib/widgets/`, `lib/app/build_app.dart`, `lib/app/router.dart`
- **Tasks:**
  1. Palette screen scaffold with keyed regions (paint list, legend, palette selector, projects list, vision-profile card) rendering placeholders; E31 selector, E32 add, E33 open, E34 export controls present but inert.
  2. Mount `PaletteReadEndpoint` + `ProjectReadEndpoint`; add the PaletteScreen entry marker + `buildApp` home selection; add a bs-07-entry placeholder route.
- **Exit criteria:** unit gate on touched files; existing suite green; screen renders with empty state and all region keys resolvable.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — AC-1 switch views

- **Kind:** behavior · **Target AC:** AC-1 (full) · **Depends on:** SCREEN-1, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/palette/palette_screen.dart`
- **Tasks:** E31 selector toggles the screen between the My-paints view and the Projects view (one visible at a time).
- **Acceptance gate:** un-pend AC-1; `palette_test.dart` green — Projects region shown and paint-list region gone after the toggle.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — AC-11 vision-profile card

- **Kind:** behavior · **Target AC:** AC-11 (full) · **Depends on:** SCREEN-1, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/palette/palette_screen.dart` (vision-profile card widget), `lib/app/router.dart`
- **Tasks:** the vision-profile card shows the current estimate from the injected `CvdProfile` (e.g. "deutan-type, moderate"); choosing "retake the self-assessment" navigates to the bs-07 self-assessment entry placeholder.
- **Acceptance gate:** un-pend AC-11; suite green — the estimate text is shown AND navigation to the self-assessment entry is observed.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->
