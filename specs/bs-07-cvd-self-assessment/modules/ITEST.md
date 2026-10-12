# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/self_assessment_harness.dart`, `integration_test/self_assessment_test.dart`, `integration_test/bs07/pending.dart`; the grade grid `behavior-test-completeness-bs-07-cvd-self-assessment.md`.
**Depends on:** every shell phase (ENGINE-2, PROFILE-1, FLOW-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness + smoke) | ⬜ Todo | | |
| 2 | acceptance-tests | AC-1,2,10,11,12,13,14 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-3,4,5,6,7,8,9 | ⬜ Todo | | |
| 4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the public surface is the real app via `buildApp(deps)` driven by `WidgetTester` (keyed region finders for E36–E41, E43 and the progress indicator) plus the `OnboardingReadEndpoint` and `CvdProfileReadEndpoint` for Thens the widget tree doesn't surface, and bs-03's `ConfusionCheck` on `fixedPair` for AC-13. Production wiring throughout. Fakes are infrastructure only: `FakeSpeech`, `FakeHaptics`, and an `InMemoryPersistentStore` double behind the production `PersistentStore` interface. No scoring/colour math faked — direction and band graded against in-harness references.
- **Observation points:** AC-1 caveat strings (widget + `caveatShown`); AC-2 `testingStarted`/step (settle after Continue); AC-3/4 `prior`; AC-5 `screening {present, direction}`; AC-6/7/8 `pool`/`arranged`/arrangement-present; AC-9 `threshold.severity`; AC-10 `estimate.type`; AC-11 band text (+ `referenceBand`); AC-12 `calibratedSeverity`; AC-13 `CvdProfileReadEndpoint` count+fields + live `cvdProfile` + `ConfusionCheck(fixedPair)`; AC-14 `stepIndex`/`stepTotal` + indicator text.
- **Pending gate:** `integration_test/bs07/pending.dart` holds `pendingACs` (AC → owning behavior phase) and a helper `ac(tester, "AC-n")` that skips unless `--dart-define=BS07_RUN_PENDING=true`; un-pending = delete one AC's row. Default run skips pending; run-pending executes them (the red baseline). `-d <booted-udid>` mandatory.

## Open gates

- **G-2** (decision, ITEST-4's packet) blocks every behavior phase. Recorded via `/feature-next-phase --gate bs-07-cvd-self-assessment G-2 approved | "<changes>"`.

## Phase 1 — harness + fixtures + pending gate + smoke

- **Kind:** acceptance-tests · **Target AC:** —
- **Depends on:** ENGINE-2, PROFILE-1, FLOW-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `self_assessment_harness.dart`, `self_assessment_test.dart`, `bs07/pending.dart`
- **Tasks:**
  1. Given/When/Then vocabulary over the flow (open self-assessment, confirm lighting checks, answer intake, report diagnosis, run screening, place/start-over/skip caps, run threshold, advance to result, set type, set severity, confirm calibration, save) + the read-endpoint accessors.
  2. Fixtures (master-plan table): `fakeSpeech`, `fakeHaptics`, `memoryStore` (empty), `intakeAnswers`, `screeningPlates`, `capPool`, `thresholdProbe`, `referenceBand`, `fixedPair`.
  3. Pending gate with all **14** ACs pending, each mapped to its owning behavior phase; the `ac(...)` skip helper + `BS07_RUN_PENDING`.
  4. Runner targets (default + run-pending). A **never-pending smoke test** proving the shells are wired: open the self-assessment, the host + progress indicator + each step's keyed region render, and the read endpoints respond.
- **Exit criteria + grade:** suite green with the 14 tests pending; smoke passes; harness/scaffold tests graded (no vacuous passes — assert the pending map has 14 entries and every key names a real phase; comments claim only what is checked; deterministic polling, no fixed sleeps).

## Phase 2 — AC tests: flow & result group

- **Kind:** acceptance-tests · **Target AC:** AC-1, AC-2, AC-10, AC-11, AC-12, AC-13, AC-14
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · (shares `self_assessment_test.dart` with ITEST-3 → sequential)
- **Tasks:** write the 7 tests per the master-plan catalogue (`TestAC01/02/10/11/12/13/14`), all pending; Givens built only through public flows and asserted before the When; Thens at the step's grain with the catalogue's Rejects/controls. Run the run-pending mode and fill the Red baseline rows. Grade the tests (fresh subagent); fix any below A here.
- **Exit criteria:** suite green (pending skipped); run-pending red baseline recorded; all 7 rows graded A (or *B pending <phase>* with an augmentation row).

## Phase 3 — AC tests: tiers & arrangement group

- **Kind:** acceptance-tests · **Target AC:** AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9
- **Depends on:** ITEST-1 (and ITEST-2 if same file — sequential) · **Blocks:** ITEST-4
- **Tasks:** write the 7 tests (`TestAC03/04/05/06/07/08/09`), all pending, per the catalogue; direction (AC-5) and threshold (AC-9) graded against in-harness references; arrangement tests assert per-item (G4) and only their own AC (G6). Run-pending red baseline; grade; fix below-A here.
- **Exit criteria:** suite green (pending skipped); red baseline recorded; all 7 rows graded A (or *B pending*).

## Phase 4 — test review (G-2)

- **Kind:** test-review · **Target AC:** —
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Preconditions:** both AC-test phases done; the whole-suite grade grid all A (or *B pending <phase>* with an augmentation row) — fix other Bs first.
- **Tasks:** assemble the packet below (per AC: test name, Given checks, When, Then + Rejects, one–two lines each; red-baseline summary; augmentations scheduled + closing phase; grid path + counts; what to look at first). Set this phase `⏸ Awaiting review`, G-2 *awaiting decision*, record the ledger row, commit, and stop with: `/feature-next-phase --gate bs-07-cvd-self-assessment G-2 approved | "<changes>"`.

### Packet  <!-- filled by ITEST-4 -->

## Red baseline  <!-- filled by ITEST-2 / ITEST-3 -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_EstimateLabelledApproximate | | Given precondition (FLOW-5) → Then caveat strings | FLOW-8 | |
| AC-2 | TestAC02_LightingConfirmedBeforeTesting | | Then: still on lighting step after Continue | FLOW-3 | |
| AC-3 | TestAC03_IntakeAnswerToPrior | | Then: prior reflects "Often" | ENGINE-3 | |
| AC-4 | TestAC04_DiagnosisSeedsPrior | | Then: prior.type == deutan | ENGINE-4 | |
| AC-5 | TestAC05_ScreeningPresenceAndDirection | | Then: present + direction | ENGINE-5 | |
| AC-6 | TestAC06_PlaceCapNextPosition | | Then: arranged.last == placed, pool −1 | FLOW-4 | |
| AC-7 | TestAC07_StartOverClearsArrangement | | Then: arranged empty, pool full | FLOW-4 | |
| AC-8 | TestAC08_SkipArrangement | | Then: advanced, arrangementResult absent | FLOW-4 | |
| AC-9 | TestAC09_ThresholdSeverity | | Then: severity on confusion line | ENGINE-6 | |
| AC-10 | TestAC10_AdjustTypeByHand | | Given precondition (FLOW-5) → Then type == protan | FLOW-6 | |
| AC-11 | TestAC11_SeverityBand | | Given precondition (FLOW-5) → Then band per example | ENGINE-7 | |
| AC-12 | TestAC12_SelfCalibration | | Given precondition (FLOW-5) → Then calibratedSeverity | FLOW-7 | |
| AC-13 | TestAC13_SaveConfiguresPipeline | | Given precondition (FLOW-5/ENGINE-7) → Then one profile + pipeline moved | PROFILE-2 | |
| AC-14 | TestAC14_ProgressStepOfTotal | | Then: 2 of 4 | FLOW-2 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC13 | bs-08 (simulation) and bs-10 (daltonization) are not built, so "configures the simulation/daltonization" can only be asserted at the shared profile seam, not behaviourally | **out of scope** — bs-08 / bs-10 (known gap, no bs-07 phase closes it) | behavioural sim/dalt assertions once those features exist | ⬜ Open (known gap) |

No intra-feature test is green-at-baseline (each fails on its Then or on a precondition naming its behavior phase), so no pre-seeded intra-feature augmentation rows are expected; AC-test phases confirm or add rows from the real red baseline.
