# Module SOURCE — capture source + sampling

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/source/capture_source.dart` (interface), `lib/capture/source/software_capture_source.dart`, `lib/capture/source/sampling.dart` (point / area-average / from-photo), `lib/capture/source/frame.dart` (frame model).
**Depends on:** bs-01 domain (`ColorCoordinates`) · **Blocks:** CAPTURE-2 (controller consumes the source), SCREEN behavior (reticle reads radius)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-2 | ⬜ Todo | | |
| 3 | behavior | AC-9 | ⬜ Todo | | |

## Interface reconciliation

- **`CaptureSource`** (SI D2): yields `Frame`s (a colour buffer tagged with its colour space), exposes
  lock controls (`lockExposure/WhiteBalance/Focus`), a stability signal, lighting assessment and
  reference-card presence. Platform-native impls (CameraX/AVFoundation) live outside this Dart build; bs-02
  ships `SoftwareCaptureSource` (deterministic, configurable) as the default non-native impl and the base the
  test `FakeCaptureSource` configures.
- **Sampling** is pure functions over a `Frame`: `samplePoint(frame, x, y)`, `sampleAreaAverage(frame, x, y,
  radiusPx)`, `sampleFromPhoto(image, x, y, radiusPx)` → `ColorCoordinates`. Default radius 5 px (D-7).
- **Frame averaging** primitive: `averageFrames(List<Frame>)` → `Frame`, consumed by CAPTURE-6 commit.
- Produces `ColorCoordinates` (bs-01 canonical CIELAB); no new colour-space math — reuse bs-01 color-science
  for any conversion.

## Open gates

- **G-2 (bs-01 foundation)** and **G-3 (approve tests)** gate this module's behavior phases (SOURCE-2/3).

## Phase 1 — Shell: source interface + sampling signatures

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CAPTURE-1 · **Blocks:** CAPTURE-2
- **Files:** `lib/capture/source/capture_source.dart`, `software_capture_source.dart`, `sampling.dart`, `frame.dart`.
- **Tasks:**
  1. Define `CaptureSource` (frame stream, lock controls, stability signal, lighting, card presence) and the
     `Frame` model (colour buffer + colour-space tag).
  2. `SoftwareCaptureSource` skeleton: constructable from a scene spec (ground-truth colour, lighting, lock
     capability, card presence, optional per-frame noise / frame list); returns placeholder frames for now.
  3. Sampling function signatures (`samplePoint`, `sampleAreaAverage`, `sampleFromPhoto`, `averageFrames`)
     with placeholder bodies (deferred to SOURCE-2/3); default radius constant 5 px.
- **Exit criteria:** unit gate passes on the new types; `flutter analyze` clean; existing suite green.
- **Acceptance gate:** *(n/a — shell)*

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — Behavior: live feed + point/area-average sampling (AC-2)

- **Kind:** behavior
- **Target AC:** AC-2 (full). **Enabler** for AC-1 (live feed), AC-3 (radius-driven averaging), AC-11 (commit sampling).
- **Depends on:** SOURCE-1, G-3 · **Blocks:** SOURCE-3, SCREEN-2, CAPTURE-4, CAPTURE-6 · ∥ CAPTURE-3
- **Files:** `lib/capture/source/software_capture_source.dart`, `sampling.dart`, `frame.dart`.
- **Tasks:**
  1. `SoftwareCaptureSource` emits real frames from its scene spec (the live feed).
  2. Implement `samplePoint` and `sampleAreaAverage(radiusPx)` (true pixel average over the disc of the given
     radius); wire the controller's `currentSample` to the centre sample at the current `radiusPx` (default 5).
  3. Implement `averageFrames` (mean of several frames) for CAPTURE-6.
- **Exit criteria:** un-pend AC-2; run-pending suite green for AC-2; unit coverage 100% on touched files; grade gate A.
- **Acceptance gate:** un-pend AC-2; `TestAC02_AreaAverage5px` green (5 px average at centre, not a point read).
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — Behavior: sample from a gallery photo (AC-9)

- **Kind:** behavior
- **Target AC:** AC-9 (full)
- **Depends on:** SOURCE-2 · **Blocks:** SIGNOFF-1 · ∥ SCREEN-2, CAPTURE-4
- **Files:** `lib/capture/source/sampling.dart` (from-photo path), a photo-import entry on the controller/source.
- **Tasks:**
  1. Implement `sampleFromPhoto(image, x, y, radiusPx)`: decode the image, area-average at the chosen point.
  2. Photo-import flow: load a gallery image into the source so sampling reads from the image, not the live
     feed (the switch is observable via the read endpoint / sampled colour).
- **Exit criteria:** un-pend AC-9; run-pending green for AC-9; coverage 100% touched; grade A.
- **Acceptance gate:** un-pend AC-9; `TestAC09_SampleFromPhoto` green (reads point P of the photo, not the camera).
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
