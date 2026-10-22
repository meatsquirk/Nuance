# Sign-off packet — bs-19 Live camera capture source — Round 2

**Feature:** [bs-19-live-camera-capture.feature](../../bs-19-live-camera-capture.feature) ·
**Master plan:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**At code:** `9345e45` (plans; code @ `9c8d697`) · branch `feat/bs-19-live-camera-capture` · **Prepared:** 2026-10-22 · **Phase:** SIGNOFF-2 (fresh packet after PERM-5)
**Decision:** ⬜ _Awaiting human decision._

> **What changed since Round 1.** SIGNOFF-1 was returned **changes requested** (2026-10-22, Matt Quirk): resolve §9
> toward **production activation** — ship the real camera by default rather than wiring it dormant. Phase **PERM-5**
> did exactly that (commit `9c8d697`): `main.dart` probes device camera availability at startup
> (`_deviceHasCamera()` over `availableCameras()`), threads `hasCamera` into assembly, and the new pure
> `selectUseCamera({hasCamera, permission}) = hasCamera && permission != denied` drives
> `selectCaptureSource(useCamera:)`. **A camera-bearing device now opens on the live `CameraCaptureSource` by
> default**, with the software scene as the no-camera / denied fallback — **D-2 realised fully**. `hasCamera`
> defaults `false`, so the flutter-tester harness and no-camera devices still get the deterministic software scene.
> No AC test changed; the previous round-1 record stays as history.

Real `CameraCaptureSource` over the Flutter `camera` plugin, behind the bs-02 `CaptureSource` seam: renders the
live feed into the Capture view (replacing the flat-grey placeholder), converts device frames (YUV420/Android,
BGRA/iOS) to the `Frame` RGB model, drives AE·AWB·AF locks and the torch on the real device, requests camera
permission with a graceful software fallback, releases/re-acquires across the app lifecycle, declares camera use
on both platforms, **and is now the shipped production default on a camera-bearing device.** **All 10 ACs
delivered, 0 pending.**

**Scorecard (summary page):** https://claude.ai/artifact/4JfXYVUKW6FPoHp3rmJ4Pa

---

## 1. Preconditions (all met)

| Precondition | State |
|---|---|
| Every non-sign-off phase done | ✅ 22/23 (session log); CAM/VIEW/PERM/ITEST modules complete; VIEW-4 + PERM-5 done |
| Every AC ✅ in the coverage table | ✅ AC-1..AC-10 all ✅ Done |
| Pending list empty | ✅ `pendingACs` map is `{}` (every AC runs by default) |
| No open *Test augmentations* row | ✅ all 5 rows CLOSED (TestAC03→CAM-4, TestAC05→CAM-5, TestAC06→CAM-6, TestAC04→VIEW-3, TestAC10→PERM-4) |
| Fresh whole-suite grade grid all A | ✅ 10 A / 0 below A (fresh **independent** grader, 2026-10-22, @ `9345e45`, after PERM-5) |

---

## 2. Per-AC result

Every AC test is un-pended and green in both default and run-pending modes (identical — nothing pending).
Grades from the fresh SIGNOFF-2 grid
([behavior-test-completeness-bs-19-live-camera-capture.md](../behavior-test-completeness-bs-19-live-camera-capture.md),
§ *Sign-off re-grade — SIGNOFF-2 (whole suite at HEAD `9345e45` … after PERM-5)*).

| AC | Scenario | Test | Behavior phase | Grade |
|---|---|---|---|---|
| AC-1 | The live view shows the camera feed | `TestAC01_LivePreview` (`preview_test.dart`) | VIEW-2 | A |
| AC-2 | Camera frames convert to the correct colour | `TestAC02_FrameConversion` (`preview_test.dart`) | CAM-3 | A |
| AC-3 | The reading follows the live camera frame | `TestAC03_ReadingFollowsFrame` (`reading_test.dart`) | CAM-4 | A |
| AC-4 | Value-only mode shows the live feed in grayscale | `TestAC04_ValueOnlyLive` (`preview_test.dart`) | VIEW-3 | A |
| AC-5 | Locking AE·AWB·AF settles the live camera | `TestAC05_LockClearsWarning` (`reading_test.dart`) | CAM-5 | A |
| AC-6 | The torch toggles the device light | `TestAC06_Torch` (`controls_test.dart`) | CAM-6 | A |
| AC-7 | Permission requested; denial falls back gracefully | `TestAC07_PermissionFallback` (`permission_test.dart`) | PERM-2 | A |
| AC-8 | A device with no camera falls back gracefully | `TestAC08_NoCameraFallback` (`permission_test.dart`) | PERM-3 | A |
| AC-9 | Camera released and re-acquired across lifecycle | `TestAC09_Lifecycle` (`controls_test.dart`) | CAM-7 | A |
| AC-10 | The app declares camera use on both platforms | `TestAC10_PlatformDeclarations` (`platform_test.dart`) | PERM-4 | A |

---

## 3. Verification (from the primary checkout @ `9345e45` / code `9c8d697`, machine-readable JSON)

**Unit suite + coverage** — `flutter test --coverage --reporter=json test/` → **1694 passed / 0 failed** (exit 0).
**Coverage gate** — SIGNOFF-2 touches no `lib/` (sign-off is docs/plan only) → `dart run tool/coverage_gate.dart 9345e45` =
`no touched lib/**.dart files — PASS` (0 touched source files).

**This feature's acceptance suite** — `flutter test -d flutter-tester [--dart-define=BS19_RUN_PENDING=true] integration_test/live_camera/<file>.dart`,
every file in **default AND run-pending** (identical now): **21 passed / 0 failed in each mode.**

| File | Tests (per mode) |
|---|---|
| `smoke_test.dart` | 11 (1 smoke + guards) |
| `preview_test.dart` (AC-1/2/4) | 3 |
| `reading_test.dart` (AC-3/5) | 2 |
| `controls_test.dart` (AC-6/9) | 2 |
| `permission_test.dart` (AC-7/8) | 2 |
| `platform_test.dart` (AC-10) | 1 |

**Grade grid** — `specs/bs-19-live-camera-capture/behavior-test-completeness-bs-19-live-camera-capture.md`
(§ *Sign-off re-grade — SIGNOFF-2 … HEAD `9345e45`*): **10 A / 0 below A**; all scaffold/smoke/guard tests
non-vacuous. The independent grader confirmed PERM-5 changed **no** `integration_test/` file
(`git diff --name-only 1d634e3 9345e45 -- integration_test/` is empty) and touched **no** lib path any AC test
exercises — only `main.dart`'s startup probe and the pure `selectUseCamera`. Every prior-A grade carried and
re-verified against the current `lib/`.

**Full cross-feature regression** — `flutter test -d flutter-tester --reporter=json <file>` over every feature's
acceptance suite (19 files) plus the whole unit target above:

**Result: 340 passed / 4 failed; 15 of 19 regression suites fully green; the 4 failures are the carried off-lane
flakes only. `design_system_test` is 27/0 — the bs-17 AC-14 fix (VIEW-4) holds.**

Clean suites (0 fail): advanced_capture 21, bs11 accessibility 19, bs12 nfr 33, bs13 dataset 19, bs14 (consent 5 /
exchange 3 / harness 12 / refine 4), capture 19, comparison 26, correction 22, daltonization 25,
**design_system 27**, harness 5, readout 12, recipes 24.

| Suite | Failing test | Classification | Proof |
|---|---|---|---|
| palette | bs-06 AC-3 provenance legend | carried off-lane flake | fails identically at base `11944b6` / `c00422f` (round-1) |
| palette | bs-06 AC-5 palette re-points recipe search | carried off-lane flake | fails identically at base `11944b6` / `c00422f` (round-1) |
| display | bs-08 AC-9 one consistent spoken phrasing | carried off-lane flake | fails identically at base `11944b6` / `c00422f` (round-1) |
| self_assessment | bs-07 AC-4 intake seeds the prior (`Expected CvdType.deutan, Actual null`) | carried off-lane flake | fails identically at base `11944b6` (round-1) |

All four are in the master plan's **Known flakes** table, owned by other features, measured off the exclusive
iOS-sim lane, and proven at the merge-base — **not** bs-19 regressions. They are the **same four** as round-1
(340/4, unchanged). No new flake, and **no bs-19-owned failure**: every bs-19 test and every other feature's
lane-correct suite is green.

---

## 4. Augmentations made

All five pre-seeded *Test augmentations* rows are closed (none open at sign-off):

| AC test | Augmentation | Closed by |
|---|---|---|
| TestAC03 | reading **changes** c1→c2 when the live frame changes (rejects a stale/fixed sampler) | CAM-4 |
| TestAC05 | warning clears **because** the source reports `allLocked` (`canLock:false` control) | CAM-5 |
| TestAC06 | toggle reaches the source + off-path extinguishes; torch-OFF `litByTorch:false` control | CAM-6 |
| TestAC04 | the readings subtree sits **outside** the grayscale `ColorFiltered` (stays in colour) | VIEW-3 |
| TestAC10 | `<uses-feature>` present + non-empty `NSCameraUsageDescription` (not permission alone) | PERM-4 |

---

## 5. Non-A grades accepted

None — every row grades A.

## 6. Phases closed by user acceptance (with gaps)

None — every behavior phase passed its unit, coverage, acceptance and grade gates normally.

---

## 7. Gates

| Gate | Kind | Status |
|---|---|---|
| G-1 | decision — approve the spec | ✅ Resolved 2026-10-21 — Matt Quirk (spec first line records it) |
| G-2 | decision — approve the acceptance tests (ITEST-4 packet) | ✅ Resolved 2026-10-21 12:36 EDT — Matt Quirk |

No open or unresolved gates.

---

## 8. Known flakes (carried; none owned by bs-19)

| Test | Symptom | Measured at | Owner |
|---|---|---|---|
| bs-06 palette AC-3 | provenance-legend "Found 0 widgets" off the exclusive iOS-sim lane | `c00422f` / `11944b6` | bs-06 (off-lane viewport) |
| bs-06 palette AC-5 | travel-set / recipe-re-point selection off-lane | `c00422f` / `11944b6` | bs-06 (device-independent) |
| bs-08 display AC-9 | spoken-phrasing off-lane | `c00422f` / `11944b6` | bs-08 (off-lane viewport) |
| bs-07 self_assessment AC-4 | intake seeds the prior (`Expected CvdType.deutan, Actual null`) off-lane | `11944b6` (bs-19 base) | bs-07 (off-lane interaction) |

These reproduce at the merge-base and are **not** bs-19 regressions. All four appear in §3's regression and are
classified there; none blocks sign-off.

---

## 9. Production activation (resolved — the Round-1 change request)

Round 1's one standing reviewer call — ship the camera dormant, or wire production auto-probe-and-select — was
answered **changes requested → production activation**, and **PERM-5 implemented it**:

- `main.dart` `productionDependencies()` probes `_deviceHasCamera()` (an `availableCameras()` call; any error → `false`)
  and threads `hasCamera` into `assembleDependencies(hasCamera:)`.
- The new pure `selectCaptureSource`-feeding decision `selectUseCamera({hasCamera, permission}) =
  hasCamera && permission != denied` (`capture_source_factory.dart`) picks the live `CameraCaptureSource` when a
  camera is present and permission is not denied, else the software scene.
- **Result:** the shipped app opens on the **real camera by default** on a camera-bearing device; a device with no
  camera, or one whose permission is denied, falls back to the deterministic software scene (+ the "Camera access
  needed" affordance on denial). This realises **D-2** in production.
- `hasCamera` defaults **false**, so the flutter-tester acceptance harness (which injects `captureSource` at the
  seam) and no-camera devices keep the software scene — the automated suite is unaffected.

**Coverage-excluded device code** (the only `// coverage:ignore` in `lib/`, exercised only on a physical device,
per **D-5**): `main.dart` `_deviceHasCamera()` (the `availableCameras()` probe),
`lib/capture/source/camera_capture_source.dart` `PluginCameraDevice` (real `CameraController`: init, frame stream
start/convert/stop, lock/torch/lifecycle), and `lib/capture/camera_permission.dart` `PluginCameraPermission.request()`
(the OS permission prompt). Its pure consumer `selectUseCamera` has an **exhaustive unit truth-table**
(`capture_source_factory_test.dart`). These three device seams are the subject of the §10E on-device walkthrough.

---

## 10. Known gaps & deferred items

- **D-6 (deferred, out of scope):** real reference-card calibration (`normaliseAgainstCard`) against the live
  camera, RAW capture, and wide-gamut selection stay on the software path; the camera source reports the processed
  **sRGB** pipeline. Needs camera-specific CV / device tuning — a candidate for a follow-up feature.
- **D-5 device-only code** is verified by the §10E on-device walkthrough, not by `flutter-tester` (the plugin's
  platform channels can't run there). This is unchanged policy; PERM-5 added `_deviceHasCamera()` to that set.
- **Round-1 attempt-1 blocker — RESOLVED and holding.** The bs-17 AC-14 regression (hardcoded placeholder literal)
  was fixed by VIEW-4 (D-8): the placeholder grey comes from `AppTheme.cameraPlaceholderSurface`, the D-4
  capture-device exemption is retired (`kCaptureDeviceLiteralFiles = {}`), and `design_system_test` passes **27/0**
  in this round's regression.

---

## 11. Manual walkthrough — how a reviewer sees each Rule working

Prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has no `timeout`, run bare. The whole
`integration_test/live_camera/` dir won't launch at once under load — run per file.

### A. Live preview & colour (AC-1..AC-4) — on `flutter-tester`
```
flutter test -d flutter-tester integration_test/live_camera/preview_test.dart   # AC-1 render, AC-2 conversion, AC-4 value-only
flutter test -d flutter-tester integration_test/live_camera/reading_test.dart   # AC-3 reading follows the live frame, AC-5 lock
```
The scripted camera source emits known frames; the live view paints them (placeholder gone, AC-1 — the placeholder
grey is `AppTheme.cameraPlaceholderSurface`, same tone, D-8), conversion lands the reticle pixel within tolerance
and a second colour converts differently (AC-2), the reading tracks the live frame cyan→orange (AC-3), and
value-only greys the feed while the readings stay in colour (AC-4).

### B. Camera controls (AC-5, AC-6)
```
flutter test -d flutter-tester integration_test/live_camera/reading_test.dart    # AC-5
flutter test -d flutter-tester integration_test/live_camera/controls_test.dart   # AC-6 torch, AC-9 lifecycle
```
Locking AE·AWB·AF flips `source.locks.allLocked` and clears the "exposure not locked" warning **because** the
source reports locked (the `canLock:false` control proves it, AC-5). The torch toggle reaches the source, a reading
committed while lit is stamped `litByTorch`, and turning it off extinguishes (AC-6).

### C. Permission, availability & fallback (AC-7, AC-8, AC-9)
```
flutter test -d flutter-tester integration_test/live_camera/permission_test.dart   # AC-7 permission, AC-8 no-camera
flutter test -d flutter-tester integration_test/live_camera/controls_test.dart     # AC-9 lifecycle
```
On live-capture entry the app requests permission exactly once; granted keeps the camera, denied swaps to the
software source and raises the **"Camera access needed — enable it in Settings, then retry."** affordance with a
**Retry** button (`_CameraAccessAffordance`, AC-7) — no crash, no black screen. A source reporting
`available:false` falls back to software synchronously with no prompt (AC-8). Backgrounding releases the controller
and returning re-acquires so the feed resumes, not frozen/black (AC-9).

### D. Platform declarations (AC-10) — on-disk source-scan
```
flutter test -d flutter-tester integration_test/live_camera/platform_test.dart
```
- `android/app/src/main/AndroidManifest.xml` — `android.permission.CAMERA` + `<uses-feature
  android:name="android.hardware.camera" android:required="false"/>`.
- `ios/Runner/Info.plist` — non-empty `NSCameraUsageDescription` ("Paint Color Assistant uses the camera to read
  paint colours from the live view so you can sample, compare and match them.").

### E. On-device camera walkthrough (D-5 — the real plugin, now the shipped default)

**This is the crux of SIGNOFF-2** and a human, on-device step — it cannot be automated in this suite. Since PERM-5,
the shipped build **selects the real camera by default** on a camera-bearing device, so no dev flag is needed.
Build and install:
```
export PATH="$HOME/development/flutter/bin:$PATH"
flutter build apk --release        # → build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-release.apk   # Pixel = 38180DLJG000RF
```
On device, confirm the shipped real-camera default:
1. **Launch → live feed.** The app opens on the Capture screen showing the **live camera feed** (not the software
   demo scene), via the startup `_deviceHasCamera()` probe + `selectUseCamera`.
2. **First-entry permission prompt.** The OS camera-permission prompt appears on first live-capture entry.
   **Grant** → the live feed shows and the reading tracks the scene. **Deny** → falls back to the software scene
   with the "Camera access needed … Retry" affordance; no crash, no black screen.
3. **No-camera device** (or camera disabled) → opens on the software scene, no prompt; the rest of the app works.
4. **AE·AWB·AF lock + torch** drive the real hardware; the "exposure not locked" warning clears on lock; the torch
   lights the device LED and a reading committed while lit is stamped `litByTorch`.
5. **Lifecycle:** backgrounding releases the controller and returning re-acquires so the feed resumes (not
   frozen/black).

These exercise the three `// coverage:ignore` device seams — `_deviceHasCamera`, `PluginCameraDevice`,
`PluginCameraPermission.request` — that `flutter-tester` cannot reach.

---

## 12. Cost & token usage

Full breakdown: [cost-per-ac-round-2.md](cost-per-ac-round-2.md). Headline (list rates, `pricing.json` as-of
2026-09-25; **including** PERM-5, the SIGNOFF-1 sessions + decision, VIEW-4 and this SIGNOFF-2 session):

- **Feature total:** **$173.60** over **26 sessions** / **200,065,715 tokens** (input $0.02, cache write $47.13,
  cache read $96.79, output $29.67). All 26 sessions priced from their transcripts.
- **Time:** Σ active **9h 06m** (Σ wall 14h 30m), first start 2026-10-20 20:38 EDT → last end 2026-10-22 10:31 EDT.
- **Fully loaded per AC:** ≈ **$17.36** / 20.01M tokens each (10 ACs, evenly shared — see the note below).
- **Shared buckets:** activities (plan + sign-off decisions) $143.93 / 166.6M tok; sign-off $29.67 / 33.43M tok.
- **This round (SIGNOFF-2):** 5.34M tokens / 21m 04s active. PERM-5 (the round-1 change request): 5.79M / 31m 35s.

> Note: `ac_cost.py` reads each phase's *Target AC* from the module dashboards; those cells name the AC the phase
> delivers but not in the exact token the parser keys on, so the **Direct** attribution shows $0 and all cost lands
> in the **Fully loaded** (evenly shared) view — the meaningful figure here, since most ACs were green-at-baseline
> and kept green by phases targeting other ACs. LOC-per-AC is omitted (`feature_loc.py` is not installed in this
> environment).

---

## 13. Status & recommendation

**Ready for sign-off.** bs-19 is behaviour- **and production-complete** — all 10 ACs green in both modes, whole
suite **10 A / 0 below A** (fresh independent grade at HEAD `9345e45`, after PERM-5), unit 1694/0, coverage gate
PASS, no open gates or augmentations, no bs-19-owned flakes. The Round-1 change request (ship the real camera by
default) is implemented by PERM-5: a camera-bearing device now opens on the live `CameraCaptureSource`, with the
software scene as the no-camera / denied fallback (D-2 realised). The full cross-feature regression is clean save
the 4 documented carried off-lane flakes owned by other features (unchanged from round-1), and `design_system_test`
holds 27/0.

**The one remaining verification is the §10E on-device walkthrough** — the human check of the shipped real-camera
default and the three D-5 device seams, which `flutter-tester` cannot run. No automated gap remains.

**Decision command:** `/feature-next-phase --signoff bs19 approved | changes "<items>"`
