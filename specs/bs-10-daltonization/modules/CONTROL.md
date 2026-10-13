# Module CONTROL — daltonization settings control

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** the daltonization region of bs-08's display-settings panel — the on/off toggle and the
no-saved-profile affordance (path confirmed in DALT-1 against merged bs-08, e.g. `lib/display/display_settings_panel.dart`
or a new `lib/display/regions/daltonization_region.dart`) (+ its widget test).
**Depends on:** DALT (shell — `DisplayController.setDaltonization`), bs-07 (`CvdProfileReadEndpoint.hasSavedProfile`) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| CONTROL-1 | shell | — | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
