# Module PERM — Permission, fallback, wiring & platform declarations

**Status:** In progress — PERM-1..4 complete (AC-7/8/10 live). **PERM-5 (§9 production activation)** queued (changes requested at SIGNOFF-1, 2026-10-22, Matt Quirk). Module exits to SIGNOFF-2.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/camera_permission.dart` (new), production source selection in `lib/main.dart` (+ `selectCaptureSource` use), the capture-state camera-availability/permission field, `lib/capture/capture_read_endpoint.dart` (extend), `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`; tests under `test/capture/` + the AC-10 source-scan.
**Depends on:** CAM · **Blocks:** SIGNOFF-1 (PERM-1..4), SIGNOFF-2 (PERM-5)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| PERM-1 | shell | — | ✅ Done | 9.02M | 14m 15s |
| PERM-2 | behavior | AC-7 | ✅ Done | 17.79M | 29m 12s |
| PERM-3 | behavior | AC-8 | ✅ Done | 10.75M | 17m 46s |
| PERM-4 | behavior | AC-10 | ✅ Done | 5.21M | 11m 01s |
| PERM-5 | behavior | — (§9 production activation) | ⬜ Next | — | — |

## Interface reconciliation

- Adds a `CameraPermission` seam (request/status) so the request is mockable off-device (the plugin's platform channels can't run under `flutter-tester`; tests inject a recording fake — D-5). **PERM-1:** `lib/capture/camera_permission.dart` — `CameraPermissionState {undetermined, granted, denied}`, abstract `CameraPermission` (status + `request()`), and the inert shipped `PluginCameraPermission` (status starts undetermined; `request()` throws until PERM-2 wires the platform prompt).
- Extends the capture **read endpoint** (`capture_read_endpoint.dart`) to expose the **active source kind** (`camera` | `software`) and the **permission state**, so AC-1/AC-7/AC-8 Thens can observe the selection the public surface otherwise hides. **PERM-1:** `activeSourceKind => controller.source.kind` and `permissionState => controller.state.cameraPermission`.
- **Active source kind (PERM-1):** a `CaptureSourceKind {camera, software}` enum + a `kind` getter were added to the `CaptureSource` interface (camera source → camera, software source → software; the ITEST scripted source will make it settable). **Camera availability is observed through `activeSourceKind == software`** (the fallback is selected when no camera), so no separate availability field was added to the capture state — the state carries only the `cameraPermission` field. AC-8's no-camera probe seam lands in PERM-3 as scoped.
- Production selection moves into `selectCaptureSource(...)` (CAM-2 seam) used by `main.dart`'s assembly; **PERM-2** drives its `useCamera` from the resolved permission (and PERM-3 from availability); the software source stays the fallback.

## Open gates

- G-2 (test review) ✅ Resolved 2026-10-21 (Matt Quirk) — behaviour stage unblocked; PERM-2/3/4 startable.

## Phase PERM-1 — Permission seam, state field, read endpoint, platform entries

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CAM-1 · **Blocks:** ITEST-1, PERM-2, PERM-4
- **Files:** `camera_permission.dart`, capture state, `capture_read_endpoint.dart`, `AndroidManifest.xml`, `Info.plist`
- **Tasks:**
  1. Define the `CameraPermission` seam (status + request) with a real plugin-backed impl and a test fake.
  2. Add a camera-availability/permission field to the capture state (inert default: as today).
  3. Extend the read endpoint to report `activeSourceKind` + `permissionState`.
  4. Add the Android `CAMERA` permission + `<uses-feature>` and iOS `NSCameraUsageDescription` entries (declarations only; source selection still defaults to software until PERM-2, so behaviour is unchanged).
- **Exit criteria:** unit gate; existing suite green; app still boots on the software source.
- **Acceptance gate:** —

### Result
Inert permission/selection shell — **no behaviour change** (the app still assembles on the software source; `selectCaptureSource` default `useCamera:false` is untouched). New + touched lib (all 100% covered):
- `lib/capture/camera_permission.dart` (new) — `CameraPermissionState {undetermined, granted, denied}`, abstract `CameraPermission` (status + `request()`), inert `PluginCameraPermission` (status starts undetermined; `request()` throws `UnimplementedError` until PERM-2, mirroring the CAM-2 frame-conversion stub).
- `lib/capture/source/capture_source.dart` — added `CaptureSourceKind {camera, software}` + abstract `kind` getter.
- `camera_capture_source.dart` → `kind => camera`; `software_capture_source.dart` → `kind => software` (so `FakeCaptureSource` inherits it).
- `capture_state.dart` — added `cameraPermission` field (default `undetermined`) threaded through ctor/`copyWith`/`==`/`hashCode` (left out of `toString`, which stays a summary — existing toString asserts unchanged).
- `capture_read_endpoint.dart` — added `activeSourceKind => controller.source.kind` and `permissionState => controller.state.cameraPermission`.
- Platform declarations: `AndroidManifest.xml` `<uses-permission android:name="android.permission.CAMERA"/>` + `<uses-feature android:name="android.hardware.camera" android:required="false"/>`; `ios/Runner/Info.plist` `NSCameraUsageDescription` (non-empty, explains the colour-reading use). These satisfy AC-10 at baseline; PERM-4 finalises/augments.
- **Test fake:** `_ControllableSource` (capture_controller_test) got the `kind` override; the two `_InertCaptureSource` use `noSuchMethod` so needed none.
- **Tests:** +8 unit (camera_permission_test ×4, camera-source kind, software-source kind, capture_state default/copyWith/unequal, read-endpoint activeSourceKind+permissionState).
- **Gates:** analyze `lib/ test/ integration_test/` clean; `flutter test --coverage test/` = **1663 passed** (1655 + 8), exit 0; `dart run tool/coverage_gate.dart 5459d88` = **100% on all 6 touched lib files**. No acceptance/grade gate (shell). **Fix passes: 0/3.**
- **Tokens/Time:** see dashboard (PERM-1 row) + master ledger.

### Checkpoint / Handoff
- **Frozen this phase (PERM-2/3/4 + ITEST build on):**
  - `CameraPermission` seam — PERM-2 adds a mutable `_status` and wires `request()` to the camera plugin's permission prompt, then drives `selectCaptureSource(useCamera:)` from the result (granted → camera, denied → software + "camera access needed" affordance, D-3) and reflects it into `CaptureState.cameraPermission`.
  - `CaptureSourceKind kind` on `CaptureSource` — the ITEST `ScriptedCameraSource` makes `kind` **settable** (its test-only `activeKind`) so AC-7 denied → `activeKind==software` / granted → camera can be scripted without a real `CameraCaptureSource`.
  - `CaptureState.cameraPermission` + endpoint `activeSourceKind`/`permissionState` — the observation seam AC-1/AC-7/AC-8 Thens read.
  - Platform files — PERM-4 (AC-10) augments the source-scan to assert the usage string is non-empty and the uses-feature present, not just the permission.
- **Availability:** no capture-state availability field — observed via `activeSourceKind == software`. The AC-8 availability *probe* seam is PERM-3's (module scopes it there).
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`, run bare): unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart 5459d88`; analyze `dart analyze lib/ test/ integration_test/`.
- **Known gaps:** none. Everything is inert — the permission is never requested, no source but software is selected, and the platform declarations change no Dart behaviour. PERM-2/3/4 are **gated by G-2** (test review).

## Phase PERM-2 — Permission request + denial fallback + state

- **Kind:** behavior
- **Target AC:** AC-7 (full)
- **Depends on:** PERM-1, CAM-3 · **Blocks:** PERM-3, SIGNOFF-1
- **Files:** `main.dart` (selection), `camera_permission.dart`, capture state/UI for the "camera access needed" affordance
- **Tasks:**
  1. Request camera permission at first live-capture entry; on `granted` select `CameraCaptureSource`, on `denied` select the software source and surface a "camera access needed" affordance (retry / open settings) — never crash or black-screen (D-3).
  2. Reflect `activeSourceKind`/`permissionState` through the read endpoint.
- **Exit criteria:** unit/coverage gate; `TestAC07_PermissionFallback` green (both granted and denied branches, one request).
- **Acceptance gate:** un-pend AC-7; suite green.
- **Augments:** none

### Result
AC-7 live (grade **A**): the Capture host requests camera permission on first
live-capture entry and selects the source from the outcome. New + touched lib
(all 100% covered; device call coverage-exempt):
- `build_app.dart` — `AppDependencies.cameraPermission` seam (default null);
  `_CaptureHomeScreenState` now, on first `didChangeDependencies`, builds the
  controller over the injected source **and** — only when a `cameraPermission`
  seam is wired *and* the source is `CaptureSourceKind.camera` — requests access
  (`_applyInitialPermission`): **granted keeps the already-subscribed camera
  controller** (no teardown → no lost seed frame, AC-1/AC-9 timing preserved)
  and records the grant via `CaptureController.setCameraPermission`; **denied**
  swaps to a fresh `cameraFallbackSource()` (`SoftwareCaptureSource`, neutral
  mid-grey scene, kind `software`) and shows the `_CameraAccessAffordance`
  ("Camera access needed… Retry", D-3). `_retryPermission` re-requests from the
  affordance (granted → re-selects the kept `_cameraSource`; still-denied →
  stays on a fresh fallback). `_replaceController` tears down + rebuilds with the
  handoff listeners re-wired.
- `capture_controller.dart` — `setCameraPermission(state)` records the resolved
  permission into `CaptureState.cameraPermission` (the read endpoint's
  `permissionState`).
- `camera_permission.dart` — `PluginCameraPermission.request()` now wired to the
  `camera` plugin's `initialize()` OS prompt (granted on init, denied on
  `CameraException`), `// coverage:ignore` like CAM-3's `PluginCameraDevice`
  (device-only, verified at the sign-off walkthrough, D-5); `_status` made
  mutable.
- `main.dart` — wires `cameraPermission: PluginCameraPermission()`; dormant while
  the shipped source is the software scene (the host only prompts for a live
  camera source), ready for the on-device camera selection.
- **Test wiring:** `givenLiveCamera` now forwards the injected permission into
  `buildApp` (so the assembly requests it); AC-7 un-pended (`pendingACs` row
  deleted). Harness/smoke doc + guards updated: smoke boot now reads
  `permissionState == granted`; the smoke exact-set guard adds AC-7 to
  `unpendedACs`; the pending-skip example moved AC-7→AC-8 (owner PERM-3). PERM-1
  unit test's "request throws" case dropped (now device-wired/coverage-exempt).
- **Gates:** `dart analyze lib/ test/ integration_test/` clean; `flutter test
  --coverage test/` = **1684 passed**, exit 0; `dart run tool/coverage_gate.dart
  e0eb599` = **100% on all 4 touched lib files**. Acceptance: AC-7
  (`TestAC07_PermissionFallback`) **green** in the default run (per-file;
  `permission_test.dart` +1, AC-8 skipped pending PERM-3); every other
  live_camera file green per-file (smoke 11/11, preview 3, reading 2, controls 2,
  platform skip). **Grade: fresh independent re-grade = 8 A / 0 below A** across
  all un-pended AC tests (AC-1..AC-7, AC-9); the shared `givenLiveCamera` change
  confirmed safe (granted keeps the controller; AC-9 acquireCount stays 1).
  Cross-feature regression (the suites that pump the Capture host): bs-02
  `capture_test.dart` 19/19, bs-11 `accessibility_test.dart` 19/19, bs-12
  `nfr_test.dart` 33/33 — all green (the permission flow is inert for their
  no-seam / software sources). The 2 carried off-lane flakes (bs-06 palette
  AC-3/AC-5, bs-08 display AC-9) are untouched by this phase. **Fix passes: 1/3**
  (grader re-grade required none; one in-flight fix: smoke guards updated to the
  new delivered set).
- **Tokens/Time:** see dashboard (PERM-2 row) + master ledger.

### Checkpoint / Handoff
- **Frozen this phase (PERM-3/4 build on):**
  - `AppDependencies.cameraPermission` seam + the host's request-and-select flow.
    PERM-3 adds the **availability** probe: when the device reports no usable
    camera it must select the software fallback *before* (or without) prompting,
    so AC-8 lands on `activeSourceKind == software` with a readable
    `currentSample`. The `cameraFallbackSource()` helper + `_replaceController`
    are the reuse points; the AC-8 probe seam is PERM-3's (the scripted source's
    `available` flag stands for it).
  - `CaptureController.setCameraPermission` — the one state seam for the resolved
    permission; do not re-add a permission field to the source.
  - `_CameraAccessAffordance` — the denied-path affordance; PERM-3's no-camera
    path needs no affordance (availability ≠ permission), only the fallback.
  - `PluginCameraPermission.request()` is coverage-ignored device code; keep new
    off-device logic in the host (covered through the injected fake).
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`, run bare): unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart <base>`; analyze `dart analyze lib/ test/ integration_test/`; AC-7 `flutter test -d flutter-tester integration_test/live_camera/permission_test.dart` (**per-file — the whole `live_camera/` dir fails to launch at once**).
- **Known gaps:** none for AC-7. AC-8 (PERM-3) and AC-10 (PERM-4) remain pending. Production still opens on the software source (real camera selection is on-device, D-5), so the wired `PluginCameraPermission` is dormant in the shipped build.

## Phase PERM-3 — No-camera fallback

- **Kind:** behavior
- **Target AC:** AC-8 (full)
- **Depends on:** PERM-2 · **Blocks:** SIGNOFF-1
- **Files:** `main.dart`/`selectCaptureSource`, availability probe
- **Tasks:**
  1. Probe camera availability; when none, select the software source and keep import-photo + the rest of the app working; no throw.
- **Exit criteria:** unit/coverage gate; `TestAC08_NoCameraFallback` green.
- **Acceptance gate:** un-pend AC-8; suite green.
- **Augments:** none

### Result
AC-8 live (grade **A**): a live camera source on a device that reports no usable
camera falls back to the software source at once — no prompt, no affordance. New
+ touched lib (all 100% covered):
- `capture_source.dart` — new abstract `bool get available` on the `CaptureSource`
  interface (doc: software always usable; a camera source that exists is backed by
  a camera; the host honours it on the injected source, so `false` models a
  no-camera device).
- `software_capture_source.dart` → `available => true`; `camera_capture_source.dart`
  → `available => true` (a camera source is built only after the on-device
  selection finds a camera, D-5).
- `build_app.dart` — `_CaptureHomeScreenState.didChangeDependencies`: when
  `source.kind == camera && !source.available`, build over `cameraFallbackSource()`
  (a `SoftwareCaptureSource`, kind `software`) **synchronously** and return — the
  seed frame is sampled on the first pump, and the permission prompt / affordance
  are skipped (availability ≠ permission, D-3). The camera-present path is
  unchanged (PERM-2 flow).
- **Test fakes:** `available` override added to `_ControllableSource` +
  `_RecordingFeedSource` (capture_controller_test), `_LifecycleCaptureSource`
  (build_app_test, settable), and `@override` on `ScriptedCameraSource.available`.
- **Acceptance wiring:** AC-8 un-pended (pending.dart row → comment); smoke
  exact-set guard adds AC-8 to `unpendedACs`; pending-skip example moved AC-8→AC-10
  (owner PERM-4). +3 unit tests (host no-camera fallback asserting
  `activeSourceKind==software`, `currentSample!=null`, `requestCount==0`,
  `permissionState==undetermined`, `acquireCount==0`, no affordance, no crash; each
  source's `available`).
- **Gates:** `dart analyze lib/ test/ integration_test/` clean; `flutter test
  --coverage test/` = **1687 passed**; `dart run tool/coverage_gate.dart ec96777` =
  **100% on all 4 touched lib files**. Acceptance: AC-8 (`TestAC08_NoCameraFallback`)
  **green** (permission_test.dart, with AC-7); whole `live_camera/` per-file green
  (smoke 11/11, preview 2, reading 2, controls 2), AC-10 still skipped (PERM-4).
  **Grade: fresh independent re-grade = 9 A / 0 below A** across every un-pended AC
  test (AC-1..AC-9); the `available` interface change weakened no neighbour (the
  branch is never taken for an `available=true` source). Cross-feature regression
  (host-pumping suites): bs-02 capture 19/19, bs-09 advanced-capture 21/21, bs-11
  a11y 19/19, bs-12 nfr 33/33 — all green. Carried off-lane flakes (bs-06 palette
  AC-3/AC-5, bs-08 display AC-9) untouched. **Fix passes: 0/3** (green on the first
  full run).
- **Tokens/Time:** see dashboard (PERM-3 row) + master ledger.

### Checkpoint / Handoff
- **Frozen this phase (PERM-4 + SIGNOFF-1 build on):**
  - `CaptureSource.available` — the availability seam. Every shipped/fake source
    reports `true`; the host falls back only on an injected `kind==camera` source
    that reports `false`. The real device-availability probe (whether the device has
    any camera) is the production selection's job on-device (D-5); a constructed
    `CameraCaptureSource` reports available.
  - The host no-camera branch runs **before** the permission prompt and tears
    nothing down — it simply builds the fallback controller. It does not touch
    `_cameraPermission`/`_cameraSource`/`_resolvedPermission`, so no affordance
    shows and `permissionState` stays `undetermined`.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`, run bare): unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart <base>`; analyze `dart analyze lib/ test/ integration_test/`; AC-8 `flutter test -d flutter-tester integration_test/live_camera/permission_test.dart` (**per-file — the whole `live_camera/` dir fails to launch at once**).
- **Known gaps:** none for AC-8. AC-10 (PERM-4) remains the only pending AC; it is green-at-baseline (declarations shipped in PERM-1), so PERM-4 is un-pend + confirm + the usage-string/uses-feature augmentation. Then SIGNOFF-1.

## Phase PERM-4 — Platform declarations (Android + iOS)

- **Kind:** behavior
- **Target AC:** AC-10 (full)
- **Depends on:** PERM-1 · **Blocks:** SIGNOFF-1
- **Files:** `AndroidManifest.xml`, `ios/Runner/Info.plist`
- **Tasks:**
  1. Confirm/finalise the Android `CAMERA` permission + `<uses-feature android:name="android.hardware.camera" android:required="false"/>` (false so no-camera devices still install, AC-8) and a meaningful iOS `NSCameraUsageDescription`.
- **Exit criteria:** `TestAC10_PlatformDeclarations` source-scan green (both files).
- **Acceptance gate:** un-pend AC-10; suite green.
- **Augments:** `TestAC10`: assert the usage description is non-empty and the uses-feature is present, not just the permission.

### Result
AC-10 live (grade **A**) — the **last** AC; all 10 bs-19 ACs now delivered. This
phase is **un-pend + confirm + augment only**: AC-10's platform declarations
already shipped in PERM-1 and its test (`TestAC10_PlatformDeclarations`, the
non-empty-usage augmentation already built in ITEST-3) was green-at-baseline, so
**no lib/ and no product code changed**. Two integration-test files only:
- `integration_test/live_camera/pending.dart` — deleted the `'AC-10': 'PERM-4'`
  row; the `pendingACs` map is now **empty** (every AC runs by default).
- `integration_test/live_camera/smoke_test.dart` — rewrote the two pending-gate
  guards to the terminal all-delivered state: guard 1 adds AC-10 to `unpendedACs`
  (so `expectedPending` is the empty set) + an explicit `expect(pendingACs,
  isEmpty)`; guard 2 (which had used AC-10 as the live pending example) became
  "with every AC delivered the gate runs them all in either mode" — a fixed
  `for n=1..10` loop asserting each AC's skip reason is null in **both** default
  and run-pending modes (fails if an AC were silently re-pended or the gate
  inverted). Both stay non-vacuous.
- **Confirmed on disk:** `AndroidManifest.xml` `android.permission.CAMERA` +
  `<uses-feature android:name="android.hardware.camera" android:required="false"/>`
  (false so no-camera devices still install, AC-8); `ios/Runner/Info.plist`
  `NSCameraUsageDescription` = a real non-empty sentence. All match the spec
  scenario verbatim.
- **Augmentation:** the scheduled `TestAC10` augmentation (assert the usage
  string non-empty and the uses-feature present, not just the permission) was
  already satisfied in ITEST-3 — confirmed present, no change needed.
- **Gates:** `dart analyze lib/ test/ integration_test/` clean; `flutter test
  --coverage test/` = **1687 passed**, exit 0; `dart run tool/coverage_gate.dart
  0624e0f` = **PASS (no touched lib/**.dart files — nothing to gate)**. Acceptance:
  AC-10 (`TestAC10_PlatformDeclarations`) **green in the default run** (no longer
  skipped); whole `live_camera/` per-file green (smoke 11/11, preview 3, reading
  2, controls 2, permission 2, platform 1), **no AC pending**. **Grade: fresh
  independent re-grade = 10 A / 0 below A** across every AC test (AC-1..AC-10) +
  both rewritten smoke guards + scaffold tests confirmed non-vacuous; no
  downgrade from any prior grid, no fix owed. **Fix passes: 0/3** (green on the
  first full run). The 2 carried off-lane flakes (bs-06 palette AC-3/AC-5, bs-08
  display AC-9) are untouched by this phase.
- **Tokens/Time:** see dashboard (PERM-4 row) + master ledger.

### Checkpoint / Handoff
- **Feature behaviour is COMPLETE.** All 10 ACs un-pended and green; the
  `pendingACs` map is empty; `behaviorPhases` fully consumed. The only remaining
  phase is **SIGNOFF-1** (sign-off packet + summary page + human approval).
- **Frozen:** the platform declarations (`AndroidManifest.xml`,
  `ios/Runner/Info.plist`) are final. No further behaviour change is scheduled.
- **For SIGNOFF-1:** run the **full cross-feature regression** (every feature's
  acceptance suite + the whole unit target) per the lifecycle table; note the 2
  carried off-lane flakes (bs-06 palette AC-3/AC-5, bs-08 display AC-9 —
  reproduce at merge-base, not bs-19 regressions); the on-device camera
  walkthrough is the D-5 manual item (real `PluginCameraDevice` /
  `PluginCameraPermission` are the only `// coverage:ignore` in lib/, exercised
  only on a physical device). Production still opens on the software source
  (real camera selection is on-device), so the wired plugin is dormant in the
  shipped flutter-tester build.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`;
  macOS has **no** `timeout`, run bare): unit+cov `flutter test --coverage test/`;
  gate `dart run tool/coverage_gate.dart <base>`; analyze `dart analyze lib/
  test/ integration_test/`; acceptance **per-file** `flutter test -d
  flutter-tester integration_test/live_camera/<file>_test.dart` (**the whole
  `live_camera/` dir fails to launch at once**).
- **Known gaps:** none. Every AC delivered and graded A.

## Phase PERM-5 — §9 production activation (ship the real camera by default)

- **Kind:** behavior (production activation; **no new AC** — all 10 ACs are already green via the injected scripted source. This wires the real `camera`-plugin path, built behind the seams in CAM-3/PERM-2/PERM-3, into the shipped `main.dart` so the live feed is the default on a device with a camera. Realises D-2 fully; resolves the §9 standing call recorded as *changes requested* at SIGNOFF-1, 2026-10-22, Matt Quirk.)
- **Target AC:** — (production wiring / enabler)
- **Depends on:** PERM-2 (permission flow), PERM-3 (availability fallback), CAM-3 (real `CameraCaptureSource` + `PluginCameraDevice`) · **Blocks:** SIGNOFF-2
- **Files:** `lib/main.dart` (production assembly), `lib/capture/source/capture_source_factory.dart` (and, if needed, a small camera-availability probe seam + a pure selection helper)
- **Tasks:**
  1. In the production assembly (`main.dart`), probe real device camera availability at startup and, when a camera is present, assemble over `selectCaptureSource(useCamera: true)` so the shipped default is the real `CameraCaptureSource` (live feed). Keep `demoCaptureSource` as the graceful fallback when no camera is present (D-2). The runtime permission prompt + grant/deny handling (PERM-2, `_CameraAccessAffordance`, D-3), the no-camera synchronous fallback (PERM-3), and lifecycle release/resume (CAM-7, D-7) already fire from the Capture host once the source is `kind==camera`, so no new runtime behaviour is needed — only the production *selection*.
  2. Factor the **pure** selection decision (has-camera × resolved-permission → source kind) into a unit-testable function; keep only the real device probe and plugin calls behind `// coverage:ignore` (D-5), mirroring `PluginCameraDevice` / `PluginCameraPermission.request()`. The default off (`useCamera:false`) path must remain so the acceptance harness and any no-camera device are unaffected.
  3. Keep the import-photo / software paths and every existing suite green — the ITEST harness still injects its scripted source at the `captureSource:` seam and must be untouched by the production selection.
- **Exit criteria:** unit + coverage gate (the pure selection helper covered; the real device probe / plugin calls coverage-ignored per D-5 — the only such code in `lib/`, alongside CAM-3/PERM-2's); the full bs-19 acceptance suite green in both modes (injected-source harness unchanged); the host-pumping cross-feature suites (bs-02/09/11/12) green.
- **Acceptance gate:** no AC to un-pend; confirm all 10 ACs stay green (default + run-pending) and the grade grid holds 10 A. The real on-device behaviour (live feed, prompt, hardware lock/torch, fallback, lifecycle) is verified by the **SIGNOFF-2 on-device walkthrough** (D-5, packet §10E) — it cannot run under `flutter-tester`.
- **Augments:** a unit test of the pure selection function (has-camera × permission → kind); no AC-test change.

### Result
_(to be written when the phase runs)_

### Checkpoint / Handoff
_(to be written when the phase runs)_
