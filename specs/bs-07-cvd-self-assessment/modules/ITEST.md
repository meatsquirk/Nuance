# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-2 (AC tests: flow & result group) ✅ Done; next ITEST-3 (AC tests: tiers & arrangement group)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/self_assessment_harness.dart`, `integration_test/self_assessment_test.dart`, `integration_test/bs07/pending.dart`; the grade grid `behavior-test-completeness-bs-07-cvd-self-assessment.md`.
**Depends on:** every shell phase (ENGINE-2, PROFILE-1, FLOW-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness + smoke) | ✅ Done | 12,779,960 | 1h 30m |
| 2 | acceptance-tests | AC-1,2,10,11,12,13,14 | ✅ Done | 6,494,040 | 27m 23s |
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

### Result — ✅ Done (ITEST-1, harness + smoke + fixtures)

- **Landed:**
  - `integration_test/self_assessment_harness.dart` — Given/When/Then vocabulary + fixtures + read accessors. `givenSelfAssessment(tester, {profile})` assembles the real app via `buildApp` (fakes only `Speech`/`Haptics` + an empty `InMemoryPersistentStore` behind the production `CvdProfileStore`) and reaches onboarding the production way: `unawaited(navigator.push(router.toSelfAssessment()))` under the real `AppScope` (the route the bs-06 vision-profile card pushes; there is no `buildApp` home-entry for onboarding). `SelfAssessmentHarness` reads live state via the `OnboardingReadEndpoint`/`CvdProfileReadEndpoint`; `when…` methods drive the real keyed/labelled controls (inert in the shell, live per their behaviour phase). Re-exports the pending gate + fakes.
  - Fixtures: `intakeOften`/`intakeNever` + `intakeAnswers` (AC-3/4); `screeningPlatesRedGreen`/`BlueYellow`/`None` (AC-5); `capPool` (AC-6/7/8); `thresholdProbesMild`/`Strong` (AC-9); `referenceBand` (independent D-5 band map, AC-11); `fixedPair` (AC-13 — grounded against the shipped `DichromatConfusionCheck`: confusable at deutan sev 1.0, not at 0.6; normal ΔE00 ≈ 33.9).
  - `integration_test/self_assessment_test.dart` — `IntegrationTestWidgetsFlutterBinding`, a never-pending **smoke** test (routes to the host; every keyed region renders; both endpoints respond with the default `OnboardingState` + "Step 1 of 4"; profile count 0), 6 **fixture guards**, and the 3 ENGINE-1 scaffold guards.
- **Gate:** `flutter analyze` clean · bs-07 acceptance suite **10 passed** (smoke + 6 fixture guards + 3 scaffold guards) on the booted sim · unit **957 passed** (unchanged — no `lib/` touched) · coverage gate **N/A** (no `lib/` source touched; the harness is test code). No AC un-pended (all 14 still pending). **Grade A** (fresh-subagent review; the one B — a vacuous `.where().every()` in the screening guard — fixed in-phase by asserting subset counts). **Fix passes: 2/3** (1: `await push` hang → `unawaited`+pump; 2: screening-guard vacuous pass).
- **Tokens / time:** 12,779,960 · 1h 30m.

### Checkpoint / Handoff

- **Frozen for ITEST-2/3:** import `self_assessment_harness.dart` only (it re-exports the pending gate + fakes). Open with `givenSelfAssessment(tester, {profile})`; read Thens via `SelfAssessmentHarness` getters (`state`, `stepIndex`/`stepTotal`, `prior`, `screening`, `arrangementPool`/`arrangedCaps`/`arrangementSkipped`, `threshold`, `estimate`, `calibratedSeverity`, `caveatShown`, `saved`, `profileCount`, `savedProfile`, `progressText`); drive Whens via `whenConfirmLightingCheck`/`whenContinue`/`whenAnswerIntake`/`whenReportDiagnosis`/`whenReadPlate`/`whenStartOver`/`whenSkipArrangement`/`whenProbe`/`whenAdjustType`/`whenSetSeverity`/`whenSave`.
- **Verification commands** (worktree `../Nuance-bs07`, `export PATH="$PATH:/Users/matthew.quirk/development/flutter/bin"`): `flutter analyze integration_test/` · `flutter test test/` (unit) · device suite `flutter test integration_test/self_assessment_test.dart -d <booted-udid>` (a booted sim is **mandatory** — no `-d`/no device ⇒ 0 tests, exit 0; run through `coord.sh with-lock` for the shared device lane, wrapping `bash -c "cd ../Nuance-bs07 && …"` so the lock stays in the main repo). Run-pending / red baseline (ITEST-2/3): add `--dart-define=BS07_RUN_PENDING=true`.
- **For ITEST-2 (next, AC-1,2,10,11,12,13,14):** register one *pending* `acTestWidgets` per AC in `self_assessment_test.dart` (shares the file with ITEST-3 → sequential); build Givens through public flows and assert them before the When; result-step ACs (AC-1/10/11/12/13) fail at baseline on a precondition naming **FLOW-5** (estimate assembly) — assert it explicitly rather than tap into a not-yet-built sub-control. Fill the Red baseline rows from the run-pending pass; grade in a fresh subagent.
- **Known gaps:** no AC test exists yet (ITEST-2/3). Placing a *specific* cap (AC-6), reporting a *specific* diagnosis type (AC-4) and the type override choices (AC-10) need sub-controls their behaviour phases (FLOW-4 / ENGINE-4 / FLOW-6) key — the harness drives only what the shell exposes, so ITEST-2/3 assert a precondition until then. `whenSetSeverity` taps along the slider track (approximate until FLOW-7 pins the control).

## Phase 2 — AC tests: flow & result group

- **Kind:** acceptance-tests · **Target AC:** AC-1, AC-2, AC-10, AC-11, AC-12, AC-13, AC-14
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · (shares `self_assessment_test.dart` with ITEST-3 → sequential)
- **Tasks:** write the 7 tests per the master-plan catalogue (`TestAC01/02/10/11/12/13/14`), all pending; Givens built only through public flows and asserted before the When; Thens at the step's grain with the catalogue's Rejects/controls. Run the run-pending mode and fill the Red baseline rows. Grade the tests (fresh subagent); fix any below A here.
- **Exit criteria:** suite green (pending skipped); run-pending red baseline recorded; all 7 rows graded A (or *B pending <phase>* with an augmentation row).

### Result — ✅ Done (ITEST-2, AC tests: flow & result group)

- **Landed:** 7 *pending* `acTestWidgets` in `self_assessment_test.dart` (new `group('bs-07 AC tests — flow & result group (ITEST-2)')`) for AC-1, 2, 10, 11, 12, 13, 14, each registered through the pending gate (`acTestWidgets('AC-n', …)`) so default runs skip them. Givens built only through the public UI surface and asserted before the When. The result-step ACs (AC-1/10/11/12/13) assert the `estimate != null` precondition (naming FLOW-5) rather than tap a not-yet-built advance-to-result control (per the ITEST-1 handoff). AC-11/AC-12 read the Slider's **actual** value as source of truth (robust to the tap-along-track approximation): AC-11 grades the product band against the independent `referenceBand`; AC-12 asserts `calibratedSeverity == slider/100` with a different-value control. AC-13 asserts the save at the store seam (`profileCount==1`, `savedProfile {deutan, moderate}`) and the confusion reconfiguration at the saved-profile value seam (`DichromatConfusionCheck().confusable(fixedPair, saved)` flips vs the injected deutan@1.0 default). AC-14 reconciles the catalogue's 1-based "step 2" with the shell/smoke-frozen **0-based** `stepIndex` (index 0 → "Step 1 of 4"): asserts `stepIndex==1` + `progressText=='Step 2 of 4'` with a control advancing to index 2 / "Step 3 of 4".
- **Gate:** `flutter analyze integration_test/` clean · default run (pending skipped) **10 passed / 7 skipped** on the booted sim (iPhone 17) · run-pending red baseline **+10 / −7** — every AC test fails cleanly (no panic/compile/hit-test error; the inert-control taps in AC-2/AC-14 are no-ops, confirmed). Unit suite unchanged (no `lib/` touched). Coverage gate **N/A** (test-only phase, no `lib/` source). **Fix passes: 0/3** (first full run produced the clean red baseline).
- **Grades (fresh independent subagent, G1–G6):** 5 A (AC-1, 2, 11, 12, 14) + 2 *B pending* (AC-10 → FLOW-6, AC-13 → PROFILE-2); both are limited only by behaviour not yet built (see *Test augmentations*), not by a fixable test defect. Grid: [behavior-test-completeness-bs-07-cvd-self-assessment.md](../behavior-test-completeness-bs-07-cvd-self-assessment.md).
- **Red baseline / augmentations:** tables below.
- **Tokens / time:** 6,494,040 · 27m 23s.

### Checkpoint / Handoff

- **Frozen for ITEST-3:** `self_assessment_test.dart` now holds the smoke test, the `bs-07 fixtures` group, the ITEST-2 AC group, and the pending-gate scaffold group. ITEST-3 **shares this file** (→ sequential, not parallel): re-read it, then append a **second** `group('bs-07 AC tests — tiers & arrangement group (ITEST-3)')` for AC-3,4,5,6,7,8,9 before the pending-gate scaffold group. Import only `self_assessment_harness.dart` (re-exports the pending gate + fakes). Do not touch the ITEST-2 group.
- **Patterns to reuse:** build Givens through the public `when…` drivers; assert the Given before the When; grade scoring ACs (AC-5 direction, AC-9 severity) against the harness's **independent** fixture axes/references, never the product function; the arrangement ACs (AC-6/7/8) assert per-item (G4) and only their own AC (G6). For a Given that needs unbuilt behaviour, assert an explicit precondition naming the owning phase (as AC-1/10/11/12/13 do with FLOW-5) rather than tapping an inert control. The tier ACs (AC-3/4/5/9) fail at baseline on their Then (the shell engine returns trivial defaults — `recordIntake`→none, `scoreScreening`→present:false, `scoreThreshold`→severity 0); AC-6/7/8 need FLOW-4 sub-controls (`placeCap` has no public cap-selection control in the shell yet) → likely *B pending FLOW-4* with an augmentation row, like AC-10 here.
- **Verification commands** (worktree `../Nuance-bs07`, `export PATH="$PATH:/Users/matthew.quirk/development/flutter/bin"`): `flutter analyze integration_test/`; default `flutter test integration_test/self_assessment_test.dart -d <booted-udid>` (pending skipped — **`-d` mandatory**, no device ⇒ 0 tests exit 0); run-pending red baseline add `--dart-define=BS07_RUN_PENDING=true`. Shared device lane → run through `coord.sh with-lock bs-07 ITEST-3 --wait 600 -- bash -c "cd ../Nuance-bs07 && …"` (FNP_COORD_REPO=/Users/matthew.quirk/Nuance). The run-pending pass can exceed a 120s foreground timeout on first build — redirect to a file (`> log 2>&1`) rather than piping through `tail`.
- **Known gaps:** AC-10 and AC-13 carry open augmentation rows (FLOW-6 / PROFILE-2). The TestAC13 sim/dalt gap (bs-08/bs-10) stays out of scope.

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
| AC-1 | TestAC01_EstimateLabelledApproximate (`AC-1`) | FAIL | Given precondition `estimate != null` (FLOW-5) | FLOW-8 | A |
| AC-2 | TestAC02_LightingConfirmedBeforeTesting (`AC-2`) | FAIL | Control Then `lightingConfirmed` after confirming all three (FLOW-3); primary "unconfirmed Continue stays" passes at baseline (inert) | FLOW-3 | A |
| AC-3 | TestAC03_IntakeAnswerToPrior | | Then: prior reflects "Often" | ENGINE-3 | |
| AC-4 | TestAC04_DiagnosisSeedsPrior | | Then: prior.type == deutan | ENGINE-4 | |
| AC-5 | TestAC05_ScreeningPresenceAndDirection | | Then: present + direction | ENGINE-5 | |
| AC-6 | TestAC06_PlaceCapNextPosition | | Then: arranged.last == placed, pool −1 | FLOW-4 | |
| AC-7 | TestAC07_StartOverClearsArrangement | | Then: arranged empty, pool full | FLOW-4 | |
| AC-8 | TestAC08_SkipArrangement | | Then: advanced, arrangementResult absent | FLOW-4 | |
| AC-9 | TestAC09_ThresholdSeverity | | Then: severity on confusion line | ENGINE-6 | |
| AC-10 | TestAC10_AdjustTypeByHand (`AC-10`) | FAIL | Given precondition `estimate != null` (FLOW-5) | FLOW-6 | **B pending FLOW-6** |
| AC-11 | TestAC11_SeverityBand (`AC-11`) | FAIL | Given precondition `estimate != null` (FLOW-5) | ENGINE-7 | A |
| AC-12 | TestAC12_SelfCalibration (`AC-12`) | FAIL | Given precondition `estimate != null` (FLOW-5) | FLOW-7 | A |
| AC-13 | TestAC13_SaveConfiguresPipeline (`AC-13`) | FAIL | Given precondition `estimate != null` (FLOW-5) | PROFILE-2 | **B pending PROFILE-2** |
| AC-14 | TestAC14_ProgressStepOfTotal (`AC-14`) | FAIL | Then `stepIndex == 1` (Actual 0) — second step not reached | FLOW-2 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC10 (`AC-10`) | the harness `whenAdjustType()` only *opens* the type control — it carries no type argument, so the test can't select protan specifically among protan/deutan/tritan; a bare tap only discriminates against a 2-way toggle, not a 3-way picker (G4/G5) | **FLOW-6** | FLOW-6 wires the by-hand type picker and gives the driver a type argument (tap the protan choice) so `estimate!.type == protan` rejects selecting the wrong type, not merely "stays deutan" | ⬜ Open (added ITEST-2) |
| TestAC13 (`AC-13`) | the save reconfiguration is asserted only at the saved-profile **value** seam (`confusable(fixedPair, savedProfile)` flips vs the injected default); a save that persists the profile but never rewires the **live** `AppDependencies.cvdProfile` still passes, so the Reject "leaves the pipeline on the default" is uncovered (G4/G5) | **PROFILE-2** | PROFILE-2 asserts the **live** `AppDependencies.cvdProfile` (or the live confusion pipeline on `fixedPair`) reflects the saved profile after save | ⬜ Open (added ITEST-2) |
| TestAC13 (`AC-13`) | bs-08 (simulation) and bs-10 (daltonization) are not built, so "configures the simulation/daltonization" can only be asserted at the shared profile seam, not behaviourally | **out of scope** — bs-08 / bs-10 (known gap, no bs-07 phase closes it) | behavioural sim/dalt assertions once those features exist | ⬜ Open (known gap) |

AC-10 and AC-13 are *B pending* (limited by behaviour not yet built, per the rows above); the other five ITEST-2 tests graded A. No ITEST-2 test is green-at-baseline (each fails on its Then or on a precondition naming its behaviour/enabler phase).
