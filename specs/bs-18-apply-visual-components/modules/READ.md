# Module READ — Readout + Capture screen swaps

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/readout/**`, `lib/capture/**` (screen/control/region widgets only — not controllers, sources, read endpoints or `capture/source/**` device literals).
**Depends on:** ITEST (G-2) · **Blocks:** GUARD

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| READ-1 | behavior | AC-3 | ⬜ Todo | | |
| READ-2 | behavior | AC-4 | ⬜ Todo | | |
| READ-3 | behavior | AC-5 | ⬜ Todo | | |

## Interface reconciliation

Consumes the bs-17 wrappers (`PillButton`, `SpeakButton`, `SurfaceCard`, `MonoLabel`, `SwatchCaption`).
Changes only the widgets rendering Capture/Readout controls and regions; capture controllers, sources,
sampling, stability/accuracy logic and read endpoints are frozen (D-2). The camera-device colour literals in
`lib/capture/source/**` and viewfinder/reticle/shutter-chrome literals stay on the bs-17 AC-14 exclusion list
(D-4).

## Open gates

G-2 blocks all three phases.

## Phase READ-1 — behavior: Capture controls (AC-3)

- **Kind:** behavior
- **Target AC:** AC-3 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** READ-2
- **Files:** `lib/capture/capture_controls.dart`, `lib/capture/capture_screen.dart`, `lib/capture/capture_eyedropper.dart` (shutter), `lib/capture/capture_accuracy.dart`.
- **Tasks:**
  1. Render the shutter as the 88px round capture button (anchor `shutterKey`); primary actions as `PillButton.primary`, secondary as `PillButton.secondary`; torch + import-photo as design-system controls.
  2. Remove the superseded `ElevatedButton`/`TextButton` capture actions.
- **Exit criteria:** `lib/capture` suite + bs-09 advanced-capture suite green; after READ-1, sequence READ-2 (shared `lib/capture`).
- **Acceptance gate:** un-pend AC-3; `TestAC03_CaptureControls` green with earlier ACs; sibling suites green.
- **Augments:** `TestAC03`: add the "superseded widget absent" assertions for the controls `capture_screen.dart` already partly swapped, so the test discriminates the full swap.

## Phase READ-2 — behavior: Capture warning overlap fix (AC-4)

- **Kind:** behavior
- **Target AC:** AC-4 (full)
- **Depends on:** READ-1 · **Blocks:** GUARD-1
- **Files:** `lib/capture/capture_live_view.dart` (the stacked warning banners).
- **Tasks:**
  1. Lay the warnings (low-light `warningKey`, torch colour-temp `torchWarningKey`, AE/AWB/AF-not-locked, no-reference-card) in a single vertical run so their rects never intersect (D-6); render each in the design-system banner style.
  2. Keep each warning's text, key, visibility condition and semantics unchanged (presentation only).
- **Exit criteria:** `lib/capture` + bs-09 suites green; warning strings/keys unchanged.
- **Acceptance gate:** un-pend AC-4; `TestAC04_CaptureWarnings` green (render rects non-overlapping) with earlier ACs; sibling suites green.

## Phase READ-3 — behavior: Readout cards + mono + speak FAB (AC-5)

- **Kind:** behavior
- **Target AC:** AC-5 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** GUARD-1
- **Files:** `lib/readout/value_region.dart`, `name_header.dart`, `space_selector.dart`, `provenance_region.dart`, `actions_bar.dart`, `temperature_line.dart`, `readout_screen.dart`.
- **Tasks:**
  1. Wrap the value/name/colour-space regions in `SurfaceCard`; render field eyebrows as `MonoLabel`; render the speak action as `SpeakButton` (standard size).
  2. Remove the ad-hoc `Card`/`IconButton`/header widgets these superseded.
- **Exit criteria:** `lib/readout` suite + bs-01 colour-readout + bs-08 spoken-output suites green.
- **Acceptance gate:** un-pend AC-5; `TestAC05_Readout` green with earlier ACs; sibling suites green.
- **Augments:** `TestAC05`: add "old `Card`/plain speak `IconButton` absent" for the regions `value_region.dart` already partly swapped.
