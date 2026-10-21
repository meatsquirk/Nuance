# Module PERM — Permission, fallback, wiring & platform declarations

**Status:** In progress — PERM-1 shell done; PERM-2/3/4 behavior gated by G-2
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/camera_permission.dart` (new), production source selection in `lib/main.dart` (+ `selectCaptureSource` use), the capture-state camera-availability/permission field, `lib/capture/capture_read_endpoint.dart` (extend), `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`; tests under `test/capture/` + the AC-10 source-scan.
**Depends on:** CAM · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| PERM-1 | shell | — | ✅ Done | 9.02M | 14m 15s |
| PERM-2 | behavior | AC-7 | ⬜ Todo | | |
| PERM-3 | behavior | AC-8 | ⬜ Todo | | |
| PERM-4 | behavior | AC-10 | ⬜ Todo | | |

## Interface reconciliation

- Adds a `CameraPermission` seam (request/status) so the request is mockable off-device (the plugin's platform channels can't run under `flutter-tester`; tests inject a recording fake — D-5). **PERM-1:** `lib/capture/camera_permission.dart` — `CameraPermissionState {undetermined, granted, denied}`, abstract `CameraPermission` (status + `request()`), and the inert shipped `PluginCameraPermission` (status starts undetermined; `request()` throws until PERM-2 wires the platform prompt).
- Extends the capture **read endpoint** (`capture_read_endpoint.dart`) to expose the **active source kind** (`camera` | `software`) and the **permission state**, so AC-1/AC-7/AC-8 Thens can observe the selection the public surface otherwise hides. **PERM-1:** `activeSourceKind => controller.source.kind` and `permissionState => controller.state.cameraPermission`.
- **Active source kind (PERM-1):** a `CaptureSourceKind {camera, software}` enum + a `kind` getter were added to the `CaptureSource` interface (camera source → camera, software source → software; the ITEST scripted source will make it settable). **Camera availability is observed through `activeSourceKind == software`** (the fallback is selected when no camera), so no separate availability field was added to the capture state — the state carries only the `cameraPermission` field. AC-8's no-camera probe seam lands in PERM-3 as scoped.
- Production selection moves into `selectCaptureSource(...)` (CAM-2 seam) used by `main.dart`'s assembly; **PERM-2** drives its `useCamera` from the resolved permission (and PERM-3 from availability); the software source stays the fallback.

## Open gates

- G-2 (test review) blocks PERM-2, PERM-3, PERM-4.

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

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

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

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

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

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->
