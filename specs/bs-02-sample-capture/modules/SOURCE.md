# Module SOURCE — capture source + sampling

**Status:** ✅ Done — SOURCE-1 (shell), SOURCE-2 (AC-2: live feed + point/area-average sampling), SOURCE-3 (AC-9: gallery-photo import + sample point P) all done; 100% covered, AC-2 & AC-9 un-pended green, grade A.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/source/capture_source.dart` (interface), `lib/capture/source/software_capture_source.dart`, `lib/capture/source/sampling.dart` (point / area-average / from-photo), `lib/capture/source/frame.dart` (frame model).
**Depends on:** bs-01 domain (`ColorCoordinates`) · **Blocks:** CAPTURE-2 (controller consumes the source), SCREEN behavior (reticle reads radius)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 2,451,815 | 12m 12s (12m 12s) |
| 2 | behavior | AC-2 | ✅ Done | 13,393,296 | 23m 23s (23m 23s) |
| 3 | behavior | AC-9 | ✅ Done | 13,040,341 | 20m 59s (20m 59s) |

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

### Result

Landed AC-2 — the live feed and point/area-average sampling, wired into `currentSample`:

- **`sampling.dart`:** `samplePoint` (single pixel → CIELAB), `sampleAreaAverage` (true per-channel sRGB
  mean over the disc of `radiusPx`, clamped to frame bounds, then one CIELAB conversion), `averageFrames`
  (per-pixel mean across frames, for CAPTURE-6). sRGB→CIELAB reuses the `color_models` library (plan D-2 — the
  same library bs-01's conversions use for the inverse direction), since the `ColorScience` interface exposes
  only CIELAB→X and the frozen sampling signatures take no `ColorScience`. `sampleFromPhoto` stays deferred to
  SOURCE-3.
- **`software_capture_source.dart`:** `frames` now generates a **finite** live feed (12 frames, 64×64) from
  `SceneSpec.groundTruth` when no explicit frames are given — uniform at `noise:0`, and with an antisymmetric
  per-frame offset at `noise>0` whose mean over the feed is exactly the ground truth (so `averageFrames`
  recovers it for AC-11). Explicit frames are still replayed. `.stability` left as the SOURCE-1 placeholder —
  the settling signal is CAPTURE-3's.
- **`capture_controller.dart`:** subscribes to the feed in its constructor and samples the frame centre at the
  current `radiusPx` into `currentSample` (measured provenance, current accuracy) on every frame — the feed
  drives the reading passively (no painter action). `dispose` cancels the subscription.

**Gates (Flutter 3.47.6):** `flutter analyze` clean. Unit suite green — 290 tests (288 + 2 new controller
tests); coverage gate **PASS, 100% line coverage** on all 16 touched `lib` files (base `main`), including the
new sampling/feed/subscription branches (edge-clamp + outside-disc skips unit-tested). **Acceptance gate:**
AC-2 un-pended (removed from `bs02/pending.dart`; pending-gate scaffold updated to 9); default integration run
green — `TestAC02_AreaAverage5px` passes live (5 px average ≈ inner disc, rejects point read and wider radius),
AC-1 stays green, the other 9 ACs skip as pending. **Grade gate:** fresh independent grader re-graded the
un-pended tests against live behaviour — **AC-1 A, AC-2 A (2×A, 0×B)**; whole-suite grid unchanged at
**10×A + AC-6 B-pending-CAPTURE-5**. **Augmentations:** none. **Fix passes: 0/3** (first full run clean).
Tokens 13,393,296 · time 23m 23s (23m 23s).

### Checkpoint / Handoff

- **Frozen now (SOURCE-2):** `samplePoint` / `sampleAreaAverage(radiusPx)` / `averageFrames` behaviour;
  `SoftwareCaptureSource.frames` generation contract (finite feed from `groundTruth`+`noise`, mean = ground
  truth); the controller's passive `currentSample` wiring (centre sample at `state.radiusPx` per frame,
  cancelled on dispose). Sampling takes raw sRGB `Pixel`s → canonical CIELAB via `color_models` (no new colour
  math); default radius 5 px.
- **Consumers:** **SOURCE-3** adds `sampleFromPhoto` (decode + area-average at P) and a photo-import flow that
  switches the controller's sampling from the live feed to the staged photo (observable via `currentSample`).
  **SCREEN-2** drives `setRadius` (still throws here) and retargets `whenSelectRadius` to per-option 1/5/21
  anchors over this radius-driven averaging (AC-3). **CAPTURE-6** commits via `averageFrames` over the feed
  (`framesAveraged > 1`; `FakeCaptureSource.framesRead` counts the generated frames).
- **Merge-risk with CAPTURE-3 (running ∥):** both edit `capture_controller.dart` (SOURCE-2: feed→`currentSample`
  subscription + `dispose`; CAPTURE-3: stability subscription + `lock`), `software_capture_source.dart`
  (SOURCE-2: `frames`; CAPTURE-3: `.stability`), and the shared scaffold in `integration_test/capture_test.dart`
  (SOURCE-2: smoke `currentSample` now `isNotNull`; CAPTURE-3: smoke `SETTLING 0/12` as it drives the counter)
  and the grade grid. Edits are additive / in separate members; reconcile both branches onto `main` with care.
- **Verification commands** (repo root; `export PATH="$HOME/development/flutter/bin:$PATH"` first):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` ·
  `flutter test integration_test/`.

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

### Result

Landed AC-9 — import a gallery photo and sample its point P, switching the reading off the live feed:

- **`sampling.dart`:** `sampleFromPhoto(image, x, y, radiusPx)` implemented — the photo arrives already decoded
  as a `Frame`, so it reuses `sampleAreaAverage` over the imported pixels at the chosen point P (default 5 px),
  no new colour math. Reading P (not the frame centre) is what distinguishes an import from a live-feed read.
- **`capture_source.dart`:** new `ImportedPhoto` value type (decoded `image` + sample point `pointX`/`pointY`)
  and two interface members — `ImportedPhoto? get importedPhoto` and `void importPhoto(ImportedPhoto)` — so the
  controller reads an imported photo through the public `CaptureSource` surface.
- **`software_capture_source.dart`:** holds the most-recently imported photo (`importPhoto` sets it,
  `importedPhoto` returns it; null until one is imported).
- **`capture_controller.dart`:** new `importPhoto()` action — reads `source.importedPhoto`, samples point P via
  `sampleFromPhoto` at the current radius, publishes it as a measured `currentSample` at the current accuracy,
  and sets a `_photoImported` flag so `_onFrame` stops letting the live feed overwrite the reading (the switch).
  A no-op when no photo is staged.
- **`capture_controls.dart`:** E19 "Import photo" enabled and wired to `controller.importPhoto` (was a disabled
  placeholder); only E18 (radius) remains a placeholder for SCREEN-2.
- **Test wiring:** the acceptance fake's `stagedPhoto` fixture is surfaced through the production `importedPhoto`
  getter (so staging a fixture == the painter picking that gallery image). Scaffold pending-gate test updated
  (AC-9 removed; 9 → 8 pending).

**Gates (Flutter 3.47.6):** `flutter analyze` clean. Unit suite green — 293 tests (290 + 3 new: controller
import + feed-switch + null-guard, sampleFromPhoto point-read + default-radius, source import hold/return);
coverage gate **PASS, 100% line coverage** on all 16 touched `lib` files (base `main`). **Acceptance gate:**
AC-9 un-pended; default integration run green — `TestAC09_SampleFromPhoto` passes live (reads point P, rejects
the image centre and the live camera); AC-1/AC-2 stay green; the other 8 ACs skip as pending (28 pass / 8 skip).
**Grade gate:** fresh independent re-grade of the un-pended tests (AC-1, AC-2, AC-9) against live behaviour —
**3×A, 0×B** (AC-9 A, now graded live; no downgrades); whole-suite grid **10×A + AC-6 B-pending-CAPTURE-5**.
**Augmentations:** none. **Fix passes: 1/3** — one fix after the first unit run: the AC-9 controller unit
test's photo swatch was a 3×3 square, too small for the default 5 px sampling disc, so the average bled into
the background; widened it to an r=6 disc (test-fixture fix; production code unchanged). Tokens 13,040,341
· time 20m 59s (20m 59s).

### Checkpoint / Handoff

- **Frozen now (SOURCE-3):** `sampleFromPhoto` behaviour (area-average at point P over a decoded `Frame`);
  the `CaptureSource` import surface — `ImportedPhoto {image, pointX, pointY}`, `importedPhoto`, `importPhoto` —
  and `SoftwareCaptureSource`'s hold-last-import semantics; the controller's `importPhoto()` action and the
  `_photoImported` feed-switch (once a photo is imported the live feed no longer overwrites `currentSample`).
  E19 is wired to `controller.importPhoto`.
- **Module SOURCE is complete** (SOURCE-1/2/3 all done). No SOURCE phases remain.
- **Consumers / interactions:** the import switch is one-way within a controller instance (no "return to live"
  flow is specified by bs-02). CAPTURE phases that read `currentSample` (e.g. CAPTURE-6 commit) see the imported
  sample after an import exactly as they see a live sample.
- **Merge-risk with CAPTURE-3 (running ∥, uncommitted in the primary checkout):** both edit
  `capture_controller.dart` — SOURCE-3 adds `importPhoto()` + the `_onFrame` early-return guard + a
  `_photoImported` field; CAPTURE-3 adds the settling tick + `lock()` behaviour and (in its WIP) reshapes
  `_onFrame`. Reconcile onto `main` carefully: keep SOURCE-2's passive `_onFrame` sampling AND SOURCE-3's
  `if (_photoImported) return;` guard at its top, alongside CAPTURE-3's settling logic. Re-run the suite after
  each merge.
- **Verification commands** (repo root; `export PATH="$HOME/development/flutter/bin:$PATH"` first):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` ·
  `flutter test integration_test/`.
