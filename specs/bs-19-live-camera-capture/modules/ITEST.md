# Module ITEST — Acceptance integration suite

**Status:** 🔶 In progress — ITEST-1..3 done; ITEST-4 packet assembled, ⏸ awaiting G-2 decision
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/live_camera/` (new), `integration_test/fakes/scripted_camera_source.dart` (new), the `BS19_RUN_PENDING` pending gate for this suite.
**Depends on:** CAM-2, PERM-1, VIEW-1 (all shells) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ✅ Done | 7,639,135 | 14m 08s |
| ITEST-2 | acceptance-tests | AC-1..AC-5 | ✅ Done | 14,061,597 | 34m 15s |
| ITEST-3 | acceptance-tests | AC-6..AC-10 | ✅ Done | 16,840,597 | 1h 16m |
| ITEST-4 | test-review | — (G-2) | ⏸ Awaiting review | | |

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

### Result
Harness + fixtures + scaffold tests only — **no `lib/` code** (coverage gate confirms 0 touched lib files; the harness drives the existing production `buildApp` directly, exactly as the bs-02 `capture_harness` does, so no assembly constructor had to be extracted).
- **New test files:**
  - `integration_test/fakes/scripted_camera_source.dart` — `ScriptedCameraSource implements CaptureSource`: a controllable feed (replays `initialFrames` on subscribe, then forwards `emitFrame` pushes so AC-3 can change the reticle colour mid-stream), settable `kind`/`permissionState`/`available` selection signals, settable `lighting`/`canLock`/`referenceCardPresent`, real lock/torch state, and `lockCalls`/`torchOnCalls`/`torchOffCalls` recorders for the AC-5/AC-6 "the control reached the source" augmentations. Plus `RecordingCameraPermission implements CameraPermission` (counts `request()`, resolves to a scripted granted/denied outcome — held for PERM-2, which wires a `CameraPermission` into the assembly) and a `knownFrame(Pixel)` uniform-frame builder.
  - `integration_test/live_camera/harness.dart` — the Given/When/Then vocabulary: `givenLiveCamera(tester, {source, permission})` builds the real app via `buildApp` with the scripted source at `AppDependencies.captureSource` (opens on Capture), single `pump` (not `pumpAndSettle`, mirroring bs-02 so the settle counter doesn't run to STABLE). `LiveCameraHarness` exposes `controller`/`state`, `activeSourceKind`/`permissionState` (via the read endpoint), `showsPlaceholder` (reads the live-view tree for the VIEW-1 placeholder), and `when…` actions (`whenLock`, `whenTurnTorchOn/Off`, `whenToggleValueOnly`, `whenCommit`, `whenFrameChangesTo`). Fixtures `FRAME_CYAN`/`FRAME_ORANGE` (distinct reticle colours for AC-2's conversion control and AC-3's c1→c2 change). Re-exports the pending gate + fakes.
  - `integration_test/live_camera/smoke_test.dart` — 1 never-pending smoke + 10 guard tests.
- **Pending gate:** untouched (CAM-1 seeded all 10 ACs); ITEST-2/3 register the AC tests via `acTestWidgets`.
- **Gates:** unit + coverage **PASS** — `flutter test test/` = **1666 passed** (baseline unchanged; ITEST-1 touches only `integration_test/`); coverage gate = **no touched lib files → PASS**. Acceptance (this feature): `smoke_test.dart` **11/11** green in default **and** `--dart-define=BS19_RUN_PENDING=true` modes; whole `integration_test/live_camera/` dir launches green. No AC tests yet → no acceptance/grade-vs-spec gate; scaffold tests are **non-vacuous** (smoke asserts feed reaches the controller *and* the render is still the honest VIEW-1 placeholder; the pending guard asserts the map's exact size=10 and contents with real owners; the fixture guards assert actual recording, both lock-honouring and lock-refusing paths). **Fix passes: 0/3** (green on first full test run).
- **Tokens/Time:** see dashboard (ITEST-1 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase (the surface ITEST-2/3 write against):**
  - `givenLiveCamera(tester, {ScriptedCameraSource? source, RecordingCameraPermission? permission}) → LiveCameraHarness` — defaults: a camera-kind scripted source seeded with `FRAME_CYAN`, a granting permission recorder.
  - `LiveCameraHarness`: `controller`, `state`, `activeSourceKind`, `permissionState`, `showsPlaceholder`, `readEndpoint`; actions `whenLock`, `whenTurnTorchOn`, `whenTurnTorchOff`, `whenToggleValueOnly`, `whenCommit`, `whenFrameChangesTo(Frame)`.
  - `ScriptedCameraSource({initialFrames, kind, permissionState, available, lighting, canLock, referenceCardPresent})` + `setKind`, `emitFrame`, `dispose`, recorders `lockCalls`/`torchOnCalls`/`torchOffCalls`.
  - `RecordingCameraPermission({initial, resolvesTo})` + `requestCount`.
  - `knownFrame(Pixel, {width, height})`; `FRAME_CYAN`/`RETICLE_CYAN`, `FRAME_ORANGE`/`RETICLE_ORANGE`.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has no `timeout`, run bare):
  - Acceptance (default): `flutter test -d flutter-tester integration_test/live_camera/<file>_test.dart` (whole dir works now but run per file under load).
  - Red baseline / run-pending: add `--dart-define=BS19_RUN_PENDING=true`.
  - Unit + coverage: `flutter test --coverage test/`; gate: `COVERAGE_GATE_BASE=<phase-start HEAD> dart run tool/coverage_gate.dart` (ITEST adds no lib, so expect "no touched lib files PASS").
- **Next (ITEST-2 ∥ ITEST-3):** write the one *pending* AC test per AC against this harness, run run-pending, record the red baseline + grades in the tables below. ITEST-2 = AC-1..AC-5 (`preview_test.dart`, `reading_test.dart`); ITEST-3 = AC-6..AC-10 (`controls_test.dart`, `permission_test.dart`, `platform_test.dart`). Disjoint files → parallel-safe.
- **Known gaps / watch-outs for the AC phases:**
  - **No permission seam in `buildApp` yet** — `AppDependencies` has no `cameraPermission` field (PERM-1 added the `CameraPermission` seam but not its injection; PERM-2 wires it). So AC-7's "the permission seam received exactly one request" and the granted→camera / denied→software selection cannot be driven through the assembly yet; AC-7's test asserts them via a Given precondition naming **PERM-2** and stays pending. `permissionState` on the read endpoint is inert `undetermined` until PERM-2.
  - **Render path still the placeholder** — the Capture screen builds `CaptureLiveView` with no `frame:`, so `showsPlaceholder` is true even though the feed reaches the controller. AC-1 (render) is red until **VIEW-2** feeds the source's frame in.
  - **`emitFrame` timing** — push a frame *then* `pump` (as `whenFrameChangesTo` does); a frame pushed before the controller subscribes (its `didChangeDependencies`) is dropped by the broadcast stream.

## Phase ITEST-2 — AC-1..AC-5 pending + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-1..AC-5 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/live_camera/preview_test.dart`, `reading_test.dart`
- **Tasks:** write `TestAC01_LivePreview`, `TestAC02_FrameConversion`, `TestAC03_ReadingFollowsFrame`, `TestAC04_ValueOnlyLive`, `TestAC05_LockClearsWarning` per the catalogue; run run-pending; record the red baseline + grades; confirm/amend augmentation rows.
- **Exit criteria:** each pending test fails on a Then or a Given precondition naming its owning phase (or is recorded *green at baseline* with its augmentation); grade grid all A (or *B pending*).
- **Acceptance gate:** —

### Result
Five *pending* AC tests over the ITEST-1 harness — **no `lib/` code** (coverage gate = no touched lib files → PASS; analyze clean).
- **New test files (ITEST-2 owns):**
  - `integration_test/live_camera/preview_test.dart` — `TestAC01_LivePreview` (AC-1), `TestAC02_FrameConversion` (AC-2), `TestAC04_ValueOnlyLive` (AC-4). AC-1/AC-4 drive the real app via `givenLiveCamera` and read the live-view tree (`showsPlaceholder`, `LiveFrameView.frame`, `ColorFiltered` ancestry over `liveViewKey` vs `accuracyKey`). AC-2 is a pure-Dart conversion test over `frameFromCameraImage`: it builds platform-shaped `CameraImage` fixtures (`_bgraImage`/`_yuvImage` — the plan's `rawCameraImage(yuv420/bgra)`) of a uniform known colour and asserts the converted `Frame`'s reticle pixel reproduces it.
  - `integration_test/live_camera/reading_test.dart` — `TestAC03_ReadingFollowsFrame` (AC-3), `TestAC05_LockClearsWarning` (AC-5). Read `currentSample` (via `_science.toSRGB`) and the rendered `exposureUnlocked` warning text through the public surface.
- **Red baseline** (`--dart-define=BS19_RUN_PENDING=true`, per file): AC-1 ❌ red on its Then (`showsPlaceholder` still true → VIEW-2); AC-2 ❌ red on the `returnsNormally` guard (`frameFromCameraImage` throws `UnimplementedError … CAM-3` — clean `TestFailure`, not a panic); AC-4 ❌ red on its Given precondition `liveView.frame isNotNull` naming VIEW-2. **AC-3 ✅ and AC-5 ✅ green at baseline** (sampling + lock/warning pipeline already source-agnostic), written *with* their discriminating controls so each still rejects a fixed/independent impl (plan line 94). Default run skips all 5; smoke 11/11 (pending guard confirms exactly 10 ACs pending — pending map untouched).
- **AC-2 conversion contract pinned (for G-2 review):** iOS BGRA8888 byte order B,G,R,A (exact, tol L1 3); Android YUV420 full-range BT.601 read through each plane's `bytesPerRow`/`bytesPerPixel` strides (uniform frame → downsample-lossless, tol L1 12). The stride-respecting fixture nudges CAM-3 toward a robust converter.
- **Grades:** fresh independent grader (did not write the tests) → first pass **4×A, 1×B**; the B (AC-2, G5 — `_yuvToleranceL1=30` let a limited-/video-range BT.601 mis-decode (L1 21) pass) was fixed in-phase by tightening the tolerance 30→12 (correct decode ≤ L1 3; limited-range 21/29 now rejected), baseline unchanged. **Re-grade 5×A, 0×B.** Grid: `behavior-test-completeness-bs-19-live-camera-capture.md`.
- **Gates:** analyze clean; unit+coverage = no touched lib → PASS; acceptance = red baseline recorded + default green + smoke green; grade gate 5×A. **Fix passes: 1/3** (AC-2 YUV tolerance).
- **Tokens/Time:** see dashboard (ITEST-2 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase (the surface ITEST-3 + the behaviour phases build against):**
  - AC tests registered via `acTestWidgets('AC-n', …)`; un-pend = delete the `pendingACs` row. Test names: `TestAC01_LivePreview`, `TestAC02_FrameConversion`, `TestAC03_ReadingFollowsFrame`, `TestAC04_ValueOnlyLive`, `TestAC05_LockClearsWarning`.
  - AC-2 fixtures `_bgraImage(Pixel)` / `_yuvImage(Pixel)` (private to `preview_test.dart`) + the pinned conversion contract above — CAM-3 must satisfy it.
  - **Two-app-per-test gotcha:** `buildApp`'s root element is reused across a second `pumpWidget` of the same type, so the Capture controller (built in `initState`) keeps the *first* source. To mount a second independent scenario in one test, pump a different root first (`await tester.pumpWidget(const SizedBox())`) — AC-5's control does this. ITEST-3 phases building multi-scenario tests must do the same.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has no `timeout`, run bare; launch per file, the dir won't launch at once):
  - Acceptance (default): `flutter test -d flutter-tester integration_test/live_camera/<file>_test.dart`.
  - Red baseline / un-pend: add `--dart-define=BS19_RUN_PENDING=true`.
  - Coverage gate: `COVERAGE_GATE_BASE=<phase-start HEAD> dart run tool/coverage_gate.dart`.
- **Next:** ITEST-3 (AC-6..AC-10 pending + red baseline, disjoint files: `controls_test.dart`, `permission_test.dart`, `platform_test.dart`). ITEST-2 ∥ ITEST-3 are disjoint; ITEST-3 is startable now. Then ITEST-4 (test review = G-2) needs both done.
- **Carried watch-outs (unchanged):** AC-7 stays pending on a PERM-2 precondition (no `cameraPermission` seam in `AppDependencies` yet; `permissionState` inert `undetermined`). AC-6 torch augmentation is ITEST-3's.

## Phase ITEST-3 — AC-6..AC-10 pending + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-6..AC-10 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Files:** `integration_test/live_camera/controls_test.dart`, `permission_test.dart`, `platform_test.dart`
- **Tasks:** write `TestAC06_Torch`, `TestAC07_PermissionFallback`, `TestAC08_NoCameraFallback`, `TestAC09_Lifecycle`, `TestAC10_PlatformDeclarations` per the catalogue; red baseline + grades; augmentation rows.
- **Exit criteria:** as ITEST-2.
- **Acceptance gate:** —

### Result
Five *pending* AC tests over the ITEST-1 harness — **no `lib/` code** (coverage gate = no touched lib files → PASS; analyze clean).
- **New test files (ITEST-3 owns):**
  - `integration_test/live_camera/controls_test.dart` — `TestAC06_Torch` (AC-6), `TestAC09_Lifecycle` (AC-9). AC-6 drives the real E-torch control: toggle on → `source.torchOn`/`torchOnCalls`, torch warning banner; toggle off → extinguished/`torchOffCalls`; then two fresh scenarios (SizedBox reset) for the `litByTorch` commit stamp (lit → true) and a torch-off control (→ false). AC-9 drives app-lifecycle via `tester.binding.handleAppLifecycleStateChanged` against the scripted source's new `acquireCount`/`releaseCount` recorders.
  - `integration_test/live_camera/permission_test.dart` — `TestAC07_PermissionFallback` (AC-7), `TestAC08_NoCameraFallback` (AC-8). AC-7 drives a `RecordingCameraPermission` (granted + denied branches) and reads `permission.requestCount`, `activeSourceKind`, `permissionState` and the "Camera access" affordance. AC-8 injects an `available:false` camera-kind source and asserts the active source resolves to `software`.
  - `integration_test/live_camera/platform_test.dart` — `TestAC10_PlatformDeclarations` (AC-10): a source-scan (bs-11/12/13 idiom) of the real `AndroidManifest.xml` + `Info.plist` for the CAMERA permission, the camera `<uses-feature>`, and a structured non-empty `NSCameraUsageDescription`.
- **Fixture change (additive):** `ScriptedCameraSource` gains `acquireCount`/`releaseCount` recorders — a try/finally around the `frames` generator counts each subscription (acquisition) and its end (release); semantics of the replay-then-forward feed are unchanged (ITEST-2's AC-3 still green).
- **Red baseline** (`--dart-define=BS19_RUN_PENDING=true`, per file): **AC-6 ✅ green**, **AC-10 ✅ green** at baseline; **AC-7 ❌** red on `requestCount==1` (naming PERM-2), **AC-8 ❌** red on `activeSourceKind==software` (naming PERM-3), **AC-9 ❌** red on `releaseCount>=1` after background (naming CAM-7). All reds are clean `TestFailure`s (no panic/hang). Default run skips all 5 (`All tests skipped`); smoke 11/11 (pending map still exactly 10).
- **Grades:** independent fresh grader (did not write the tests) → **5×A, 0×B** on the first grading pass. Grid: `behavior-test-completeness-bs-19-live-camera-capture.md` (`## Grade — ITEST-3`).
- **Gates:** analyze clean; unit+coverage = **1666 pass**, no touched lib → PASS; acceptance = red baseline recorded + default all-skipped + smoke green; grade gate 5×A. **Fix passes: 1/3** — the first AC-9 run *hung*: `pumpAndSettle`/`pump` while the app is `paused` never returns on the **live** `IntegrationTestWidgetsFlutterBinding` (the engine stops producing frames). Fixed by settling the stability tick first and dispatching the background sequence with **no** frame pump (`tester.idle()` drains the async release), pumping only once back in `resumed`. No gate bar was lowered.
- **Tokens/Time:** see dashboard (ITEST-3 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase (the surface the behaviour phases build against):**
  - AC tests registered via `acTestWidgets('AC-n', …)`; un-pend = delete the `pendingACs` row. Test names: `TestAC06_Torch`, `TestAC07_PermissionFallback`, `TestAC08_NoCameraFallback`, `TestAC09_Lifecycle`, `TestAC10_PlatformDeclarations`.
  - `ScriptedCameraSource.acquireCount`/`releaseCount` — a subscription is an acquisition, its end a release; CAM-7's lifecycle observer must cause releaseCount≥1 on background and acquireCount≥2 on resume (likely by disposing+recreating the `CaptureController`, which cancels+re-subscribes the feed — no new `CaptureSource` member needed).
  - **Live-binding lifecycle gotcha:** never `pump`/`pumpAndSettle` while the app is `paused` — it hangs forever on `flutter-tester`. Dispatch lifecycle transitions, use `tester.idle()` to drain, and pump only after `resumed`. CAM-7's un-pend must keep this shape.
  - **AC-7/AC-8 contracts for PERM-2/PERM-3:** AC-7 expects the assembly to request permission exactly once on live-capture entry (through an injected `CameraPermission`), select camera on granted / software on denied, and render a "Camera access"-prefixed affordance on denial. AC-8 expects an availability probe to fall back to software when the source reports `available:false`. Both need the harness wired to run the **real selection** (inject the selection *inputs*, not an already-chosen source) — PERM-2/PERM-3's test-infra change.
- **⚠ AC-10 / PERM-4:** the platform declarations already shipped in the **PERM-1 shell**, so AC-10 is green now. PERM-4 has **no new product work** — its residual is purely un-pend (delete the `pendingACs` AC-10 row) + confirm green. Raised for the G-2 reviewer and PERM-4.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has no `timeout`, run bare; launch per file):
  - Acceptance (default): `flutter test -d flutter-tester integration_test/live_camera/<file>_test.dart`.
  - Red baseline / un-pend: add `--dart-define=BS19_RUN_PENDING=true`.
  - Coverage gate: `COVERAGE_GATE_BASE=<phase-start HEAD> dart run tool/coverage_gate.dart`.
- **Next:** ITEST-4 (test review = G-2) — needs ITEST-2 **and** ITEST-3 done (both are). Assemble the packet and set the phase awaiting review; no behaviour phase may start before G-2.

## Phase ITEST-4 — Test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (per AC: test name, Given checks, When, Then + Rejects; red-baseline summary; augmentations scheduled + closing phase; grid path + counts; what to look at first — esp. the green-at-baseline source-agnostic ACs 3/5/6 and the hardware-faking boundary). Set `⏸ Awaiting review`; G-2 awaiting decision.
- **Exit criteria:** packet complete; grid all A (or *B pending*); stop with `/feature-next-phase --gate bs-19-live-camera-capture G-2 approved | "<changes>"`.
- **Acceptance gate:** —

### Result

**Status: ⏸ Awaiting review — G-2 awaiting human decision.** No `lib/` or test code changed this phase (packet assembly only; coverage N/A). Packet below is the whole acceptance suite put in front of a human before any behavior is coded.

#### Review packet — bs-19 acceptance suite (G-2)

**Scope.** 10 pending integration tests, one per AC, over the ITEST-1 harness (`givenLiveCamera` → real `buildApp`, the only faked thing the camera device via `ScriptedCameraSource` at `AppDependencies.captureSource` + a `RecordingCameraPermission`). Lane: `-d flutter-tester`, per file. Pending gate `BS19_RUN_PENDING`; default run skips all 10, smoke (never-pending) stays green at 11/11.

**Grid:** `specs/bs-19-live-camera-capture/behavior-test-completeness-bs-19-live-camera-capture.md` — **10 A / 0 B**, independent fresh grader (did not write the tests), 2026-10-21. ITEST-2 grid (AC-1..5) + ITEST-3 grid (AC-6..10). AC-2 was B→A in-phase (YUV tolerance 30→12).

**Look at first (reviewer):**
1. **The hardware-faking boundary** (D-5): every test drives the real app + real `CaptureController` + real conversion maths; only the camera *device* is scripted. Satisfy yourself the scripted source is a faithful stand-in and not a shortcut past the behavior. The real `camera`-plugin source (`CameraCaptureSource`) is exercised by the **device walkthrough at sign-off**, not here.
2. **The 4 green-at-baseline ACs (AC-3, AC-5, AC-6, AC-10)** — they pass today because the reading/lock/torch pipeline is source-agnostic and the manifests already ship. Confirm each still *rejects* a placeholder/fixed/independent impl via its control (detailed per-AC below); their behavior phases' residual is "un-pend + keep green".
3. **⚠ AC-10 / PERM-4:** the platform declarations already landed in the **PERM-1 shell**, so AC-10 is green now and **PERM-4 has no new product work** — residual is purely un-pend + confirm. Flagged so the reviewer knows PERM-4 is bookkeeping.
4. **AC-7 / AC-8 wiring note:** both rest on the production *source selection*, which the assembly doesn't run yet. PERM-2/PERM-3 must wire the harness to inject selection *inputs* (permission outcome + availability), not an already-chosen source. The AC-7 denied-branch control already proves permission (not injected kind) is what answers.

**Per-AC** — test · Given (checked on public surface) · When · Then + Rejects:

| AC | Test | Given (pre-When check) | When | Then + Rejects |
|---|---|---|---|---|
| AC-1 | `TestAC01_LivePreview` | read endpoint `activeSourceKind==camera` (granted-camera selection) | Capture screen opens | `showsPlaceholder` false **and** `LiveFrameView.frame` not null. Rejects: a view that keeps the placeholder / ignores frames. |
| AC-2 | `TestAC02_FrameConversion` | raw buffer bytes `[b,g,r,255]` (BGRA) / Y-plane byte (YUV) == known | convert `CameraImage`→`Frame` | reticle pixel == known within tol (BGRA L1≤3, YUV L1≤12) + a 2nd colour yields a different pixel. Rejects: BGR↔RGB swap, mis-ranged/limited-range YUV, constant pixel. |
| AC-3 | `TestAC03_ReadingFollowsFrame` | current reading ≈ c1 (RETICLE_CYAN), control c1≠c2 (450 L1) | source emits `knownFrame(c2)` | reading follows to c2 **and** not stale (≫ from c1). Rejects: stale/placeholder/fixed sampler. *(green at baseline)* |
| AC-4 | `TestAC04_ValueOnlyLive` | live `frame` not null (VIEW-2) + no placeholder | value-only toggled on | `ColorFiltered` ancestor over `liveViewKey` **and** none over `accuracyKey`. Rejects: graying whole screen incl. readings; filtering placeholder only. |
| AC-5 | `TestAC05_LockClearsWarning` | `source.locks.allLocked` false + "Exposure not locked" warning present | painter locks AE+AWB+AF | `allLocked` true **and** that warning gone; **control:** `canLock:false` source keeps warning despite UI lock. Rejects: clearing warning without locking; UI flag not reflecting source. *(green at baseline)* |
| AC-6 | `TestAC06_Torch` | `source.torchOn` false, `torchOnCalls==0`, torch-off affordance | painter turns torch on | `torchOn` true + `torchOnCalls==1` (reached device) + committed sample `litByTorch`; off-path extinguishes (`torchOffCalls==1`); control: torch-off commit `litByTorch:false`. Rejects: toggle not reaching source; missing/always-on stamp. *(green at baseline)* |
| AC-7 | `TestAC07_PermissionFallback` | recorder `requestCount==0`, status undetermined | Capture opened for live read | `requestCount==1` exactly; granted→`camera`, denied→`software` + "Camera access" affordance + no throw. **Control:** denied branch injects an identical `kind==camera` source, so only the permission decision explains camera→software. Rejects: never requesting; crash/black on denial; staying on dead camera. |
| AC-8 | `TestAC08_NoCameraFallback` | `source.available` false | Capture opens | `activeSourceKind==software`; reading still works; no throw. Discrimination built in: injected `kind==camera`, so echoing injected kind fails `==software`. Rejects: crash/black; forcing a camera that can't stream. |
| AC-9 | `TestAC09_Lifecycle` | `acquireCount==1`, `releaseCount==0`, opening reading renders live frame | app `paused` then `resumed` (dispatched) | `releaseCount≥1` on background **and** `acquireCount≥2` on resume; **control:** post-resume live-frame change renders (not frozen/black). Rejects: leaking controller; not re-acquiring. |
| AC-10 | `TestAC10_PlatformDeclarations` | `AndroidManifest.xml` + `Info.plist` exist on disk | source-scan read | Android has `android.permission.CAMERA` **and** camera `<uses-feature>` (separate asserts); iOS `NSCameraUsageDescription` present **and** non-empty (structured key→string). Rejects: declaring one not the other; bare key; empty usage string. *(green at baseline)* |

**Red baseline** (`--dart-define=BS19_RUN_PENDING=true`, per file): **red** — AC-1 (Then `showsPlaceholder isFalse` → VIEW-2), AC-2 (`returnsNormally` guard, `frameFromCameraImage` throws `UnimplementedError … CAM-3` → CAM-3), AC-4 (Given `frame isNotNull` → VIEW-2/VIEW-3), AC-7 (`requestCount==1`, actual 0 → PERM-2), AC-8 (`activeSourceKind==software`, actual camera → PERM-3), AC-9 (`releaseCount>=1`, actual 0 → CAM-7). **Green at baseline** — AC-3, AC-5, AC-6, AC-10 (source-agnostic pipeline / shipped manifests), each written with a discriminating control. All reds are clean `TestFailure`s (no panic/hang).

**Augmentations** (full table in *Test augmentations* below; all already written in the AC-test phases, each closed by un-pend + keep-green in its behavior phase): TestAC03→CAM-4 (reading changes c1→c2), TestAC05→CAM-5 (warning clears *because* `allLocked`), TestAC06→CAM-6 (toggle reaches source + off-extinguish), TestAC04→VIEW-3 (readings subtree outside grayscale), TestAC10→PERM-4 (`<uses-feature>` + non-empty iOS usage; ⚠ no new product work).

**Owning behavior phases:** AC-1→VIEW-2, AC-2→CAM-3, AC-3→CAM-4, AC-4→VIEW-3, AC-5→CAM-5, AC-6→CAM-6, AC-7→PERM-2, AC-8→PERM-3, AC-9→CAM-7, AC-10→PERM-4.

**Decision:** `/feature-next-phase --gate bs-19-live-camera-capture G-2 approved | "<changes>"`. Approval unblocks every behavior phase (CAM-3 first — it is the enabler for VIEW-2 and the CAM behavior phases). "Changes requested" turns each item into an `ITEST` change phase before the behavior stage, then a fresh review.

### Checkpoint / Handoff
- **Gate G-2 is the only thing this phase produces** — a human decision on the packet above. **No behavior phase (CAM-3, VIEW-2/3, CAM-4/5/6/7, PERM-2/3/4) may start before G-2 is approved.**
- **On approval:** record via `--gate bs-19-live-camera-capture G-2 approved`; that flips ITEST-4 → ✅ Done and makes **CAM-3** the next startable phase (the enabler: AC-2 frame conversion + real frame stream; blocks VIEW-2, CAM-4/5/6/7, PERM-2).
- **On changes requested:** each item becomes an ITEST change phase before behavior; a fresh test review follows it.
- Suite state frozen at HEAD `c7d34b0`: default run skips all 10 pending + smoke 11/11; run-pending reproduces the red baseline above. Verification commands unchanged (ITEST-3 Checkpoint).

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_LivePreview | ❌ red | Then `showsPlaceholder isFalse` (still the `ColoredBox` placeholder — screen passes no `frame:` yet) | VIEW-2 | A |
| AC-2 | TestAC02_FrameConversion | ❌ red | `returnsNormally` guard — `frameFromCameraImage` throws `UnimplementedError('… lands in CAM-3')` (clean `TestFailure`, no panic) | CAM-3 | A (B→A, in-phase) |
| AC-3 | TestAC03_ReadingFollowsFrame | ✅ green at baseline | — (sampling is source-agnostic; c1→c2 change + 10× separation control already discriminate) | CAM-4 | A (live) |
| AC-4 | TestAC04_ValueOnlyLive | ❌ red | Given precondition `liveView.frame isNotNull` naming VIEW-2 (no live frame to grey yet) | VIEW-3 | A |
| AC-5 | TestAC05_LockClearsWarning | ✅ green at baseline | — (lock/warning pipeline source-agnostic; `canLock:false` control already discriminates) | CAM-5 | A (live) |
| AC-6 | TestAC06_Torch | ✅ green at baseline | — (torch on/off + `litByTorch` commit are source-agnostic; toggle-reaches-source + off-extinguish augmentation and a torch-off `litByTorch:false` control already discriminate) | CAM-6 | A (live) |
| AC-7 | TestAC07_PermissionFallback | ❌ red | Then `permission.requestCount == 1` (actual 0 — no `CameraPermission` wired into the assembly) | PERM-2 | A |
| AC-8 | TestAC08_NoCameraFallback | ❌ red | Then `activeSourceKind == software` (actual `camera` — no availability-driven selection yet) | PERM-3 | A |
| AC-9 | TestAC09_Lifecycle | ❌ red | Then `releaseCount >= 1` after background (actual 0 — `CaptureHomeScreen` is no `WidgetsBindingObserver` yet) | CAM-7 | A |
| AC-10 | TestAC10_PlatformDeclarations | ✅ green at baseline | — (CAMERA permission + camera `<uses-feature>` + non-empty `NSCameraUsageDescription` already declared in PERM-1; structured key→string + separate-declaration asserts already discriminate) | PERM-4 | A (live) |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC03 | sampling is source-agnostic → green at baseline against any frame source | CAM-4 | assert the reading **changes** when the live frame changes c1→c2 (rejects a stale/fixed sampler) | ✅ Written in ITEST-2 (c1→c2 change + 10× separation control in the AC test, graded A live). CAM-4's residual = un-pend + keep green (real `CameraCaptureSource.frames` stream exercised by CAM-4's unit tests + the sign-off device walkthrough, not flutter-tester). |
| TestAC05 | the "approximate" warning + lock state already plumb through the abstraction | CAM-5 | assert the warning clears **because** the source reports `allLocked` (G2), not independently | ✅ Written in ITEST-2 (`canLock:false` control proves the warning tracks `source.locks.allLocked`, not the UI flag; graded A live). CAM-5's residual = un-pend + keep green (real source lock state at the device walkthrough). |
| TestAC06 | `torchOn`/`litByTorch` already plumb through the abstraction | CAM-6 | assert the toggle reaches the source and the off-path extinguishes (settle after off tap) | ✅ Written in ITEST-3 (`torchOnCalls==1`/`torchOffCalls==1` + `source.torchOn` false after off; plus a torch-OFF commit control `litByTorch:false` vs the torch-ON `litByTorch:true`; graded A live). CAM-6's residual = un-pend + keep green via the real device `setFlashMode`. |
| TestAC04 | grayscale filter exists over the placeholder | VIEW-3 | assert the readings subtree sits **outside** the grayscale filter (stays in colour) | ✅ Written in ITEST-2 (`ColorFiltered` ancestor over `liveViewKey` but **not** over `accuracyKey`). Activates once VIEW-2/VIEW-3 render a real frame (the Given); VIEW-3's residual = un-pend (make the Given pass) + keep green. |
| TestAC10 | permission alone is a weak check | PERM-4 | assert the `<uses-feature>` is present and the iOS usage description is non-empty | ✅ Written in ITEST-3 (asserts CAMERA permission **and** the camera `<uses-feature>` **and** a structured `NSCameraUsageDescription` key→non-empty-string; graded A). ⚠ The declarations already landed in the **PERM-1 shell**, so PERM-4's residual is purely un-pend + confirm — no new product work. Flag for G-2 / PERM-4. |
