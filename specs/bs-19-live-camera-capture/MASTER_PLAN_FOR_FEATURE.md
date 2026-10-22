# Master Plan — bs-19 Live camera capture source

**Spec:** [bs-19-live-camera-capture.feature](../bs-19-live-camera-capture.feature)
**Status:** ⏸ Awaiting sign-off — SIGNOFF-1 (re-run) packet prepared @ `1d634e3`. All 10 ACs ✅, grade 10 A/0; unit 1687/0; coverage PASS; full regression clean save the 4 carried off-lane flakes (bs-17 AC-14 regression RESOLVED, design_system 27/0). Packet [signoff/round-1.md](signoff/round-1.md) awaits a human decision.
**Architecture:** `lib/capture/source/` (`CaptureSource`, `Frame`, `SoftwareCaptureSource`), `lib/capture/capture_live_view.dart` (placeholder feed), `lib/app/build_app.dart` + `lib/main.dart` (`AppDependencies.captureSource` injection seam); `docs/paint-color-app-solution-intent.md` (SI D2 capture). Wireframe: the Capture live-view region.
**Code home:** /Users/matthew.quirk/Nuance · https://github.com/meatsquirk/Nuance.git · base `main` · extends existing (confirmed by Matt Quirk, 2026-10-20)

## Gap analysis (against `main` @ fa21c49 — d3a1c4f + bs-18 plan/gate; capture code is bs-02, present on main)

| AC | Exists today | Missing |
|---|---|---|
| AC-1 Live preview | `capture_live_view.dart` renders `ColoredBox(0xFF3A3A3A)` placeholder + grayscale filter + `liveViewKey` | A render path that paints the active source's `Frame` into the view |
| AC-2 Frame conversion | `Frame`/`Pixel.pixelAt`, `FrameColorSpace` | `CameraImage` (YUV420/BGRA) → `Frame` RGB conversion |
| AC-3 Reading follows live frame | Source-agnostic sampling in `CaptureController` already samples `pixelAt` of the active source's frame | A real streaming source whose frames change with the scene; assertion that the reading tracks the live frame, not the placeholder |
| AC-4 Value-only grayscale | `ColorFiltered` grayscale over the placeholder | The same filter over real rendered frames |
| AC-5 AE·AWB·AF lock | `CaptureLocks`, lock controls, "approximate" warning plumbing on the software source | Locks that drive the **real** camera; warning clears from real lock state |
| AC-6 Torch | `torchOn`/`turnTorchOn/Off` on the abstraction + `litByTorch` stamp | Torch wired to the **real** device flash LED |
| AC-7 Permission + fallback | `captureSource` injection seam; `SoftwareCaptureSource` default | Runtime camera-permission request; graceful fallback + "camera access needed" state; production source selection |
| AC-8 No-camera fallback | software default | Camera-availability probe; fallback wiring |
| AC-9 Lifecycle | — | Camera controller acquire/release tied to app lifecycle + screen dispose |
| AC-10 Platform declarations | neither declared | Android `CAMERA` permission + `<uses-feature>`; iOS `NSCameraUsageDescription` |

## Build order

| Stage | Phases |
|---|---|
| 1 Scaffold | CAM-1 |
| 2 Component shells | CAM-2, PERM-1, VIEW-1 |
| 3 Acceptance tests | ITEST-1, ITEST-2, ITEST-3, ITEST-4 (test review, G-2) |
| 4 Behavior | CAM-3 (*enabler-ish*), VIEW-2, CAM-4, VIEW-3, CAM-5, CAM-6, CAM-7, PERM-2, PERM-3, PERM-4, **VIEW-4** (fix: theme placeholder, added at SIGNOFF-1 attempt 1) |
| 5 Sign-off | SIGNOFF-1 |

## Acceptance criteria coverage

| AC | Scenario | Integration test (ITEST) | Behavior phases | Status |
|---|---|---|---|---|
| AC-1 | The live view shows the camera feed | ITEST-2 `TestAC01_LivePreview` | VIEW-2 | ✅ Done |
| AC-2 | Camera frames convert to the correct colour | ITEST-2 `TestAC02_FrameConversion` | CAM-3 | ✅ Done |
| AC-3 | The reading follows the live camera frame | ITEST-2 `TestAC03_ReadingFollowsFrame` | CAM-4 | ✅ Done |
| AC-4 | Value-only mode shows the live feed in grayscale | ITEST-2 `TestAC04_ValueOnlyLive` | VIEW-3 | ✅ Done |
| AC-5 | Locking AE·AWB·AF settles the live camera | ITEST-2 `TestAC05_LockClearsWarning` | CAM-5 | ✅ Done |
| AC-6 | The torch toggles the device light | ITEST-3 `TestAC06_Torch` | CAM-6 | ✅ Done |
| AC-7 | Permission requested; denial falls back gracefully | ITEST-3 `TestAC07_PermissionFallback` | PERM-2 | ✅ Done |
| AC-8 | A device with no camera falls back gracefully | ITEST-3 `TestAC08_NoCameraFallback` | PERM-3 | ✅ Done |
| AC-9 | Camera released and re-acquired across lifecycle | ITEST-3 `TestAC09_Lifecycle` | CAM-7 | ✅ Done |
| AC-10 | The app declares camera use on both platforms | ITEST-3 `TestAC10_PlatformDeclarations` | PERM-4 | ✅ Done |

## Design decisions

| # | Decision | Why |
|---|---|---|
| D-1 | Real source uses the official Flutter `camera` plugin (project-local dep, added in CAM-2) | Maintained, cross-platform, exposes `CameraImage` frames + lock/torch/lifecycle controls |
| D-2 | `CameraCaptureSource` is the production default **only when** a camera is available AND permission granted; `SoftwareCaptureSource` (demo scene) is the graceful fallback and stays the test/driver source | Keeps the app usable with no camera / denied permission; preserves the deterministic default seam `main.dart` already wires |
| D-3 | Permission requested at first live-capture entry; denial is non-fatal — fallback + a visible "camera access needed" affordance, never a crash or black screen | AC-7; respects platform permission UX |
| D-4 | Frame conversion is pure-Dart (`CameraImage` YUV420/Android, BGRA/iOS → `Frame` RGB), downsampled for sampling cost, unit-tested with golden pixels | AC-2; keeps colour maths testable off-device |
| D-5 | Acceptance tests inject a scripted `CaptureSource` (known frames + lock/torch/permission/availability state) at the `AppDependencies.captureSource` seam — no real hardware on `flutter-tester`; the real plugin is verified by a device walkthrough at sign-off | Mirrors `FakeCaptureSource`; the plugin's platform channels can't run under `flutter-tester` |
| D-6 | **Deferred (out of scope):** real reference-card calibration/`normaliseAgainstCard` against the live camera, RAW capture, and wide-gamut selection — the camera source reports the processed sRGB pipeline and leaves card-normalisation on the software path | Those need camera-specific CV / device tuning; this feature delivers the live feed + sampling. Listed at sign-off as a known gap |
| D-7 | Camera lifecycle tied to `WidgetsBindingObserver` + screen dispose: release on `inactive`/`paused`, re-init on `resumed` | AC-9; avoids a leaked/locked controller and black frames |
| D-8 | The live-view **placeholder colour** is sourced from `AppTheme`, not a hardcoded `Color(0x…)` literal (VIEW-4); **the D-4 capture-device exemption is retired** (`kCaptureDeviceLiteralFiles = {}`), leaving `AppTheme` the sole AC-14 file-level exemption | Matt Quirk, 2026-10-21. VIEW-1 relocated the placeholder grey into the new `live_frame_view.dart`, which bs-17's design-system AC-14 flags as a residual palette literal. Chosen over exempting the new file: theming removes the literal entirely (`AppTheme.cameraPlaceholderSurface`), aligning with the design system. VIEW-4 found VIEW-1 had moved the lone camera-device literal **out of** the D-4-exempt `capture_live_view.dart`, so theming it left the carve-out silencing nothing and broke AC-14's load-bearing augmentation; Matt chose to retire the now-moot exemption and rewrite that augmentation (empty set + `AppTheme` as sole authority). Core AC-14 rule unchanged; D-4's frame-conversion decision is otherwise untouched |

## Acceptance integration test plan

Module plan: [modules/ITEST.md](modules/ITEST.md).

**Where it lives and how it runs:** `integration_test/live_camera/`, run `-d flutter-tester` per file (the repo's canonical lane; the whole dir won't launch at once under load — run per-file). Default target skips pending; run-pending via `--dart-define=BS19_RUN_PENDING=true`.
**Where assertions look:** the Capture widget tree (live-view render vs placeholder, grayscale filter, warning text, torch/lock affordances), the `CaptureController`/capture state (current reading, `litByTorch`), the capture **read endpoint** extended in PERM-1 (active source kind + permission state), and a static source-scan of `android/app/src/main/AndroidManifest.xml` + `ios/Runner/Info.plist` (AC-10, like bs-11/12/13 source-scan ACs).
**What is real and what is faked:** real `buildApp` assembly, real `CaptureController`, real live-view widget, real conversion maths; **faked** = the camera device, via a scripted `CaptureSource` injected at `captureSource:` (the plugin's platform channels are the only thing stubbed). AC-10 reads the real repo config files.

**Fixtures:**

| Fixture | Shape |
|---|---|
| `ScriptedCameraSource` | A `CaptureSource` (based on the `FakeCaptureSource`/`SoftwareCaptureSource` pattern) emitting a controllable list of known `Frame`s, with settable locks, torch, lighting, `referenceCardPresent`, and test-only `activeKind`/`permissionState`/`available` signals. Drives AC-1..AC-9 |
| `knownFrame(colour)` | A `Frame` whose pixel at the reticle is a specified colour; a second distinct-colour frame for the conversion control (AC-2) and the "reading follows frame" change (AC-3) |
| `rawCameraImage(yuv420 / bgra)` | Encoded device-style buffers with known pixels, fed to the conversion unit under test (AC-2) |
| `permissionScenario` | `granted` / `denied` / `undetermined` / `noHardware` — selects the source-selection path (AC-7, AC-8) |
| `platformManifests` | The on-disk `AndroidManifest.xml` + `Info.plist`, read by the AC-10 source-scan |

**Test catalogue:**

| AC | Given: built via public flows → checked by | When | Then: exact assertions (negative Thens after a settle point) | Rejects |
|---|---|---|---|---|
| AC-1 | Scripted source active + permission granted (inject `captureSource` = ScriptedCameraSource, `permissionState=granted`) → assert read endpoint reports `activeKind==camera` before the When | Capture screen opens | live view contains the frame-render widget painting the source frame; **no** `ColoredBox(0xFF3A3A3A)` placeholder under `liveViewKey` (after first frame pumps) | A view that keeps the placeholder / ignores frames |
| AC-2 | A `rawCameraImage` with a known reticle pixel → assert the raw buffer's documented bytes | convert to `Frame` | `frame.pixelAt(reticle)` == known colour within tolerance; **control:** a second different-colour buffer yields a correspondingly different pixel | Channel-swapped (BGR↔RGB) or mis-ranged YUV conversion; a constant pixel |
| AC-3 | Scripted source active, emitting `knownFrame(c1)` → assert current reading == c1 | source emits `knownFrame(c2)` | current reading updates to c2; reading == live frame pixel under reticle, not a fixed value (**control:** c1≠c2) | A sampler reading a stale/placeholder/fixed colour |
| AC-4 | Scripted source active, frame visible → assert view shows colour frame | value-only toggled on | live view wraps the frame render in the saturation-0 `ColorFiltered`; overlaid readings remain outside the filter (in colour) | Graying the whole screen incl. readings; filtering the placeholder only |
| AC-5 | Scripted source, `locks.allLocked==false`, reading marked approximate → assert the "exposure not locked" warning is present | painter locks AE+AWB+AF | source `locks.allLocked==true`; the "exposure not locked" warning is **absent** after the lock settles (settle point: next stability/warning rebuild) | Clearing the warning without locking; locking state not reflected from the source |
| AC-6 | Scripted source, `torchOn==false` → assert torch-off affordance | painter turns torch on | source `torchOn==true`; a reading committed now is stamped `litByTorch`; **then** turning it off → `torchOn==false` (settle: after the off tap rebuild) | A torch toggle that doesn't reach the source; missing `litByTorch` stamp |
| AC-7 | `permissionScenario=undetermined`, a permission seam recording requests → assert no request made before the When | Capture opened for live read | the permission seam received exactly one request; **granted** branch → `activeKind==camera`; **denied** branch → `activeKind==software` and a "camera access needed" affordance is present and the app did not throw (settle: after the decision resolves) | Never requesting; crashing/black-screen on denial; staying on a dead camera source |
| AC-8 | `permissionScenario=noHardware` (available==false) → assert the availability probe reports none | Capture opens | `activeKind==software`; reading + import-photo flows still work; no throw (settle: after assembly) | Crash / black view when no camera; forcing a camera source that can't stream |
| AC-9 | Scripted source active, a lifecycle-observer seam recording acquire/release → assert one acquire, zero releases | app sent `paused` then `resumed` (dispatch lifecycle) | a release recorded on `paused`; a re-acquire recorded on `resumed`; the live feed renders again (not frozen/black) after resume (settle: after the resumed frame pumps) | Leaking the controller (no release); not re-acquiring (frozen/black after resume) |
| AC-10 | The real `AndroidManifest.xml` + `Info.plist` on disk → read them | source-scan | Android file contains `android.permission.CAMERA` and `<uses-feature android:name="android.hardware.camera...">`; iOS file contains a non-empty `NSCameraUsageDescription` | Missing either declaration; an empty usage string |

**Red baseline** and **test augmentations:** tracked in [modules/ITEST.md](modules/ITEST.md).
Pre-seeded augmentations: AC-3/AC-5/AC-6 may run **green at baseline** against a scripted source because the reading/lock/torch pipeline is already source-agnostic — their discriminating value is the *live-frame-change* / *source-state-reflection* control above; the AC-test phases confirm each still Rejects a placeholder/fixed implementation, and the owning behavior phase (which makes the **real** `CameraCaptureSource` drive those signals) keeps them green. AC-1/AC-2/AC-4/AC-7/AC-8/AC-9/AC-10 are red at baseline (no render path / conversion / permission / fallback / lifecycle / declarations yet).

## Modules

| Module | Plan | Purpose | Depends on | Status |
|---|---|---|---|---|
| CAM | [modules/CAM.md](modules/CAM.md) | Real `CameraCaptureSource` over the `camera` plugin: frame stream + conversion, AE·AWB·AF locks, torch, lifecycle | — | ✅ Complete |
| VIEW | [modules/VIEW.md](modules/VIEW.md) | Render the active source's frames in the live view (replace the placeholder); value-only grayscale over real frames | CAM | ✅ Done (VIEW-1/2/3/4) |
| PERM | [modules/PERM.md](modules/PERM.md) | Permission request + graceful fallback + production source selection + platform declarations + read endpoint | CAM | ✅ Complete |
| ITEST | [modules/ITEST.md](modules/ITEST.md) | Acceptance integration suite: one pending test per AC, and its review | all shell phases | ✅ Complete |

## Dependency graph

```mermaid
graph LR
  CAM-1 --> CAM-2 & PERM-1 & VIEW-1
  CAM-2 & PERM-1 & VIEW-1 --> ITEST-1 --> ITEST-2 & ITEST-3
  ITEST-2 & ITEST-3 --> ITEST-4
  ITEST-4 --> CAM-3
  CAM-3 --> VIEW-2 & CAM-4 & CAM-5 & CAM-6 & CAM-7
  VIEW-2 --> VIEW-3
  PERM-1 --> PERM-2
  CAM-3 --> PERM-2 --> PERM-3
  PERM-1 --> PERM-4
  VIEW-3 & CAM-3 --> VIEW-4
  VIEW-2 & VIEW-3 & CAM-4 & CAM-5 & CAM-6 & CAM-7 & PERM-2 & PERM-3 & PERM-4 & VIEW-4 --> SIGNOFF-1
```

**VIEW-4** (added at SIGNOFF-1 attempt 1, 2026-10-21): a fix phase that themes the live-view placeholder
colour (D-8), resolving a bs-17 design-system AC-14 regression the full cross-feature regression surfaced. It
blocks a clean SIGNOFF-1 and must run before the sign-off is re-attempted.

**Parallel windows:** the three shells (CAM-2 ∥ PERM-1 ∥ VIEW-1) touch disjoint files. ITEST-2 ∥ ITEST-3. After CAM-3, the CAM behavior phases (CAM-4/5/6/7) and VIEW-2 run concurrently; PERM-2/3 form a short chain; PERM-4 (manifests) is independent. Merge-risky pair: CAM-3 and VIEW-2 both read `capture_live_view.dart` — sequence VIEW-2 after CAM-3.

## Open gates

| Gate | Kind | Decision needed | Blocks | Status |
|---|---|---|---|---|
| G-1 | decision | Approve the spec (record the approval as its first line) | CAM-1 | ✅ Resolved 2026-10-21: approved — spec first line records it — Matt Quirk |
| G-2 | decision | Approve the acceptance tests (ITEST-4's packet) | every behavior phase | ✅ Resolved 2026-10-21 12:36 EDT: approved — Matt Quirk (packet modules/ITEST.md § ITEST-4, suite @ c7d34b0, 10 A/0 B; behavior stage unblocked) |

Resolved: `✅ Resolved <date time>: <decision, one line> — <who>`.

## Known flakes

| Test | Symptom | Rate (runs) | Measured at | Owner | Status |
|---|---|---|---|---|---|
| bs-06 palette AC-3 | provenance-legend "Found 0 widgets" off the exclusive iOS-sim lane | carried | `c00422f` | bs-06 (off-lane viewport) | Open |
| bs-06 palette AC-5 | travel-set selection off-lane | carried | `c00422f` | bs-06 (device-independent) | Open |
| bs-08 display AC-9 | spoken-phrasing off-lane | carried | `c00422f` | bs-08 (off-lane viewport) | Open |
| bs-07 self_assessment AC-4 | intake-seeds-prior off-lane (`Expected CvdType.deutan, Actual null`) | carried | `11944b6` (base) | bs-07 (off-lane interaction) | Open — confirmed at bs-19 base, not a regression |

## Session log

| # | Phase | Target | Status | Tokens | Time | Notes |
|---|---|---|---|---|---|---|
| 1 | CAM-1 | scaffold: branch, BS19_RUN_PENDING runner, baseline, coverage gate | ✅ Done | 4,687,376 | 13m 23s (44m 03s) | G-1 approved in-session; baseline 1643✓; gate both ways |
| 2 | CAM-2 | shell: `camera` dep + `CameraCaptureSource` skeleton + source-selection factory seam (default software) | ✅ Done | 4,236,040 | 10m 17s (10m 17s) | inert shell; factory wired into assembly (still software); 12 unit tests; 100% cov |
| 3 | PERM-1 | shell: permission seam + capture-state availability/permission field + manifest/plist entries + read endpoint | ✅ Done | 9.02M | 14m 15s | ∥ VIEW-1 |
| 4 | VIEW-1 | shell: frame-render widget seam in live view (inactive: null→placeholder) | ✅ Done | 3.75M | 11m 03s | all shells done |
| 5 | ITEST-1 | acceptance-tests: harness, `ScriptedCameraSource` + fixtures, pending gate (all 10 pending), smoke | ✅ Done | 7,639,135 | 14m 08s | harness over `buildApp`; smoke 11/11 both modes; no lib touched |
| 6 | ITEST-2 | acceptance-tests: AC-1..AC-5 (pending) + red baseline | ✅ Done | 14,061,597 | 34m 15s | 5×A; AC-1/2/4 red, AC-3/5 green-at-baseline; AC-2 B→A (YUV tol) fix 1/3 |
| 7 | ITEST-3 | acceptance-tests: AC-6..AC-10 (pending) + red baseline | ✅ Done | 16,840,597 | 1h 16m | 5×A; AC-6/AC-10 green-at-baseline, AC-7/8/9 red (PERM-2/PERM-3/CAM-7); fix 1/3 (AC-9 paused-pump hang) |
| 8 | ITEST-4 | test-review: packet; G-2 | ✅ Done | 1,411,488 | 2m 42s | G-2 approved 2026-10-21 (Matt Quirk); behavior stage unblocked |
| 9 | CAM-3 | AC-2 frame conversion + real frame stream (enabler-ish) | ✅ Done | 8.08M | 19m 38s | AC-2 live (A); CameraDevice seam, PluginCameraDevice coverage-ignored (D-5); cov 100% 2 touched; fix 1/3 |
| 10 | VIEW-2 | AC-1 live preview renders real frames | ✅ Done | 7.74M | 14m 54s | AC-1 live (A); `currentFrame` seam, camera-only paint; smoke guards updated; fix 0/3 |
| 11 | CAM-4 | AC-3 reading follows the live frame | ✅ Done | 4.41M | 9m 06s | un-pend + keep green (no lib); 3×A; cov PASS (0 touched lib); fix 0/3 |
| 12 | VIEW-3 | AC-4 value-only grayscale over live frame | ✅ Done | 3.88M | 11m 59s | un-pend + keep green (no lib); VIEW module complete; 4×A; cov PASS (0 touched lib); fix 0/3 |
| 13 | CAM-5 | AC-5 real AE·AWB·AF locks clear the warning | ✅ Done | 6,178,509 | 11m 02s | real lock forwarding via CameraDevice seam; AWB implicit w/ AE (no plugin ctrl, D-5); 5×A; cov 100% 1 touched; fix 0/3 |
| 14 | CAM-6 | AC-6 real device torch | ✅ Done | 5,348,128 | 13m 23s | real torch forwarding via CameraDevice seam (`setFlashMode`); un-pend AC-6; 6×A; unit 1674; cov 100% 1 touched; fix 0/3 |
| 15 | CAM-7 | AC-9 camera lifecycle release/resume | ✅ Done | 17,712,519 | 47m 55s | WidgetsBindingObserver on Capture host → controller pauseFeed/resumeFeed (D-7); AC-9 un-pended; CAM module complete; 7×A; unit 1680; cov 100% 2 touched; fix 1/3 (host unit test: FakeAsync no-flush of async cancel) |
| 16 | PERM-2 | AC-7 permission request + denial fallback + state | ✅ Done | 17,788,884 | 29m 12s | host requests on entry (camera source + seam); granted keeps camera, denied swaps to software fallback + affordance; 8×A; unit 1684; cov 100% 4 touched; fix 1/3 |
| 17 | PERM-3 | AC-8 no-camera fallback | ✅ Done | 10,749,642 | 17m 46s | 9×A re-grade; AC-8 live; `available` seam; fix 0/3 |
| 18 | PERM-4 | AC-10 platform declarations (Android + iOS) | ✅ Done | 5,210,656 | 11m 01s | un-pend + confirm only (no lib); AC-10 live; map now empty; 10×A re-grade; cov PASS (0 touched lib); fix 0/3 |
| 19 | SIGNOFF-1 | sign-off: packet + full regression + manual approval (attempt 1) | ⚠ Blocked | 18.16M | 40m 27s (3h 56m) | bs-19 suite 10/10 A, unit 1687/0, cov PASS; full regression surfaced a **bs-17 AC-14** regression (live_frame_view placeholder, proven vs base `11944b6`) → VIEW-4 queued; re-run after. Packet: [signoff/round-1.md](signoff/round-1.md) |
| 20 | VIEW-4 | behavior-fix: theme the live-view placeholder from AppTheme (D-8); resolve bs-17 AC-14; keep AC-1/AC-4 green | ✅ Done | 3.79M | 14m 40s | theme token `AppTheme.cameraPlaceholderSurface`; D-4 capture exemption retired (Matt Quirk, realises D-8); unit 1687/0, cov PASS 2 touched, bs-19 suite green both modes, bs-17 AC-14 27/27; grade A; fix 1/3 |
| 21 | SIGNOFF-1 | sign-off (re-run after VIEW-4) | ⏸ Awaiting sign-off | 6.04M | 26m 36s | clean re-run: unit 1687/0, cov PASS (0 touched lib), bs-19 acceptance 21/21 both modes, grade 10 A/0 @ `1d634e3`; full regression 340/4 (4 = carried off-lane flakes), bs-17 AC-14 RESOLVED (design_system 27/0). Packet: [signoff/round-1.md](signoff/round-1.md) |

*Tokens* / *Time* = the phase totals from the *Token usage* ledger (Time = active, wall in brackets), filled when the row is marked done.

## Next phase

**SIGNOFF-1 (re-run) packet prepared — awaiting a human decision. No further agent phase until then.**
The clean re-run verification is green: unit 1687/0, coverage PASS, bs-19 acceptance 21/21 both modes, fresh
whole-suite grade 10 A/0 @ `1d634e3`, full cross-feature regression 340/4 (the 4 are the carried off-lane
flakes), and the attempt-1 blocker (bs-17 AC-14) is RESOLVED (`design_system_test` 27/0).
- **Human decision:** `/feature-next-phase --signoff bs19 approved | changes "<items>"`. The standing
  reviewer call is §9 — accept shipping the real camera **wired-but-dormant** (D-2/D-5; software scene opens,
  plugin activates on-device), or request production auto-select wiring as a follow-up. §10E is the on-device
  walkthrough of the real plugin (not automatable under `flutter-tester`).
- **Approved →** feature `Status: Done`; then merge `feat/bs-19-live-camera-capture` → main (clean-merged-branches).
- **Changes requested →** each item becomes a phase before a fresh SIGNOFF-2.
- **Carried gotchas:** the whole `integration_test/live_camera/` dir **won't launch at once** — run per-file.
  macOS has no `timeout`; run bare. `AppTheme` is now the sole AC-14 file-level exemption
  (`kCaptureDeviceLiteralFiles = {}`).

## Token usage

<!-- One row per session, appended as that session's last edit (SKILL.md § Token usage). -->

| Phase / activity | Session | Start | End | Wall | Active | Model(s) | Input | Cache write | Cache read | Output | Total | Outcome |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PLAN | 9072bbeb | 2026-10-20 20:38 EDT | 22:43 | 2h 04m | 41m 52s | claude-opus-4-8 | 132 | 286,390 | 7,949,040 | 81,245 | 8,316,807 | plan written (spec 10 ACs + master + CAM/VIEW/PERM/ITEST modules, 19 phases); real CameraCaptureSource over camera plugin; shared session after bs-18 signoff |
| CAM-1 | a47f10a5 | 2026-10-21 06:03 EDT | 06:47 | 44m 03s | 13m 23s | claude-opus-4-8 | 92 | 95,473 | 4,554,587 | 37,224 | 4,687,376 | scaffold done; G-1 approved in-session (on main); branch off 11944b6; BS19_RUN_PENDING runner (10 ACs seeded); baseline 1643 pass; coverage gate proven both directions; no product code |
| CAM-2 | 706c419e | 2026-10-21 06:50 EDT | 07:01 | 10m 17s | 10m 17s | claude-opus-4-8 | 80 | 107,291 | 4,095,289 | 33,380 | 4,236,040 | shell done: camera dep + inert CameraCaptureSource + frame_conversion stub + selectCaptureSource factory wired into assembly (still software); 12 unit tests; 1655 pass; 100% cov on 4 touched lib files; app boots on software source unchanged |
| PERM-1 | e0c78d3c | 2026-10-21 07:03 EDT | 07:17 | 14m 15s | 14m 15s | claude-opus-4-8 | 156 | 118,429 | 8,859,213 | 42,134 | 9,019,932 | shell done: CameraPermission seam + PluginCameraPermission (inert), CaptureSourceKind+kind on interface, CaptureState.cameraPermission, read endpoint activeSourceKind/permissionState, Android CAMERA+uses-feature & iOS NSCameraUsageDescription; +8 unit, 1663 pass, 100% cov 6 touched; app still software by default; fix passes 0/3 |
| VIEW-1 | cb3235a5 | 2026-10-21 07:41 EDT | 07:52 | 11m 03s | 11m 03s | claude-opus-4-8 | 80 | 82,817 | 3,642,896 | 24,170 | 3,749,963 | shell: LiveFrameView frame-render seam; unit+cov 100% (11 touched), 1666 pass; existing capture suites green; placeholder unchanged |
| ITEST-1 | 298d1e40 | 2026-10-21 09:05 EDT | 09:19 | 14m 08s | 14m 08s | claude-opus-4-8 | 104 | 164,685 | 7,423,711 | 50,635 | 7,639,135 | harness + ScriptedCameraSource/RecordingCameraPermission + fixtures + pending gate (all 10 ACs pending) + smoke; 3 test files, no lib touched; smoke 11/11 green default + run-pending; unit 1666; coverage gate PASS (0 touched lib); fix passes 0/3 |
| ITEST-2 | 8202bc18 | 2026-10-21 09:41 EDT | 10:16 | 34m 15s | 34m 15s | claude-opus-4-8 | 180 | 359,870 | 13,602,806 | 98,741 | 14,061,597 | 5 pending AC tests (AC-1..AC-5); red baseline recorded; grade 5xA (AC-2 B->A YUV tolerance, fix 1/3); no lib touched |
| ITEST-3 | 636a10e0 | 2026-10-21 11:13 EDT | 12:29 | 1h 16m | 1h 16m | claude-opus-4-8 | 166 | 366,807 | 16,375,454 | 98,170 | 16,840,597 | 5 pending AC tests (AC-6..AC-10); red baseline AC-6/10 green, AC-7/8/9 red (PERM-2/PERM-3/CAM-7); grade 5xA; unit 1666; coverage PASS no touched lib; fix 1/3 (AC-9 paused-pump hang) |
| ITEST-4 | 94dd8ba1 | 2026-10-21 12:32 EDT | 12:35 | 2m 42s | 2m 42s | claude-opus-4-8 | 34 | 73,170 | 1,327,773 | 10,511 | 1,411,488 | test-review packet assembled (10 pending AC tests, grid 10 A/0 B @ c7d34b0); phase ⏸ awaiting review; G-2 awaiting human decision; no code changed |
| SIGNOFF-DECISION | 94dd8ba1 | 2026-10-21 12:36 EDT | 12:37 | 1m 08s | 1m 08s | claude-opus-4-8 | 20 | 12,542 | 1,181,191 | 5,023 | 1,198,776 | ITEST-4 approved — G-2 tests accepted by Matt Quirk; behavior stage unblocked (next CAM-3) |
| CAM-3 | 12093520 | 2026-10-21 12:41 EDT | 13:00 | 19m 38s | 19m 38s | claude-opus-4-8 | 114 | 237,653 | 7,779,414 | 62,082 | 8,079,263 | behavior done: AC-2 live (A) real CameraImage->Frame conversion + CameraDevice-seam frame stream; PluginCameraDevice coverage-ignored (D-5 device walkthrough); unit 1670, coverage 100% on 2 touched lib files, acceptance AC-2 green default+run-pending, later ACs pending; grade 1xA; fix 1/3 |
| VIEW-2 | 65b7b2d6 | 2026-10-21 13:03 EDT | 13:18 | 14m 54s | 14m 54s | claude-opus-4-8 | 124 | 228,782 | 7,480,031 | 36,018 | 7,744,955 | AC-1 live preview (grade A); currentFrame camera-only seam; smoke guards updated; unit 1672, cov 100% 2 touched, suite green; fix 0/3 |
| CAM-4 | 3c347988 | 2026-10-21 13:38 EDT | 13:47 | 9m 06s | 9m 06s | claude-opus-4-8 | 88 | 187,594 | 4,202,596 | 22,019 | 4,412,297 | AC-3 un-pended (reading follows the live frame); no lib change (source-agnostic sampling, CAM-3 frame stream); unit 1672, coverage PASS (0 touched lib), acceptance AC-3 green default+run-pending, smoke 11/11; grade 3xA/0; fix 0/3 |
| VIEW-3 | 3a0ed481 | 2026-10-21 14:11 EDT | 14:23 | 11m 59s | 11m 59s | claude-opus-4-8 | 80 | 179,522 | 3,676,408 | 20,059 | 3,876,069 | AC-4 un-pended (value-only grayscale over the live frame); no lib change (shell ColorFiltered + VIEW-2 frame flow; augmentation written in ITEST-2); unit 1672, coverage PASS (0 touched lib), acceptance preview 3/3 default + smoke 11/11, VIEW module complete; grade 4A/0; fix 0/3 |
| CAM-5 | 375c6867 | 2026-10-21 14:28 EDT | 14:39 | 11m 02s | 11m 02s | claude-opus-4-8 | 112 | 216,864 | 5,931,841 | 29,692 | 6,178,509 | AC-5 real AE·AWB·AF lock forwarding via CameraDevice seam; AWB implicit w/ AE (no plugin ctrl, D-5); un-pend AC-5; 5×A; unit 1673; cov 100% 1 touched; fix 0/3 |
| CAM-6 | 80228cbc | 2026-10-21 14:44 EDT | 14:58 | 13m 23s | 13m 23s | claude-opus-4-8 | 106 | 222,564 | 5,100,087 | 25,371 | 5,348,128 | AC-6 real device torch forwarding via CameraDevice seam (setFlashMode torch/off); un-pend AC-6; 6×A; unit 1674; cov 100% 1 touched; fix 0/3 |
| CAM-7 | 82fe6d69 | 2026-10-21 15:00 EDT | 15:48 | 47m 55s | 47m 55s | claude-opus-4-8 | 210 | 336,106 | 17,290,790 | 85,413 | 17,712,519 | AC-9 lifecycle release/resume delivered; CAM module complete; 7xA; unit 1680; coverage PASS 2 touched; fix 1/3 |
| PERM-2 | 524c73db | 2026-10-21 16:14 EDT | 16:43 | 29m 12s | 29m 12s | claude-opus-4-8 | 196 | 371,418 | 17,328,340 | 88,930 | 17,788,884 | AC-7 permission request + denial fallback live (grade A); 8 ACs delivered (AC-1..AC-7,AC-9); unit 1684, cov 100% 4 touched, 8 A/0 below; fix 1/3 |
| PERM-3 | 9d0d231d | 2026-10-21 16:54 EDT | 17:11 | 17m 46s | 17m 46s | claude-opus-4-8 | 166 | 268,475 | 10,433,083 | 47,918 | 10,749,642 | AC-8 no-camera fallback live; grade 9A/0; available seam; fix 0/3 |
| PERM-4 | fb59c5de | 2026-10-21 17:18 EDT | 17:29 | 11m 01s | 11m 01s | claude-opus-4-8 | 112 | 188,840 | 4,994,508 | 27,196 | 5,210,656 | AC-10 platform declarations un-pended; 10/10 ACs delivered; grade 10 A/0; coverage gate PASS (0 touched lib); fix 0/3 |
| SIGNOFF-1 | 7d5f31da | 2026-10-21 18:26 EDT | 22:23 | 3h 56m | 40m 27s | claude-opus-4-8 | 286 | 475,210 | 17,604,833 | 76,690 | 18,157,019 | attempt 1 BLOCKED: bs-19 suite 10/10 A, unit 1687/0, cov PASS, feature acceptance green both modes; full cross-feature regression found a bs-17 AC-14 regression (live_frame_view placeholder, proven vs base 11944b6) + 3 carried off-lane flakes; VIEW-4 (theme placeholder, D-8) queued before re-run |
| VIEW-4 | 04e94f77 | 2026-10-21 22:55 EDT | 23:24 | 28m 50s | 14m 40s | claude-opus-4-8 | 80 | 92,832 | 3,657,304 | 34,948 | 3,785,164 | themed live-view placeholder (D-8); retired D-4 exemption; resolved bs-17 AC-14; unit 1687/0, cov PASS, bs-19 green both modes, AC-14 27/27; grade A; fix 1/3 |
| SIGNOFF-1 | afe10333 | 2026-10-21 23:28 EDT | 23:54 | 26m 36s | 26m 36s | claude-opus-4-8 | 108 | 235,249 | 5,763,723 | 44,113 | 6,043,193 | re-run: clean full verification; packet awaiting human sign-off (10 A/0, unit 1687/0, cov PASS, regression 340/4 carried flakes, AC-14 resolved); scorecard published |
| **Feature total** |  | **2026-10-20 20:38 EDT** | **2026-10-21 23:54** | **13h 29m** | **8h 06m** |  | **2,826** | **4,908,583** | **180,254,918** | **1,081,682** | **186,248,009** |  |

## Sign-off

| Round | Packet | At code | Grades | Decision |
|---|---|---|---|---|
| 1 | [signoff/round-1.md](signoff/round-1.md) | `1d634e3` | bs-19 10 A/0 | ⏸ Awaiting sign-off 2026-10-21 — clean re-run after VIEW-4 (AC-14 regression resolved; regression 340/4 = carried flakes only). Scorecard https://claude.ai/artifact/4JfXYVUKW6FPoHp3rmJ4Pa. Supersedes attempt 1 (was blocked @ `1d01c9d`) |
