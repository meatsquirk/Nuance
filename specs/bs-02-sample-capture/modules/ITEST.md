# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 (harness + scaffold suite) done; ITEST-2/3 (AC tests) next, then ITEST-4 (G-3)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/capture_test.dart` (AC tests), `integration_test/capture_harness.dart` (Given/When/Then vocabulary, fixtures, pending gate, `buildApp` driver with the capture source), `integration_test/fakes/fake_capture_source.dart`; reuses bs-01's `integration_test/fakes/fake_haptics.dart`.
**Depends on:** all shell phases (SOURCE-1, CAPTURE-2, SCREEN-1) · **Blocks:** every behavior phase (via G-3)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ✅ Done | 6,008,655 | 17m 53s (17m 53s) |
| 2 | acceptance-tests | AC-1,2,3,9,10 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-4,5,6,7,8,11 | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

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
| AC-1 | TestAC01_Eyedropper | (to record) | Then: eyedropper centred | SCREEN-2 | |
| AC-2 | TestAC02_AreaAverage5px | (to record) | Then: 5 px average (not point) | SOURCE-2 | |
| AC-3 | TestAC03_RadiusSelector | (to record) | Then: reticle size + radius averaging | SOURCE-2, SCREEN-2 | |
| AC-4 | TestAC04_LockSettles | (to record) | Then: LOCKED + STABLE 12/12 | CAPTURE-3 | |
| AC-5 | TestAC05_SettlingWarns | (to record) | Then: SETTLING 6/12 + lock invites | CAPTURE-3 | |
| AC-6 | TestAC06_LowLightApproximate | (to record) | Then: approximate within ΔE00 8 | CAPTURE-4 | B pending CAPTURE-5 |
| AC-7 | TestAC07_DismissWarning | (to record) | Then: warning cleared, stays approximate | CAPTURE-4 | |
| AC-8 | TestAC08_CardCalibrates | (to record) | Then: normalised ΔE00 3 + upgraded | CAPTURE-5 | |
| AC-9 | TestAC09_SampleFromPhoto | (to record) | Then: reads point P of the photo | SOURCE-3 | |
| AC-10 | TestAC10_ValueOnly | (to record) | Then: grayscale feed + "✓ Value" | SCREEN-3 | |
| AC-11 | TestAC11_CommitOpensReadout | (to record) | Then: multi-frame mean + haptic + Readout | CAPTURE-6 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC06_LowLightApproximate | until a tighter tier exists (only "approximate" until the reference-card path, CAPTURE-5), the test can't prove low light *specifically* downgrades vs a single always-on tier | CAPTURE-5 | add the control: a `SCENE_CARD` calibrated capture reads **calibrated** ΔE3 while the card-less dim capture reads **approximate** ΔE8 | ⬜ Open |
