# Behaviour-test completeness grid — bs-02-sample-capture

Per-AC grade grid for the bs-02 acceptance suite (`integration_test/capture_test.dart`). Each AC-test phase
grades the tests it wrote; each behaviour phase re-grades every un-pended test. Grades the assertions as
written — the behaviour each pending test will exercise once its owning phase lands — except for ACs that run
live (un-pended), which are graded against the live behaviour.

## Grade — ITEST-2 (AC-1, AC-2, AC-3, AC-9, AC-10)

Graded by an independent fresh grader (did not write these tests) on 2026-10-07. Grades the assertions **as
written** — i.e. the behaviour each test will exercise once its owning phase lands (AC-2/SOURCE-2,
AC-3/SCREEN-2+SOURCE-2, AC-9/SOURCE-3, AC-10/SCREEN-3), not the red baseline — except **AC-1**, which runs live
now against the SCREEN-1 shell and is graded live.

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-1 | `TestAC01_Eyedropper` | A | G1,G3,G4,G5,G6 | Given checked through the real UI (`AppBar 'Capture'` + `liveViewKey` both `findsOneWidget`). Asserts the raw observable the step names: not mere presence but `getCenter(reticleKey)` vs `getCenter(liveViewKey)` on both axes, epsilon 0.5. Sound because the live-view `Stack` lays the `liveViewKey` `ColoredBox` as `StackFit.expand` (centre = stack centre) and the reticle inside a `Center` (centre = stack centre), so a correct impl matches to 0px and 0.5 is tight enough to kill an off-centre marker. **Kills:** absent eyedropper (findsOneWidget fails) and an off-centre reticle, e.g. a top-left or Positioned marker (centre delta ≫ 0.5). One AC, no negative-Then settle needed (pure structural read after `pumpAndSettle`). |
| AC-2 | `TestAC02_AreaAverage5px` | A | G1,G2,G4,G5,G6 | Given answered by the **configured** input, read through the public endpoint (`harness.state.radiusPx == 5`), not a fake override — G2 holds. Asserts the raw sampled colour rendered back via the real `ColorScienceImpl.toSRGB` (same conversion the fixtures were built with, so the 8-bit round-trip is tight). Three-way relative-distance Then genuinely bites: `SCENE_CENTRE_VARIED` centre = Lab(55,62,45) vivid red, disc = Lab(50,−22,−6) teal, outer = Lab(72,2,66) yellow — pairwise L1 sRGB gaps are in the ~200+ range, far above `_sampleToleranceL1 = 45`. The 5px disc (r≤8 in the fixture) contains exactly **one** red distractor among ~81 pixels, so the correct average's pull off pure teal is ≈1/81 of the red–teal gap (a few L1) — comfortably under 45, and 45 is nowhere near tight enough to break the correct impl. **Kills:** single-pixel/point read (`toCentre` ≈200 ≫ `toDisc`), and a wrong/wider radius that pulls toward yellow (`toOuter` ≈280 ≫ `toDisc`). Red baseline is clean: `currentSample` null → `isNotNull` fails, no panic. One AC. |
| AC-3 | `TestAC03_RadiusSelector` | A | G1,G4,G5,G6 (G2 note) | Given checked via UI (`liveViewKey`). Faithful one-loop Scenario-Outline over `{1:8, 5:20, 21:44}`, ordered smallest-first so the first iteration (radius 1 → reticle 8) diverges most from the shell's 20px placeholder and the baseline reds on the Then, not a missing control. Asserts **both** halves of the step at grain: exact reticle `getSize` width+height == 8/20/44 (epsilon 0.5, square), **and** radius-driven averaging — the three sampled colours are pairwise distinct (`>0`, safe: s1's ≈1/5 red pull vs s5's ≈1/81 differ by ~47 L1, well above quantization), with s1 nearer the centre distractor than s5 (r≤1 disc = 1 red + 4 teal) and s21 nearer the outer band than s5 (r≤21 is mostly yellow; the 64×64 frame fits a 21px disc). **Kills:** reticle size unchanged (placeholder stays 20 → fails for radii 1 and 21) and an average that ignores the selected radius (all three equal → the distinctness and the directional-pull inequalities fail). **Judgement call (not a defect):** the frozen `whenSelectRadius(px)` currently taps the single E18 placeholder regardless of `px`; correctness depends on SCREEN-2 retargeting it to per-option 1/5/21 anchors — explicitly carried in the ITEST-1 handoff and the helper doc. Assertions as written are correct against the intended behaviour, so A. |
| AC-9 | `TestAC09_SampleFromPhoto` | A | G1,G2,G4,G5,G6 | Given checked: P ≠ image-centre asserted on the fixture itself (`atP` magenta Lab(55,50,−10) vs `atCentre` neutral-grey Lab(50,0,0) — P=(12,12) is inside the r=6 swatch, centre (24,24) is ~17px away in background). Two independent discriminators against the one raw observable: `toP < toCentre` (magenta vs grey, L1 ~120 ≫ 45) and `toP < toColor(sampled, liveCamera)` where the host scene is olive Lab(40,−8,24) (magenta vs olive, large L1). `toP < 45` holds because r≤5 around P is entirely swatch → average = magenta, tight round-trip. **Kills:** sampling the image centre (grey) and sampling the olive live camera instead of the imported photo — the two wrong impls the catalogue names. The olive host scene is the load-bearing choice that makes the camera-vs-photo rejection bite. Red baseline clean (`isNotNull`). One AC. |
| AC-10 | `TestAC10_ValueOnly` | A | G1,G3,G4,G5,G6 | Given fully checked on the public surface: `state.valueOnly == false`, the E21 control reads exactly `'Value'` (shell text; `find.text` is exact-match so it will not spuriously match `'✓ Value'`), and **no** `ColorFiltered` ancestor over `liveViewKey` (the paired control proving the reading can change — G3). After a settle point (`whenToggleValueOnly` ends in `pumpAndSettle`), the negative→positive Then asserts `state.valueOnly == true`, a `ColorFiltered` **ancestor of the feed** (`findsWidgets`) and the label flips to exactly `'✓ Value'`. **Kills:** feed stays colour (no ColorFiltered over liveView → fails), label unchanged (`'✓ Value'` findsNothing → fails), and greyscaling only an unrelated widget (the filter must be an **ancestor of `liveViewKey`**, so a ColorFiltered elsewhere does not satisfy it). The `tester.takeException()` is **sound**: E21 is wired to the throwing `controller.toggleValueOnly`, so the baseline red is the deferred `UnimplementedError` consumed here while the real red stays on the Then; `anyOf(isNull, isA<UnimplementedError>())` is bounded — any other exception type still fails the test, and post-SCREEN-3 it is a harmless no-op. Minor residual masking risk only if a *stray* `UnimplementedError` survived post-SCREEN-3, which the owning phase removes. One AC. |

### Summary — ITEST-2 (AC-1, AC-2, AC-3, AC-9, AC-10)

- **Grade counts: 5×A, 0×B.** No B rows — every test checks its Givens through the public surface before the
  When, asserts the raw observable the spec step names at its stated grain (exact reticle sizes, exact label
  strings, centre position, sampled-colour distances), and each kills ≥1 concrete wrong implementation from
  the catalogue's *Rejects* with the fixture data genuinely able to separate right from wrong.
- **Fixture-discrimination confirmation:** `SCENE_CENTRE_VARIED`'s three regions (vivid red / teal / yellow)
  and `PHOTO_SWATCH`'s magenta-P / grey-centre / olive-camera are separated by L1 sRGB gaps in the ~120–280
  range — an order of magnitude above `_sampleToleranceL1 = 45` — so the reject-inequalities are not vacuous;
  45 is simultaneously loose enough for the correct impl (≈1/81 single-distractor pull + ≤ a couple L1 of
  8-bit round-trip, fixtures and comparisons sharing the identical `ColorScienceImpl`).
- **Judgement calls (none downgrade to B):**
  1. **AC-3 `whenSelectRadius`** taps the single E18 placeholder for every radius; correctness depends on
     SCREEN-2 retargeting that helper to per-option 1/5/21 anchors (carried in the ITEST-1 handoff + helper
     doc). Flagged to the SCREEN-2 owner: if SCREEN-2 lands the selector but leaves the helper tapping one
     key, AC-3's directional-pull Thens would exercise only whichever radius the placeholder maps to.
  2. **AC-10 `takeException`** is bounded (only `UnimplementedError`/`null` passes) so it cannot mask a real
     exception of another type; the only theoretical masking is a stray `UnimplementedError` after SCREEN-3,
     which that phase removes.
- All five are ready for the G-3 packet at grade A.

## Grade — ITEST-3 (AC-4, AC-5, AC-6, AC-7, AC-8, AC-11)

Graded by an independent fresh grader (did not write these tests) on 2026-10-07, then re-graded after the
AC-8 fixture fix. Grades the assertions **as written** — the behaviour each test will exercise once its owning
phase lands (AC-4/5 → CAPTURE-3, AC-6/7 → CAPTURE-4, AC-8 → CAPTURE-5, AC-11 → CAPTURE-6). All six are pending
(red at baseline).

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-4 | `TestAC04_LockSettles` | A | G1,G4,G5,G6 (G3 n/a) | Given `lockState==auto` via endpoint; the "SETTLING 6/12" precondition depends on unbuilt behaviour and is an explicit `find.text` naming CAPTURE-3 (G1). When taps real E16 (`whenLock`); deferred `UnimplementedError` consumed + bounded. Thens assert the spec's exact strings "AE · AWB · AF LOCKED" + "STABLE 12/12" plus `lockState==locked` at grain (G4). **Kills** the catalogue's three Rejects: unchanged indicator, never-settles, partial lock (full-lock string + `locked` enum). Baseline reds on the precondition, no panic. |
| AC-5 | `TestAC05_SettlingWarns` | A | G1,G3,G4,G5,G6 | Given `lockState==auto`. Pumps to "SETTLING 6/12" (no lock tap → no deferred throw). Textbook G3: negatives (`isStable==false`, "STABLE 12/12" findsNothing) after a settle point, paired with the counter 0→6 proving the reading is live. `lockButton.enabled==true` (correct `TextButton` cast) proves the affordance. **Kills** STABLE-while-unlocked and a missing/disabled lock control. |
| AC-6 | `TestAC06_LowLightApproximate` | **B pending CAPTURE-5** | G1,G2,G4,G6; G5 limited | Givens `lighting==low` + no card answered by the configured SCENE_DIM via `harness.source` (G2). Robustly kills refusal-in-dim (`lastCommittedSample isNotNull`) and no-warning (`warningKey` + flag); SCENE_DIM now reads ΔE00 ~5.1 off truth so "within ΔE00 8" is non-vacuous. But `accuracy==approximate` is the controller default — with only one reachable tier the test can't prove low light *specifically* downgrades; needs CAPTURE-5's calibrated-vs-approximate control (augmentation). A once that lands. |
| AC-7 | `TestAC07_DismissWarning` | A | G1,G3,G4,G5,G6 | Given built through the real commit flow on SCENE_DIM; warning-present precondition asserted explicitly naming CAPTURE-4; accuracy captured as approximate before the dismiss. Textbook G3: warning present → `whenDismissWarning` (settle) → `warningKey` findsNothing + flag false, on a demonstrably-changed reading. Accuracy invariance before **and** after kills *dismiss clears/upgrades the accuracy* (fully testable now). Also kills *warning reappears*. |
| AC-8 | `TestAC08_CardCalibrates` | A | G1,G2,G4,G5,G6 | SCENE_CARD now replays a uniform `_cardRaw` frame ΔE00 4.56 off ground truth (outside calibrated's 3, inside approximate's 8). A relabel-only calibration commits `_cardRaw`, so `_deltaE00(committed, groundTruth) ≈ 4.56 > 3` → the `<= 3` Then **fails it**, genuinely rejecting the catalogue's "calibration no-ops (colour unchanged)" Reject; the 1.56 ΔE margin above the bound is well clear of 8-bit round-trip noise (<1 ΔE). Accuracy-upgrade Reject stays killed (live "Calibrated" label + committed `accuracy==calibrated`). Both named Rejects bite (G5). One AC. |
| AC-11 | `TestAC11_CommitOpensReadout` | A | G1,G4,G5,G6 (G3 n/a) | Givens `haptics==0` + "STABLE 12/12" precondition naming CAPTURE-3 (reached via real `whenLock`). Asserts at grain: `framesAveraged>1` (kills single-frame by count on noisy SCENE_MULTIFRAME), mean within ΔE00 8, **exactly** `confirmations==1` (kills no-haptic + double-pulse), AppBar "Readout" + `NameHeader` descendant "Deep Olive Green" (kills nav-without-sample / wrong name). |

### Summary — ITEST-3 (AC-4, AC-5, AC-6, AC-7, AC-8, AC-11)

- **Grade counts: 5×A, 1×B** (AC-6 **B pending CAPTURE-5** — matches the planner's pre-seeded augmentation; A
  once the calibrated-vs-approximate control lands). No remaining must-fix defects.
- **Fixture fix applied this phase (fix pass 1/3):** AC-8's `ΔE00 ≤ 3` Then was initially vacuous because
  `SCENE_CARD` read at ground truth (a relabel-only calibrate would have passed). Hardened `SCENE_CARD`
  (raw ΔE00 4.56) and `SCENE_DIM` (raw ΔE00 5.07) to carry genuine raw errors, with a never-pending soundness
  guard (sRGB L1 36 / 42). AC-8 re-graded B → **A**; AC-6/AC-7 unaffected (AC-6 stays B-pending).
- **`_deltaE00` is genuine CIEDE2000** (Sharma vectors 2.0425 / 2.8615 / 0 reproduce exactly), bounds tied to
  the production `CaptureAccuracy.maxDeltaE` enum (8 / 3), not literals.
- **Carried hazards (do not affect grades):** AC-11 navigation — keep the `CaptureReadEndpoint` reachable
  across the Readout push (CAPTURE-6) or `harness.state` throws (false-negative only); AC-4/AC-5 settling
  cadence — CAPTURE-3 must advance the counter one countable step per pumped frame so 6/12 is hit exactly;
  `takeException()` consumes are bounded so they cannot mask a real failure.
- Whole-suite grid is now **10×A + AC-6 B-pending-CAPTURE-5** — ready for the ITEST-4 G-3 packet.

## Re-grade — SOURCE-2 (un-pended: AC-1, AC-2)

SOURCE-2 landed the live feed + 5 px area-average sampling behind AC-2 and un-pended it. Per the grade gate a
behaviour phase re-grades **every un-pended AC test** against the **live** behaviour. Graded by an independent
fresh grader (did not write these tests) on 2026-10-07; confirmed by a live run
(`flutter test integration_test/capture_test.dart` → all passed, +10 / ~9 skipped; AC-1 and AC-2 executed live).

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-1 | `TestAC01_Eyedropper` | A | G1,G4,G5,G6 (G2/G3 n/a) | Unchanged from ITEST-2: Given checked through the real UI; asserts reticle centre vs feed centre on both axes at epsilon 0.5 (not mere presence). Live `CaptureLiveView` lays the feed as `StackFit.expand` and the reticle in a `Center`, so the correct render matches to ~0 px and 0.5 kills an absent/off-centre marker. One AC. |
| AC-2 | `TestAC02_AreaAverage5px` | A | G1,G2,G4,G5,G6 (G3 n/a) | Now **live**: `_onFrame` calls the real `sampleAreaAverage(frame, centre, radiusPx:5)` — a true sRGB disc average → `color_models` CIELAB — rendered back through the same `ColorScienceImpl.toSRGB` the fixtures use, so the round-trip is tight. The r≤5 disc holds ~80 teal pixels + one red centre speck, so the average sits ≈1/81 off pure teal (a few L1, far under `_sampleToleranceL1 = 45`); `toCentre` (~200 L1) and `toOuter` (~280 L1) are an order of magnitude larger. **Kills** a point read (`toDisc < toCentre`) and a wider radius (`toDisc < toOuter`). Correct impl passes with margin. Matches the prior "as written" A — no downgrade. One AC. |

### Summary — SOURCE-2

- **Grade counts (re-grade): 2×A, 0×B.** No downgrades against the "as-written" grades; AC-2 holds A now that
  the real true-average sampler drives the three-way distance Then.
- **Whole-suite grid unchanged: 10×A + AC-6 B-pending-CAPTURE-5** (AC-6 owned by CAPTURE-5; untouched here).

## Re-grade — SOURCE-3 (un-pended: AC-1, AC-2, AC-9)

SOURCE-3 landed AC-9 (import a gallery photo and sample its point P, switching the reading off the live feed)
and un-pended it. Per the grade gate a behaviour phase re-grades **every un-pended AC test** against the
**live** behaviour. Graded by an independent fresh grader (did not write these tests) on 2026-10-07; confirmed
by a live run (`flutter test integration_test/capture_test.dart` → all passed, +11 / ~8 skipped; AC-1, AC-2,
AC-9 executed live).

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-1 | `TestAC01_Eyedropper` | A | G1,G4,G5,G6 (G2/G3 n/a) | Unchanged from the SOURCE-2 re-grade: Given checked through the real UI; asserts reticle centre vs feed centre on both axes at epsilon 0.5 (not mere presence). Live `CaptureLiveView` lays the feed as `StackFit.expand` and the reticle in a `Center`, so the correct render matches to ~0 px and 0.5 kills an absent/off-centre marker. One AC. |
| AC-2 | `TestAC02_AreaAverage5px` | A | G1,G2,G4,G5,G6 (G3 n/a) | Unchanged live grade: configured radius read through the endpoint (G2); the real `sampleAreaAverage` drives the three-way distance Then on `SCENE_CENTRE_VARIED` (red/teal/yellow, pairwise L1 ~200–280 ≫ `_sampleToleranceL1 = 45`). Kills a point read and a wider radius. One AC. |
| AC-9 | `TestAC09_SampleFromPhoto` | A | G1,G2,G4,G5,G6 (G3 n/a) | Now **live**: `whenImportPhoto` stages the fixture and taps E19 (wired to `controller.importPhoto`), whose real `importPhoto()` reads `source.importedPhoto` and calls the real `sampleFromPhoto(image, P=(12,12), radiusPx:5)`; observed through `currentSample`, rendered back via the same `ColorScienceImpl.toSRGB`. Given checked on the fixture before the When (`atP != atCentre`): P is the centre of the r=6 magenta swatch Lab(55,50,−10); the image centre (24,24) is ~17 px away in neutral-grey Lab(50,0,0). Two discriminators against the one raw observable bite with margin: `toP < 45` (r≤5 disc around P is entirely swatch → magenta), `toP < toCentre` (magenta vs grey, L1 ~120 ≫ 45 → rejects the image centre) and `toP < distToColor(sampled, liveCamera)` where the host SCENE_OLIVE is Lab(40,−8,24) (→ rejects the live camera). The olive host scene is load-bearing for the camera-vs-photo rejection. The fake's `stagedPhoto`→`importedPhoto` bridge surfaces only the image + P; the sampled colour comes from the real `sampleFromPhoto` reading fixture pixels, so G2 holds (no faked sample value). One AC. |

### Summary — SOURCE-3

- **Grade counts (re-grade): 3×A, 0×B.** No downgrades; AC-9 holds the A it carried as-written in the ITEST-2
  grid, now re-confirmed against live SOURCE-3 code and a passing live run.
- **Whole-suite grid unchanged: 10×A + AC-6 B-pending-CAPTURE-5** (AC-6 owned by CAPTURE-5; untouched here).
- **Non-downgrading observation (grader):** AC-9's `_photoImported` feed-switch guard is *not* strictly
  exercised by `TestAC09_SampleFromPhoto` — `source.frames` is a finite 12-frame `Stream.fromIterable` fully
  drained by `givenCaptureOf`'s `pumpAndSettle`, so no live frame remains to overwrite the sample after E19.
  The guard is unit-tested instead (`capture_controller_test.dart`: a controllable source delivers a distinct
  frame after import and the imported sample is unchanged, with a control showing the feed *can* change before
  import). The AC test stays non-vacuous (the two named wrong impls still fail its Thens). *(Superseded by the
  CAPTURE-3 re-grade below: once `givenCaptureOf` stops at `pumpWidget`, the feed is no longer pre-drained at
  open, so live frames now arrive during `whenImportPhoto`'s local `pumpAndSettle` and the guard IS exercised
  by the AC test.)*

## Re-grade — CAPTURE-3 (un-pended: AC-4, AC-5; live re-grade of AC-1, AC-2, AC-9)

CAPTURE-3 landed the lock lifecycle + frame-driven stability settling behind AC-4 and AC-5 and un-pended them.
Per the grade gate a behaviour phase re-grades **every un-pended AC test** against the **live** behaviour — so
the five currently un-pended tests (AC-1, AC-2, AC-4, AC-5, AC-9) are graded here; AC-3, AC-6, AC-7, AC-8,
AC-10, AC-11 remain pending and their prior rows are untouched. Graded by an independent fresh grader (did not
write these tests) on 2026-10-07.

**Harness change weighed this phase:** CAPTURE-3 changed the shared `givenCaptureOf` to end at `pumpWidget`
instead of `pumpAndSettle`, because the settling counter now advances one step per rendered frame (via
`_scheduleSettleTick`'s post-frame callback) and `pumpAndSettle` would run it straight to STABLE. Re-examined
AC-1/AC-2/AC-9 for silent weakening: **none weakened.** AC-1 is a pure structural layout read (independent of
settling); AC-2 reads a deterministic single-frame disc average (`currentSample` is populated after the first
frame — the smoke test pins this); AC-9's `whenImportPhoto` runs its **own** `pumpAndSettle` and the
`_photoImported` guard holds. If anything AC-9 is *strengthened*: because the feed is no longer pre-drained at
open, live frames now arrive during the post-import `pumpAndSettle`, so the camera-vs-photo rejection genuinely
bites against the guard rather than against an already-exhausted stream.

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-1 | `TestAC01_Eyedropper` | A | G1,G4,G5,G6 (G2/G3 n/a) | Unchanged under `pumpWidget`: a structural read with no dependency on settling. Given checked through the real UI (`AppBar 'Capture'` + `liveViewKey`); asserts reticle centre vs feed centre on both axes at epsilon 0.5 (not mere presence). Live `CaptureLiveView` lays the feed `StackFit.expand` and the reticle in a `Center`, so the correct render matches to ~0 px and 0.5 kills an absent/off-centre marker. One AC. |
| AC-2 | `TestAC02_AreaAverage5px` | A | G1,G2,G4,G5,G6 (G3 n/a) | Unchanged live grade; not weakened by `pumpWidget`. `SCENE_CENTRE_VARIED` is a single static frame, so the real `sampleAreaAverage(..., radiusPx:5)` disc average is deterministic and `currentSample` is set after frame one. Configured radius read through the endpoint (G2). Three-way distance Then on red/teal/yellow (pairwise L1 ~200–280 ≫ `_sampleToleranceL1 = 45`) kills a point read (`toDisc < toCentre`) and a wider radius (`toDisc < toOuter`). One AC. |
| AC-4 | `TestAC04_LockSettles` | A | G1,G4,G5,G6 (G3 n/a) | **Now live.** Given `lockState==auto` via endpoint, then `_pumpUntilText` climbs the real frame-driven counter to an explicit `find.text('SETTLING 6/12')` (G1 — checked through the rendered UI, no lock tapped yet so no deferred throw). When taps real E16 (`whenLock` → `controller.lock`); `takeException` consume is bounded (only `UnimplementedError`/null, now a harmless no-op post-CAPTURE-3). Thens assert the spec's exact strings "AE · AWB · AF LOCKED" + "STABLE 12/12" plus `lockState==locked` and `stabilityText=='STABLE 12/12'` at grain (G4 — the raw indicator/stability text the step names). **Kills** the three catalogue Rejects: unchanged indicator (would read "… AUTO"), never-settles (would stay "SETTLING n/12"), partial lock (full `locked` enum + full-lock string). One AC. |
| AC-5 | `TestAC05_SettlingWarns` | A | G1,G3,G4,G5,G6 | **Now live.** Given `lockState==auto` via endpoint. `_pumpUntilText` advances the real counter 0→6 (no lock tap → no deferred throw). Textbook G3: the negatives (`isStable==false`, `find.text('STABLE 12/12')` findsNothing) are asserted at a settle point (still `auto` at 6/12, re-asserted) and paired with the control proving the reading is live (the counter demonstrably advanced from 0 to 6) — and AC-4 proves a locked reading WOULD show STABLE, so the negative is not vacuous. `lockButton.enabled==true` on the correct `TextButton` cast (verified: `lockKey` is a `TextButton` with non-null `onPressed: controller.lock`) proves the affordance invites locking. **Kills** STABLE-while-unlocked and a missing/disabled lock control. One AC. |
| AC-9 | `TestAC09_SampleFromPhoto` | A | G1,G2,G4,G5,G6 (G3 n/a) | Live grade holds and is now **strengthened** by the `pumpWidget` change. Given checked on the fixture before the When (`atP != atCentre`). `whenImportPhoto` stages the fixture and taps E19 → real `controller.importPhoto` sets `_photoImported` and `sampleFromPhoto(image, P=(12,12), radiusPx:5)`; the subsequent local `pumpAndSettle` now delivers the still-undrained live frames, which `_onFrame` ignores because `_photoImported` is set — so the feed-switch guard is exercised by the AC test itself (previously only unit-tested). Two discriminators against the one raw observable bite with margin: `toP < 45` (r≤5 around P is all magenta swatch), `toP < toCentre` (magenta vs neutral-grey, L1 ~120 ≫ 45 → rejects the image centre) and `toP < distToColor(sampled, liveCamera)` (vs olive host SCENE_OLIVE → rejects reading the camera). No faked sample value (G2). One AC. |

### Summary — CAPTURE-3

- **Grade counts (re-grade): 5×A, 0×B** across the un-pended set (AC-1, AC-2, AC-4, AC-5, AC-9). AC-4 and AC-5
  move from their as-written ITEST-3 A to a **live A** against CAPTURE-3's lock/settle code; AC-1/AC-2/AC-9
  hold their prior live A with no downgrade.
- **Harness `pumpWidget` change does not weaken any un-pended test.** AC-1 (structural), AC-2 (deterministic
  single-frame average) are unaffected; AC-9 is strengthened (the `_photoImported` feed-switch guard is now
  exercised by the AC test, not just the controller unit test).
- **Still-pending rows untouched:** AC-3 (SCREEN-2), AC-6 (CAPTURE-5 / B-pending), AC-7, AC-8, AC-10, AC-11
  keep their prior grid rows.
- **Whole-suite grid: 10×A + AC-6 B-pending-CAPTURE-5** (unchanged; AC-6 owned by CAPTURE-5).

## Re-grade — CAPTURE-4 (un-pended: AC-1, AC-2, AC-4, AC-5, AC-6, AC-7, AC-9)

CAPTURE-4 implemented two controller methods only — `CaptureController.commit()` (reads `_state.currentSample`,
emits `lastCommittedSample` stamped with `_state.accuracy`, and sets `lowLightWarning: source.lighting ==
Lighting.low` — downgraded-never-refused per D-3) and `CaptureController.dismissWarning()`
(`emit(copyWith(lowLightWarning: false))` only) — and un-pended AC-6 and AC-7. It did **not** touch the harness,
`givenCaptureOf`, the frame-driven settling model, `CaptureLiveView`, `CaptureControls`,
`sampleAreaAverage`/`sampleFromPhoto`, `lock()`, or the source, so no previously-un-pended test (AC-1/2/4/5/9)
can be silently weakened — each was re-examined and holds its prior live A. Verified against live code on
2026-10-07 by an independent fresh grader (did not write these tests); the smoke test pins `currentSample
isNotNull` after the single `pumpWidget`, so `commit()` has a reading to commit at tap time.

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-1 | `TestAC01_Eyedropper` | A | G1,G4,G5,G6 (G2/G3 n/a) | Carried forward from CAPTURE-3 live A; untouched by CAPTURE-4 (pure structural layout read). Given checked through the real UI (`AppBar 'Capture'` + `liveViewKey`); asserts reticle centre vs feed centre on both axes at epsilon 0.5. Live `CaptureLiveView` lays the feed `StackFit.expand` and the reticle in a `Center`, so a correct render matches to ~0 px and 0.5 kills an absent/off-centre marker. |
| AC-2 | `TestAC02_AreaAverage5px` | A | G1,G2,G4,G5,G6 (G3 n/a) | Carried forward live A; untouched. Configured radius read through the endpoint (`state.radiusPx==5`, G2). Real `sampleAreaAverage(..., radiusPx:5)` drives the three-way distance Then on `SCENE_CENTRE_VARIED` (pairwise L1 ~200–280 ≫ `_sampleToleranceL1 = 45`); kills a point read and a wider radius. |
| AC-4 | `TestAC04_LockSettles` | A | G1,G4,G5,G6 (G3 n/a) | Carried forward live A; lock/settle unchanged. Given `lockState==auto`; `_pumpUntilText` climbs the real frame counter to `find.text('SETTLING 6/12')` (G1). Taps real E16; `takeException` bounded (now a no-op). Thens assert exact "AE · AWB · AF LOCKED" + "STABLE 12/12" + `lockState==locked` at grain (G4). Kills unchanged-indicator / never-settles / partial-lock. |
| AC-5 | `TestAC05_SettlingWarns` | A | G1,G3,G4,G5,G6 | Carried forward live A; unaffected. Given `lockState==auto`; counter advances 0→6 (no lock tap). Textbook G3: negatives (`isStable==false`, "STABLE 12/12" findsNothing) at a settle point, paired with the counter climbing 0→6; `lockButton.enabled==true` proves the affordance. Kills STABLE-while-unlocked and a missing/disabled control. |
| AC-6 | `TestAC06_LowLightApproximate` | **B pending CAPTURE-5** | G1,G2,G4,G6; G5 limited | **Now live, grade unchanged.** Givens `lighting==low` + no card via `harness.source` (G2). Live `commit()` lands `lastCommittedSample` (kills refusal-in-dim), raises `lowLightWarning` + renders `warningKey` (kills no-warning), and the committed colour (`_dimRaw`, ΔE00 ≈5.1) is `<= approximate.maxDeltaE` (8) via the real `_deltaE00` — non-vacuous. But `accuracy==approximate` is still the only reachable tier (`calibrate()` throws until CAPTURE-5), so the test cannot separate "low light downgraded to approximate" from "every reading is always approximate" — it needs CAPTURE-5's calibrated-vs-approximate control (pre-seeded augmentation). CAPTURE-4 correctly did **not** close this. A once CAPTURE-5 lands. |
| AC-7 | `TestAC07_DismissWarning` | A | G1,G3,G4,G5,G6 | **Now live.** Given built through the real `commit()` flow on SCENE_DIM: `warningKey` findsOneWidget + `lowLightWarning==true` + `lastCommittedSample.accuracy==approximate` all asserted before the When (G1). Taps real E15 → `dismissWarning()`; `takeException` bounded. Textbook G3: the negative (warning gone) is asserted after `whenDismissWarning`'s settle point and paired with the warning-present Given control. Kills *dismiss clears the sample* and *dismiss upgrades the accuracy* (accuracy-invariance bites because `dismissWarning()` only flips `lowLightWarning` and `copyWith` preserves `lastCommittedSample`). Asserts `warningKey` findsNothing + `lowLightWarning==false` at grain (G4). |
| AC-9 | `TestAC09_SampleFromPhoto` | A | G1,G2,G4,G5,G6 (G3 n/a) | Carried forward live A; unaffected. Given checked on the fixture (`atP != atCentre`). `whenImportPhoto` taps E19 → real `importPhoto()` sets `_photoImported` + `sampleFromPhoto(image, P=(12,12), radiusPx:5)`; the local `pumpAndSettle` delivers still-undrained live frames that `_onFrame` ignores (feed-switch guard exercised). Discriminators `toP < 45`, `toP < toCentre` (magenta vs grey), `toP < distToColor(sampled, liveCamera)` (vs olive host). No faked sample value (G2). |

### Summary — CAPTURE-4

- **Grade counts: 6×A + AC-6 B-pending-CAPTURE-5** across the un-pended set (AC-1, AC-2, AC-4, AC-5, AC-6,
  AC-7, AC-9). AC-7 moves from its as-written ITEST-3 A to a **live A** against CAPTURE-4's real
  `commit()`/`dismissWarning()`; AC-1/AC-2/AC-4/AC-5/AC-9 hold their prior live A; AC-6 **remains B pending
  CAPTURE-5** (CAPTURE-4 did not and should not have closed its one-reachable-tier G5 limitation).
- **CAPTURE-4 cannot weaken any un-pended test.** It added only `commit()` and `dismissWarning()` on the
  controller; the harness, settling model, live-view, controls, sampling, lock and source are unchanged.
- **Whole-suite grid: 10×A + AC-6 B-pending-CAPTURE-5** (unchanged). Still-pending rows untouched: AC-3
  (SCREEN-2), AC-8 (CAPTURE-5), AC-10 (SCREEN-3), AC-11 (CAPTURE-6).
- **Carried hazards (do not affect grades):** (1) AC-6's accuracy-downgrade proof and a missing adequate-light
  warning control both land with CAPTURE-5's augmentation — do not mark AC-6 A before then. (2) `takeException()`
  consumes stay bounded (`UnimplementedError`/null only) and are now harmless no-ops for AC-6/AC-7. (3) AC-11's
  navigation hazard (keep `CaptureReadEndpoint` reachable across the Readout push) is carried to CAPTURE-6.

## Re-grade — CAPTURE-5 (un-pended: AC-1, AC-2, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9)

CAPTURE-5 landed the reference-card calibration path behind AC-8 and un-pended it, and added the
calibrated-vs-approximate control that closes AC-6's prior `B pending CAPTURE-5`. The live pieces: a new
`CaptureController.calibrate()` (no-op without a card; else upgrades `accuracy → calibrated` and replaces
`currentSample` with `_normalisedAgainstCard`); a new abstract `CaptureSource.normaliseAgainstCard(raw)`
implemented on `SoftwareCaptureSource` as `return scene.groundTruth` (the deterministic card recovers the true
colour, ΔE00 0) and inherited unchanged by `FakeCaptureSource`; and a `KeyedSubtree(key: accuracyKey)` wrapper
around the live-view accuracy label. Per the grade gate a behaviour phase re-grades **every un-pended AC test**
against the **live** behaviour — so the eight currently un-pended tests (AC-1, AC-2, AC-4, AC-5, AC-6, AC-7,
AC-8, AC-9) are graded here; AC-3 (SCREEN-2), AC-10 (SCREEN-3), AC-11 (CAPTURE-6) remain pending and their prior
rows are untouched. Graded by an independent fresh grader (did not write these tests) on 2026-10-07; confirmed
by a live run (`flutter test integration_test/capture_test.dart` → **16 passed, 3 skipped**; AC-1, AC-2, AC-4,
AC-5, AC-6, AC-7, AC-8, AC-9 all executed live and passed).

**Silent-weakening check (CAPTURE-5's two touch points):** (1) The `KeyedSubtree(key: accuracyKey)` wrapper does
not weaken any un-pended test. The only reader of `accuracyKey` is AC-8's `find.descendant(of: accuracyKey,
matching: find.text('Calibrated'))`, which the wrapper is built to serve (the label `Text` is a descendant of
the keyed subtree). AC-6/AC-7 read the accuracy through `harness.state…accuracy` (the enum, **not** the label),
so the wrapper is irrelevant to them; the smoke test's `find.text('Approximate')` still matches the `Text`
inside the subtree. (2) The new `normaliseAgainstCard` interface method is reached only from `calibrate()`
(AC-8 and AC-6's control); it does not touch AC-1/2/4/5/7/9, whose structural / sampling / lock / commit paths
are unchanged. No un-pended test is weakened.

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-1 | `TestAC01_Eyedropper` | A | G1,G4,G5,G6 (G2/G3 n/a) | Carried forward live A; untouched by CAPTURE-5 (pure structural layout read, no accuracy label or calibration dependency). Given checked through the real UI (`AppBar 'Capture'` + `liveViewKey`); asserts reticle centre vs feed centre on both axes at epsilon 0.5 (not mere presence). Live `CaptureLiveView` lays the feed `StackFit.expand` and the reticle in a `Center`, so a correct render matches to ~0 px and 0.5 kills an absent/off-centre marker. |
| AC-2 | `TestAC02_AreaAverage5px` | A | G1,G2,G4,G5,G6 (G3 n/a) | Carried forward live A; untouched. Configured radius read through the endpoint (`state.radiusPx==5`, G2). Real `sampleAreaAverage(..., radiusPx:5)` drives the three-way distance Then on `SCENE_CENTRE_VARIED` (red/teal/yellow, pairwise L1 ~200–280 ≫ `_sampleToleranceL1 = 45`); kills a point read (`toDisc < toCentre`) and a wider radius (`toDisc < toOuter`). |
| AC-4 | `TestAC04_LockSettles` | A | G1,G4,G5,G6 (G3 n/a) | Carried forward live A; lock/settle unchanged by CAPTURE-5. Given `lockState==auto`; `_pumpUntilText` climbs the real frame counter to `find.text('SETTLING 6/12')` (G1). Taps real E16; `takeException` bounded (no-op). Thens assert exact "AE · AWB · AF LOCKED" + "STABLE 12/12" + `lockState==locked` at grain (G4). Kills unchanged-indicator / never-settles / partial-lock. |
| AC-5 | `TestAC05_SettlingWarns` | A | G1,G3,G4,G5,G6 | Carried forward live A; unaffected. Given `lockState==auto`; counter advances 0→6 (no lock tap). Textbook G3: negatives (`isStable==false`, "STABLE 12/12" findsNothing) at a settle point, paired with the counter climbing 0→6; `lockButton.enabled==true` proves the affordance. Kills STABLE-while-unlocked and a missing/disabled control. |
| AC-6 | `TestAC06_LowLightApproximate` | **A** (was B pending CAPTURE-5) | G1,G2,G3,G4,G5,G6 | **Upgraded B→A: the pre-seeded CAPTURE-5 augmentation landed and discriminates.** Dim half (live `commit()` on configured SCENE_DIM via `harness.source`, G2): kills refusal-in-dim (`lastCommittedSample isNotNull`), kills no-warning (`warningKey` + flag), committed accuracy==approximate, and the committed `_dimRaw` sits ΔE00 ≈5.1 of ground truth — asserted **both** `≤ approximate.maxDeltaE (8)` and **`> calibrated.maxDeltaE (3)`**, so the approximate label is a real downgrade, not a conservative relabel of an already-tight reading. **Control (G3/G5):** resets the tree (`pumpWidget(SizedBox.shrink())`) — which disposes the dim `CaptureHomeScreen`/controller — then mounts a **fresh** SCENE_CARD app, asserts the card scene is in *adequate* light (so the tier delta is the card, not lighting), calibrates, commits, and asserts the committed capture reads `calibrated` within ΔE00 3. The reset is sound: `CaptureHomeScreen` builds its controller once in `initState`, so the control reads the card controller via the endpoint, not the torn-down dim one (live run confirms the fresh source is sampled: committed card colour = ΔE00 0). The control **discriminates** — pre-CAPTURE-5 `calibrate()` threw `UnimplementedError` (the body takes no exception after `whenCalibrate`, so it would error the test), and a relabel-only calibration leaves `_cardRaw` at ΔE00 ≈4.6 > 3 → the `≤3` Then fails. Pairing the two commits proves low light *specifically* downgrades vs a single always-on tier — the exact G5 gap the prior row named. **G6 judgement (not a defect):** the control asserts `calibrated`/ΔE00 3 (steps that also appear in AC-8), but here they serve AC-6's own downgrade claim as the required contrast, not an independent re-verification of AC-8; this is the planner's pre-seeded augmentation strengthening AC-6's own Then, so it stays one-AC. |
| AC-7 | `TestAC07_DismissWarning` | A | G1,G3,G4,G5,G6 | Carried forward live A; unaffected by CAPTURE-5. Given built through the real `commit()` flow on SCENE_DIM (`warningKey` + `lowLightWarning==true` + `lastCommittedSample.accuracy==approximate` before the When — read via `state`, not the accuracy label, so the `KeyedSubtree` wrapper does not touch it). Taps real E15 → `dismissWarning()`; `takeException` bounded. Textbook G3: the negative (warning gone) after the settle point, paired with the warning-present Given; accuracy-invariance before **and** after kills *dismiss clears/upgrades the accuracy*. |
| AC-8 | `TestAC08_CardCalibrates` | A | G1,G2,G4,G5,G6 | **Now live.** Given `referenceCardPresent==true` answered by the configured SCENE_CARD via `harness.source` (G2). When taps real E17 → live `calibrate()`: reads the already-sampled `_cardRaw`, calls `source.normaliseAgainstCard` and upgrades `accuracy → calibrated`; `takeException` bounded (no-op). Asserts the upgraded label live through the `KeyedSubtree`/`find.descendant(of: accuracyKey, matching: 'Calibrated')` finder (rejects an accuracy stuck at approximate). Then taps real E20 and asserts the committed sample is `calibrated` **and** within ΔE00 3 via the test-side CIEDE2000. **Non-vacuous (G5):** SCENE_CARD's raw `_cardRaw` sits ΔE00 ≈4.6 of ground truth (the never-pending fixture guard pins sRGB L1 > 20), so a calibration no-op (colour unchanged) commits at ≈4.6 > 3 → the `≤3` Then **fails it**; the relabel-only impl is killed by the committed `accuracy==calibrated` plus the colour bound. `normaliseAgainstCard` returning `scene.groundTruth` lands the correct impl at ΔE00 0 — a 3-ΔE margin, well clear of 8-bit round-trip noise. One AC. |
| AC-9 | `TestAC09_SampleFromPhoto` | A | G1,G2,G4,G5,G6 (G3 n/a) | Carried forward live A; unaffected by CAPTURE-5. Given checked on the fixture (`atP != atCentre`). `whenImportPhoto` taps E19 → real `importPhoto()` sets `_photoImported` + `sampleFromPhoto(image, P=(12,12), radiusPx:5)`; the local `pumpAndSettle` delivers still-undrained live frames that `_onFrame` ignores (feed-switch guard exercised). Discriminators `toP < 45`, `toP < toCentre` (magenta vs grey), `toP < distToColor(sampled, liveCamera)` (vs olive host). No faked sample value (G2). |

### Summary — CAPTURE-5

- **Grade counts (re-grade): 8×A, 0×B** across the un-pended set (AC-1, AC-2, AC-4, AC-5, AC-6, AC-7, AC-8,
  AC-9). **AC-6 moves B→A** (the pre-seeded calibrated-vs-approximate control landed, discriminates, and closes
  the one-reachable-tier G5 gap the prior row named — no rule now limits it); **AC-8 is a fresh live A** against
  CAPTURE-5's `calibrate()` → `normaliseAgainstCard` → `commit()` path; AC-1/AC-2/AC-4/AC-5/AC-7/AC-9 hold their
  prior live A with **no downgrade**.
- **No silent weakening.** The `KeyedSubtree(key: accuracyKey)` wrapper serves AC-8's `find.descendant` and is
  irrelevant to AC-6/AC-7 (which read the accuracy enum off `state`, not the label); the new
  `CaptureSource.normaliseAgainstCard` is reached only from `calibrate()` (AC-8 + AC-6 control) and leaves the
  structural / sampling / lock / commit paths of AC-1/2/4/5/7/9 untouched.
- **AC-6 control is a genuine control, not an AC-8 duplicate.** The tree-reset mounts a fresh card app so the
  control exercises the real card controller (not the torn-down dim one); it discriminates (pre-CAPTURE-5
  `calibrate()` threw → the body would error; a relabel-only calibrate fails the ΔE00 3 bound); and its
  calibrated assertions serve AC-6's *own* downgrade claim as the required contrast (G6 stays one-AC).
- **Live-run evidence:** default `flutter test integration_test/capture_test.dart` → **16 passed, 3 skipped**
  (AC-3/AC-10/AC-11 pending). The eight un-pended AC tests all executed live and passed.
- **Whole-suite grid: 11×A, 0×B.** AC-6's B-pending is now resolved to A; every other row holds A. Still-pending
  rows carry their prior A-as-written grades: AC-3 (SCREEN-2), AC-10 (SCREEN-3), AC-11 (CAPTURE-6).
