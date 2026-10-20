# Module CFG — Display + Onboarding screen swaps

**Status:** Done
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/display/**`, `lib/onboarding/screens/**` (screen/step widgets only — not controllers, read endpoints, `display/color_simulation.dart`, `grayscale_filter.dart` or `onboarding/engine/**`).
**Depends on:** ITEST (G-2) · **Blocks:** GUARD

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| CFG-1 | behavior | AC-10 | ✅ Done | 23.22M | 44m 06s (44m 06s) |

## Interface reconciliation

Consumes the bs-17 wrappers. Changes only the Display settings and Onboarding step presentation; the display
controller, simulation/daltonisation filters, spoken-output panel logic and the onboarding/assessment engine
are frozen (D-2). The simulated/daltonised preview colours are colour *data*, not chrome — they stay on the
bs-17 AC-14 exclusion list (D-4).

## Open gates

G-2 (approve the acceptance tests) ✅ resolved 2026-10-19 — Matt Quirk; CFG-1 unblocked and done. No open gates.

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

### Result — CFG-1 (✅ Done)

- **Landed (production, presentation-only, D-2):** followed the FLOW-1 house-style precedent — swap only the
  controls the tasks name, leave unnamed in-step buttons as `TextButton`.
  - `lib/display/settings_screen.dart` — the E47 CVD-simulation options (`simulationOptionKey`) and the theme
    options are now `PillButton` (selected → `.primary`, else `.secondary`; the ✓ mark kept so selection
    never rides on fill alone; keys stay on the pills so the bs-08/bs-10/`build_app` suites that drive them by
    key are unchanged). Each setting group (simulation, grayscale, severity, daltonization+no-profile, theme)
    is wrapped in a `SurfaceCard` via a new top-level `_settingGroup` helper, which inserts a transparent
    `Material` inside the card so the `SwitchListTile`s paint their ink on it (the framework asserts if a
    ListTile paints past a decorated box). New `_simulationOption` / `_themeOption` pill helpers.
  - `lib/onboarding/screens/lighting_step.dart` — content wrapped in `SurfaceCard` (+ transparent `Material`,
    it has `CheckboxListTile`s); `continueKey` → `PillButton.primary`.
  - `intake/screening/arrangement/threshold_step.dart` — content wrapped in `SurfaceCard` + `Padding`; the
    in-step answer/choice buttons left as `TextButton` (not named in the tasks, not superseded — FLOW-1 rule).
  - `onboarding_screen.dart` — `seeResultKey` ("See my result") → `PillButton.primary`.
  - `result_step.dart` — both the placeholder and assembled branches wrapped in `SurfaceCard` + `Padding`;
    `saveKey` → `PillButton.primary` (placeholder stays inert/`const`); one `SwatchCaption()` beside the
    simulated/original colour pair. The by-hand type picker choices (`typeChoiceKey`) left as `TextButton`.
- **Un-pended:** AC-10 (`pending.dart` row removed). Smoke pending-exemplar re-pointed AC-10 → AC-11 (owner
  GUARD-2); AC-10 added to the un-pended set.
- **Augmentation:** none owed, none added — a wholesale key-preserving swap of a fully-ad-hoc baseline (sim
  options, continue, seeResult, save were all `TextButton`s; lighting step a bare `Column`), so no co-presence
  surface a leftover control could linger on (grader-confirmed; the AC-6/AC-9/AC-10 fully-ad-hoc precedent,
  distinct from AC-8/ORG-1's partly-swapped case). AC-10 body unchanged from ITEST-3 (`git diff` empty).
- **Tests (sibling maintenance for the swap, no behaviour weakened):**
  - `integration_test/self_assessment_harness.dart` (bs-07) — `whenAnswerIntake` and `whenReportDiagnosis`
    gained `ensureVisible` before their taps: carding made the steps taller, so the intake controls now sit
    at/below the 600px fold like **every other** below-fold driver the harness already scrolls to (the taps
    and assertions are unchanged). This also resolved the previously-carried bs-07 **AC-4** off-lane flake.
  - Four unit tests swapped `widget<TextButton>` → `widget<PillButton>` on the continue/seeResult/save keys
    (`lighting_step_test`, `onboarding_screen_test`, `onboarding_host_test`, `result_step_test`); same
    `onPressed` enabled-state assertions kept. `typeChoiceKey` stays `TextButton` (not swapped).
- **Verification:** `flutter analyze` (touched lib + test) clean. Unit `flutter test --coverage test/` →
  **1676 pass**. Coverage gate `dart run tool/coverage_gate.dart 78aa8b2` → **100% line on all 8 touched lib
  files**. Acceptance (`-d flutter-tester`): `config_test.dart` (AC-10) **1✅**; `smoke_test.dart` **13✅/1-skip**
  (the AC-11 pending exemplar). Siblings one at a time: **bs-07 `self_assessment_test` 24✅/0** (AC-4 flake
  gone — the `ensureVisible` fix), **bs-10 `daltonization_test` 25✅/0**, **bs-08 `display_test` 20✅ + AC-9**
  (carried off-lane flake, verified unrelated — AC-9 taps the text "Speak whole comparison", which bs-18
  FLOW-1 re-homed to a `SpeakButton` FAB on the **compare** screen; CFG-1 touches neither that control nor
  that screen; failure reproduces under the exclusive lane too).
- **Grade gate: PASS** (independent fresh-subagent grader; grid `../behavior-test-completeness-bs-18-apply-visual-components.md`):
  AC-10 **straight A** (red at baseline, green on the swap; non-vacuous, keyed wholesale swap; two ◑-on-G4
  scope narrowings carried from ITEST-3, both justified). No drift in AC-1..AC-9 (CFG-1's change is confined
  to `lib/display/**` + `lib/onboarding/screens/**`, which no AC-1..AC-9 test exercises; no shared
  visual_application harness helper changed). **Straight A = 10 (AC-1..AC-10), A-core/B-pending = 0, plain-B = 0.**
- **Fix passes: 1/3** — one pass, **test-infra / layout only, no AC body weakened**: the first full run red on
  the `ListTile`-in-decorated-box framework assertion (SwitchListTiles/CheckboxListTiles directly inside the
  `SurfaceCard`) and, once that was fixed, on the bs-07 intake taps missing the now-below-fold controls →
  added the transparent `Material` inside the cards and `ensureVisible` to the two bs-07 intake drivers. All
  gates green thereafter.

### Checkpoint / Handoff — after CFG-1

- **Frozen interfaces (this phase):** the Display settings panel renders its simulation + theme options as
  `PillButton`s (keys unchanged) with each group in a `SurfaceCard`; every onboarding step's content sits in a
  `SurfaceCard`; `LightingStep.continueKey`, `OnboardingScreen.seeResultKey` and `ResultStep.saveKey` are
  `PillButton.primary`; the result step carries one `SwatchCaption` beside its colour pair. A later phase
  restyling these must keep those treatments or AC-10 / the sibling unit tests redden. The in-step
  answer/choice buttons (intake/screening/arrangement/threshold/result-type) remain `TextButton` by design.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout` on
  macOS): unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart <BASE>`; AC-10
  `flutter test -d flutter-tester integration_test/visual_application/config_test.dart`; siblings one at a
  time `integration_test/{self_assessment,daltonization,display}_test.dart` (loading two visual_application
  suites in one invocation hits the documented "Unable to start the app" launch flake).
- **Watch (carried):** the `SurfaceCard` is a decorated box — any `ListTile`/`SwitchListTile`/`CheckboxListTile`
  put directly inside one needs a transparent `Material` between them or the framework asserts. The onboarding
  host lays every step out in one `SingleChildScrollView`, so adding height (cards/padding) pushes lower
  controls below the 600px fold — every driver that taps one must `ensureVisible` first.
- **Known gaps / next:** CFG module complete; all 10 screen-swap ACs (AC-1..AC-10) done. **GUARD-1** (AC-12
  swatch-caption sweep) is now unblocked — every screen phase (CHROME/READ/FLOW/ORG/CFG) is done; then
  GUARD-2 (AC-11 single theme + AC-14 source-scan) → GUARD-3 (AC-13 a11y regression) → SIGNOFF-1, sequentially.
  Carried flakes: bs-06 palette AC-3/AC-5, bs-08 display AC-9 (FLOW-1-era "Speak whole comparison" label on the
  compare screen) stay Open in the Known flakes table — reproduce at merge-base, not regressions. (bs-07
  self_assessment AC-4 is no longer flaky after the CFG-1 `ensureVisible` fix.)
