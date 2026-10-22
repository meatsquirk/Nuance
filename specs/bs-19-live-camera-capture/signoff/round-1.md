# Sign-off packet — bs-19 Live camera capture source — Round 1

**Feature:** [bs-19-live-camera-capture.feature](../../bs-19-live-camera-capture.feature) ·
**Master plan:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**At code:** `1d634e3` (branch `feat/bs-19-live-camera-capture`) · **Prepared:** 2026-10-21 · **Phase:** SIGNOFF-1 (re-run, after VIEW-4)
**Decision:** ⏸ **Awaiting human sign-off.**

> This is the **clean re-run**. SIGNOFF-1 attempt 1 (at `1d01c9d`) was blocked by a bs-17 design-system
> **AC-14** regression bs-19 introduced (a hardcoded placeholder literal in the new `live_frame_view.dart`).
> **VIEW-4** themed that placeholder from `AppTheme` (D-8) and retired the now-moot D-4 capture exemption; the
> full cross-feature regression below is now clean (AC-14 green, `design_system_test` 27/0). This packet
> supersedes the attempt-1 record in this same file's history.

Real `CameraCaptureSource` over the Flutter `camera` plugin, behind the bs-02 `CaptureSource` seam: renders
the live feed into the Capture view (replacing the flat-grey placeholder), converts device frames
(YUV420/Android, BGRA/iOS) to the `Frame` RGB model, drives AE·AWB·AF locks and the torch on the real device,
requests camera permission with a graceful software fallback, releases/re-acquires across the app lifecycle,
and declares camera use on both platforms. **All 10 ACs delivered, 0 pending.**

**Scorecard (summary page):** https://claude.ai/artifact/4JfXYVUKW6FPoHp3rmJ4Pa

---

## 1. Preconditions (all met)

| Precondition | State |
|---|---|
| Every non-sign-off phase done | ✅ 20/21 (session log); CAM/VIEW/PERM/ITEST modules complete, VIEW-4 done |
| Every AC ✅ in the coverage table | ✅ AC-1..AC-10 all ✅ Done |
| Pending list empty | ✅ `pendingACs` map is `{}` (every AC runs by default) |
| No open *Test augmentations* row | ✅ all 5 rows CLOSED (TestAC03→CAM-4, TestAC05→CAM-5, TestAC06→CAM-6, TestAC04→VIEW-3, TestAC10→PERM-4) |
| Fresh whole-suite grade grid all A | ✅ 10 A / 0 below A (fresh independent grader, 2026-10-21, @ `1d634e3`, after VIEW-4) |

---

## 2. Per-AC result

Every AC test is un-pended and green in both default and run-pending modes (identical — nothing pending).
Grades from the fresh sign-off re-run grid
([behavior-test-completeness-bs-19-live-camera-capture.md](../behavior-test-completeness-bs-19-live-camera-capture.md),
§ *Sign-off re-grade — SIGNOFF-1 re-run (whole suite at HEAD `1d634e3`, after VIEW-4)*).

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

## 3. Verification (from the primary checkout @ `1d634e3`, machine-readable JSON)

**Unit suite + coverage** — `flutter test --coverage --reporter=json test/` → **1687 passed / 0 failed** (exit 0).
**Coverage gate** — SIGNOFF-1 touches no `lib/` (sign-off is docs/plan only) → **PASS** (0 touched source files).

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
(§ *Sign-off re-grade — SIGNOFF-1 re-run … HEAD `1d634e3`*): **10 A / 0 below A**; all scaffold/smoke/guard
tests non-vacuous. The independent grader confirmed VIEW-4's placeholder-getter change weakened no test (the
AC-test bodies are byte-identical to `1d01c9d`; placeholder detection stays exact by ARGB value). The only
historical sub-A (AC-2 YUV tolerance) was fixed in ITEST-2 (`_yuvToleranceL1` 30→12) and holds A.

**Full cross-feature regression** — `flutter test -d flutter-tester --reporter=json <file>` over every
feature's acceptance suite (19 files) plus the whole unit target above:

**Result: 340 passed / 4 failed; 16 of 19 suites fully green; the 4 failures are the carried off-lane flakes
only. The attempt-1 blocker (bs-17 AC-14) is RESOLVED — `design_system_test` is 27/0.**

Clean suites (0 fail): advanced_capture 21, bs11 accessibility 19, bs12 nfr 33, bs13 dataset 19, bs14 (consent
5 / exchange 3 / harness 12 / refine 4), capture 19, comparison 26, correction 22, daltonization 25,
**design_system 27**, harness 5, readout 12, recipes 24.

| Suite | Failing test | Classification | Proof |
|---|---|---|---|
| palette | bs-06 AC-3 provenance legend | carried off-lane flake | fails identically at base `11944b6` / `c00422f` |
| palette | bs-06 AC-5 palette re-points recipe search | carried off-lane flake | fails identically at base `11944b6` / `c00422f` |
| display | bs-08 AC-9 one consistent spoken phrasing | carried off-lane flake | fails identically at base `11944b6` / `c00422f` |
| self_assessment | bs-07 AC-4 intake seeds the prior (`Expected CvdType.deutan, Actual null`) | carried off-lane flake | fails identically at base `11944b6` |

All four are in the master plan's **Known flakes** table, owned by other features, measured off the exclusive
iOS-sim lane, and proven at the merge-base — **not** bs-19 regressions. No new flake, and **no bs-19-owned
failure**: every bs-19 test and every other feature's lane-correct suite is green.

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

These reproduce at the merge-base and are **not** bs-19 regressions. All four appear in §3's regression and
are classified there; none blocks sign-off.

---

## 9. Known gaps & deferred items

- **D-6 (deferred, out of scope):** real reference-card calibration (`normaliseAgainstCard`) against the live
  camera, RAW capture, and wide-gamut selection stay on the software path; the camera source reports the
  processed **sRGB** pipeline. Needs camera-specific CV / device tuning — a candidate for a follow-up feature.
- **D-5 / production activation — the reviewer's key call.** The live-camera behaviour is fully implemented
  and tested **behind the `AppDependencies.captureSource` / `cameraPermission` seams** with a scripted camera
  device. The **shipped production entry point** (`main.dart`) still assembles the deterministic **software**
  demo scene: `selectCaptureSource(softwareFallback: demoCaptureSource)` keeps the default `useCamera:false`,
  and the Capture host runs the permission/selection flow only when the injected source is already
  `kind==camera`. So in the shipped build the real `CameraCaptureSource`, `PluginCameraDevice` and
  `PluginCameraPermission.request()` are **wired but dormant** — the app opens on the software scene and does
  not prompt for the camera. This is the deliberate D-2/D-5 design (keep the deterministic default; the
  plugin's platform channels can't run under `flutter-tester`, so on-device activation + the real-plugin
  behaviour are verified by the device walkthrough in §10E, not automated). **The reviewer decides** whether
  shipping with the camera dormant-by-default is acceptable for this feature, or whether production
  auto-probe-and-select wiring (flip `useCamera` from a real availability probe + permission at startup) is
  required before "done" — that wiring would add on-device-only, coverage-excluded code and was intentionally
  not written blind without a device.
- **Coverage-excluded device code** (the only `// coverage:ignore` in `lib/`, exercised only on a physical
  device, per D-5): `lib/capture/source/camera_capture_source.dart` `PluginCameraDevice` (real
  `CameraController`: init, frame stream start/convert/stop, lock/torch/lifecycle calls) and
  `lib/capture/camera_permission.dart` `PluginCameraPermission.request()` (the OS permission prompt).
- **Attempt-1 blocker — RESOLVED.** The bs-17 AC-14 regression (hardcoded placeholder literal) is fixed by
  VIEW-4 (D-8): the placeholder grey now comes from `AppTheme.cameraPlaceholderSurface`, the D-4 capture-device
  exemption is retired (`kCaptureDeviceLiteralFiles = {}`), and `design_system_test` passes 27/0 at HEAD.

---

## 10. Manual walkthrough — how a reviewer sees each Rule working

Prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has no `timeout`, run bare. The whole
`integration_test/live_camera/` dir won't launch at once under load — run per file.

### A. Live preview & colour (AC-1..AC-4) — on `flutter-tester`
```
flutter test -d flutter-tester integration_test/live_camera/preview_test.dart   # AC-1 render, AC-2 conversion, AC-4 value-only
flutter test -d flutter-tester integration_test/live_camera/reading_test.dart   # AC-3 reading follows the live frame, AC-5 lock
```
The scripted camera source emits known frames; the live view paints them (placeholder gone, AC-1 — the
placeholder grey is now `AppTheme.cameraPlaceholderSurface`, same tone, D-8), conversion lands the reticle
pixel within tolerance and a second colour converts differently (AC-2), the reading tracks the live frame
cyan→orange (AC-3), and value-only greys the feed while the readings stay in colour (AC-4).

### B. Camera controls (AC-5, AC-6)
```
flutter test -d flutter-tester integration_test/live_camera/reading_test.dart    # AC-5
flutter test -d flutter-tester integration_test/live_camera/controls_test.dart   # AC-6 torch, AC-9 lifecycle
```
Locking AE·AWB·AF flips `source.locks.allLocked` and clears the "exposure not locked" warning **because** the
source reports locked (the `canLock:false` control proves it, AC-5). The torch toggle reaches the source, a
reading committed while lit is stamped `litByTorch`, and turning it off extinguishes (AC-6).

### C. Permission, availability & fallback (AC-7, AC-8, AC-9)
```
flutter test -d flutter-tester integration_test/live_camera/permission_test.dart   # AC-7 permission, AC-8 no-camera
flutter test -d flutter-tester integration_test/live_camera/controls_test.dart     # AC-9 lifecycle
```
On live-capture entry the app requests permission exactly once; granted keeps the camera, denied swaps to the
software source and raises the **"Camera access needed — enable it in Settings, then retry."** affordance with
a **Retry** button (`_CameraAccessAffordance`, AC-7) — no crash, no black screen. A source reporting
`available:false` falls back to software synchronously with no prompt (AC-8). Backgrounding releases the
controller and returning re-acquires so the feed resumes, not frozen/black (AC-9).

### D. Platform declarations (AC-10) — on-disk source-scan
```
flutter test -d flutter-tester integration_test/live_camera/platform_test.dart
```
- `android/app/src/main/AndroidManifest.xml` — `android.permission.CAMERA` + `<uses-feature
  android:name="android.hardware.camera" android:required="false"/>`.
- `ios/Runner/Info.plist` — non-empty `NSCameraUsageDescription` ("Paint Color Assistant uses the camera
  to read paint colours from the live view so you can sample, compare and match them.").

### E. On-device camera walkthrough (D-5 — the real plugin)
The real `camera`-plugin source is **not** reachable on `flutter-tester` and (see §9) is dormant in the
shipped build. To exercise the real `PluginCameraDevice` / `PluginCameraPermission` on a physical device,
assemble with the camera selected — e.g. a dev build passing `selectCaptureSource(..., useCamera: true)` (or
wire the production probe discussed in §9) — then on device confirm: the OS camera-permission prompt appears;
granting shows the live feed in the Capture view; the reading tracks the scene; AE·AWB·AF lock and the torch
drive the hardware; denying / one-with-no-camera falls back to the software scene with the affordance;
backgrounding and returning resumes the feed. **This is a human, on-device step** — it cannot be automated in
this suite.

---

## 11. Cost & token usage

Full breakdown: [cost-per-ac-round-1.md](cost-per-ac-round-1.md). Headline (list rates, `pricing.json`
as-of 2026-09-25; **including** both SIGNOFF-1 sessions and VIEW-4):

- **Feature total:** **$160.71** over **23 sessions** / **186,248,009 tokens** (input $0.01, cache write
  $43.53, cache read $90.13, output $27.04). All 23 sessions priced from their transcripts.
- **Time:** Σ active **8h 06m** (Σ wall 13h 29m), first start 2026-10-20 20:38 EDT → last end 2026-10-21
  23:54 EDT.
- **Fully loaded per AC:** ≈ **$16.07** / 18.62M tokens each (10 ACs, evenly shared — see the note below).
- **Shared buckets:** activities (plan + sign-off decisions) $138.98 / 160.8M tok; sign-off $21.73 / 25.40M tok.
- **SIGNOFF-1 (both attempts):** 24.20M tokens, 1h 07m active (attempt-1 18.16M / 40m 27s + re-run 6.04M /
  26m 36s); VIEW-4 3.79M / 14m 40s.

> Note: `ac_cost.py` reads each phase's *Target AC* from the module dashboards; those cells name the AC the
> phase delivers but not in the exact token the parser keys on, so the **Direct** attribution shows $0 and all
> cost lands in the **Fully loaded** (evenly shared) view — the meaningful figure here, since most ACs were
> green-at-baseline and kept green by phases targeting other ACs. LOC-per-AC is omitted (`feature_loc.py`
> is not installed in this environment).

---

## 12. Status & recommendation

**Ready for sign-off.** bs-19's behaviour is complete and strong — all 10 ACs green in both modes, whole suite
**10 A / 0 below A** (fresh independent grade at HEAD `1d634e3`), unit 1687/0, coverage gate PASS, no open
gates or augmentations, no bs-19-owned flakes. The attempt-1 blocker (bs-17 AC-14) is resolved by VIEW-4, and
the full cross-feature regression is clean save the 4 documented carried off-lane flakes owned by other
features.

**The one standing reviewer decision is §9 production activation:** accept shipping with the real camera
**wired but dormant** by default (the deliberate D-2/D-5 design — the deterministic software scene opens, the
plugin activates on-device), **or** request production auto-probe-and-select wiring as a follow-up. The D-5
on-device camera walkthrough (§10E) is the human verification of the real plugin, which `flutter-tester`
cannot run.

**Decision command:** `/feature-next-phase --signoff bs19 approved | changes "<items>"`
