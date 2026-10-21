# Module VIEW — Live preview rendering

**Status:** In progress — VIEW-1 shell done; VIEW-2/VIEW-3 (behavior) gated by G-2
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_live_view.dart`, a frame-render widget (e.g. `lib/capture/live_frame_view.dart`), widget tests under `test/capture/`.
**Depends on:** CAM · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| VIEW-1 | shell | — | ✅ Done | | |
| VIEW-2 | behavior | AC-1 | ⬜ Todo | | |
| VIEW-3 | behavior | AC-4 | ⬜ Todo | | |

## Interface reconciliation

- `capture_live_view.dart` currently renders `const Widget feedSurface = ColoredBox(key: liveViewKey, color: Color(0xFF3A3A3A))` and wraps it in a saturation-0 `ColorFiltered` for value-only mode; the marked-point/readings overlays are Stack siblings of the feed.
- VIEW introduces a frame-render widget that paints the active source's latest `Frame` and keeps `liveViewKey` as the stable anchor; when no frame is available it shows the existing placeholder (so the software-source / no-camera paths are unchanged). The grayscale filter and overlays stay exactly where they are (presentation invariant).

## Open gates

- G-2 (test review) blocks VIEW-2, VIEW-3.

## Phase VIEW-1 — Frame-render widget seam

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CAM-1 · **Blocks:** ITEST-1, VIEW-2
- **Files:** `lib/capture/live_frame_view.dart` (new), `capture_live_view.dart`
- **Tasks:**
  1. Add a `LiveFrameView(frame)` widget that paints a `Frame` (e.g. via `RawImage`/`CustomPaint` over the converted pixels), keyed `liveViewKey`.
  2. Route the live view through it with `frame == null` → the existing `ColoredBox` placeholder, so behaviour is unchanged until a source provides frames.
- **Exit criteria:** unit gate; existing capture widget/integration suites stay green; placeholder still shows (no source frames wired yet).
- **Acceptance gate:** —

### Result
Frame-render widget seam — **no behaviour change** (the feed still shows the flat placeholder; `frame` is null everywhere until VIEW-2 wires a live source, so the software-source / no-camera paths render exactly as before).
- **New lib file (100% covered):** `lib/capture/live_frame_view.dart` — `LiveFrameView({required Frame? frame})`, carries `CaptureLiveView.liveViewKey`. `frame == null` → `ColoredBox(color: placeholderColor = 0xFF3A3A3A)` (the original SCREEN-1 colour); `frame != null` → `CustomPaint(painter: _FramePainter(frame), child: SizedBox.expand())` painting the row-major RGB pixels scaled to fill (per-pixel `drawRect`; D-4 downsampling keeps it cheap). `_FramePainter.shouldRepaint` = `oldDelegate.frame != frame` (Frame keeps identity equality).
- **Routed through it:** `capture_live_view.dart` gains an optional `final Frame? frame` (default null) and renders the feed via `LiveFrameView(frame: frame, key: liveViewKey)` in place of the inline `ColoredBox`. The value-only `ColorFiltered` still wraps that surface (grayscale invariant) and the eyedropper/readings/overlays are untouched Stack siblings.
- **Tests:** +3 widget tests (`test/capture/live_frame_view_test.dart`): null→placeholder (ColoredBox, no CustomPaint under the view), non-null→CustomPaint (no placeholder), and a rebuild with a fresh frame (exercises `shouldRepaint`). Existing `capture_live_view_test.dart` (grayscale ancestor assertions over `liveViewKey`) and `capture_screen_test.dart` stay green unchanged.
- **Gates:** unit + coverage **PASS** — `flutter test --coverage test/` = **1666 passed** (1663 baseline + 3), exit 0; `dart run tool/coverage_gate.dart 11944b6` = **100% on all 11 touched lib files**. Existing integration suites green per-file: `integration_test/capture_test.dart` 19/19, `advanced_capture_test.dart` 21/21. No acceptance/grade gate (shell). **Fix passes: 1/3** (scoped one test's `CustomPaint` matcher under `LiveFrameView` — framework-internal CustomPaints tripped a global `findsNothing`; test-only, no product change).
- **Tokens/Time:** see dashboard (VIEW-1 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase (VIEW-2 builds on):**
  - `LiveFrameView({required Frame? frame, Key? key})` — the single frame-render seam. VIEW-2 passes the active source's latest `Frame` (non-null) so the preview paints the live feed; `frame == null` must keep showing `placeholderColor` (the software / no-camera path).
  - `CaptureLiveView.frame` (optional, default null) — the Capture screen will feed the controller's latest frame here in VIEW-2; `liveViewKey` stays on `LiveFrameView` (anchor + grayscale-wrap target unchanged).
  - `_FramePainter` is private to `live_frame_view.dart`; its per-pixel paint is a preview-only seam — VIEW-2 may keep it or swap to a `ui.Image` path, but must preserve: `liveViewKey` resolves to one widget, and no `ColoredBox` placeholder under `liveViewKey` while a camera source streams (the VIEW-2 `TestAC01` assertion).
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`, run bare):
  - Unit + coverage: `flutter test --coverage test/`
  - Coverage gate on touched files: `dart run tool/coverage_gate.dart 11944b6`
  - Existing capture integration suites (run **one file per invocation** — launching two at once fails to start the app): `flutter test -d flutter-tester integration_test/capture_test.dart` then `… integration_test/advanced_capture_test.dart`.
- **Known gaps:** none introduced. No frame source is wired — `frame` is null in assembly, so the feed is still the flat placeholder; VIEW-2 (behavior, gated by G-2 and dependent on CAM-3's real stream) wires it. The grayscale value-only toggle already wraps the new surface, so VIEW-3 only needs the real frame flowing.

## Phase VIEW-2 — Live preview renders real frames

- **Kind:** behavior
- **Target AC:** AC-1 (full)
- **Depends on:** VIEW-1, CAM-3 · **Blocks:** VIEW-3, SIGNOFF-1
- **Files:** `capture_live_view.dart`, `live_frame_view.dart`
- **Tasks:**
  1. Feed the active source's latest `Frame` into `LiveFrameView` so the preview paints the camera feed.
  2. Ensure the placeholder is gone once frames flow (and still present on the software/no-camera path).
- **Exit criteria:** unit/coverage gate; `TestAC01_LivePreview` green (render present, no `ColoredBox` placeholder under `liveViewKey` when a camera source streams).
- **Acceptance gate:** un-pend AC-1; `integration_test/live_camera/` green.
- **Augments:** none

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase VIEW-3 — Value-only grayscale over the live frame

- **Kind:** behavior
- **Target AC:** AC-4 (full)
- **Depends on:** VIEW-2 · **Blocks:** SIGNOFF-1
- **Files:** `capture_live_view.dart`
- **Tasks:**
  1. Ensure the saturation-0 `ColorFiltered` wraps the real frame render (not the placeholder), leaving overlaid readings in colour.
- **Exit criteria:** unit/coverage gate; `TestAC04_ValueOnlyLive` green.
- **Acceptance gate:** un-pend AC-4; suite green.
- **Augments:** `TestAC04`: assert the readings subtree sits **outside** the grayscale filter (stays in colour).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->
