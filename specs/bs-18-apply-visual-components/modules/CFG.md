# Module CFG — Display + Onboarding screen swaps

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/display/**`, `lib/onboarding/screens/**` (screen/step widgets only — not controllers, read endpoints, `display/color_simulation.dart`, `grayscale_filter.dart` or `onboarding/engine/**`).
**Depends on:** ITEST (G-2) · **Blocks:** GUARD

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| CFG-1 | behavior | AC-10 | ⬜ Todo | | |

## Interface reconciliation

Consumes the bs-17 wrappers. Changes only the Display settings and Onboarding step presentation; the display
controller, simulation/daltonisation filters, spoken-output panel logic and the onboarding/assessment engine
are frozen (D-2). The simulated/daltonised preview colours are colour *data*, not chrome — they stay on the
bs-17 AC-14 exclusion list (D-4).

## Open gates

G-2 blocks CFG-1.

## Phase CFG-1 — behavior: Display + Onboarding (AC-10)

- **Kind:** behavior
- **Target AC:** AC-10 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** GUARD-1
- **Files:** `lib/display/settings_screen.dart`, `lib/display/spoken_output_panel.dart`; `lib/onboarding/screens/{onboarding_screen,intake_step,screening_step,arrangement_step,threshold_step,lighting_step,result_step,progress_region}.dart`.
- **Tasks:**
  1. Display: render the view-switch and option controls as `PillButton` or a design-system segmented control; render setting groups in `SurfaceCard`.
  2. Onboarding: wrap each step's content in `SurfaceCard`; render next/back as `PillButton`; style the result-step colour pairs (with their `SwatchCaption`).
  3. Remove the superseded `ElevatedButton`/`TextButton`/`Card` on these screens.
- **Exit criteria:** `lib/display` + `lib/onboarding` suites + bs-07 self-assessment + bs-08 display-simulation + bs-10 daltonization suites green (expect the carried display AC-9 and self_assessment AC-4 flakes off the exclusive lane — not regressions). This phase touches two dirs but one AC; run alone to keep the regression surface legible.
- **Acceptance gate:** un-pend AC-10; `TestAC10_DisplayOnboarding` green with earlier ACs; sibling suites green (carried flakes excepted).
