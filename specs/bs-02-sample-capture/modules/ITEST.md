# Module ITEST — acceptance integration suite

**Status:** Done — all 4 phases complete; G-3 approved 2026-10-07, behaviour stage un-blocked
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/capture_test.dart` (AC tests), `integration_test/capture_harness.dart` (Given/When/Then vocabulary, fixtures, pending gate, `buildApp` driver with the capture source), `integration_test/fakes/fake_capture_source.dart`; reuses bs-01's `integration_test/fakes/fake_haptics.dart`.
**Depends on:** all shell phases (SOURCE-1, CAPTURE-2, SCREEN-1) · **Blocks:** every behavior phase (via G-3)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ✅ Done | 6,008,655 | 17m 53s (17m 53s) |
| 2 | acceptance-tests | AC-1,2,3,9,10 | ✅ Done | 9,320,845 | 27m 06s (27m 06s) |
| 3 | acceptance-tests | AC-4,5,6,7,8,11 | ✅ Done | 13,046,220 | 41m 18s (41m 18s) |
| 4 | test-review | — (G-3) | ✅ Done | | |

## Interface reconciliation
- **Boundary:** the assembled app via bs-01's production `buildApp(deps)` (Capture route added by CAPTURE-2),
  driven by `WidgetTester`. Real: sampling, lock/settle, accuracy/calibration, screen, routing, commit, the
  bs-01 Readout. Faked (infrastructure only): `FakeCaptureSource` (software frames + known ground truth;
  records frame reads) and bs-01's `FakeHaptics`.
- **Observation points:** AC-1 — eyedropper widget + centre position; AC-2/AC-3 — `currentSample` via the
  read endpoint + reticle widget size; AC-4/AC-5 — stability/lock indicator text; AC-6/AC-7 — low-light
  warning widget + committed `accuracy` (label + ΔE00 vs ground truth); AC-8 — committed colour vs ground
  truth + upgraded label; AC-9 — `currentSample` after photo import; AC-10 — grayscale render on the feed +
  "✓ Value"; AC-11 — `framesAveraged` + committed colour vs multi-frame mean, `FakeHaptics` log, the Readout
  route rendering "Deep Olive Green".
- **Pending gate:** a `pendingACs` map (AC → owning phase) + `ac('AC-n')` calling `markTestSkipped('AC-n
  pending <phase>')` unless `BS02_RUN_PENDING=1`. Un-pending an AC = delete its map row. Default
  `flutter test integration_test/capture_test.dart` skips pending; run-pending executes them.

## Open gates
- **G-3 (approve acceptance tests)** — ✅ Resolved 2026-10-07 07:04 EDT: **approved** — Matt Quirk. The
  ITEST-4 packet (11 AC tests, grid 10×A + AC-6 *B pending CAPTURE-5*) is accepted as the gate for behaviour;
  AC-6's one deferred strengthening is accepted (augmentation closes it at CAPTURE-5). No spec/intent
  amendment. Behaviour stage un-blocked; ITEST-4 → Done.

## Phase 1 — Harness

- **Kind:** acceptance-tests
- **Target AC:** — (harness)
- **Depends on:** SOURCE-1, CAPTURE-2, SCREEN-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/capture_harness.dart`, `integration_test/fakes/fake_capture_source.dart`.
- **Tasks:**
  1. A `buildApp` driver that assembles the real app with `FakeCaptureSource` + `FakeHaptics` injected, opened
     on the Capture route.
  2. Given/When/Then helpers: `givenCaptureOf(scene)`, `whenSelectRadius(px)`, `whenLock()`, `whenCommit()`,
     `whenDismissWarning()`, `whenCalibrate()`, `whenImportPhoto(photo)`, `whenToggleValueOnly()`; the fixtures
     (`SCENE_OLIVE`, `SCENE_CENTRE_VARIED`, `SCENE_DIM`, `SCENE_CARD`, `PHOTO_SWATCH`, `SCENE_MULTIFRAME`) from
     the plan, each with its known ground-truth colour.
  3. The pending gate with **all 11 ACs pending**, and a never-pending **smoke test** proving the shells wire
     end to end (app boots to the Capture route and renders the live view + E15–E21 regions).
  4. Grade the scaffold tests: no vacuous passes (assert the pending map has exactly 11 keys, each naming a
     real phase; the smoke test asserts concrete rendered regions); comments claim only what is checked;
     deterministic (`pumpAndSettle`/polling with a timeout, no fixed sleeps).
- **Exit criteria:** `flutter test integration_test/capture_test.dart` green (all AC tests pending, smoke
  passes); harness tests graded A.
- **Acceptance gate:** smoke green; pending gate in place (11 pending).

### Result

Landed the bs-02 acceptance harness and the never-pending scaffold suite:
- `capture_harness.dart` — the fixtures, the Given/When/Then vocabulary and the `givenCaptureOf` driver
  (builds the real app via bs-01's `buildApp` with a `FakeCaptureSource` injected → opens on Capture);
  re-exports the pending gate + fakes so an AC test imports only this file.
- `fakes/fake_capture_source.dart` — `FakeCaptureSource` (the software source + recorded `framesRead` +
  `groundTruth` + a `stagedPhoto` seam) and the `Photo` fixture type.
- `capture_test.dart` — the AC-suite file: a smoke test + guard tests (never pending). ITEST-2/3 append the
  per-AC `acTestWidgets`.
- Seeded `bs02/pending.dart` (CAPTURE-1's gate) with **all 11 ACs** → owning phase (AC-3 → SCREEN-2, matching
  the red-baseline column); default run skips them, `BS02_RUN_PENDING=1` runs them.

Fixtures: SCENE_OLIVE/DIM/CARD/MULTIFRAME carry the olive ground truth (uniform; frame generation deferred to
SOURCE-2 — DIM = low light, CARD = card present, MULTIFRAME = per-frame noise). SCENE_CENTRE_VARIED and
PHOTO_SWATCH carry explicit frames whose pixels are rendered from chosen CIELAB region colours via the real
`ColorScienceImpl.toSRGB`, so centre ≠ 5 px avg ≠ 21 px avg (the AC-2/AC-3 control) and P ≠ image centre (AC-9).

Verification (Flutter 3.47.6): `flutter analyze` clean. `flutter test integration_test/capture_test.dart`
**7 green** (smoke + 6 guards; no AC tests yet). Full `integration_test/` **24 green** (17 bs-01 + 7 bs-02).
Unit **282 green**. Coverage gate `dart run tool/coverage_gate.dart main`: **PASS 100%** (no `lib` touched —
only test files + the pending gate). **Grade (scaffold tests, self-assessed against the ITEST-1 criteria):
A** — no vacuous passes (the pending map is pinned to exactly 11 ACs and owners; the control fixtures are
proven distinct; the fake's frame count is asserted), comments claim only what is checked, deterministic
(`pumpAndSettle`, stream `toList`, no sleeps). Per-AC grade grid begins at ITEST-2 (bs-01 convention).

Ownership vs the plan's Files: also created `capture_test.dart` (the suite file the exit criteria runs) and
seeded `bs02/pending.dart` (pre-created by CAPTURE-1) — both within the ITEST module's stated ownership.
No AC un-pended (harness phase); no exclusions. Fix passes **0/3** (two pre-run compile fixes during analyze:
the app-bar "Capture" assertion scoped to `AppBar` since E20 also reads "Capture"; `LockState` hidden from
`material`). Tokens 6,008,655 · time 17m 53s (17m 53s).

### Checkpoint / Handoff

- **Verification commands** (unchanged; PATH `~/development/flutter/bin`): `flutter analyze`;
  `flutter test integration_test/capture_test.dart` (default — pending skipped) /
  `BS02_RUN_PENDING=1 flutter test integration_test/capture_test.dart` (run-pending / red baseline);
  `flutter test integration_test/` (full); `flutter test --coverage` + `dart run tool/coverage_gate.dart main`.
- **Frozen harness API (ITEST-1):**
  - `givenCaptureOf(WidgetTester, CaptureScene) → CaptureHarness`.
  - `CaptureHarness`: `.source` (`FakeCaptureSource`: `.groundTruth`, `.framesRead`, `.stagedPhoto`),
    `.haptics`, `.controller`, `.state`; When helpers `whenLock` / `whenCommit` / `whenDismissWarning` /
    `whenCalibrate` / `whenToggleValueOnly` / `whenSelectRadius(px)` / `whenImportPhoto(Photo)`.
  - Fixtures: `SCENE_OLIVE`, `SCENE_DIM`, `SCENE_CARD`, `SCENE_MULTIFRAME`, `SCENE_CENTRE_VARIED`
    (`CaptureScene`, `.groundTruth` / `.groundTruthName`); `PHOTO_SWATCH` (`Photo`: `.image`, `.pointX/Y`,
    `.colorAtPoint`). `oliveGroundTruthName == 'Deep Olive Green'` (AC-11's Readout name).
  - Pending gate (re-exported from `bs02/pending.dart`): `acTestWidgets(acId, desc, body)`, `pendingACs`,
    `pendingSkipReason`, `behaviorPhases`. Un-pend an AC = delete its row in `bs02/pending.dart`.
- **For ITEST-2 (AC-1,2,3,9,10) / ITEST-3 (AC-4..8,11):** append `acTestWidgets('AC-n', 'TestACnn_<Slug>',
  …)` to `capture_test.dart`; name per the red-baseline table; observe via `harness.state` / the read endpoint
  + rendered text. These two phases split the file region and may run concurrently.
- **Seams ITEST-2/3 refine (flagged, not yet finalised):**
  - `whenSelectRadius(px)` taps the E18 region; SCREEN-2 adds per-option 1/5/21 anchors → retarget then
    (AC-3). `whenImportPhoto` stages the photo on the fake + taps E19; **SOURCE-3 wires how the controller
    reads the staged photo and must enable E19** (carried from the SCREEN-1 handoff — E19 is a disabled
    placeholder not in SOURCE-3's current Files).
  - SCENE_CENTRE_VARIED's exact 5 px/21 px averages and PHOTO_SWATCH's P read depend on SOURCE-2/3's sampler;
    assert `currentSample` ≈ the dominant region colour (`groundTruth` = the disc / `colorAtPoint`), tolerance
    tuned at ITEST-2/3.
  - **Red-baseline shape:** observe `currentSample` (null at baseline → the Then fails cleanly, no panic).
    Tapping a wired-but-deferred control (`whenLock/Commit/Calibrate/DismissWarning/ToggleValueOnly`) throws
    `UnimplementedError` until its phase, so AC-4/5/6/7/11 should assert the Given precondition / observable
    Then rather than let the tap panic — structure them so the baseline red is a Then or a phase-named Given.
- **G-3** (approve the acceptance tests) still gates every behaviour phase; decided at ITEST-4.

## Phase 2 — AC tests: sampling + screen (AC-1,2,3,9,10)

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-3, AC-9, AC-10 (all **pending**)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-3
- **Files:** `integration_test/capture_test.dart` (sampling+screen group).
- **Tasks:** write catalogue rows AC-1, AC-2, AC-3, AC-9, AC-10 as pending tests, grade-A (every Given checked
  via the read endpoint/UI, When through the real UI, Then asserted tightly with the `SCENE_CENTRE_VARIED` /
  `PHOTO_SWATCH` controls so a point-read or wrong-radius / wrong-source impl fails). Run run-pending; record
  the **red baseline** row per test below.
- **Exit criteria:** default run green (these pending); run-pending shows each failing on a Then or a Given
  precondition naming its owning phase; grade grid all A.
- **Acceptance gate:** *(AC-test)* suite green with new tests pending; red baseline recorded; grade gate passed.

### Result

Appended the five sampling+screen AC tests to `integration_test/capture_test.dart` (`TestAC01_Eyedropper`,
`TestAC02_AreaAverage5px`, `TestAC03_RadiusSelector`, `TestAC09_SampleFromPhoto`, `TestAC10_ValueOnly`), each
driving the real assembled app through the ITEST-1 harness and observing `currentSample` / reticle size /
feed render / control text. Sampled colours are rendered back to sRGB via the real `ColorScienceImpl` and
compared (L1, `_sampleToleranceL1 = 45`) against the fixtures' own frame pixels, so the Thens reject a
point read, a wrong-radius average, the wrong source, and a missing grayscale render.

**AC-1 un-pended — green at baseline.** The SCREEN-1 shell already renders a centre-point reticle over the
feed (`Center` inside a `StackFit.expand` live view), so `TestAC01_Eyedropper` (present + reticle centre ≈
feed centre, ε 0.5) passes live. Per the red-baseline rule a green-at-baseline test is un-pended: removed
`AC-1` from `bs02/pending.dart`, updated the guard test (`expectedOwners` → 10, length 10, the skip-example
AC switched to AC-2, AC-1 asserted un-mapped). AC-1 now runs in the default suite; SCREEN-2 still builds the
real eyedropper/reticle and keeps it green. The other four stay pending on a clean Then naming their owning
phase (red baseline table above).

**Verification** (Flutter 3.47.6, PATH `~/development/flutter/bin`): `flutter analyze` clean.
`flutter test integration_test/capture_test.dart` (default) **8 green** (smoke + 6 guards + AC-1), 4 pending
skipped. `--dart-define=BS02_RUN_PENDING=true` (red baseline) **+8 −4**: AC-1 green; AC-2/AC-9 fail on
`currentSample` null, AC-3 on reticle 8 px (shell 20 px), AC-10 on `valueOnly` false — all clean Thens, no
panics. Full `integration_test/` **25 green + 4 pending**. Unit **282 green**. Coverage gate
`dart run tool/coverage_gate.dart main`: **PASS 100%** (no `lib` touched — only `capture_test.dart` and the
`bs02/pending.dart` gate). **Grade: 5×A, 0×B** — graded by an independent fresh grader (did not write the
tests); grid `behavior-test-completeness-bs-02-sample-capture.md`. No exclusions. **Fix passes 1/3** (after
the first run-pending baseline: consumed AC-10's deferred `UnimplementedError` via `takeException` so its red
is a clean Then, and un-pended AC-1).

### Checkpoint / Handoff

- **Verification commands** unchanged (see Phase 1 handoff): `flutter analyze`; `flutter test
  integration_test/capture_test.dart` (default) / `--dart-define=BS02_RUN_PENDING=true` (run-pending);
  `flutter test integration_test/`; `flutter test --coverage` + `dart run tool/coverage_gate.dart main`.
- **AC tests landed (AC-1,2,3,9,10) — contracts the behaviour phases must satisfy:**
  - **SOURCE-2 (AC-2):** opening a scene must populate `state.currentSample` from the live feed (sampled
    under the centre reticle at the 5 px default) after a `pump`; AC-2 reads it back as sRGB and requires it
    ≈ the inner-disc colour of `SCENE_CENTRE_VARIED`, nearer the disc than the centre distractor and the
    outer band. **The test takes no explicit "sample" action — it is passive (`await tester.pump()`), so the
    live feed must drive `currentSample`** (and the frame stream must terminate / settle so `pumpAndSettle`
    in the harness `given`/`when` helpers does not hang).
  - **SCREEN-2 (AC-1 already green; AC-3):** AC-3 iterates radii {1,5,21} via `whenSelectRadius(px)` and
    asserts the reticle `getSize` == {8,20,44} (ε 0.5) **and** that the average follows the radius. **Carry
    (flagged by the grader + ITEST-1 handoff):** `whenSelectRadius(px)` currently taps the single E18
    placeholder regardless of `px`; SCREEN-2 must give each 1/5/21 option its own anchor **and retarget the
    harness helper** so the three iterations select the three radii — otherwise all three iterations select
    one radius and the directional-pull Thens don't exercise the selector.
  - **SOURCE-3 (AC-9):** `whenImportPhoto(PHOTO_SWATCH)` stages the photo on the fake and taps E19; SOURCE-3
    must **enable E19** (`importKey.onPressed` in `capture_controls.dart`, not in SOURCE-3's current Files —
    carried from SCREEN-1/ITEST-1) and read the staged photo so `currentSample` becomes the colour at P
    (5 px average, entirely inside the r=6 swatch), not the image centre, not the olive live camera.
  - **SCREEN-3 (AC-10):** `toggleValueOnly` must set `state.valueOnly = true`, render the feed grayscale as a
    **`ColorFiltered` ancestor of `CaptureLiveView.liveViewKey`** (the test asserts that ancestor — use
    `ColorFiltered`/`ColorFilter.matrix` saturation, not a filter on an unrelated widget), and flip the E21
    label to exactly **"✓ Value"**. Un-pending AC-10 stops the deferred `UnimplementedError` the test
    currently consumes.
- **Pending gate now:** `pendingACs` holds **10** ACs (AC-1 removed). The guard test pins the 10 owners and
  `length == 10`; a behaviour phase un-pends its AC by deleting its row (AC-10 → SCREEN-3, etc.).
- **ITEST-3** (AC-4,5,6,7,8,11) is the sibling AC-test phase — same file, lifecycle group; it is now `⬜ Next`
  and still startable (G-3 blocks only behaviour). ITEST-4 (test review, G-3) needs both ITEST-2 and ITEST-3
  done.

## Phase 3 — AC tests: lifecycle + accuracy + commit (AC-4,5,6,7,8,11)

- **Kind:** acceptance-tests
- **Target AC:** AC-4, AC-5, AC-6, AC-7, AC-8, AC-11 (all **pending**)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Files:** `integration_test/capture_test.dart` (lifecycle group — split file region to allow ∥ with ITEST-2).
- **Tasks:** write catalogue rows AC-4..AC-8 and AC-11 as pending tests, grade-A; AC-6 asserts the committed
  colour is within ΔE00 8 of ground truth **and** a sample commits (not refused), recorded *B pending
  CAPTURE-5* until its card control lands; AC-7 settles the warning-dismiss negative Then; AC-8 asserts
  normalisation within ΔE00 3 + the upgraded label; AC-11 asserts multi-frame averaging (not a single frame),
  one haptic, and the Readout route. Record the red baseline rows.
- **Exit criteria:** as ITEST-2 (AC-6 may carry *B pending CAPTURE-5* with its augmentation row).
- **Acceptance gate:** *(AC-test)* suite green with new tests pending; red baseline recorded; grade gate passed.

### Result

Appended the six lifecycle/accuracy/commit AC tests to `integration_test/capture_test.dart`
(`TestAC04_LockSettles`, `TestAC05_SettlingWarns`, `TestAC06_LowLightApproximate`, `TestAC07_DismissWarning`,
`TestAC08_CardCalibrates`, `TestAC11_CommitOpensReadout`), each driving the real assembled app through the
ITEST-1 harness and observing `state` / the read endpoint + rendered text. Added a test-side CIEDE2000
`_deltaE00` helper (verified exact against Sharma et al. vectors 2.0425 / 2.8615 / 0) so the accuracy Thens
measure the committed colour against the fake's ground truth in real ΔE00, bounded by the real
`CaptureAccuracy.{approximate,calibrated}.maxDeltaE` (8 / 3 — D-4); and a `_pumpUntilText` helper to advance
the frame-driven settling counter to "SETTLING 6/12".

**Fixture hardening (grade-gate fix, fix pass 1/3):** the independent grader caught AC-8's ΔE00 ≤ 3 Then as
vacuous — `SCENE_CARD` read at ground truth, so a relabel-only calibration would pass. Gave `SCENE_CARD` a raw
`_cardRaw` frame ΔE00 4.56 off truth and `SCENE_DIM` a raw `_dimRaw` frame ΔE00 5.07 off truth (both in
(3, 8], via a new `_uniformFrame` helper), and added a never-pending guard that both raw readings sit clearly
off ground truth (sRGB L1 36 / 42). Now only a real normalisation lands AC-8 within ΔE00 3, and AC-6's
ΔE00 ≤ 8 + the CAPTURE-5 augmentation contrast are non-vacuous. No AC un-pended (all six red at baseline);
pending gate stays at **10**.

**Verification** (Flutter 3.47.6): `flutter analyze` clean. Default `flutter test
integration_test/capture_test.dart` **9 green** (smoke + 7 guards + AC-1), 10 pending skipped.
`--dart-define=BS02_RUN_PENDING=true` red baseline **+9 −10**: each new test fails on a clean Then or a Given
precondition naming its owning phase — no panics (deferred `UnimplementedError`s consumed via
`takeException`). Unit **282 green**; coverage gate `dart run tool/coverage_gate.dart main` **PASS 100%** (no
`lib` touched — only `capture_test.dart` + `capture_harness.dart`). **Grade: 5×A, 1×B** by an independent
fresh grader (AC-4/5/7/8/11 A; AC-6 **B pending CAPTURE-5** per the pre-seeded augmentation). No exclusions.
Fix passes **1/3** (AC-8 fixture vacuity, found by the grade gate). Tokens 13,046,220 · time 41m 18s (41m 18s).

### Checkpoint / Handoff

- **Verification commands** unchanged (Phase 1 handoff): `flutter analyze`; `flutter test
  integration_test/capture_test.dart` (default) / `--dart-define=BS02_RUN_PENDING=true` (run-pending);
  `flutter test --coverage` + `dart run tool/coverage_gate.dart main`.
- **AC tests landed (AC-4,5,6,7,8,11) — contracts the behaviour phases must satisfy:**
  - **CAPTURE-3 (AC-4, AC-5):** the settling counter must advance **one countable step per pumped frame** so
    `_pumpUntilText('SETTLING 6/12')` lands exactly on 6/12 (AC-4 Given, AC-5 Then) without `givenCaptureOf`'s
    own `pumpAndSettle` overshooting. `lock()` must render a text indicator reading **exactly**
    "AE · AWB · AF LOCKED" — **no such widget exists yet** (the live view renders only stability / accuracy /
    warning, and CAPTURE-3's Files is the controller): surface a lock indicator (e.g. a derived `lockText` on
    `CaptureState` rendered by `CaptureLiveView`), and complete stability to "STABLE 12/12" with
    `lockState == locked`.
  - **CAPTURE-4 (AC-6, AC-7):** a low-light commit must set `lowLightWarning` (rendered via `warningKey`) and
    commit an **approximate** sample within ΔE00 8 of ground truth — never refuse; `dismissWarning()` clears
    the warning without changing the accuracy. AC-6 stays **B pending CAPTURE-5**.
  - **CAPTURE-5 (AC-8 + AC-6 augmentation):** `calibrate()` on `SCENE_CARD` must **normalise** the reading
    toward ground truth — its raw reading is ΔE00 4.56 off truth, so a relabel-only calibrate fails AC-8's
    ΔE00 ≤ 3; flip the live accuracy label to "Calibrated" and commit `CaptureAccuracy.calibrated`. Then close
    AC-6's augmentation (SCENE_CARD calibrated ΔE00 ≤ 3 vs card-less SCENE_DIM approximate ΔE00 ~5 — both
    fixtures already carry the raw error) and re-grade AC-6 → A.
  - **CAPTURE-6 (AC-11):** commit must average several frames (`framesAveraged > 1`), fire exactly one haptic,
    and navigate to the Readout carrying the sample. **Navigation hazard:** the test reads `harness.state` via
    the `CaptureReadEndpoint` after the push — keep the controller/endpoint reachable across the push (don't
    strand it offstage under an opaque route) or the read throws on a correct impl. Its "STABLE 12/12" Given
    needs CAPTURE-3.
- **Pending gate unchanged: 10 ACs** (none un-pended here — all six red at baseline). The guard test still
  pins the 10 owners and `length == 10`.
- **ITEST-4** (test review, G-3) is next: ITEST-2 and ITEST-3 are both done. Whole-suite grade grid is
  **10×A + AC-6 B-pending-CAPTURE-5** (with its augmentation row) — no other B to fix before the packet.

## Phase 4 — Test review (G-3)

- **Kind:** test-review
- **Target AC:** —
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase (via G-3)
- **Preconditions:** ITEST-2 and ITEST-3 done; the whole-suite grade grid all A (or *B pending CAPTURE-5* for
  AC-6 with its augmentation row). Fix any other B here first.
- **Tasks:** assemble the review packet (below) — per AC: test name, Given checks, When, Then + Rejects (a
  line or two each); the red-baseline summary; the augmentation scheduled (AC-6 → CAPTURE-5) ; the grid path +
  counts; what to look at first. Set the phase `⏸ Awaiting review`, G-3 to *awaiting decision*, record the
  ledger row, commit, and stop with:
  `/feature-next-phase --gate bs-02-sample-capture G-3 approved | "<changes>"`.
- **Exit criteria:** packet written; human decision recorded via `--gate`.
- **Acceptance gate:** *(decision — human)*

### Packet

**For the reviewer (G-3): approve the acceptance tests before any behaviour is coded.** The eleven AC tests
below live in `integration_test/capture_test.dart`, each driving the **real assembled app** (bs-01's
production `buildApp`, Capture route) through the ITEST-1 harness. Only infrastructure is faked:
`FakeCaptureSource` (software frames + known ground-truth colour, counts frame reads) and bs-01's
`FakeHaptics`. Sampling, lock/settle, accuracy/calibration, the screen, routing, commit and the bs-01 Readout
are all real. One AC runs live today (AC-1, un-pended as green at baseline); the other ten are **pending** and
red at baseline, each failing on a Then or a Given precondition naming the phase that will make it pass.

**Look at these first (the judgement calls behind the grades):**
1. **AC-6 is graded `B pending CAPTURE-5`** — the one non-A row, by design. With only one reachable accuracy
   tier until the reference-card path exists, the test can prove a low-light commit is *approximate within
   ΔE00 8 and not refused*, but not that low light *specifically* downgrades vs a single always-on tier. The
   augmentation (below) closes it at CAPTURE-5 and re-grades it A. Approving the packet accepts this one
   deferred strengthening, not a weak test.
2. **AC-3's `whenSelectRadius(px)`** currently taps the single E18 placeholder for every radius; its
   directional-pull Thens only bite once SCREEN-2 retargets the helper to per-option 1/5/21 anchors (carried
   in the handoff). Assertions as written are correct against the intended behaviour.
3. **`tester.takeException()` consumes** in AC-4/6/7/8/10/11 are bounded to `UnimplementedError`/`null` — any
   other exception type still fails the test — so they move the baseline red onto the real Then without
   masking a genuine failure.
4. **AC-8 fixture hardening** — `SCENE_CARD` was given a raw frame ΔE00 4.56 off truth (ITEST-3 fix pass), so
   only a real normalisation lands the `≤ 3` Then; a relabel-only calibrate fails it. A never-pending guard
   pins `SCENE_CARD`/`SCENE_DIM` raw readings clearly off ground truth so the ΔE Thens can't silently regress.

**Grade grid:** `specs/bs-02-sample-capture/behavior-test-completeness-bs-02-sample-capture.md` — whole-suite
**10×A + AC-6 B-pending-CAPTURE-5** (ITEST-2: 5×A; ITEST-3: 5×A + AC-6 B-pending), each phase graded by an
independent fresh grader. No other B to fix.

**Suite state at packet time (full cross-feature regression, 2026-10-07, Flutter 3.47.6):** `flutter analyze`
clean; `flutter test integration_test/` **26 pass + 10 pending-skipped** (17 bs-01 + bs-02 smoke + 7 guards +
AC-1; the 10 pending ACs skipped by default); unit **282 pass**; coverage gate `dart run
tool/coverage_gate.dart main` **PASS 100%** on touched files. Nothing to fix before the decision.

#### Per-AC (test · Given checks · When · Then + Rejects)

- **AC-1 · `TestAC01_Eyedropper`** *(live — un-pended, owner SCREEN-2)*
  - **Given:** Capture screen shown on `SCENE_OLIVE` — `AppBar 'Capture'` + `liveViewKey` both present.
  - **When:** the live view is shown (on open).
  - **Then:** a centre-point eyedropper + reticle are present and the reticle centre equals the feed centre on
    both axes (ε 0.5). **Rejects:** an absent marker; an off-centre / top-left / `Positioned` marker.

- **AC-2 · `TestAC02_AreaAverage5px`** *(pending → SOURCE-2)*
  - **Given:** live view on `SCENE_CENTRE_VARIED`; default radius 5 px asserted via the read endpoint
    (`state.radiusPx == 5`).
  - **When:** the feed samples under the centre reticle (`pump` — passive, no explicit sample action).
  - **Then:** `currentSample` ≈ the inner-disc colour, nearer the disc than the centre pixel **and** than the
    outer band. **Rejects:** a single-pixel/point read (pulls to the centre distractor); a wider/wrong radius
    (pulls to the outer band). Fixture regions are ~200+ L1 apart vs tolerance 45.

- **AC-3 · `TestAC03_RadiusSelector`** *(pending → SCREEN-2 + SOURCE-2)*
  - **Given:** live view on `SCENE_CENTRE_VARIED`.
  - **When:** select each radius {1,5,21} px via `whenSelectRadius` (E18).
  - **Then:** reticle `getSize` == {8,20,44} px square (ε 0.5) **and** the three averages are distinct, the
    1 px nearer the centre distractor than the 5 px, the 21 px nearer the outer band than the 5 px.
    **Rejects:** an unchanged reticle (placeholder 20 px); an average that ignores the radius (all three equal).

- **AC-4 · `TestAC04_LockSettles`** *(pending → CAPTURE-3)*
  - **Given:** `SCENE_OLIVE`, `lockState == auto`; pump the frame-driven counter until "SETTLING 6/12" (at
    baseline it never leaves 0/12 — Given precondition reds cleanly naming CAPTURE-3).
  - **When:** `whenLock()` (E16).
  - **Then:** indicator reads exactly "AE · AWB · AF LOCKED", stability "STABLE 12/12", `lockState == locked`,
    `stabilityText == 'STABLE 12/12'`. **Rejects:** an unchanged indicator; a reading that never settles; a
    partial AE/AWB/AF lock.

- **AC-5 · `TestAC05_SettlingWarns`** *(pending → CAPTURE-3)*
  - **Given:** `SCENE_OLIVE`, `lockState == auto`.
  - **When:** pump frames to "SETTLING 6/12" without locking.
  - **Then:** indicator reads "SETTLING 6/12", `isStable == false`, no "STABLE 12/12", lock control present +
    enabled. Negative Thens taken at a settle point (counter advanced 0→6 proves the reading is live).
    **Rejects:** STABLE shown before a lock; a missing/disabled lock control.

- **AC-6 · `TestAC06_LowLightApproximate`** *(pending → CAPTURE-4; grade **B pending CAPTURE-5**)*
  - **Given:** `SCENE_DIM`; `source.lighting == low` and `referenceCardPresent == false` via the endpoint.
  - **When:** `whenCommit()` (E20).
  - **Then:** low-light warning shown (flag + `warningKey`); a sample **is** committed; `accuracy ==
    approximate`; committed colour within ΔE00 8 of ground truth. **Rejects:** refusing the capture in dim
    light; no warning; leaving it calibrated with no card. **Limit:** can't yet prove low light *specifically*
    downgrades — see the augmentation.

- **AC-7 · `TestAC07_DismissWarning`** *(pending → CAPTURE-4)*
  - **Given:** a low-light warning raised through the real commit flow on `SCENE_DIM`; `warningKey` present,
    accuracy approximate before the dismiss.
  - **When:** `whenDismissWarning()` (E15).
  - **Then:** warning cleared (`warningKey` findsNothing + flag false) while accuracy stays approximate.
    Negative Then settled against a reading that demonstrably changed (warning present → absent). **Rejects:**
    a dismiss that also clears/upgrades the accuracy; a warning that reappears.

- **AC-8 · `TestAC08_CardCalibrates`** *(pending → CAPTURE-5)*
  - **Given:** `SCENE_CARD`, `source.referenceCardPresent == true` (raw frame ΔE00 4.56 off truth).
  - **When:** `whenCalibrate()` (E17), then `whenCommit()` (E20).
  - **Then:** live accuracy label flips to "Calibrated"; committed colour within ΔE00 3 of ground truth;
    committed `accuracy == calibrated`. **Rejects:** a calibrate that no-ops the colour (stays ΔE00 4.56 > 3);
    an accuracy that stays approximate.

- **AC-9 · `TestAC09_SampleFromPhoto`** *(pending → SOURCE-3)*
  - **Given:** `SCENE_OLIVE` live view; `PHOTO_SWATCH` with a known colour at P ≠ the image centre (asserted
    on the fixture).
  - **When:** `whenImportPhoto(PHOTO_SWATCH)` (E19) + sample P.
  - **Then:** `currentSample` ≈ the colour at P, nearer P than the image centre **and** than the olive live
    camera. **Rejects:** sampling the image centre (wrong point); sampling the live camera instead of the
    imported photo.

- **AC-10 · `TestAC10_ValueOnly`** *(pending → SCREEN-3)*
  - **Given:** `SCENE_OLIVE` in colour; `valueOnly == false`, E21 reads exactly "Value", no `ColorFiltered`
    ancestor over `liveViewKey` (the paired control proving the reading can change — G3).
  - **When:** `whenToggleValueOnly()` (E21).
  - **Then:** `valueOnly == true`, a `ColorFiltered` ancestor over the feed, E21 reads exactly "✓ Value".
    **Rejects:** feed left in colour; label unchanged; greyscaling an unrelated widget (filter must be an
    ancestor of `liveViewKey`).

- **AC-11 · `TestAC11_CommitOpensReadout`** *(pending → CAPTURE-6; Given needs CAPTURE-3)*
  - **Given:** `SCENE_MULTIFRAME` (noisy frames whose mean is ground truth); no haptic fired; `whenLock()` to
    reach "STABLE 12/12" (baseline reds on this precondition naming CAPTURE-3).
  - **When:** `whenCommit()` (E20).
  - **Then:** `framesAveraged > 1`; committed colour within ΔE00 8 of ground truth (per-frame noise averages
    out); exactly one haptic; the Readout route shows "Deep Olive Green" under `NameHeader`. **Rejects:** a
    single-frame commit (by count); no haptic / a double pulse; navigating without the sample or with the
    wrong name.

#### Red-baseline summary (run-pending mode)

Every pending test reds on a **Then** or a **Given precondition naming its owning phase** — never a panic,
compile error or harness error (deferred `UnimplementedError`s are consumed via bounded `takeException`):
AC-2/AC-9 on `currentSample` null; AC-3 on the reticle size (shell 20 px); AC-5/AC-6/AC-8/AC-10 on their
Thens; AC-4/AC-7/AC-11 on Given preconditions naming CAPTURE-3/CAPTURE-4/CAPTURE-3. AC-1 is green at baseline
(un-pended) and runs in the default suite. Full per-test rows: the **Red baseline** table below.

#### Augmentation scheduled

| AC test | Limited because | Closed by | Add |
|---|---|---|---|
| `TestAC06_LowLightApproximate` | only one reachable accuracy tier until the reference-card path lands, so the test can't prove low light *specifically* downgrades vs a single always-on tier | **CAPTURE-5** | the calibrated-vs-approximate control (fixtures ready: `SCENE_CARD` raw ΔE00 ~4.6, `SCENE_DIM` raw ΔE00 ~5.1): a `SCENE_CARD` calibrated capture reads **calibrated** (ΔE00 ≤ 3) while the card-less `SCENE_DIM` capture reads **approximate** (ΔE00 ~5, ≤ 8) — then re-grade AC-6 → A |

### Result
G-3 **approved** 2026-10-07 07:04 EDT — Matt Quirk (recorded via `--gate`). Packet accepted as assembled:
11 AC tests, whole-suite grid **10×A + AC-6 B-pending-CAPTURE-5**, clean red baseline, full regression green.
No tests changed; AC-6's deferred strengthening accepted (augmentation owned by CAPTURE-5). Phase → Done.

### Checkpoint / Handoff
Behaviour stage un-blocked. Startable concurrently in separate sessions: **SOURCE-2** (AC-2) ∥ **CAPTURE-3**
(AC-4,5) — disjoint files. Each behaviour phase un-pends its AC(s), makes its augmentations, re-grades every
un-pended AC test, and holds the suite green with only later phases' ACs still pending. Carried handoffs from
ITEST-2/ITEST-3 stand (see the master plan's "Next phase").

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_Eyedropper | **green at baseline** — un-pended at ITEST-2 (SCREEN-1 shell already centres the reticle over the feed); now runs in the default suite | — (passes live; SCREEN-2 keeps it green) | SCREEN-2 | A |
| AC-2 | TestAC02_AreaAverage5px | red — clean Then fail | Then: `currentSample` null → 5 px average | SOURCE-2 | A |
| AC-3 | TestAC03_RadiusSelector | red — clean Then fail | Then: reticle 8 px (shell stays 20 px) | SOURCE-2, SCREEN-2 | A |
| AC-4 | TestAC04_LockSettles | red — clean Given-precondition fail | Given: "SETTLING 6/12" not shown (shell stays "SETTLING 0/12") → CAPTURE-3 drives settling | CAPTURE-3 | A |
| AC-5 | TestAC05_SettlingWarns | red — clean Then fail | Then: "SETTLING 6/12" not shown while unlocked | CAPTURE-3 | A |
| AC-6 | TestAC06_LowLightApproximate | red — clean Then fail | Then: low-light warning not raised on commit | CAPTURE-4 | B pending CAPTURE-5 |
| AC-7 | TestAC07_DismissWarning | red — clean Given-precondition fail | Given: warning not shown (commit deferred) → CAPTURE-4 | CAPTURE-4 | A |
| AC-8 | TestAC08_CardCalibrates | red — clean Then fail | Then: accuracy label not "Calibrated" (calibrate deferred) | CAPTURE-5 | A |
| AC-9 | TestAC09_SampleFromPhoto | red — clean Then fail | Then: `currentSample` null → reads point P | SOURCE-3 | A |
| AC-10 | TestAC10_ValueOnly | red — clean Then fail | Then: `valueOnly` false → grayscale feed + "✓ Value" | SCREEN-3 | A |
| AC-11 | TestAC11_CommitOpensReadout | red — clean Given-precondition fail | Given: "STABLE 12/12" not reached (lock deferred) → CAPTURE-3 | CAPTURE-6 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC06_LowLightApproximate | until a tighter tier exists (only "approximate" until the reference-card path, CAPTURE-5), the test can't prove low light *specifically* downgrades vs a single always-on tier | CAPTURE-5 | add the control (fixtures ready: `SCENE_DIM` raw ΔE00 ~5.1, `SCENE_CARD` raw ΔE00 ~4.6): a `SCENE_CARD` calibrated capture reads **calibrated** (ΔE00 ≤ 3) while the card-less `SCENE_DIM` capture reads **approximate** (ΔE00 ~5, ≤ 8) — proving low light specifically downgrades | ✅ Closed CAPTURE-5 — control added to `TestAC06_LowLightApproximate` (card-vs-card-less); re-graded A (whole-suite 11×A). Confirmed by SIGNOFF-1 fresh re-grade. |
