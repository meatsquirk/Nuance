# Module SOURCE — capture source + sampling

**Status:** In progress — SOURCE-1 (shell) done; `CaptureSource` interface + `SoftwareCaptureSource` + sampling signatures landed, 100% covered. SOURCE-2 (AC-2) next, blocked by G-3.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/source/capture_source.dart` (interface), `lib/capture/source/software_capture_source.dart`, `lib/capture/source/sampling.dart` (point / area-average / from-photo), `lib/capture/source/frame.dart` (frame model).
**Depends on:** bs-01 domain (`ColorCoordinates`) · **Blocks:** CAPTURE-2 (controller consumes the source), SCREEN behavior (reticle reads radius)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 2,451,815 | 12m 12s (12m 12s) |
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

### Result

Landed the SOURCE module shell under `lib/capture/source/` — four pure-Dart files, no
flutter dependency, not yet wired into the app (CAPTURE-2 wires it):
- `frame.dart`: `FrameColorSpace` {srgb, displayP3}, `Pixel` (sRGB 8-bit value type),
  `Frame` (row-major `Pixel` buffer + `colorSpace`, `pixelAt(x,y)`). Frame keeps
  identity equality by design (compared through sampled values, not structurally).
- `capture_source.dart`: `const kStabilityFrameTarget = 12`; `Lighting` {adequate, low};
  `CaptureLocks` {exposure, whiteBalance, focus} + `allLocked`/`copyWith`; `StabilityReading`
  {settledFrames, requiredFrames=12} + `isStable`; the abstract `CaptureSource` interface
  (frames stream, locks, stability stream, lighting, referenceCardPresent, lock controls).
- `software_capture_source.dart`: `SceneSpec` (groundTruth `ColorCoordinates`, lighting,
  canLock, referenceCardPresent, noise, optional explicit frames) + `SoftwareCaptureSource`
  skeleton — exposes scene lighting/card, records lock requests, replays explicit frames;
  frame generation + stability signal deferred to SOURCE-2 (empty placeholders for now).
- `sampling.dart`: `const kDefaultSamplingRadiusPx = 5` (D-7) + `samplePoint`,
  `sampleAreaAverage`, `sampleFromPhoto`, `averageFrames` — signatures only, bodies throw
  `UnimplementedError` (SOURCE-2/3).

Gates (Flutter 3.47.6 / Dart 3.13.5): `flutter analyze` clean (no issues). Unit suite green,
229 tests (196 baseline + 33 new across 4 mirror test files). Coverage gate PASS — 100% line
coverage on all 4 touched `lib` files. Integration suite green (17 tests, unchanged — no wired
code touched). Fix passes: 0/3 (first full run clean). No augmentations, no exclusions, no gates
resolved (G-3 remains open for the ITEST test review). Tokens 2,451,815 · time 12m 12s (12m 12s).

### Checkpoint / Handoff

- **Frozen interfaces (SOURCE-1):** `CaptureSource` (abstract), `Frame`/`Pixel`/`FrameColorSpace`,
  `CaptureLocks`, `StabilityReading`, `Lighting`, `SceneSpec`, `SoftwareCaptureSource`, and the
  four sampling function signatures. Constants: `kStabilityFrameTarget = 12`,
  `kDefaultSamplingRadiusPx = 5`.
- **Deferred placeholders SOURCE-2 replaces:** `SoftwareCaptureSource.frames` (generate the live
  feed from `SceneSpec.groundTruth` + `noise`, not just replay explicit frames),
  `.stability` (emit real settling progress), and all of `sampling.dart` (`samplePoint`,
  `sampleAreaAverage`, `averageFrames`); SOURCE-3 does `sampleFromPhoto`. Sampling converts raw
  frame pixels → canonical CIELAB using bs-01 color-science (reuse, no new colour math).
- **Deferred shell fields** held for later phases: `SceneSpec.canLock` (CAPTURE-3 honours it when
  locking), `SceneSpec.noise` (SOURCE-2 frame generation). Lock controls currently record the lock
  unconditionally; the lock→settle behaviour is CAPTURE-3.
- **Verification commands** (repo root; `export PATH="$HOME/development/flutter/bin:$PATH"` first):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` ·
  `flutter test integration_test/`.
- **CAPTURE-2 (next in the shell layer)** consumes `CaptureSource` into the controller and wires a
  `SoftwareCaptureSource` into `buildApp` + a Capture route.

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
