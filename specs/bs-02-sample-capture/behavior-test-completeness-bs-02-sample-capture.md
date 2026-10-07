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
