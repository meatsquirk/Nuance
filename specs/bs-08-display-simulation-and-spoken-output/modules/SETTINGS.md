# Module SETTINGS — display & simulation settings surface

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/display/settings_screen.dart` (the panel: E46 grayscale toggle, E47 simulation selector, E48 severity slider, theme control), the open-from-any-screen entry affordance (E2) — a shared control surfaced app-wide (e.g. in the common app scaffold / a `DisplaySettingsButton` wired into every screen's chrome). Unit tests under `test/display/settings_*`.
**Depends on:** DISPLAY (`DisplayController` + `DisplayScope`) · **Blocks:** ITEST (observes the panel), SIGNOFF

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| SETTINGS-1 | shell | — | ⬜ Todo | | |
| SETTINGS-2 | behavior | AC-1 | ⬜ Todo | | |

## Interface reconciliation

- **Consumes:** `DisplayScope.of(context)` → `DisplayController`; the panel's controls call `setSimulationType` / `setSimulationSeverity` / `setGrayscale` (DISPLAY). The selector defaults its initial type from `AppDependencies.cvdProfile` (D-2).
- **Reachable from any screen (AC-1):** the entry (E2) is surfaced through the shared app chrome, so every screen (readout, capture, comparison, recipes, palette) exposes it. The panel is pushed/shown over the current screen; it does not replace the feature screens.
- **Theme control (D-11):** the panel **shows** a theme (light/dark) control to satisfy AC-1's "theme controls are shown", but its behaviour is out of scope (spec boundary) — a presentation affordance only, not wired to behaviour this feature grades.

## Open gates

- **G-2** (acceptance tests approved) blocks SETTINGS-2.

## Phase SETTINGS-1 — shell: entry + panel scaffold

- **Kind:** shell
- **Target AC:** —
- **Depends on:** DISPLAY-2 · **Blocks:** SPEECH-1, ITEST-1, SETTINGS-2
- **Files:** `lib/display/settings_screen.dart`, the shared entry affordance, `lib/app/build_app.dart` (surface the entry in the common chrome). Tests under `test/display/`.
- **Tasks:**
  1. Add the open-display-settings entry (E2) to the shared app chrome so it is present on every screen; opening it shows the settings panel.
  2. Build the panel scaffold with keyed regions: the simulation selector (E47), the value-only grayscale toggle (E46), the severity slider (E48) and a theme control (E? / D-11) — controls present and wired to the `DisplayController` setters, but the *rendering* consequences live in the DISPLAY behavior phases.
  3. Keyed finders for each region so the acceptance suite can locate them.
- **Exit criteria:** unit gate (100% on the new files); existing suites green; the panel opens from a screen and shows the four controls (as a shell — their effects are DISPLAY's behavior phases).

## Phase SETTINGS-2 — AC-1 open settings from any screen

- **Kind:** behavior
- **Target AC:** AC-1 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** —  *(independent of the simulation chain; may run in parallel)*
- **Files:** `lib/display/settings_screen.dart`, the shared entry affordance
- **Tasks:** opening the display and simulation settings (E2) from any screen shows the surface with the simulation selector (E47), the grayscale toggle (E46) **and** the theme control (D-11) all present.
- **Exit criteria:** unit gate; existing suites green.
- **Acceptance gate:** un-pend AC-1; `display_test.dart` green (`TestAC01_OpenDisplaySettings`).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d <udid>`
