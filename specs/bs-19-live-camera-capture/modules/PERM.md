# Module PERM — Permission, fallback, wiring & platform declarations

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/camera_permission.dart` (new), production source selection in `lib/main.dart` (+ `selectCaptureSource` use), the capture-state camera-availability/permission field, `lib/capture/capture_read_endpoint.dart` (extend), `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`; tests under `test/capture/` + the AC-10 source-scan.
**Depends on:** CAM · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| PERM-1 | shell | — | ⬜ Todo | | |
| PERM-2 | behavior | AC-7 | ⬜ Todo | | |
| PERM-3 | behavior | AC-8 | ⬜ Todo | | |
| PERM-4 | behavior | AC-10 | ⬜ Todo | | |

## Interface reconciliation

- Adds a `CameraPermission` seam (request/status) so the request is mockable off-device (the plugin's platform channels can't run under `flutter-tester`; tests inject a recording fake — D-5).
- Extends the capture **read endpoint** (`capture_read_endpoint.dart`) to expose the **active source kind** (`camera` | `software`) and the **permission state**, so AC-1/AC-7/AC-8 Thens can observe the selection the public surface otherwise hides.
- Production selection moves into `selectCaptureSource(permission, availability)` used by `main.dart`'s `productionDependencies` (today it hard-wires `demoCaptureSource()`); the software source stays the fallback.

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

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

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
