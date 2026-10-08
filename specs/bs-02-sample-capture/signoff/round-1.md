# Sample capture and sampling (bs-02) — sign-off round 1

**Status:** ✅ Approved 2026-10-08 by Matt Quirk · **At code:** `2404763` (`feat/bs-02-sample-capture`) · **Packet built:** 2026-10-07 23:20 EDT · **Flutter:** 3.47.6 (stable)

bs-02 builds the Capture screen on top of bs-01's merged foundation: the live-view eyedropper, point/area-average sampling (incl. from a gallery photo), the AE/AWB/focus lock + stability settling, low-light detection with an honest `approximate` accuracy tier, reference-card calibration that upgrades to `calibrated`, the value-only grayscale preview, and a multi-frame commit that haptically confirms and opens bs-01's Readout. The native camera sits behind the SI `CaptureSource` interface (D-2); this pure-Dart build exercises it through a deterministic `FakeCaptureSource` with known ground-truth scenes, so the accuracy ACs are real numeric ΔE00 checks.

## Verification (primary checkout, commit 2404763)

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **No issues found** |
| Unit + coverage | `flutter test --coverage` | **324 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart main` | **PASS — 100% line on all touched `lib` files** (14 files incl. all of `lib/capture/**`) |
| Cross-feature integration regression | `flutter test integration_test/` | **36 passed, 0 failed, 0 skipped** (bs-01 Readout/harness 17 + bs-02 capture 19) |
| Acceptance (default) | `flutter test integration_test/capture_test.dart` | **19 passed, 0 pending** |
| Acceptance (run-pending) | `… --dart-define=BS02_RUN_PENDING=true` | **19 passed** — identical to default; `pendingACs` is empty |

Machine-readable results (`flutter test --machine`) captured for every suite above; see the summary page.

## Per-AC result

Every AC un-pended and green; test names per the catalogue in [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md) § *Acceptance criteria coverage*.

| AC | Scenario | Test | Result |
|---|---|---|---|
| AC-1 | Centre-point eyedropper on the live view | `TestAC01_Eyedropper` | ✅ PASS |
| AC-2 | Sample under centre = 5 px area average (not the centre pixel) | `TestAC02_AreaAverage5px` | ✅ PASS |
| AC-3 | Radius selector → reticle 8/20/44, averaged over the radius | `TestAC03_RadiusSelector` | ✅ PASS |
| AC-4 | Lock AE/WB/focus → "AE · AWB · AF LOCKED" + "STABLE 12/12" | `TestAC04_LockSettles` | ✅ PASS |
| AC-5 | Before lock: "SETTLING 6/12", lock invites | `TestAC05_SettlingWarns` | ✅ PASS |
| AC-6 | Low light → committed `approximate` (ΔE00 ≤ 8), not refused | `TestAC06_LowLightApproximate` | ✅ PASS |
| AC-7 | Dismiss low-light warning; accuracy stays `approximate` | `TestAC07_DismissWarning` | ✅ PASS |
| AC-8 | Reference card → normalised, upgraded to `calibrated` (ΔE00 ≤ 3) | `TestAC08_CardCalibrates` | ✅ PASS |
| AC-9 | Sample a colour at point P of a gallery photo (P ≠ centre) | `TestAC09_SampleFromPhoto` | ✅ PASS |
| AC-10 | Value-only grayscale preview, control reads "✓ Value" | `TestAC10_ValueOnly` | ✅ PASS |
| AC-11 | Commit = multi-frame mean + haptic + opens Readout for the sample | `TestAC11_CommitOpensReadout` | ✅ PASS |

## Test grades

Fresh **independent** whole-suite re-grade for this sign-off (a separate grader, given the SCREEN-3 grid, graded on the G1–G6 rubric): **19×A, 0×B** — 11 AC tests + 8 harness/scaffold tests. No downgrade from the prior grid; no upgrade needed. Grid: [regrade-round-1.md](regrade-round-1.md). Prior running grid: [../behavior-test-completeness-bs-02-sample-capture.md](../behavior-test-completeness-bs-02-sample-capture.md).

- **Non-A grades accepted:** none (every row A).
- **One documented residual (grade stays A):** `TestAC10_ValueOnly` asserts a `ColorFilter`ed ancestor over the feed + the exact "✓ Value" label, but not the exact saturation-0 matrix — the only available value-check (`ColorFilter.matrix(...)`) would over-fit the Rec.709 luma coefficients and false-reject a valid alternate matrix, and the feed is a flat-grey placeholder today so pixel grayscale is meaningless. Worth tightening once real camera frames render (native-camera work, outside bs-02). Carried, not a defect.

## Augmentations made

- **`TestAC06_LowLightApproximate` (CAPTURE-5):** added the card-vs-card-less control — a `SCENE_CARD` calibrated capture reads `calibrated` (ΔE00 ≤ 3) while the card-less `SCENE_DIM` capture reads `approximate` (ΔE00 ~5, ≤ 8), proving low light *specifically* downgrades the tier rather than a single always-on tier. Closed the pre-seeded *B pending CAPTURE-5* → A. (ITEST augmentation table updated this round; the status cell had been left stale at ⬜ Open.)

## Gates

All resolved — nothing open.

| Gate | Decision |
|---|---|
| G-1 (approve spec) | ✅ Approved 2026-10-06 — Matt Quirk |
| G-2 (bs-01 foundation merged) | ✅ Resolved 2026-10-06 — bs-01 signed off + merged to `main` at c793839 |
| G-3 (approve acceptance tests) | ✅ Approved 2026-10-07 — Matt Quirk |
| G-4 (confirm `givenCaptureOf`→`pumpWidget` render-frame settling) | ✅ Approved 2026-10-07 23:18 EDT — Matt Quirk |
| G-5 (confirm read endpoint `skipOffstage: false` after commit navigates) | ✅ Approved 2026-10-07 23:18 EDT — Matt Quirk |
| SCREEN-2 `whenSelectRadius` per-option-anchor retarget (no gate id) | ✅ Confirmed 2026-10-07 23:18 EDT — Matt Quirk |

- **Closed by user acceptance (with a gap):** none — every AC closed by a passing gate.
- **Open known flakes:** none recorded.

## Known gaps / deferred

- **Native `CaptureSource` implementations (CameraX / AVFoundation) are platform work** outside this pure-Dart build (D-2). The feature is exercised through `FakeCaptureSource`; on-device camera capture, real AE/AWB/focus lock, wide-gamut handling and real-frame grayscale are validated on device separately. There is no runnable on-device demo in this build — a reviewer observes behaviour through the integration suite driving the assembled app (below).
- **AC-10 value-only** asserts the filter structurally (see *Test grades* residual) — tighten to the saturation-0 matrix once real frames render.
- **Cosmetic:** `integration_test/fakes/fake_haptics.dart` and `fake_speech.dart` doc comments still cite bs-01's `AC-12`/`AC-8` (copy-over text); comment-only, no behaviour or grade impact. Left untouched to keep this sign-off session free of unrelated bs-01-fake edits.

## Token usage and cost

Feature total **207,567,264 tokens** across 22 sessions — input 2,712 · cache write 4,719,219 · cache read 201,419,091 · output 1,426,242. Time **7h 41m active (11h 34m wall)**, 2026-10-05 15:54 EDT → 2026-10-07 23:20 EDT. Cost at API list rates (2026-09-25): **$178.80**.

By stage (fully-loaded): PLAN/activities $15.32 · scaffold $2.28 · shells $16.10 · acceptance-tests $28.70 · test-review $2.78 · behavior (direct) $107.47 · sign-off $6.16. Full breakdown + per-AC: [cost-per-ac-round-1.md](cost-per-ac-round-1.md). (Lines-of-code attribution omitted — `feature_loc.py` is not installed in this environment.)

## Summary page

[bs-02 Sample Capture — sign-off round 1](https://claude.ai/artifact/BQ6Ng52riEJYxq2AqNGLaL) (private artifact; owner Matt Quirk). Verification gates, per-AC results + grades, resolved gates, and cost by stage. Headline pass count (acceptance 19 / unit 324 / integration 36) matches this run.

## Manual walkthrough

How a reviewer sees each Rule of the spec working. No native camera in this build, so the surface is the assembled app driven by the `integration_test` suite over `FakeCaptureSource`; the commands reproduce each behaviour. Run-pending and default are identical (nothing pending).

Reproduce everything: `flutter test integration_test/capture_test.dart` (from `/Users/matthew.quirk/Nuance`, with `~/development/flutter/bin` on PATH).

1. **Live view + eyedropper (AC-1).** Open Capture on `SCENE_OLIVE`: the live-view region renders a frame and a centre-point eyedropper marker sits at the view centre (asserted on both axes, not mere presence).
2. **Sampling + radius (AC-2, AC-3).** On `SCENE_CENTRE_VARIED` (centre pixel ≠ 5 px mean ≠ 21 px mean) the default 5 px area-average is sampled — not the centre pixel. Selecting each radius resizes the reticle to exactly 8/20/44 px and re-samples the average over that radius (each radius gives a distinct colour here).
3. **Lock & settle (AC-4, AC-5).** Before locking, the indicator reads "SETTLING 6/12" and the lock control invites locking; locking AE/WB/focus drives "AE · AWB · AF LOCKED" and "STABLE 12/12" (exact strings).
4. **Low light (AC-6, AC-7).** On `SCENE_DIM` with no card, committing shows a low-light warning and commits a sample labelled `approximate` whose colour is within ΔE00 8 of ground truth (and > ΔE00 3, so the downgrade is real — the `SCENE_CARD` control reads `calibrated`). Dismissing the warning hides it and leaves the accuracy `approximate` (unchanged).
5. **Reference card (AC-8).** On `SCENE_CARD`, calibrating against the card normalises the next capture to within ΔE00 3 of ground truth and upgrades the label to `calibrated` (the `_cardRaw` ΔE ≈ 4.6 proves the calibration isn't a no-op).
6. **Photo (AC-9).** Importing `PHOTO_SWATCH` and sampling point P (P ≠ image centre) reads P's known colour from the photo — not the live camera, not the centre.
7. **Value-only (AC-10).** Toggling value-only renders the feed through a `ColorFilter`ed ancestor (grayscale) and the control reads "✓ Value"; readings outside the feed stay colour.
8. **Capture (AC-11).** On `SCENE_MULTIFRAME` at "STABLE 12/12", capturing averages several frames (committed colour = the multi-frame mean, not any single frame), fires exactly one `FakeHaptics` confirm pulse, and navigates to bs-01's Readout showing "Deep Olive Green".

## Decision

✅ **Approved** — 2026-10-08 03:58 EDT by **Matt Quirk**, at code `2404763`. Feature bs-02 Sample Capture is signed off and complete: all 11 ACs green, whole-suite 19×A/0×B, all gates resolved.
