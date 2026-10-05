# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/capture_test.dart` (AC tests), `integration_test/capture_harness.dart` (Given/When/Then vocabulary, fixtures, pending gate, `buildApp` driver with the capture source), `integration_test/fakes/fake_capture_source.dart`; reuses bs-01's `integration_test/fakes/fake_haptics.dart`.
**Depends on:** all shell phases (SOURCE-1, CAPTURE-2, SCREEN-1) · **Blocks:** every behavior phase (via G-3)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

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
