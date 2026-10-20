# Module READ — Readout + Capture screen swaps

**Status:** In progress — READ-1 ✅ (AC-3), READ-2 ✅ (AC-4); next READ-3 (independent, concurrent with FLOW/ORG/CFG).
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/readout/**`, `lib/capture/**` (screen/control/region widgets only — not controllers, sources, read endpoints or `capture/source/**` device literals).
**Depends on:** ITEST (G-2) · **Blocks:** GUARD

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| READ-1 | behavior | AC-3 | ✅ Done | 10.07M | 24m |
| READ-2 | behavior | AC-4 | ✅ Done | 8.17M | 20m 33s |
| READ-3 | behavior | AC-5 | ⬜ Todo | | |

## Interface reconciliation

Consumes the bs-17 wrappers (`PillButton`, `SpeakButton`, `SurfaceCard`, `MonoLabel`, `SwatchCaption`).
Changes only the widgets rendering Capture/Readout controls and regions; capture controllers, sources,
sampling, stability/accuracy logic and read endpoints are frozen (D-2). The camera-device colour literals in
`lib/capture/source/**` and viewfinder/reticle/shutter-chrome literals stay on the bs-17 AC-14 exclusion list
(D-4).

## Open gates

G-2 (the acceptance-test review) ✅ resolved 2026-10-19 — approved by Matt Quirk; all three READ phases are startable.

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

### Result — READ-1 ✅ Done (2026-10-20)

- **Landed (`lib/capture/capture_controls.dart` only):** the Capture control surface now renders as the
  wireframe's design-system components (AC-3). The **E20 capture shutter** is a round 88×88 `FilledButton`
  (`CircleBorder`, ink `onSurface` fill / `surface` glyph; `Icon(Icons.camera_alt, semanticLabel: 'Capture')`
  preserves the screen-reader label the old text button gave — bs-11 AC-6). The **action controls** (dismiss /
  lock / calibrate / import / sample-points / send-to-comparison) are `PillButton.secondary`. The **toggles**
  (value-only, torch) and each **radius option** show on/selected the non-colour way via a shared `_toggle`
  helper — filled `PillButton.primary` when on/selected, outlined `PillButton.secondary` otherwise — so the
  widget type stays `PillButton` across the flip and selection reads without colour. Every key, label,
  state-driven text (`✓ Value`/`Value`, `✓ Torch`/`Torch`, `✓ N px`), wiring and visibility is unchanged
  (presentation only, D-2/D-3). Default button tap targets stay padded ≥48dp (bs-11 AC-4).
- **Shutter anchor:** kept on the existing `CaptureControls.captureKey` (E20) — the ITEST-2 `TestAC03` anchors
  its 88px `getSize` there, so no new `shutterKey` was introduced (the plan task's "shutterKey" is that same
  E20 shutter).
- **AC-3 un-pended** (deleted its `pendingACs` row). **Augmentation made (TestAC03 → READ-1):** added the
  exhaustive "superseded ad-hoc widget absent" sweep over **every** capture control (dismiss/lock/calibrate/
  import/value-only/capture/torch/sample/send + all three radius options) plus an `expectPill` check on the
  six action controls. Discriminates: BASE `cff3d27` had 10 ad-hoc `TextButton`s, so the sweep goes red on the
  pre-READ-1 tree. Updated the ITEST-1 smoke scaffold to track the drain (pending-direction proof + wiring
  smoke moved to AC-4; `unpended = {AC-1, AC-2, AC-3}`; `fullSeed.hasLength(14)`).
- **Gates:** `dart analyze` (touched lib + 4 tests) → No issues. Unit `flutter test --coverage test/` →
  **1673 pass** (1671 + 2 new capture-controls tests: shutter 88px round, full design-system sweep). Coverage
  gate `dart run tool/coverage_gate.dart d3a1c4f` → **100% on all 12 touched lib files, PASS**. Acceptance:
  `capture_test.dart` **AC-3 green**, AC-4 pending-skipped; smoke green (13 pass / 1 skip). **Grade gate PASS**
  — independent fresh-subagent re-grade: **AC-3 A (promoted from A-core/B-pending-READ-1** — augmentation
  closes the limit, strengthens only AC-3, discriminates a partial swap), AC-1 **A**, AC-2 **A**; A=3 / B=0,
  no fix owed. **Fix passes: 1/3** (the bs-02 sibling cast below, caught on first sibling run).
- **Sibling re-verification:** `integration_test/capture_test.dart` (bs-02) AC-5 asserted the lock control via
  `tester.widget<TextButton>(lockKey).enabled` — the swap broke the cast. Fixed to
  `tester.widget<PillButton>(lockKey).onPressed isNotNull` (the exact PillButton equivalent of `enabled`;
  intent preserved, grader-confirmed, and the typed cast now pins the swapped type). Suites green: **bs-02
  capture 19✅, bs-09 advanced_capture 21✅, bs-11 accessibility 19✅** (shutter label + ≥48dp hold),
  **bs-17 design_system 27✅, bs-10 daltonization 25✅** (capture-screen live swatch), **bs-01 readout 12✅,
  correction 22✅**, bs-18 chrome AC-1/AC-2✅. palette AC-3/AC-5 remain the known bs-06 off-lane flakes.

### Checkpoint / Handoff — after READ-1

- **Frozen interfaces (this phase):** `CaptureControls` renders E20 capture as a round 88×88 `FilledButton`
  keyed `captureKey`, the action controls as `PillButton.secondary`, and the value-only/torch toggles + radius
  options via the `_toggle` helper (`PillButton.primary` on, `.secondary` off). AC-3 (`TestAC03`) is un-pended
  and must stay green; a later phase that restyles these must keep each key on a non-`TextButton`/
  non-`ElevatedButton` design-system control and keep the shutter ~88px round, or the AC-3 sweep reddens.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout`/
  `gtimeout`): unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart d3a1c4f`;
  AC-3 `flutter test -d flutter-tester integration_test/visual_application/capture_test.dart`; capture-screen
  siblings `flutter test -d flutter-tester integration_test/{capture_test,advanced_capture_test}.dart` (run one
  suite at a time under load — the whole `visual_application/` dir won't launch at once when saturated).
- **Known gaps / next:** **READ-2 (AC-4)** is next in READ — it fixes the Capture warning overlap in
  `lib/capture/capture_live_view.dart` and shares `lib/capture/**` with READ-1, so it sequences after this
  phase (not concurrent). **READ-3 (AC-5, readout)** is independent of capture and may run concurrently with
  FLOW/ORG/CFG. No `build_app.dart` edit here (D-7).

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

### Result — READ-2 ✅ Done (2026-10-20)

- **Landed (`lib/capture/capture_live_view.dart` only):** the live camera readings/warnings now lay out in a
  **single vertical run** (D-6, AC-4). The six fixed-offset corner `Positioned` banners — which collided at
  large text scale (the observed overlap: at 200% the stability `Rect(8,64,179,104)` intersected the lock
  `Rect(8,88,259,128)`) — are replaced by one `Positioned(left:8, top:8, right:8)` holding a `Column`
  (`mainAxisSize.min`, `crossAxisAlignment.start`). `top` alone (no `bottom`/`height`) leaves the run's height
  unbounded, so the Column can never flex-overflow at any text scale, and its layout guarantees each banner
  gets its own vertical band → no two rects can intersect. Each reading/warning is wrapped by a new private
  `_banner` helper in a design-system **`SurfaceCard`** (horizontal 12 / vertical 8 padding, 8px inter-banner
  gap) — the wireframe banner treatment. Every reading keeps its **key, text, visibility condition and
  semantics** unchanged (stability/lock/accuracy always present; downgrade-reasons behind `isNotEmpty`;
  low-light + torch behind `Visibility`); only the layout and the banner surface changed, and the explicit
  `Colors.white` text styles were dropped so each reads as theme `onSurface` on the paper card (presentation
  only, D-2/D-3). The feed + its value-only `ColorFiltered` and the marked-point `Positioned`s are untouched,
  so the readings stay Stack siblings of the feed (grayscale touches the feed alone, AC-10).
- **AC-4 un-pended** (deleted its `pendingACs` row). Scaffold drained: the smoke `pending.dart` proof moved
  from AC-4 → **AC-5** (owner READ-3) and AC-4 added to the smoke `unpended` set; `fullSeed.hasLength(14)`
  unchanged. **No augmentation owed** (the AC-4 test already asserts the full non-overlap grain).
- **Gates:** `dart analyze` (touched lib + 3 tests) → No issues. Unit `flutter test --coverage test/` →
  **1675 pass** (1673 + 2 new `capture_live_view_test.dart` tests: single non-overlapping vertical run at
  200%, each reading in a SurfaceCard banner). Coverage gate `dart run tool/coverage_gate.dart d3a1c4f` →
  **100% on all 13 touched lib files, PASS**. Acceptance: `visual_application/capture_test.dart` **AC-4 green**
  (AC-3 green, AC-5 pending-skipped); smoke green (13 pass / 1 skip = AC-5). **Grade gate PASS** — independent
  fresh-subagent re-grade of all four un-pended tests: **AC-1 A, AC-2 A, AC-3 A, AC-4 A**; A=4 / B=0, no
  grade changed, no fix owed. **Fix passes: 0/3** (green on the first full run).
- **Sibling re-verification (one suite at a time):** bs-18 smoke 13✅, bs-02 `capture_test` 19✅, bs-09
  `advanced_capture_test` 21✅, bs-12 `bs12/nfr_test` 33✅, bs-11 `bs11/accessibility_test` 19✅ (the
  ink-on-`SurfaceCard` banners keep AA contrast), bs-10 `daltonization_test` 25✅, bs-17 `design_system_test`
  27✅, bs-18 `chrome_test` 2✅. palette AC-3/AC-5 remain the known bs-06 off-lane flakes (not run).

### Checkpoint / Handoff — after READ-2

- **Frozen interfaces (this phase):** `CaptureLiveView` lays its readings/warnings in one `Column` inside a
  single `Positioned(left:8,top:8,right:8)`, each wrapped by `_banner` in a `SurfaceCard`. AC-4
  (`TestAC04_CaptureWarnings`) is un-pended and must stay green — a later phase that re-lays these must keep
  the banners in a layout whose rects cannot intersect at 200% text scale (a single `Column`/vertical run,
  not fixed-offset corner `Positioned`s), or AC-4 reddens. Every reading key stays on its `Text` (accuracy
  key wraps its Text; downgrade key on its inner Column); the feed's value-only `ColorFiltered` and the
  marked-point `Positioned`s are unchanged.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout`):
  unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart d3a1c4f`; AC-4
  `flutter test -d flutter-tester integration_test/visual_application/capture_test.dart`; capture-screen
  siblings `flutter test -d flutter-tester integration_test/{capture_test,advanced_capture_test}.dart` and
  `integration_test/bs11/accessibility_test.dart` (run one suite at a time under load; the whole
  `visual_application/` dir won't launch at once when saturated).
- **Known gaps / next:** **READ module is READ-1 ✅ + READ-2 ✅; only READ-3 (AC-5, readout) remains** — it
  is independent of capture and runs concurrently with FLOW-1/ORG-1/CFG-1 (disjoint dirs). No `build_app.dart`
  edit here (D-7). **Reviewer recommendation (non-blocking):** AC-4's acceptance test could additionally
  assert the "design-system banner style" (a `SurfaceCard` ancestor per present banner); the grader flagged
  this as a strengthening, not a gate blocker — the banner style is already unit-covered. Not owed.

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
