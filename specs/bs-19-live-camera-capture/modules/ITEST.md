# Module ITEST — Acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/live_camera/` (new), `integration_test/fakes/scripted_camera_source.dart` (new), the `BS19_RUN_PENDING` pending gate for this suite.
**Depends on:** CAM-2, PERM-1, VIEW-1 (all shells) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ⬜ Todo | | |
| ITEST-2 | acceptance-tests | AC-1..AC-5 | ⬜ Todo | | |
| ITEST-3 | acceptance-tests | AC-6..AC-10 | ⬜ Todo | | |
| ITEST-4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** tests drive the real `buildApp` assembly through the Capture UI + the capture read endpoint; the only faked thing is the camera device, via `ScriptedCameraSource` injected at `AppDependencies.captureSource` (the seam `FakeCaptureSource` already uses) and a recording `CameraPermission` fake. AC-2's conversion is unit-level over raw buffers; AC-10 reads the real on-disk manifests.
- **Observation points:** AC-1/AC-4 — the live-view widget tree (frame-render widget vs `ColoredBox` placeholder under `liveViewKey`; grayscale `ColorFiltered`); AC-2 — `frame.pixelAt`; AC-3/AC-5/AC-6 — the capture state / current reading / `litByTorch` / warning text; AC-7/AC-8 — the read endpoint's `activeSourceKind` + `permissionState` and the "camera access needed" affordance; AC-9 — a recording lifecycle-observer seam + post-resume render; AC-10 — source-scan of `AndroidManifest.xml` + `Info.plist`.
- **Pending gate:** a `pendingACs` map (AC → owning phase) in `integration_test/live_camera/pending.dart`, keyed by `BS19_RUN_PENDING`; un-pend = delete one row. Smoke test never pends.

## Phase ITEST-1 — Harness, scripted source, pending gate, smoke

- **Kind:** acceptance-tests
- **Target AC:** — · **Depends on:** CAM-2, PERM-1, VIEW-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/live_camera/harness.dart`, `pending.dart`, `smoke_test.dart`, `integration_test/fakes/scripted_camera_source.dart`
- **Tasks:**
  1. Build the `ScriptedCameraSource` fixture (known frames + settable locks/torch/lighting/referenceCard + test-only `activeKind`/`permissionState`/`available`) and a `pumpCapture(...)` harness over `buildApp` injecting it + the permission fake.
  2. Pending gate with **all 10 ACs pending**; default (skip) + run-pending (`BS19_RUN_PENDING=true`) targets.
  3. A never-pending smoke test: the Capture screen assembles over the scripted source and the read endpoint answers (shells wired end to end). Non-vacuous: assert `pendingACs` size/contents and that every AC test exists.
- **Exit criteria:** suite green with all ACs pending; smoke green; grade gate on scaffold tests (no vacuous passes).
- **Acceptance gate:** —

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase ITEST-2 — AC-1..AC-5 pending + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-1..AC-5 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/live_camera/preview_test.dart`, `reading_test.dart`
- **Tasks:** write `TestAC01_LivePreview`, `TestAC02_FrameConversion`, `TestAC03_ReadingFollowsFrame`, `TestAC04_ValueOnlyLive`, `TestAC05_LockClearsWarning` per the catalogue; run run-pending; record the red baseline + grades; confirm/amend augmentation rows.
- **Exit criteria:** each pending test fails on a Then or a Given precondition naming its owning phase (or is recorded *green at baseline* with its augmentation); grade grid all A (or *B pending*).
- **Acceptance gate:** —

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase ITEST-3 — AC-6..AC-10 pending + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-6..AC-10 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Files:** `integration_test/live_camera/controls_test.dart`, `permission_test.dart`, `platform_test.dart`
- **Tasks:** write `TestAC06_Torch`, `TestAC07_PermissionFallback`, `TestAC08_NoCameraFallback`, `TestAC09_Lifecycle`, `TestAC10_PlatformDeclarations` per the catalogue; red baseline + grades; augmentation rows.
- **Exit criteria:** as ITEST-2.
- **Acceptance gate:** —

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase ITEST-4 — Test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (per AC: test name, Given checks, When, Then + Rejects; red-baseline summary; augmentations scheduled + closing phase; grid path + counts; what to look at first — esp. the green-at-baseline source-agnostic ACs 3/5/6 and the hardware-faking boundary). Set `⏸ Awaiting review`; G-2 awaiting decision.
- **Exit criteria:** packet complete; grid all A (or *B pending*); stop with `/feature-next-phase --gate bs-19-live-camera-capture G-2 approved | "<changes>"`.
- **Acceptance gate:** —

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_LivePreview | _pending_ | | VIEW-2 | |
| AC-2 | TestAC02_FrameConversion | _pending_ | | CAM-3 | |
| AC-3 | TestAC03_ReadingFollowsFrame | _pending_ | | CAM-4 | |
| AC-4 | TestAC04_ValueOnlyLive | _pending_ | | VIEW-3 | |
| AC-5 | TestAC05_LockClearsWarning | _pending_ | | CAM-5 | |
| AC-6 | TestAC06_Torch | _pending_ | | CAM-6 | |
| AC-7 | TestAC07_PermissionFallback | _pending_ | | PERM-2 | |
| AC-8 | TestAC08_NoCameraFallback | _pending_ | | PERM-3 | |
| AC-9 | TestAC09_Lifecycle | _pending_ | | CAM-7 | |
| AC-10 | TestAC10_PlatformDeclarations | _pending_ | | PERM-4 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC03 | sampling is source-agnostic → green at baseline against any frame source | CAM-4 | assert the reading **changes** when the live frame changes c1→c2 (rejects a stale/fixed sampler) | ⬜ Open |
| TestAC05 | the "approximate" warning + lock state already plumb through the abstraction | CAM-5 | assert the warning clears **because** the source reports `allLocked` (G2), not independently | ⬜ Open |
| TestAC06 | `torchOn`/`litByTorch` already plumb through the abstraction | CAM-6 | assert the toggle reaches the source and the off-path extinguishes (settle after off tap) | ⬜ Open |
| TestAC04 | grayscale filter exists over the placeholder | VIEW-3 | assert the readings subtree sits **outside** the grayscale filter (stays in colour) | ⬜ Open |
| TestAC10 | permission alone is a weak check | PERM-4 | assert the `<uses-feature>` is present and the iOS usage description is non-empty | ⬜ Open |
