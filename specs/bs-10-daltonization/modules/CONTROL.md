# Module CONTROL — daltonization settings control

**Status:** In progress — CONTROL-1 (shell) done; CONTROL-2 (behavior, AC-10) blocked by G-2
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** the daltonization region of bs-08's display-settings panel — the on/off toggle and the
no-saved-profile affordance (path confirmed in DALT-1 against merged bs-08, e.g. `lib/display/display_settings_panel.dart`
or a new `lib/display/regions/daltonization_region.dart`) (+ its widget test).
**Depends on:** DALT (shell — `DisplayController.setDaltonization`), bs-07 (`CvdProfileReadEndpoint.hasSavedProfile`) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| CONTROL-1 | shell | — | ✅ Done | 2.49M | 14m 20s |
| CONTROL-2 | behavior | AC-10 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** a keyed daltonization toggle control (wired to `DisplayController.setDaltonization`) and a keyed
  no-saved-profile region, both inside bs-08's existing display-settings panel.
- **Consumes:** `DisplayController.setDaltonization` (DALT shell); `CvdProfileReadEndpoint.hasSavedProfile`
  (bs-07) to decide whether a profile has actually been **saved** (D-4 — not the const default `cvdProfile`).
- **Reconciliation:** the toggle lives alongside bs-08's simulation/grayscale/theme controls in the one
  settings surface; it does not create a second settings screen. CONTROL-1 confirms the panel's real
  insertion point against merged bs-08.

## Open gates

- CONTROL-1 depends on DALT-2 (the `setDaltonization` method). CONTROL-2 is blocked by **G-2** (acceptance
  tests approved), like every behavior phase.

## Phase CONTROL-1 — shell: toggle + no-profile placeholder

- **Kind:** shell
- **Target AC:** — · **Depends on:** DALT-2 · **Blocks:** ITEST-1
- **Files:** the daltonization region of the display-settings panel (+ widget test)
- **Tasks:**
  1. Add a keyed daltonization on/off toggle to bs-08's settings panel, wired to
     `DisplayController.setDaltonization`.
  2. Add a keyed no-saved-profile region (empty placeholder for now — rendering only).
- **Exit criteria:** unit gate; the existing suite stays green; the toggle drives `daltonization` and the
  placeholder region is reachable by a keyed finder (so ITEST can observe it). No AC behaviour yet.

## Phase CONTROL-2 — AC-10: no saved profile → self-assessment needed

- **Kind:** behavior
- **Target AC:** AC-10 · **Depends on:** CONTROL-1, bs-07 `CvdProfileReadEndpoint`, ITEST-3 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** the daltonization region (+ widget test). **Shares `daltonization_test.dart`** with the DALT
  behavior phases → sequence it (merge-risky).
- **Tasks:** when `CvdProfileReadEndpoint.hasSavedProfile` is false, the control reports that a self-assessment
  is needed before colours can be remapped, and no remap is applied; when a profile is saved, that message is
  absent and the remap applies.
- **Acceptance gate:** un-pend AC-10; `TestAC10_NoProfileNeedsAssessment` green (no-profile → message shown +
  no remap; control: saved profile → message absent + remap applies), all other ACs already delivered.

### Result — CONTROL-1  <!-- 2026-10-13 -->

- **Insertion point confirmed:** bs-08's panel is `lib/display/settings_screen.dart`
  (`DisplaySettingsScreen`, read through `DisplayScope.of`), not a separate screen — the daltonization
  controls join the existing simulation/grayscale/severity/theme controls in the one `ListView` (no second
  settings surface).
- **Daltonization toggle:** added a keyed `SwitchListTile` (`daltonizationKey =
  'display-bs10-daltonization'`) titled "Daltonize colours", `value: settings.daltonization`,
  `onChanged: controller.setDaltonization` — drives `DisplayController.setDaltonization` (DALT-2). An
  independent axis (D-3/D-5): toggling it leaves simulation/grayscale untouched. Beyond the drawn mock
  (scope §5.4) so it carries no wireframe element id.
- **No-saved-profile region:** added a keyed placeholder (`noProfileRegionKey = 'display-bs10-no-profile'`,
  an empty `SizedBox`) — reachable by a keyed finder so ITEST/CONTROL-2 can observe it; render-only, no
  behaviour. CONTROL-2 (AC-10) fills it from `CvdProfileReadEndpoint.hasSavedProfile` (D-4).
- **Gates:** `flutter analyze` (touched files) clean · `flutter test --coverage` **1239 unit pass** (+2:
  toggle drives setDaltonization both ways + leaves other axes; placeholder reachable; plus key assertions) ·
  `dart run tool/coverage_gate.dart main` → **100% on all 8 touched files** (settings_screen.dart included) ·
  full `integration_test/` on booted iPhone 17 (`-d 5AB9D06D…`, under `coord.sh with-lock`) → **197 pass**,
  exit 0 (existing suite unchanged — nothing broke). Acceptance: n/a (no bs-10 AC tests until ITEST).
- Coverage (touched `lib/`): 100%. Fix passes: 0/3 (all gates green on first run).
- Tokens/time: 2.49M · 14m 20s (1 session).
- Closed by: unit + coverage gates green; existing unit + integration suites green; controls keyed and wired.

### Checkpoint / Handoff — CONTROL-1

- **Frozen for ITEST-1 / CONTROL-2:**
  - `DisplaySettingsScreen.daltonizationKey` (`'display-bs10-daltonization'`) — the toggle wired to
    `DisplayController.setDaltonization`; ITEST drives/observes daltonization through it.
  - `DisplaySettingsScreen.noProfileRegionKey` (`'display-bs10-no-profile'`) — the no-saved-profile region,
    an empty placeholder now; **CONTROL-2 (AC-10)** fills it so that when
    `CvdProfileReadEndpoint.hasSavedProfile` is false it reports a self-assessment is needed and no remap
    applies, and when a profile is saved the message is absent and the remap applies. CONTROL-2 **shares
    `daltonization_test.dart`** with the DALT behaviour phases → sequence it (merge-risky), and it is
    blocked by **G-2**.
- **Verification commands:** unchanged from DALT-2 — Flutter SDK not on default PATH (prepend
  `/Users/matthew.quirk/development/flutter/bin`); `flutter analyze` · `flutter test --coverage` ·
  `dart run tool/coverage_gate.dart main` (host); integration on a **booted** sim only
  (`flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` under
  `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-10-daltonization <PHASE> --wait 900 --
  bash -c 'cd /Users/matthew.quirk/Nuance-bs10 && …'`). macOS has no `timeout`; redirect long sim runs.
- **Known gaps:** the no-profile region is an empty placeholder (CONTROL-2); the daltonization remap is
  still identity (DALT-3); no bs-10 harness/`daltonization_test.dart` yet (ITEST-1, now unblocked — it
  depends on DALT-2 **and** CONTROL-1, both done). Carries the D-8 sim/dalt gap note as context only
  (out of bs-10 scope, D-5).
