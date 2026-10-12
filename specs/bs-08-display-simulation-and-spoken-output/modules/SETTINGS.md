# Module SETTINGS — display & simulation settings surface

**Status:** In progress — SETTINGS-1 done (shell)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/display/settings_screen.dart` (the panel: E46 grayscale toggle, E47 simulation selector, E48 severity slider, theme control), the open-from-any-screen entry affordance (E2) — a shared control surfaced app-wide (e.g. in the common app scaffold / a `DisplaySettingsButton` wired into every screen's chrome). Unit tests under `test/display/settings_*`.
**Depends on:** DISPLAY (`DisplayController` + `DisplayScope`) · **Blocks:** ITEST (observes the panel), SIGNOFF

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| SETTINGS-1 | shell | — | ✅ Done | 7,453,272 | 19m 27s (19m 27s) |
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

### Result — SETTINGS-1 (2026-10-12)

- **Landed (behaviour unchanged):** `lib/display/settings_screen.dart` with three widgets — `DisplaySettingsButton` (E2 entry, `openKey = ValueKey('display-e2-open-settings')`, a plain `IconButton` → `onPressed`); `DisplayChrome` (the shared chrome, stateful, wired as the `MaterialApp.builder` so it wraps every route — the entry sits top-right over the screen, tapping it opens the panel as a `Positioned.fill` overlay hosted in its own `Overlay`, closing returns to the screen underneath, which stays mounted); `DisplaySettingsScreen` (the panel, `panelKey`, reads `DisplayScope.of` through a `ListenableBuilder`). Panel controls bound to the frozen `DisplayController` setters: E47 simulation selector (`simulationKey`; off + one option per `CvdType` via `simulationOptionKey`, driving `setSimulationType(null|type)`, showing `defaultSimulationType` as the pre-selected type per D-2), E46 grayscale `SwitchListTile` (`grayscaleKey` → `setGrayscale`), E48 severity `Slider` 0..100→0..1 (`severityKey` → `setSimulationSeverity`), and the theme control (`themeKey`, `_ThemeControl`) shown per D-11 but **presentation only** (local state, drives no graded behaviour). No cross-field rules (D-3 mutual exclusion is DISPLAY-6); rendering effects are DISPLAY-3..7.
- **Wiring:** `lib/app/build_app.dart` — one line, `MaterialApp(builder: (context, child) => DisplayChrome(child: child!))`; the scopes stay above `MaterialApp`, so the panel reads the app-wide controller. No other screens edited (the shared chrome surfaces the entry everywhere).
- **Verification:** `flutter analyze` clean; `flutter test --coverage` = **899 unit pass** (885 baseline + 14 new); coverage gate **100% on all 9 touched lib files** (PASS); bs08 integration scaffold guard green (3/3 on sim). Fix passes: 2/3 — pass 1 dropped the `tooltip:` on the chrome buttons (a tooltip needs an `Overlay` ancestor, absent above the Navigator); pass 2 hosted the open panel in its own `Overlay` so the slider/switch find one (implementation moved both passes).
- **Tokens / Time:** see dashboard row (ledger `SETTINGS-1`).

### Checkpoint / Handoff — SETTINGS-1

- **Frozen for SPEECH-1 / ITEST-1 / SETTINGS-2 / DISPLAY-3..7:** `DisplaySettingsButton.openKey`; `DisplaySettingsScreen` keys `panelKey` / `closeKey` / `simulationKey` / `grayscaleKey` / `severityKey` / `themeKey` and `simulationOptionKey(CvdType?)` / `simulationOptions`; `DisplayChrome` as the app chrome (open/close overlay). The panel binds to the already-frozen `DisplayController` setters + `defaultSimulationType` — no controller changes. SETTINGS-2 un-pends AC-1 against these anchors (the entry + the three controls present from any screen); the DISPLAY behaviour phases make the setters *render* (they change no panel wiring).
- **Merge-risk:** SETTINGS-1 edited `lib/app/build_app.dart` (the `builder:` line). SPEECH-1 touches the same file (app-wide speech inject) — run after this, re-reading the `buildApp` assembly before editing.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`. Toolchain: `/Users/matthew.quirk/development/flutter/bin` on PATH; booted sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`.
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`). Chrome buttons carry no `tooltip` by design (no Overlay above the Navigator).

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
