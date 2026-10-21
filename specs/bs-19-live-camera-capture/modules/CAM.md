# Module CAM — Real camera capture source

**Status:** In progress — CAM-4 done (AC-3 reading follows the live frame, un-pend only); CAM-5/6/7 startable
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/source/camera_capture_source.dart` (new), `lib/capture/source/frame_conversion.dart` (new), the source-selection factory seam in `lib/capture/source/`; `pubspec.yaml` (`camera` dep); unit tests under `test/capture/source/`. Also the scaffold (branch + runner + gate).
**Depends on:** — · **Blocks:** VIEW, PERM, ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| CAM-1 | scaffold | — | ✅ Done | 4,687,376 | 13m 23s (44m 03s) |
| CAM-2 | shell | — | ✅ Done | 4,236,040 | 10m 17s (10m 17s) |
| CAM-3 | behavior | AC-2 (+ real frame stream, enabler-ish) | ✅ Done | 8.08M | 19m 38s |
| CAM-4 | behavior | AC-3 | ✅ Done | 4.41M | 9m 06s |
| CAM-5 | behavior | AC-5 | ⬜ Todo | | |
| CAM-6 | behavior | AC-6 | ⬜ Todo | | |
| CAM-7 | behavior | AC-9 | ⬜ Todo | | |

## Interface reconciliation

- Implements the existing `CaptureSource` (lib/capture/source/capture_source.dart) unchanged — no new interface members; the abstraction was authored for this ("SOURCE-2 renders real frames", `CaptureColorSpace.ofFrame`, `supportsWideGamut`/`supportsRaw`/`captureMode` already present).
- `CameraCaptureSource` wraps the `camera` plugin's `CameraController`; its `frames` stream is fed by `startImageStream`, each `CameraImage` converted via `frame_conversion.dart`.
- Per D-6, `normaliseAgainstCard` on the camera source returns `raw` unchanged (calibration stays deferred); `colorSpace==srgb`, `captureMode==processed`, `supportsWideGamut/supportsRaw` report the plugin capability but selection stays deferred.

## Open gates

- G-1 (approve the spec) ✅ Resolved 2026-10-21 (approved — Matt Quirk); CAM-1 unblocked. G-2 (test review) ✅ Resolved 2026-10-21 (approved — Matt Quirk); CAM-3 done, CAM-4/5/6/7 unblocked.

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

### Result
Scaffold only — **no product code** (`lib/` untouched; gate confirms 0 touched lib files).
- **Branch:** `feat/bs-19-live-camera-capture` off `main` @ `11944b6` (the G-1 commit; current main head after the PLAN + G-1 decision landed on main).
- **Pending runner:** new `integration_test/live_camera/pending.dart` establishes the `BS19_RUN_PENDING` gate (mirror of bs-18's `visual_application/pending.dart`): `pendingACs` seeded with all 10 ACs → owner behaviour phases from the master AC-coverage table (AC-1→VIEW-2, AC-2→CAM-3, AC-3→CAM-4, AC-4→VIEW-3, AC-5→CAM-5, AC-6→CAM-6, AC-7→PERM-2, AC-8→PERM-3, AC-9→CAM-7, AC-10→PERM-4); `behaviorPhases` the 10 owners; `acTestWidgets`/`pendingSkipReason`/`runPending` identical to the sibling mechanism. `dart analyze` → No issues.
- **Baseline:** `flutter test --coverage test/` = **1643 passed, exit 0** (matches bs-18's scaffold baseline at the same code point); `coverage/lcov.info` generated.
- **Coverage gate proven both directions** (`tool/coverage_gate.dart`, pre-existing — confirmed it applies): clean tree vs `11944b6` → `no touched lib/**.dart files — PASS` exit 0; planted untracked uncovered `lib/_gate_probe.dart` → `FAIL … NO COVERAGE DATA` exit 1; probe removed, tree clean.
- **Gates:** no unit/acceptance/grade gate (scaffold, no AC, no lib). **Fix passes: 0/3.**
- **Tokens/Time:** see dashboard (CAM-1 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase:** the `BS19_RUN_PENDING` runner at `integration_test/live_camera/pending.dart` and its 10-row `pendingACs` map (the single source of truth for which AC is pending). ITEST-1 builds the harness + `ScriptedCameraSource` on top of it; ITEST-2/3 register the 10 ACs via `acTestWidgets`; each behaviour phase un-pends its AC by deleting its row.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`/`gtimeout`, run bare):
  - Unit + coverage: `flutter test --coverage test/`
  - Coverage gate on touched files: `dart run tool/coverage_gate.dart 11944b6` (base = branch point; `COVERAGE_GATE_BASE` also honoured)
  - Acceptance suite (default, once ITEST lands): `flutter test -d flutter-tester integration_test/live_camera/`
  - Acceptance run-pending / red baseline: add `--dart-define=BS19_RUN_PENDING=true`
  - Sibling off-lane flake suites: `flutter test -d flutter-tester integration_test/{palette,self_assessment,display}_test.dart` (the 3 carried known flakes — reproduce at merge-base, not regressions; whole `integration_test/` dir won't launch at once under load — run per file).
- **Next (CAM-2, shell):** add the `camera` plugin to `pubspec.yaml`, declare an inert `CameraCaptureSource implements CaptureSource`, stub `frame_conversion.dart`, and introduce a `selectCaptureSource(...)` factory seam that still returns the software source by default (no behaviour change). CAM-2 ∥ PERM-1 ∥ VIEW-1.
- **Known gaps:** none introduced. Base `main` does not include the signed-off-but-unmerged bs-18; bs-19 extends bs-02 capture code present on main (deliberate — see master plan). Both may touch `capture_live_view.dart` and reconcile at their respective merges.

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

### Result
Inert camera-source shell — **no behaviour change** (the app still assembles and boots on the software source; the acceptance suite does not exist yet, so only the unit gate + existing suite run for a shell).
- **Dependency:** `camera: ^0.12.1` added to `pubspec.yaml` (`flutter pub get` resolved camera 0.12.1 + camera_platform_interface 2.15.0 et al.; project-local). `camera_platform_interface: ^2.15.0` added to **dev_dependencies** so the conversion test can build a real `CameraImage` from `CameraImageData` on the host.
- **New lib files (all 100% covered):**
  - `lib/capture/source/camera_capture_source.dart` — `CameraCaptureSource implements CaptureSource`, every member present but inert/device-free: `frames`/`stability` = `const Stream.empty()`; `lighting` adequate; `referenceCardPresent` false; `normaliseAgainstCard` returns its arg (D-6); lock + torch + importPhoto record local state; `supportsWideGamut`/`supportsRaw` false; `colorSpace` sRGB; `captureMode` processed (D-6). No `CameraController`, no plugin call — construction is cheap.
  - `lib/capture/source/frame_conversion.dart` — `Frame frameFromCameraImage(CameraImage)`; signature fixed, body `throw UnimplementedError` (real YUV420/BGRA conversion is CAM-3).
  - `lib/capture/source/capture_source_factory.dart` — `selectCaptureSource({required CaptureSource Function() softwareFallback, bool useCamera=false})`; returns the fallback unless `useCamera` (then a `CameraCaptureSource`). PERM-2 drives `useCamera`.
- **Wiring:** `lib/main.dart` `assembleDependencies` now sets `captureSource: selectCaptureSource(softwareFallback: demoCaptureSource)` — default `useCamera:false` ⇒ still a `SoftwareCaptureSource`, so `smoke_test` assertions (and the Capture-route boot) hold unchanged.
- **Tests:** +12 unit tests (`camera_capture_source_test.dart` 9, `capture_source_factory_test.dart` 2, `frame_conversion_test.dart` 1). `dart analyze lib/capture/source/ test/capture/source/ lib/main.dart` → No issues.
- **Gates:** unit + coverage **PASS** — `flutter test --coverage test/` = **1655 passed** (1643 baseline + 12), exit 0; `dart run tool/coverage_gate.dart 11944b6` = **100% line coverage on all 4 touched lib files** (camera_capture_source, capture_source_factory, frame_conversion, main.dart). No acceptance/grade gate (shell). **Fix passes: 0/3.**
- **Tokens/Time:** see dashboard (CAM-2 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase (interfaces CAM-3+ build on):**
  - `CameraCaptureSource()` — no-arg, cheap. CAM-3 adds the `CameraController` wiring (inject the controller so it stays host-testable) and feeds `frames` from `startImageStream`; CAM-5 wires the lock controls to AE·AWB·AF and reflects `locks`; CAM-6 wires torch to `setFlashMode`; CAM-7 adds lifecycle release/resume. Each overrides the inert member it owns — the shell's recorded-state defaults keep the controller's reflections honest until then.
  - `frameFromCameraImage(CameraImage) → Frame` — CAM-3 replaces the `throw` with the real conversion (YUV420 Android / BGRA8888 iOS → RGB, downsampled, D-4) and unit-tests it against golden buffers.
  - `selectCaptureSource(...)` — the production source-selection seam; **PERM-2** sets `useCamera` from the resolved camera permission + availability (granted & camera present → live source; denied/none → software fallback).
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`/`gtimeout`, run bare):
  - Unit + coverage: `flutter test --coverage test/`
  - Coverage gate on touched files: `dart run tool/coverage_gate.dart 11944b6`
  - Analyze: `dart analyze lib/ test/`
- **Known gaps:** none introduced. The camera source is inert — it emits no frames and makes no device call; it is never selected in assembly yet (factory default is software). A real `CameraImage` for a host unit test is built via `CameraImage.fromPlatformInterface(CameraImageData(...))` (needs the `camera_platform_interface` dev dep, now added).
- **Next (CAM-3, behavior — GATED by G-2):** implement the real frame stream + `frameFromCameraImage`. Depends on CAM-2 (done) **and** ITEST-4 (G-2 test-review approval); blocks VIEW-2, CAM-4/5/6/7, PERM-2. The two remaining shells (PERM-1, VIEW-1) are startable now, concurrently.

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

### Result
Real `CameraImage → Frame` conversion (AC-2) + the live frame stream, over an injected `CameraDevice` seam.
- **`frame_conversion.dart`:** `frameFromCameraImage` implemented — iOS **BGRA8888** read as B,G,R,A→RGB through the plane's `bytesPerRow`/`bytesPerPixel` (exact); Android **YUV420** decoded as **full-range BT.601 (JFIF)** — `R=Y+1.402V'`, `G=Y−0.344136U'−0.714136V'`, `B=Y+1.772U'` — through each plane's own strides with 2×2 chroma subsampling. Result tagged `FrameColorSpace.srgb` (D-6) and nearest-neighbour **downsampled toward a 64px longest side** (D-4, matches the software feed size); integer step `src~/step` output dims keep every sampled `(x,y)` in-bounds with no per-pixel clamp. Unsupported formats `throw ArgumentError`.
- **`camera_capture_source.dart`:** new `CameraDevice` seam (`start(onImage)` / `stop()`); `frames` now opens a `StreamController` that on first-listen calls `_device.start(...)`, converts each delivered `CameraImage` via `frameFromCameraImage` and emits it, and on cancel calls `_device.stop()` — fully host-tested with a fake device. The inert lock/torch/colour members are unchanged (CAM-5/6/7 own them). Shipped concrete `PluginCameraDevice` drives the real `CameraController` (first camera, `ResolutionPreset.medium`, platform-native image format) — its two device-bound methods are `// coverage:ignore`-wrapped (genuinely unreachable under `flutter-tester`; verified by the D-5 on-device walkthrough at sign-off), the only ignore in `lib/`.
- **AC-2 un-pended** (`pending.dart` row removed); `smoke_test.dart` pending-gate guard changed from the fixed "all 10 pending" to an exact-set assertion `{AC-1..AC-10}\{AC-2}` + "delivered AC-2 runs by default" (independent grader: NON-VACUOUS).
- **Gates:** `dart analyze` clean. Unit **1670 pass**; coverage gate **PASS** — 100% line on both touched lib files (`camera_capture_source.dart`, `frame_conversion.dart`) with the device-bound plugin calls coverage-ignored. Acceptance (default, per file `-d flutter-tester`): **AC-2 green**, all later ACs still skipped/pending; AC-2 also green under `--dart-define=BS19_RUN_PENDING=true`. **Grade gate: 1×A** (sole un-pended AC; fresh independent grader confirmed AC-2 holds A against the live conversion). No augmentation owed (CAM-3 Augments: none). **Fix passes: 1/3** (moved `// coverage:ignore-start` above `@override` so the two annotation lines were exempted).
- **Tokens/Time:** see dashboard (CAM-3 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase (downstream builds on):**
  - `frameFromCameraImage(CameraImage) → Frame` — the real BGRA/YUV420 converter (sRGB, 64px-downsampled). VIEW-2/CAM-4 render/sample frames the active source yields; in tests that is `ScriptedCameraSource.frames` (unchanged), so they do **not** depend on the real device feed.
  - `CameraDevice` seam + `CameraCaptureSource({CameraDevice? device})` — CAM-5 wires lock controls, CAM-6 the torch, **CAM-7** the lifecycle release/resume. CAM-7 can reuse the `onListen`/`onCancel` acquire/release already on `frames` and should drive the controller over a `WidgetsBindingObserver` (D-7). PERM-2 flips `selectCaptureSource(useCamera:)` so production actually constructs `CameraCaptureSource()` (→ default `PluginCameraDevice`); no device glue is owed by PERM-2.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`, run bare):
  - Unit + coverage: `flutter test --coverage test/` (or the `test/capture/source/` subset to re-gate the touched files faster)
  - Coverage gate: `dart run tool/coverage_gate.dart 98f0d2f` (base = CAM-3 BASE)
  - Acceptance (default, per file): `flutter test -d flutter-tester integration_test/live_camera/<file>_test.dart`; run-pending adds `--dart-define=BS19_RUN_PENDING=true`.
- **Known gaps:** the real `PluginCameraDevice` is unverified by automated tests (device I/O; D-5 sign-off walkthrough). Production still defaults to the software source (factory `useCamera:false`) until PERM-2, so the live feed is not yet reachable in the shipped app.
- **Next:** VIEW-2 (merge-risky `capture_live_view.dart` pair with this phase — but CAM-3 did **not** touch `capture_live_view.dart`, so no conflict), CAM-4/5/6/7 ∥, PERM-2→PERM-3, PERM-4. Each un-pends its AC + makes its augmentation.

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

### Result
AC-3 delivered as an **un-pend + keep-green** phase — **no product code, no test-logic change** (the reading-follows-frame behaviour is the existing source-agnostic sampling, already enabled by CAM-3's real frame stream; the discriminating c1→c2 augmentation was already written in ITEST-2).
- **Change:** deleted AC-3's row from `integration_test/live_camera/pending.dart` (un-pend), so `TestAC03_ReadingFollowsFrame` now runs in the **default** suite. Updated the `smoke_test.dart` pending guards: `unpendedACs` set → `{AC-1, AC-2, AC-3}` (exact-set assertion, non-vacuous), and moved the pending-skip example AC-3→AC-4 (owner VIEW-3, still genuinely pending). No `lib/` touched.
- **Confirmation (task 1):** the live frame flows into the reading path unchanged — the real `CaptureController._onFrame` samples each `source.frames` frame via `sampleAreaAverage` into `state.currentSample`; the fake supplies only the frame buffer (the camera device, G2), not the reading. Smoke test re-proves the feed reaches the controller.
- **Gates:** `dart analyze integration_test/live_camera/` clean. Unit **1672 pass**, exit 0 (unchanged — no unit/lib change). Coverage gate vs BASE `49f9848`: **no touched lib/**.dart files — PASS**. Acceptance: **AC-3 green in the default run** (and run-pending); AC-1/AC-2 still green by default; later ACs (AC-4/5/6/7/8/9/10) still pending. Smoke **11/11** (updated guards green). **Grade gate: 3×A / 0 below A** — a fresh independent grader re-graded every un-pended AC test (AC-1, AC-2, AC-3); all hold A, no downgrade from the prior grid, no fix owed. **Fix passes: 0/3.**
- **Augmentation:** `TestAC03` augmentation (reading changes c1→c2, rejects a stale/fixed sampler) **closed** — already present from ITEST-2; CAM-4 un-pended it and kept it green. No new augmentation enabled for an already-green neighbour (AC-1/AC-2 unaffected).
- **Tokens/Time:** see dashboard (CAM-4 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase:** nothing new in `lib/` — the reading path and `CameraCaptureSource` are unchanged. AC-3 is delivered; the real-device confirmation that the live feed drives the reading on hardware rests with the D-5 sign-off walkthrough (as for AC-2's `PluginCameraDevice`).
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`, run bare):
  - Unit + coverage: `flutter test --coverage test/`
  - Coverage gate: `dart run tool/coverage_gate.dart <BASE>` (CAM-4 BASE = `49f9848`)
  - Acceptance (default, per file): `flutter test -d flutter-tester integration_test/live_camera/reading_test.dart`; add `--dart-define=BS19_RUN_PENDING=true` for run-pending. Run per file — two files in one invocation can hit the "log reader failed / Unable to start the app" launcher flake (infra, not a test failure).
- **Known gaps:** none introduced. AC-3's real-device feed is unverified by automated tests (device I/O; D-5 walkthrough), as with AC-2.
- **Next:** CAM-5 (AC-5), CAM-6 (AC-6), CAM-7 (AC-9) — all own `camera_capture_source.dart`, so sequence them to avoid clobbering. VIEW-3 (AC-4), PERM-2 (AC-7)→PERM-3 (AC-8), PERM-4 (AC-10, un-pend + confirm only) run concurrently (disjoint files).

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
