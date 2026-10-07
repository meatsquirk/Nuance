# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 (harness) + ITEST-2 (AC-1,2,3,9,10, grade 5×A; AC-1 un-pended green-at-baseline) done; ITEST-3 (AC-4,5,6,7,8,11) next, then ITEST-4 (G-3)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/capture_test.dart` (AC tests), `integration_test/capture_harness.dart` (Given/When/Then vocabulary, fixtures, pending gate, `buildApp` driver with the capture source), `integration_test/fakes/fake_capture_source.dart`; reuses bs-01's `integration_test/fakes/fake_haptics.dart`.
**Depends on:** all shell phases (SOURCE-1, CAPTURE-2, SCREEN-1) · **Blocks:** every behavior phase (via G-3)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ✅ Done | 6,008,655 | 17m 53s (17m 53s) |
| 2 | acceptance-tests | AC-1,2,3,9,10 | ✅ Done | 9,320,845 | 27m 06s (27m 06s) |
| 3 | acceptance-tests | AC-4,5,6,7,8,11 | ⬜ Next | | |
| 4 | test-review | — (G-3) | ⬜ Todo | | |

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
- **G-3 (approve acceptance tests)** is this module's exit gate (ITEST-4), blocking every behavior phase.

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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

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

### Packet  <!-- filled by ITEST-4 -->

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_Eyedropper | **green at baseline** — un-pended at ITEST-2 (SCREEN-1 shell already centres the reticle over the feed); now runs in the default suite | — (passes live; SCREEN-2 keeps it green) | SCREEN-2 | A |
| AC-2 | TestAC02_AreaAverage5px | red — clean Then fail | Then: `currentSample` null → 5 px average | SOURCE-2 | A |
| AC-3 | TestAC03_RadiusSelector | red — clean Then fail | Then: reticle 8 px (shell stays 20 px) | SOURCE-2, SCREEN-2 | A |
| AC-4 | TestAC04_LockSettles | (to record) | Then: LOCKED + STABLE 12/12 | CAPTURE-3 | |
| AC-5 | TestAC05_SettlingWarns | (to record) | Then: SETTLING 6/12 + lock invites | CAPTURE-3 | |
| AC-6 | TestAC06_LowLightApproximate | (to record) | Then: approximate within ΔE00 8 | CAPTURE-4 | B pending CAPTURE-5 |
| AC-7 | TestAC07_DismissWarning | (to record) | Then: warning cleared, stays approximate | CAPTURE-4 | |
| AC-8 | TestAC08_CardCalibrates | (to record) | Then: normalised ΔE00 3 + upgraded | CAPTURE-5 | |
| AC-9 | TestAC09_SampleFromPhoto | red — clean Then fail | Then: `currentSample` null → reads point P | SOURCE-3 | A |
| AC-10 | TestAC10_ValueOnly | red — clean Then fail | Then: `valueOnly` false → grayscale feed + "✓ Value" | SCREEN-3 | A |
| AC-11 | TestAC11_CommitOpensReadout | (to record) | Then: multi-frame mean + haptic + Readout | CAPTURE-6 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC06_LowLightApproximate | until a tighter tier exists (only "approximate" until the reference-card path, CAPTURE-5), the test can't prove low light *specifically* downgrades vs a single always-on tier | CAPTURE-5 | add the control: a `SCENE_CARD` calibrated capture reads **calibrated** ΔE3 while the card-less dim capture reads **approximate** ΔE8 | ⬜ Open |
