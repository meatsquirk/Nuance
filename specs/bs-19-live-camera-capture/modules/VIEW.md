# Module VIEW — Live preview rendering

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_live_view.dart`, a frame-render widget (e.g. `lib/capture/live_frame_view.dart`), widget tests under `test/capture/`.
**Depends on:** CAM · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| VIEW-1 | shell | — | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

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
