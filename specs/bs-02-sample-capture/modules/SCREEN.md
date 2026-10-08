# Module SCREEN — Capture screen UI

**Status:** Done — SCREEN-1 (shell) + SCREEN-2 (AC-1, AC-3) + SCREEN-3 (AC-10) done; all screen ACs green
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_screen.dart` and per-region widgets (`capture_eyedropper.dart`, `capture_controls.dart`, `capture_live_view.dart`); labels via bs-01's label-contract widgets.
**Depends on:** CAPTURE (controller + read endpoint), SOURCE (live feed, radius) · **Blocks:** ITEST-1 (needs the screen to drive), SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 6,759,706 | 13m 46s (13m 46s) |
| 2 | behavior | AC-1, AC-3 | ✅ Done | 9,046,680 | 17m 44s (17m 44s) |
| 3 | behavior | AC-10 | ✅ Done | 7,377,195 | 15m 52s (15m 53s) |

## Interface reconciliation

- The Capture screen binds to `CaptureController` and renders the wireframe regions S1.R1, E15–E21: live view
  (E? / body), dismiss low-light warning (E15), exposure/focus lock (E16), calibrate with reference card
  (E17), sampling radius selector (E18), import photo (E19), capture sample (E20), value-only preview (E21),
  plus the centre eyedropper and stability indicator text.
- Every interactive/coloured element carries a text/label per bs-01's label contract (no meaning in colour
  alone); the stability indicator, accuracy label and warning are text, not bare colour.
- Reticle sizes are exact: 1 px → 8 px, 5 px → 20 px, 21 px → 44 px (AC-3).

## Open gates

- **G-3 (approve tests)** — ✅ Resolved 2026-10-07 (ITEST-4); un-blocked SCREEN-2/3.

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

### Result

Landed the real eyedropper + E18 radius selector (AC-1, AC-3). `CaptureEyedropper` now takes a `radiusPx`
and sizes its reticle to the spec's exact mapping (`reticleSizeByRadiusPx` = {1:8, 5:20, 21:44}; a
`reticleSizeFor` fallback to the 20 px default for any non-selectable radius), staying centred over the feed
(AC-1 unchanged). `CaptureControls` renders E18 as a real selector — one `TextButton` per radius keyed
`radiusOptionKey(1|5|21)`, each calling `controller.setRadius(r)` and the selected one marked "✓ N px"; the
`radiusKey` region now wraps the options (smoke anchor preserved). `CaptureController.setRadius` is live:
it records the radius **and** re-averages the most recent live frame at it (the finite feed has already
drained, so moving `radiusPx` alone wouldn't move the reading), leaving an imported-photo reading and a
not-yet-sampled reading untouched.

**Ownership extensions (beyond this phase's declared Files — flagged for the master-plan rollup):**
`capture_controller.dart` (`setRadius` was stubbed *for SCREEN-2* but the controller wasn't in the Files
list) and `capture_live_view.dart` (one line forwarding `state.radiusPx` into the eyedropper, which lives
inside the live view). Both are small and SCREEN-only; no parallel conflict (SCREEN-3 is serial after this).

**Test change (G-3-approved acceptance infra):** the harness `whenSelectRadius(radiusPx)` now taps
`CaptureControls.radiusOptionKey(radiusPx)` instead of a single placeholder key — the per-option retarget the
ITEST-1 handoff and the AC-3 test comment anticipated. It **strengthens** AC-3 (its directional-pull Thens
now exercise all three radii, not one placeholder) and weakens nothing; recorded here per the test-change
ground rule. Advisory only; no behaviour-phase gate.

Un-pended AC-1 (already green at baseline; kept green) and AC-3 (fresh live green) by dropping the AC-3 row
from `bs02/pending.dart`; pending gate now holds only AC-10 → SCREEN-3.

Verification (Flutter 3.47.6): `flutter analyze` clean. Unit **321 green**. Coverage
`dart run tool/coverage_gate.dart main`: **100% line on all 16 touched lib files, PASS**. Acceptance
`flutter test integration_test/capture_test.dart`: **18 green + 1 skipped (AC-10 pending)** — AC-1/AC-2/AC-3
all green. Full `integration_test/`: **35 green + 1 skipped**, no bs-01 regression. Grade gate (fresh
independent subagent, re-grading every un-pended AC test): **11×A, 0×B**, no row below A; AC-3's prior
`whenSelectRadius` judgement call recorded **resolved**. Augmentations: none. Coverage exclusions: none.
Fix passes: **0/3** (first full run passed analyze + unit + coverage + acceptance). Tokens 9,046,680 ·
time 17m 44s (17m 44s).

### Checkpoint / Handoff

- **Verification commands:** unchanged (PATH `~/development/flutter/bin`; `flutter analyze` /
  `flutter test --coverage` / `flutter test integration_test/` / `dart run tool/coverage_gate.dart main`).
- **Frozen interfaces (SCREEN-2):**
  - `CaptureEyedropper({int radiusPx = kDefaultSamplingRadiusPx})` — reticle edge = `reticleSizeFor(radiusPx)`
    (`reticleSizeByRadiusPx` {1:8, 5:20, 21:44}, else `placeholderReticleSize` 20). Keys unchanged
    (`eyedropperKey`, `reticleKey`).
  - `CaptureControls.radiusOptionsPx` = `[1, 5, 21]`; `CaptureControls.radiusOptionKey(int)` = per-option
    anchor `capture-e18-radius-<n>`; `radiusKey` still wraps the selector (one widget).
  - `CaptureController.setRadius(int)` — live: records `radiusPx` and re-samples `_recentFrames.last` at it
    (no-op on the reading when a photo is imported or no frame has arrived).
  - `CaptureLiveView` passes `state.radiusPx` to the eyedropper.
- **For SCREEN-3 (AC-10, the last behaviour phase):** value-only is the only control still deferred —
  `controller.toggleValueOnly()` throws `UnimplementedError` and E21 reads "Value". SCREEN-3 makes it toggle
  `CaptureState.valueOnly`, greyscales the feed with a `ColorFiltered` (saturation-0) **ancestor of
  `liveViewKey`**, and flips E21's label to "✓ Value". SCREEN-3 edits the same screen files
  (`capture_screen.dart`, `capture_live_view.dart`, `capture_controls.dart`) — serial after this phase; base
  on this tip. Un-pend AC-10 by deleting its row from `bs02/pending.dart` (then `pendingACs` is empty).
- **Known gaps / ownership notes:** none new. The `✓ N px` option labels are exact-match distinct from
  AC-10's `find.text('Value')`/`'✓ Value'`. After SCREEN-3, `pendingACs` is empty and SIGNOFF-1 is startable.
- **G-4 / G-5** (advisory harness-change flags) remain open for SIGNOFF-1; this phase's `whenSelectRadius`
  retarget is a third, planned harness change (recorded above) to note at sign-off — it strengthened AC-3.

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

### Result

Landed the real value-only grayscale preview (AC-10) — the last bs-02 behaviour phase.
`CaptureController.toggleValueOnly()` is live: it flips `CaptureState.valueOnly`
(`emit(copyWith(valueOnly: !valueOnly))`), a purely presentational toggle that leaves the sampled reading
untouched. `CaptureLiveView` now wraps the feed surface (`liveViewKey` `ColoredBox`) in a `ColorFiltered`
with a static saturation-0, luminance-preserving `_grayscaleMatrix` **when `state.valueOnly` is true** (bare
`ColoredBox` otherwise); the overlaid text readings are Stack **siblings** of the feed, so only the feed
greyscales. `CaptureControls` E21 label flips `Text(controller.state.valueOnly ? '✓ Value' : 'Value')`; the
screen already rebuilds both via its `ListenableBuilder`, so `capture_screen.dart` needed no change (listed in
Files but untouched).

Un-pended AC-10 by deleting its row from `bs02/pending.dart` — **`pendingACs` is now empty**; updated the
harness self-tests in `capture_test.dart` (`pending gate` group) to assert the empty map (exact-map + `isEmpty`
pins the size, not vacuous) and that AC-10 now runs in both modes.

Verification (Flutter 3.47.6): `flutter analyze` clean. Unit **324 green** (`flutter test --coverage`);
coverage gate `dart run tool/coverage_gate.dart main` **100% line on all touched lib files, PASS** (3 touched:
`capture_controller.dart`, `capture_controls.dart`, `capture_live_view.dart`). Acceptance
`flutter test integration_test/`: **36 green, 0 pending** — `AC-10 TestAC10_ValueOnly` runs live and passes;
no bs-01 regression. Grade gate (fresh independent subagent, whole un-pended suite re-grade):
**11×A, 0×B** — AC-10 a fresh live A, no downgrade, no silent weakening. Augmentations: none. Coverage
exclusions: none. Fix passes: **0/3** (first full run passed analyze + unit + coverage + acceptance + grade).
One non-downgrading tightening note carried to SIGNOFF-1 (below). Tokens 7,377,195 · time 15m 52s (15m 53s).

### Checkpoint / Handoff

- **Verification commands:** unchanged (PATH `~/development/flutter/bin`; `flutter analyze` /
  `flutter test --coverage` / `flutter test integration_test/` / `dart run tool/coverage_gate.dart main`).
- **Frozen interfaces (SCREEN-3):**
  - `CaptureController.toggleValueOnly()` — flips `CaptureState.valueOnly`; notifies; leaves the reading
    untouched (presentation only).
  - `CaptureLiveView` wraps the `liveViewKey` feed in a `ColorFiltered(ColorFilter.matrix(_grayscaleMatrix))`
    iff `state.valueOnly`; the filter is an **ancestor of `liveViewKey`** and not of the text readings.
  - `CaptureControls` E21 reads `'✓ Value'` when `controller.state.valueOnly`, `'Value'` otherwise.
- **Module SCREEN is complete.** All screen ACs (AC-1, AC-3, AC-10) are green; the whole bs-02 suite is
  11×A/0×B and `pendingACs` is empty. **SIGNOFF-1 is now startable** (last behaviour phase done; SOURCE,
  CAPTURE, SCREEN, ITEST all done).
- **For SIGNOFF-1:**
  - **Three open advisory gates to confirm:** **G-4** (CAPTURE-3 `givenCaptureOf`→`pumpWidget`), **G-5**
    (CAPTURE-6 `skipOffstage:false` endpoint finder), and the SCREEN-2 `whenSelectRadius` per-option retarget
    (a planned, strengthening harness change — recorded in SCREEN-2's Result; no separate gate id).
  - **One tightening opportunity (not a defect):** AC-10's positive Then asserts a `ColorFiltered` ancestor
    over the feed structurally but not that its matrix is the saturation-0 `_grayscaleMatrix` — meaningless to
    assert now (the feed is a flat `Color(0xFF3A3A3A)` placeholder), worth tightening to
    `colorFilter == ColorFilter.matrix(_grayscaleMatrix)` once the feed renders real frames (SOURCE native
    camera work, outside bs-02).
- **Known gaps / ownership notes:** none new.
