# Module SCREEN — Capture screen UI

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_screen.dart` and per-region widgets (`capture_eyedropper.dart`, `capture_controls.dart`, `capture_live_view.dart`); labels via bs-01's label-contract widgets.
**Depends on:** CAPTURE (controller + read endpoint), SOURCE (live feed, radius) · **Blocks:** ITEST-1 (needs the screen to drive), SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-1, AC-3 | ⬜ Todo | | |
| 3 | behavior | AC-10 | ⬜ Todo | | |

## Interface reconciliation

- The Capture screen binds to `CaptureController` and renders the wireframe regions S1.R1, E15–E21: live view
  (E? / body), dismiss low-light warning (E15), exposure/focus lock (E16), calibrate with reference card
  (E17), sampling radius selector (E18), import photo (E19), capture sample (E20), value-only preview (E21),
  plus the centre eyedropper and stability indicator text.
- Every interactive/coloured element carries a text/label per bs-01's label contract (no meaning in colour
  alone); the stability indicator, accuracy label and warning are text, not bare colour.
- Reticle sizes are exact: 1 px → 8 px, 5 px → 20 px, 21 px → 44 px (AC-3).

## Open gates

- **G-3 (approve tests)** blocks SCREEN-2/3 (behavior).

## Phase 1 — Shell: Capture screen scaffold

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CAPTURE-2 · **Blocks:** ITEST-1
- **Files:** `lib/capture/capture_screen.dart`, `capture_live_view.dart`, `capture_controls.dart`, `capture_eyedropper.dart`.
- **Tasks:**
  1. Capture screen scaffold bound to the controller, with findable placeholder regions for E15–E21, the live
     view, the eyedropper and the stability indicator (keys/labels present; behaviour deferred).
  2. Render the controller's live feed as the view (placeholder colour acceptable); no sampling UI behaviour yet.
- **Exit criteria:** unit gate passes; `flutter test` green; app launches to a Capture screen showing all
  regions as placeholders.
- **Acceptance gate:** *(n/a — shell)*

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — Behavior: eyedropper + radius selector + reticle (AC-1, AC-3)

- **Kind:** behavior
- **Target AC:** AC-1 (full), AC-3 (full — selector + reticle; the radius-driven averaging is SOURCE-2)
- **Depends on:** SOURCE-2, SCREEN-1, G-3 · **Blocks:** SCREEN-3, SIGNOFF-1 · ∥ SOURCE-3, CAPTURE-4
- **Files:** `lib/capture/capture_screen.dart`, `capture_eyedropper.dart`, `capture_controls.dart`.
- **Tasks:**
  1. Centre-point eyedropper marker positioned at the live-view centre (AC-1).
  2. Radius selector (E18) that sets `controller.radiusPx` to 1 / 5 / 21 px; the reticle resizes to
     8 / 20 / 44 px to match (AC-3).
- **Exit criteria:** un-pend AC-1, AC-3; run-pending green; coverage 100% touched; grade A (re-grade all
  un-pended AC tests, including AC-2 whose radius now also comes via the selector).
- **Acceptance gate:** un-pend AC-1, AC-3; `TestAC01_Eyedropper` + `TestAC03_RadiusSelector` green (eyedropper
  centred; reticle sizes exact; averaging follows the selected radius via SOURCE-2).
- **Augments:** none (AC-2 stays within SOURCE-2; G6 — don't extend AC-2's test here).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — Behavior: value-only grayscale preview (AC-10)

- **Kind:** behavior
- **Target AC:** AC-10 (full)
- **Depends on:** SCREEN-2 (serial — same screen file), G-3 · **Blocks:** SIGNOFF-1
- **Files:** `lib/capture/capture_screen.dart`, `capture_live_view.dart`, `capture_controls.dart`.
- **Tasks:**
  1. Value-only toggle (E21): renders the live-feed widget in grayscale (saturation-0 / value-only filter on
     the feed) and sets the control label to "✓ Value".
- **Exit criteria:** un-pend AC-10; run-pending green; coverage 100% touched; grade A.
- **Acceptance gate:** un-pend AC-10; `TestAC10_ValueOnly` green (feed rendered grayscale; control reads "✓ Value").
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
