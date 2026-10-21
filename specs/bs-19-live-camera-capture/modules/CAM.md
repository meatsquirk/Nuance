# Module CAM — Real camera capture source

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/source/camera_capture_source.dart` (new), `lib/capture/source/frame_conversion.dart` (new), the source-selection factory seam in `lib/capture/source/`; `pubspec.yaml` (`camera` dep); unit tests under `test/capture/source/`. Also the scaffold (branch + runner + gate).
**Depends on:** — · **Blocks:** VIEW, PERM, ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| CAM-1 | scaffold | — | ⬜ Next | | |
| CAM-2 | shell | — | ⬜ Todo | | |
| CAM-3 | behavior | AC-2 (+ real frame stream, enabler-ish) | ⬜ Todo | | |
| CAM-4 | behavior | AC-3 | ⬜ Todo | | |
| CAM-5 | behavior | AC-5 | ⬜ Todo | | |
| CAM-6 | behavior | AC-6 | ⬜ Todo | | |
| CAM-7 | behavior | AC-9 | ⬜ Todo | | |

## Interface reconciliation

- Implements the existing `CaptureSource` (lib/capture/source/capture_source.dart) unchanged — no new interface members; the abstraction was authored for this ("SOURCE-2 renders real frames", `CaptureColorSpace.ofFrame`, `supportsWideGamut`/`supportsRaw`/`captureMode` already present).
- `CameraCaptureSource` wraps the `camera` plugin's `CameraController`; its `frames` stream is fed by `startImageStream`, each `CameraImage` converted via `frame_conversion.dart`.
- Per D-6, `normaliseAgainstCard` on the camera source returns `raw` unchanged (calibration stays deferred); `colorSpace==srgb`, `captureMode==processed`, `supportsWideGamut/supportsRaw` report the plugin capability but selection stays deferred.

## Open gates

- G-1 (approve the spec) blocks CAM-1. G-2 (test review) blocks CAM-3..CAM-7.

## Phase CAM-1 — Scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1) · **Blocks:** CAM-2, PERM-1, VIEW-1
- **Files:** none product; branch + plan/ledger only
- **Tasks:**
  1. Branch `feat/bs-19-live-camera-capture` off `main` (current main @ d3a1c4f; rebase/branch as the repo convention).
  2. Adopt `BS19_RUN_PENDING` as the pending env flag (mirror the bs-18 runner pattern); confirm the existing coverage-gate tooling applies.
  3. Baseline: run the unit suite + record counts; prove the coverage gate passes clean and fails on a planted gap.
- **Exit criteria:** branch pushed; baseline recorded; gate proven both directions. No product code.
- **Acceptance gate:** —

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase CAM-2 — Camera source skeleton + plugin + selection seam

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CAM-1 · **Blocks:** ITEST-1, CAM-3
- **Files:** `pubspec.yaml`, `lib/capture/source/camera_capture_source.dart`, `lib/capture/source/frame_conversion.dart`, a `selectCaptureSource(...)` factory seam
- **Tasks:**
  1. Add the official `camera` plugin to `pubspec.yaml` (project-local dep; `flutter pub get`).
  2. Declare `CameraCaptureSource implements CaptureSource` with every member present but inert/safe (no device calls yet) — compiles, construction cheap, `frames` an empty/placeholder stream.
  3. Add `frame_conversion.dart` with the `CameraImage`→`Frame` signature and a stub (unit-tested for real in CAM-3).
  4. Introduce a `selectCaptureSource` factory seam (chooses camera vs software) that **still returns the software source by default** — no behaviour change; real selection lands in PERM-2.
- **Exit criteria:** unit gate passes; existing suite stays green; app still boots on the software source (unchanged default).
- **Acceptance gate:** —

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase CAM-3 — Real frame stream + CameraImage→Frame conversion

- **Kind:** behavior
- **Target AC:** AC-2 (full) — and the real frame stream it rests on (enabler for VIEW-2, CAM-4/5/6/7, PERM-2)
- **Depends on:** ITEST-4 (G-2), CAM-2 · **Blocks:** VIEW-2, CAM-4, CAM-5, CAM-6, CAM-7, PERM-2
- **Files:** `camera_capture_source.dart`, `frame_conversion.dart`
- **Tasks:**
  1. Implement YUV420 (Android) and BGRA8888 (iOS) `CameraImage` → `Frame` RGB conversion (channel order + value range), downsampled for sampling cost (D-4).
  2. Wire `CameraCaptureSource.frames` to the plugin's image stream, emitting converted `Frame`s; initialise/`startImageStream` on construction/first-listen.
  3. Unit-test conversion against golden YUV/BGRA buffers with known reticle pixels (incl. the distinct-colour control).
- **Exit criteria:** unit + coverage gate on touched files; `TestAC02_FrameConversion` green (un-pended).
- **Acceptance gate:** un-pend AC-2; `integration_test/live_camera/` green (`TestAC02_*` and all earlier ACs), run-pending == default for delivered ACs.
- **Augments:** none

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase CAM-4 — Reading follows the live frame

- **Kind:** behavior
- **Target AC:** AC-3 (full)
- **Depends on:** CAM-3 · **Blocks:** SIGNOFF-1
- **Files:** `camera_capture_source.dart` (+ controller wiring only if needed; sampling is source-agnostic)
- **Tasks:**
  1. Ensure the live camera frame flows into the reading path so the current reading tracks the latest frame pixel under the reticle (confirm the existing `CaptureController` sampling consumes the camera source's frames unchanged).
  2. Make the `TestAC03` control (frame c1→c2 changes the reading) discriminate against a stale/fixed sampler.
- **Exit criteria:** unit/coverage gate; `TestAC03` green and discriminating.
- **Acceptance gate:** un-pend AC-3; suite green.
- **Augments:** `TestAC03`: assert the reading *changes* when the live frame changes (not merely equals the first frame) — closes the source-agnostic green-at-baseline limit.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase CAM-5 — Real AE·AWB·AF locks clear the warning

- **Kind:** behavior
- **Target AC:** AC-5 (full)
- **Depends on:** CAM-3 · **Blocks:** SIGNOFF-1
- **Files:** `camera_capture_source.dart`
- **Tasks:**
  1. Wire `lockExposure/lockWhiteBalance/lockFocus` to the plugin's AE/AWB/AF controls; reflect `locks` from the real controller.
  2. Confirm the "exposure not locked — approximate" warning clears from the real lock state (warning text logic stays in capture state).
- **Exit criteria:** unit/coverage gate; `TestAC05` green and discriminating.
- **Acceptance gate:** un-pend AC-5; suite green.
- **Augments:** `TestAC05`: assert the warning clears **because** the source reports `allLocked`, not independently (G2).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase CAM-6 — Real device torch

- **Kind:** behavior
- **Target AC:** AC-6 (full)
- **Depends on:** CAM-3 · **Blocks:** SIGNOFF-1
- **Files:** `camera_capture_source.dart`
- **Tasks:**
  1. Wire `turnTorchOn/Off`/`torchOn` to the plugin's `setFlashMode(torch/off)`; reflect state from the controller.
  2. Confirm `litByTorch` stamping on a committed reading (controller-level, existing) reads the real torch state.
- **Exit criteria:** unit/coverage gate; `TestAC06` green and discriminating.
- **Acceptance gate:** un-pend AC-6; suite green.
- **Augments:** `TestAC06`: assert the toggle reaches the source and the off-path extinguishes (settle point after off tap).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase CAM-7 — Camera lifecycle release/resume

- **Kind:** behavior
- **Target AC:** AC-9 (full)
- **Depends on:** CAM-3 · **Blocks:** SIGNOFF-1
- **Files:** `camera_capture_source.dart` (+ a `WidgetsBindingObserver` on the Capture host if needed)
- **Tasks:**
  1. Release the controller on `inactive`/`paused` and on screen dispose; re-initialise on `resumed` (D-7).
  2. Ensure the feed resumes without a frozen/black frame; no leaked controller.
- **Exit criteria:** unit/coverage gate; `TestAC09` green (acquire/release recorded, resume renders).
- **Acceptance gate:** un-pend AC-9; suite green.
- **Augments:** none

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->
