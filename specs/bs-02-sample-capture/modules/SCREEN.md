# Module SCREEN — Capture screen UI

**Status:** In progress — SCREEN-1 (shell) done; SCREEN-2/3 (behavior) gated on G-3
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_screen.dart` and per-region widgets (`capture_eyedropper.dart`, `capture_controls.dart`, `capture_live_view.dart`); labels via bs-01's label-contract widgets.
**Depends on:** CAPTURE (controller + read endpoint), SOURCE (live feed, radius) · **Blocks:** ITEST-1 (needs the screen to drive), SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 6,759,706 | 13m 46s (13m 46s) |
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

### Result

Landed the Capture screen scaffold: four new `lib/capture` widgets and wired them into
`CaptureHomeScreen`. `capture_screen.dart` (`CaptureScreen`) is a `Scaffold`+AppBar "Capture" whose body is a
`ListenableBuilder` over the controller → `Column[ Expanded(CaptureLiveView), CaptureControls ]`, rebuilding
on every state change. `capture_live_view.dart` (`CaptureLiveView`, reads a plain `CaptureState`) renders a
placeholder feed surface (`liveViewKey`), the centred `CaptureEyedropper`, and the readings as **text** over
the feed — stability (`stabilityKey`), accuracy label (`accuracyKey`), low-light warning (`warningKey`, via
`Visibility`) — honouring bs-01's label contract. `capture_eyedropper.dart` (`CaptureEyedropper`) is a
centred placeholder reticle (`eyedropperKey`/`reticleKey`, fixed 20 px). `capture_controls.dart`
(`CaptureControls`) lays out E15–E21 as findable keyed buttons: E15/E16/E17/E20/E21 wired to their controller
tear-off (`dismissWarning`/`lock`/`calibrate`/`commit`/`toggleValueOnly`) — present but still deferred (a tap
surfaces the owning phase's `UnimplementedError`); E18 (radius) and E19 (import) are disabled placeholders
their behaviour phase (SCREEN-2 / SOURCE-3) enables. `build_app.dart`'s `CaptureHomeScreen` now renders
`CaptureScreen(controller:…)` inside the existing `CaptureReadEndpoint` (controller ownership + endpoint
wiring unchanged).

Verification (Flutter 3.47.6): `flutter analyze` clean. Unit **282 green (+18** across the four widgets).
Coverage gate `dart run tool/coverage_gate.dart main`: **100% on all 16 touched `lib` files, PASS**.
Integration `flutter test integration_test/`: bs-01's **17 green** (unchanged — no capture source in
`givenReadoutOf`). App-launches-to-Capture-with-all-regions proven at unit level (`build_app_test`,
`smoke_test` → Capture AppBar; `capture_screen_test` → live view + controls composed and bound). No AC
un-pended (shell), no augmentations, no exclusions. Fix passes: **1/3** (one run fixed two defects — a
duplicate `eyedropperKey` on both the widget and its inner `Center`, and the live view's `AspectRatio 3/4`
forcing the controls off-screen in a `ListView`; moved to `Column`+`Expanded`). Tokens 6,759,706 ·
time 13m 46s (13m 46s).

### Checkpoint / Handoff

- **Verification commands:** unchanged (PATH `~/development/flutter/bin`; `flutter analyze` /
  `flutter test --coverage` / `flutter test integration_test/` / `dart run tool/coverage_gate.dart main`).
- **Frozen interfaces (SCREEN-1):**
  - `CaptureScreen({required CaptureController controller})` — `lib/capture/capture_screen.dart`.
  - `CaptureLiveView({required CaptureState state})` — keys `liveViewKey`, `stabilityKey`, `accuracyKey`,
    `warningKey`.
  - `CaptureEyedropper()` — keys `eyedropperKey`, `reticleKey`; `placeholderReticleSize` (20).
  - `CaptureControls({required CaptureController controller})` — one key per element:
    `dismissWarningKey` (E15 `capture-e15-dismiss-warning`), `lockKey` (E16 `capture-e16-lock`),
    `calibrateKey` (E17 `capture-e17-calibrate`), `radiusKey` (E18 `capture-e18-radius`),
    `importKey` (E19 `capture-e19-import`), `captureKey` (E20 `capture-e20-capture`),
    `valueOnlyKey` (E21 `capture-e21-value-only`).
- **For ITEST-1 (the harness):** build the real app via `buildApp(AppDependencies(…, captureSource: Fake…))`
  → opens on `CaptureScreen`. The When helpers tap controls by the keys above
  (`whenLock` → `lockKey`, `whenCommit` → `captureKey`, `whenDismissWarning` → `dismissWarningKey`,
  `whenCalibrate` → `calibrateKey`, `whenToggleValueOnly` → `valueOnlyKey`, `whenSelectRadius` → E18,
  `whenImportPhoto` → E19). Observe readings as text by `stabilityKey`/`accuracyKey`/`warningKey`, or state via
  `CaptureReadEndpoint.endpointKey` → `.controller.state`. The never-pending smoke test can assert the live
  view (`liveViewKey`) + all seven E15–E21 keys render.
- **Known gaps / ownership notes:**
  - E15/E16/E17/E20/E21 are wired but their controller action still throws until CAPTURE-3..6 / SCREEN-3
    un-defer it — no screen change is then needed for those taps to work.
  - **E18 (radius)** is a disabled placeholder; SCREEN-2 builds the real 1/5/21 selector + reticle sizing in
    `capture_controls.dart` / `capture_eyedropper.dart` (both in its Files).
  - **E19 (import)** is a disabled placeholder with no controller action yet. SOURCE-3 adds the photo-import
    entry on the controller/source **and must enable E19** (wire `importKey.onPressed`) — that touches
    `capture_controls.dart`, which is **not** in SOURCE-3's current Files list. Flag for SOURCE-3 /
    `--reconcile` so the ownership is added (small augmentation), else AC-9's `whenImportPhoto` has no enabled
    control to tap.
  - Eyedropper centring (AC-1) and exact reticle sizes 8/20/44 (AC-3) are placeholders until SCREEN-2.
- **G-3** (approve the acceptance tests) still gates every behaviour phase; decided at ITEST-4.

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
