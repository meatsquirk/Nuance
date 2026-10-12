# Module SCREEN — Capture screen: torch control, multi-point readings, send-to-comparison

**Status:** In progress — SCREEN-1 done; SCREEN-2/3 are behaviour (blocked by G-2)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_screen.dart`, `lib/capture/capture_controls.dart`,
`lib/capture/capture_live_view.dart`, and any new Capture-screen widgets (torch control + warning banner,
multi-point markers + readings list, send-to-comparison control)
**Depends on:** CAPTURE-2 (controller surface) · **Blocks:** SIGNOFF-1

> No wireframe draws these controls (the spec is proposed ahead of any mock). Key/label choices here are
> provisional and should be re-linked when a wireframe revision adds the UX; they are named so acceptance
> tests can find them, not frozen UX.

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| SCREEN-1 | shell | — | ✅ Done | 5,909,827 | 11m 12s |
| SCREEN-2 | behavior | AC-1 | ⬜ Todo | | |
| SCREEN-3 | behavior | AC-4 | ⬜ Todo | | |

## Interface reconciliation

- **New controls on `CaptureControls` (extends bs-02's E15–E21 Wrap):** a torch toggle (new key, e.g.
  `torchKey`) → `controller.turnTorchOn/Off`; a "sample points" action → `controller.sampleMarkedPoints`;
  a "send to comparison" action over two selected readings → `controller.sendPairToComparison`.
- **Warning banner:** a Visibility-gated banner reading `state.torchWarning` (sibling to bs-02's low-light
  `warningKey`), with its own key so AC-1 can find its colour-temperature text.
- **Multi-point markers + readings list (`CaptureLiveView` / new widget):** the marked points draw on the
  live view at their positions; a readings list renders each `MultiPointReading` with its position and its
  own colour value (each with a label — the label contract, SI, bars a bare swatch).
- Reads a plain `CaptureState` (as bs-02's live view does); no controller logic in widgets.

## Open gates

G-2 (test review) blocks SCREEN-2/3 as behavior phases.

## Phase SCREEN-1 — shell: placeholders for the new controls

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CAPTURE-2 · **Blocks:** ITEST-1
- **Files:** `capture_controls.dart`, `capture_live_view.dart`, `capture_screen.dart`, new widget file(s)
- **Tasks:**
  1. Add inert placeholders bound to the controller: torch toggle + warning banner, a "sample points"
     action, a multi-point readings list region, a "send to comparison" control. Keys defined.
  2. No behaviour (the warning banner is empty until the controller sets it; the readings list is empty).
- **Exit criteria:** 100% coverage on touched widgets; `flutter analyze` clean; the app still opens on the
  Capture screen and existing suites stay green.

## Phase SCREEN-2 — behavior: torch control + colour-temperature warning banner (AC-1)

- **Kind:** behavior
- **Target AC:** AC-1 (full)
- **Depends on:** CAPTURE-3 (torch mechanism + warning string), ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `capture_controls.dart`, `capture_live_view.dart` (banner)
- **Tasks:**
  1. The torch control calls `controller.turnTorchOn/Off` and reflects `state.torchOn`.
  2. The warning banner shows `state.torchWarning` when set; its text (from CAPTURE-3) names the torch colour
     temperature biasing the reading.
- **Exit criteria:** `flutter analyze` clean; 100% coverage on touched widgets.
- **Acceptance gate:** un-pend AC-1; `TestAC01_TorchWarnsColourTemp` green (and all earlier un-pended ACs).

## Phase SCREEN-3 — behavior: multi-point readings shown, each keeping position + value (AC-4)

- **Kind:** behavior
- **Target AC:** AC-4 (full)
- **Depends on:** CAPTURE-4 (marked readings), ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `capture_live_view.dart` / the readings-list widget, `capture_controls.dart`
- **Tasks:**
  1. Render each `MultiPointReading` with the position it was sampled from and its own colour value (with a
     label), so three distinct points show three distinct positions + values.
- **Exit criteria:** `flutter analyze` clean; 100% coverage on touched widgets; serial with SCREEN-2 (same
  files).
- **Acceptance gate:** un-pend AC-4; `TestAC04_EachPointKeepsPositionValue` green (and all earlier un-pended
  ACs).

### Result — SCREEN-1

- **Landed (inert placeholders over the frozen CAPTURE-2 surface):**
  - `CaptureControls`: torch toggle (`torchKey`, reads "Torch"/"✓ Torch", wired to `turnTorchOn`/`turnTorchOff`
    by `state.torchOn`), "Sample points" (`samplePointsKey` → `sampleMarkedPoints`), "Send to comparison"
    (`sendToComparisonKey` → `sendPairToComparison(0,1)` placeholder). All reach the controller's deferred
    `UnimplementedError` stubs.
  - `CaptureLiveView`: torch colour-temperature warning banner (`torchWarningKey`, `Visibility`-gated on
    `state.torchWarning != null`, sibling above the low-light warning) + a marker per `state.markedPoints`
    drawn at its frame position (`markedPointKey(point)`). Both empty by default.
  - New `CaptureReadingsList` (`capture_readings_list.dart`): one `ColorChip` row per `MultiPointReading`
    (`readingKey(i)`), each label keeping the point's position beside its own CIELAB value (bars a bare
    swatch — SI). Wired into `CaptureScreen` between the live view and controls, bound to
    `state.markedReadings` (empty in the shell).
- **No behaviour:** every new control throws until its phase (torch CAPTURE-3, sampling CAPTURE-4, send
  CAPTURE-5); banner/markers/list render only what the state already holds.
- **Gates:** unit 892 green (+15); coverage **100% on all 10 touched lib files** (`dart run
  tool/coverage_gate.dart main` PASS); `flutter analyze` clean. No acceptance run (shell; no bs-09 harness
  until ITEST-1). **Fix passes: 0/3.**
- **Tokens / Time:** 5,909,827 · 11m 12s (1 session).

### Checkpoint / Handoff — SCREEN-1

- **Frozen for the ITEST stage + SCREEN-2/3:** the Capture-screen anchors the AC tests target —
  `CaptureControls.torchKey` / `samplePointsKey` / `sendToComparisonKey`;
  `CaptureLiveView.torchWarningKey` / `markedPointKey(point)`;
  `CaptureReadingsList.readingsListKey` / `readingKey(index)`. Keys are provisional UX (no wireframe draws
  these) but stable for tests.
- **SCREEN-2 (AC-1, behaviour):** make the torch toggle round-trip live (`state.torchOn` flips, no throw)
  and the `torchWarningKey` banner show CAPTURE-3's colour-temperature string. Depends on CAPTURE-3 (torch
  mechanism + warning string) and G-2.
- **SCREEN-3 (AC-4, behaviour):** `CaptureReadingsList` already keeps position + value per row; SCREEN-3
  un-pends AC-4 against three distinct sampled points once CAPTURE-4 fills `state.markedReadings`. Serial with
  SCREEN-2 (shared `capture_controls.dart` / `capture_live_view.dart`). Depends on CAPTURE-4 and G-2.
- **Send-to-comparison placeholder:** the shell sends the fixed pair `(0, 1)`; CAPTURE-5 owns the real
  reading-selection + `AppRouter.toComparisonPair` handoff (AC-5).
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run
  tool/coverage_gate.dart main` (host, no sim). Flutter: `/Users/matthew.quirk/development/flutter/bin`.
- **Known gaps:** no torch/sampling/send behaviour yet; readings list + markers + banner are state-driven only;
  no bs-09 acceptance harness yet (**next: ITEST-1**).
