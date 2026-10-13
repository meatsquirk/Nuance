# Module SETTINGS — display & simulation settings surface

**Status:** ✅ Done — SETTINGS-1 (shell) + SETTINGS-2 (AC-1 behaviour) done
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/display/settings_screen.dart` (the panel: E46 grayscale toggle, E47 simulation selector, E48 severity slider, theme control), the open-from-any-screen entry affordance (E2) — a shared control surfaced app-wide (e.g. in the common app scaffold / a `DisplaySettingsButton` wired into every screen's chrome). Unit tests under `test/display/settings_*`.
**Depends on:** DISPLAY (`DisplayController` + `DisplayScope`) · **Blocks:** ITEST (observes the panel), SIGNOFF

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| SETTINGS-1 | shell | — | ✅ Done | 7,453,272 | 19m 27s (19m 27s) |
| SETTINGS-2 | behavior | AC-1 | ✅ Done | 3,579,655 | 12m 31s (12m 31s) |

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

### Result — SETTINGS-2 (2026-10-12)

- **Pure un-pend — no `lib/` change.** SETTINGS-1 already built the whole AC-1 surface (the E2 entry via `DisplayChrome`/`MaterialApp.builder`, and the panel's simulation selector E47, grayscale toggle E46 and theme control D-11), so AC-1 was recorded *green at baseline*. This phase only un-pended it: deleted the `'AC-1': 'SETTINGS-2'` row from `integration_test/bs08/pending.dart`, and added `'AC-1'` to the scaffold-guard `unpended` set in `integration_test/display_test.dart` (so the guard now expects `pendingACs = {AC-8, AC-9, AC-10}`). No production code, no other AC test body touched; no augmentation (this phase builds no new behaviour, so no already-green test can assert more).
- **Verification:** `flutter analyze` clean; `flutter test --coverage` = **931 unit pass**; coverage gate **100% on all 14 touched lib files** (PASS — no lib touched this phase, feature-wide coverage intact). Acceptance (`display_test.dart` on sim `5AB9D06D…`): default **+18 pass / ~3 skipped** (was 17/4 — AC-1 now runs and passes; only AC-8/9/10 remain pending); run-pending **+21 all pass** (AC-1 un-pended and green). Fix passes: 0/3.
- **Grade gate:** fresh adversarial subagent re-graded every un-pended AC test + the edited scaffold guard → **8 A / 0 below A** (AC-1..AC-7 + the `pending map is exactly the still-pending ACs` guard). AC-1 fully discriminates its own Then (rejects a surface missing any of the three spec-named controls / an entry that does not open the panel), asserts at the step's grain (does not over-assert the severity slider AC-1's Then omits). AC-2..AC-7 unchanged (unreachable by a test-only AC-1 un-pend). Grid: `behavior-test-completeness-bs-08-display-simulation-and-spoken-output.md` § *Phase graded: SETTINGS-2*.
- **Tokens / Time:** see dashboard row (ledger `SETTINGS-2`).

### Checkpoint / Handoff — SETTINGS-2

- **SETTINGS module complete.** AC-1 ✅ (un-pended + green + grade A). No SETTINGS phase remains. The frozen anchors from SETTINGS-1 (`DisplaySettingsButton.openKey`, the panel keys, `DisplayChrome` as app chrome) are unchanged.
- **Remaining for the feature:** the speech chain SPEECH-2 → SPEECH-3 → SPEECH-4 (AC-8/9/10), then SIGNOFF-1. SETTINGS owns no file the speech chain touches, so they are independent.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (default; add `--dart-define=BS08_RUN_PENDING=true` for run-pending). Toolchain: `/Users/matthew.quirk/development/flutter/bin` on PATH; booted sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; device lane shared → `coord.sh with-lock` (`FNP_COORD_REPO=/Users/matthew.quirk/Nuance`).
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`).
