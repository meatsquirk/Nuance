# Module ENGINE — assessment domain (+ feature scaffold)

**Status:** In progress — ENGINE-2 (shell) ✅ Done; next ENGINE-3 (behavior, AC-3) blocked by G-2 + FLOW-1
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/onboarding/engine/` (`assessment_engine.dart`, `tier_results.dart`, `cvd_estimate.dart`, `severity_band.dart`); the feature scaffold (branch, baseline, coverage-gate confirmation, `integration_test/bs07/pending.dart`, runner target). Behavior phases also wire a thin controller call in `lib/onboarding/onboarding_controller.dart` (FLOW-owned file — noted per phase; merge-risky with FLOW).
**Depends on:** — · **Blocks:** PROFILE, FLOW, ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 3,619,703 | 13m 16s |
| 2 | shell | — | ✅ Done | 3,709,673 | 9m 29s |
| 3 | behavior | AC-3 | ⬜ Todo | | |
| 4 | behavior | AC-4 | ⬜ Todo | | |
| 5 | behavior | AC-5 | ⬜ Todo | | |
| 6 | behavior | AC-9 | ⬜ Todo | | |
| 7 | behavior | AC-11 | ⬜ Todo | | |

## Interface reconciliation

- **The CVD profile is fixed, not redesigned.** `CvdProfile {CvdType type; double severity 0..1}` (bs-03) is reused unchanged (D-1). The engine's output feeds, but is not, the profile.
- **Estimate vs profile.** `CvdEstimate` (engine/flow-internal) carries the work-in-progress: a prior, a screening direction, an arrangement signal, a threshold severity, and the assembled `type`/`severity`. Saving (PROFILE-2) projects the final estimate onto `CvdProfile`.
- **Direction vs type.** Screening (AC-5) yields a **direction** (red-green | blue-yellow); type (protan/deutan within R-G; tritan within B-Y) is refined by prior + arrangement. The engine keeps direction and type distinct; `projectDichromat`'s confusion line (bs-03) is keyed by `CvdType`.
- **Severity scale.** Engine severity is 0..1 to match `CvdProfile.severity`; the UI's 0..100 slider normalizes at the boundary (D-5, FLOW). Band thresholds live here (ENGINE-7) around the 30/60/90 anchors — **pending G-4**.
- **Scoring is pure.** No widget or controller computes a score; the controller calls `AssessmentEngine` (D-9).

## Open gates

- **G-4** (decision) blocks **ENGINE-7**: band boundaries around 30/60/90 (and the slider→0..1 normalization). Build the band function parameterized on the chosen thresholds.

## Phase 1 — scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1 ✅ spec approved 2026-10-11; G-3 ✅ bs-05/bs-06 merged to main @ cd1c86b 2026-10-11) · **Blocks:** every other phase
- **Files:** `integration_test/bs07/pending.dart`, `integration_test/self_assessment_test.dart` (runner stub); no `lib/` product code
- **Tasks:**
  1. Branch `feat/bs-07-cvd-self-assessment` from `main` **after** bs-05 + bs-06 are merged (G-3). Confirm the merged base has `lib/store/PersistentStore`, `lib/palette/self_assessment_entry_screen.dart`, `lib/app/router.dart toSelfAssessment()` and the pubspec superset (drift etc.).
  2. Baseline: `flutter analyze` clean · `flutter test` green · `flutter test --coverage && dart run tool/coverage_gate.dart main` PASS on the clean tree.
  3. Prove the coverage gate: plant an uncovered line in a throwaway `lib/**` file, confirm the gate FAILs, revert, confirm PASS. Record both in the Result.
  4. Seed `integration_test/bs07/pending.dart` with all 14 ACs mapped to their owning behavior phase, and the `ac(t, "AC-n")`-equivalent skip helper keyed to `--dart-define=BS07_RUN_PENDING=true`.
  5. Add the runner target `integration_test/self_assessment_test.dart` (compiles, zero tests yet).
- **Exit criteria:** gate PASS on clean + FAIL on planted gap, both recorded; pending map seeded with 14 ACs; branch pushed with upstream; no `lib/` product code.

### Result

- **Branch:** `feat/bs-07-cvd-self-assessment` cut from `main` @ `a695e4c` (identical `lib/`+`pubspec` to the planned `cd1c86b` base — the three intervening commits are specs/plan-only: the G-1/G-3 gate decision and the bs-08/bs-09 PLANs; branching from HEAD carries the resolved spec/plan). Work ran in a dedicated worktree `../Nuance-bs07` (the primary checkout holds untracked spec/doc snapshots that collide on checkout — repo-established pattern).
- **Base confirmed:** `lib/store/persistent_store.dart`, `lib/palette/self_assessment_entry_screen.dart`, `lib/app/router.dart toSelfAssessment()`, `tool/coverage_gate.dart` and the pubspec superset (drift/path_provider/printing) all present on the merged base.
- **Baseline:** `flutter analyze` clean (no issues); `flutter test` green — **849** unit tests; `flutter test --coverage && dart run tool/coverage_gate.dart main` → **PASS** (`no touched lib/**.dart files vs "main" — nothing to gate`).
- **Coverage-gate proof:** planted a throwaway `lib/scaffold_coverage_probe.dart` with one never-taken branch + a test covering only the other branch → gate **FAIL** (exit 1): `lib/scaffold_coverage_probe.dart: 2/3 lines covered — uncovered lines: 7`. Removed both throwaway files, re-ran coverage → gate **PASS** (exit 0). No throwaway file committed; no `lib/` product code remains.
- **Pending gate seeded:** `integration_test/bs07/pending.dart` maps all **14** ACs to their owning behaviour phase (AC-1→FLOW-8, 2→FLOW-3, 3→ENGINE-3, 4→ENGINE-4, 5→ENGINE-5, 6/7/8→FLOW-4, 9→ENGINE-6, 10→FLOW-6, 11→ENGINE-7, 12→FLOW-7, 13→PROFILE-2, 14→FLOW-2), keyed to `--dart-define=BS07_RUN_PENDING=true` / `BS07_RUN_PENDING=1`. Enabler FLOW-5 excluded (owns no AC).
- **Runner target:** `integration_test/self_assessment_test.dart` compiles and runs on host; 3 scaffold-guard tests green (pending map is exactly the 14 ACs; every owner is a real behaviour phase; each pending AC is skipped by default and runs when forced). No AC tests and no smoke test yet (stage 3).
- **Gates:** unit ✅ (849) · coverage ✅ (PASS clean + FAIL-on-gap proven) · no acceptance/grade gate (scaffold kind). **Fix passes: 0/3.**
- **Tokens / Time:** 3,619,703 · 13m 16s.

### Checkpoint / Handoff

- **Frozen for next phases:** pending-gate API in `integration_test/bs07/pending.dart` — `pendingACs` (owner map), `behaviorPhases` (set), `runPending`, `pendingSkipReason(acId, {forceRunPending})`, `acTestWidgets(acId, description, body)`. Behaviour phases un-pend by **deleting their AC row** in `pendingACs`; the scaffold guard's `expected` set in `self_assessment_test.dart` must shrink to match (keep it non-vacuous).
- **Verification commands** (run from the worktree with `flutter` on PATH — `/Users/matthew.quirk/development/flutter/bin`):
  - analyze: `flutter analyze`
  - unit + coverage gate: `flutter test --coverage && dart run tool/coverage_gate.dart main`
  - acceptance suite (later phases): `flutter test integration_test/self_assessment_test.dart -d <booted-udid>`; add `--dart-define=BS07_RUN_PENDING=true` for the red-baseline / un-pend run.
- **Known flakes carried:** (1) coverage gate may record a const-folded ctor line as uncovered — re-run `flutter test --coverage` once; green on re-run ⇒ ignore. (2) the acceptance suite needs `-d <booted-udid>`; without it it runs zero tests and still exits 0 (false green). Neither affected this scaffold (the guard group is plain host `test()`).
- **Next phase ENGINE-2 (shell):** add `lib/onboarding/engine/` domain types + `AssessmentEngine` interface + trivial shell impl, 100% line coverage on the new files, existing suite unchanged, no behaviour. Runs ∥ PROFILE-1. Behaviour stage still blocked by G-2 (acceptance tests, decided at ITEST-4).

## Phase 2 — shell: assessment domain types + engine interface

- **Kind:** shell
- **Target AC:** —
- **Depends on:** ENGINE-1 · **Blocks:** FLOW-1, ITEST-1, ENGINE-3..7
- **Files:** `lib/onboarding/engine/tier_results.dart`, `cvd_estimate.dart`, `severity_band.dart`, `assessment_engine.dart`
- **Tasks:**
  1. Types: `IntakeAnswer`/`StartingPrior` (a bias toward a type/direction), `ScreeningResult {bool present; ScreeningDirection direction}` with `enum ScreeningDirection {redGreen, blueYellow}`, `ArrangementResult`, `ThresholdResult {double severity}`, `CvdEstimate {CvdType type; double severity; StartingPrior prior; ScreeningResult? screening; ThresholdResult? threshold; bool arrangementPresent}`, `enum SeverityBand {mild, moderate, strong}`.
  2. `abstract interface class AssessmentEngine` with methods: `recordIntake(...)→StartingPrior`, `seedFromDiagnosis(CvdType)→StartingPrior`, `scoreScreening(...)→ScreeningResult`, `scoreThreshold(...)→ThresholdResult`, `assemble({prior, screening, arrangement, threshold})→CvdEstimate`, `band(double severity)→SeverityBand`.
  3. A shell implementation whose methods return trivial/default values (keep the existing suite green; **no** real scoring). Value equality + 100% line coverage on the new files (every ctor/branch exercised by unit tests).
- **Exit criteria:** unit gate green; 100% line coverage on the new files; existing suite unchanged; no behavior.

### Result

- **Landed:** `lib/onboarding/engine/` with the four shell files. `tier_results.dart` — `enum ScreeningDirection {redGreen, blueYellow}`, `IntakeAnswer {questionId, value}`, `StartingPrior {CvdType? type, ScreeningDirection? direction, double weight=0}` (+ `const none`), `PlateResponse {axis, correct}`, `ScreeningResult {present, direction}`, `ArrangementResult {present}`, `ThresholdProbe {contrast, detected}`, `ThresholdResult {severity}`. `cvd_estimate.dart` — `CvdEstimate {type, severity, prior, screening?, threshold?, arrangementPresent=false}`. `severity_band.dart` — `enum SeverityBand {mild, moderate, strong}` + `label` getter (AC-11 vocabulary only; boundaries deferred to ENGINE-7/G-4). `assessment_engine.dart` — `abstract interface class AssessmentEngine` + `ShellAssessmentEngine` (trivial defaults, no scoring). All value types carry `==`/`hashCode`/`toString`.
- **Interface decisions (frozen):** screening input is `List<PlateResponse>` (per-plate axis+correctness), threshold input is `List<ThresholdProbe>` (contrast+detected) — `PlateResponse`/`ThresholdProbe` are new input types not in the original type list (the method inputs were `...`), chosen so ENGINE-5/6 score without changing the interface. `StartingPrior` carries an optional type **and** direction + a 0..1 weight (D — direction vs type). Severity 0..1 throughout.
- **Gates:** unit ✅ **912** (849 baseline unchanged + 63 new); coverage ✅ **100%** on all 4 touched files (gate PASS). No acceptance/grade gate (shell kind). No `lib/` wiring (AppDependencies left to PROFILE-1, controller to FLOW-1).
- **Coverage note:** an enum-only `severity_band.dart` emits no executable lines → absent from `lcov.info` → gate FAIL ("NO COVERAGE DATA"). Fixed by the `label` getter (the repo's established enum-file pattern, cf. `lib/capture/capture_accuracy.dart`), which is tested vocabulary, not the gated band logic.
- **Fix passes:** 1/3 (the `severity_band` coverage fix above).
- **Tokens / Time:** 3,709,673 · 9m 29s.

### Checkpoint / Handoff

- **Frozen interfaces** (behavior phases implement against these, don't reshape them):
  - `AssessmentEngine` in `lib/onboarding/engine/assessment_engine.dart`: `recordIntake(List<IntakeAnswer>)→StartingPrior` (ENGINE-3, AC-3), `seedFromDiagnosis(CvdType)→StartingPrior` (ENGINE-4, AC-4), `scoreScreening(List<PlateResponse>)→ScreeningResult` (ENGINE-5, AC-5), `scoreThreshold(List<ThresholdProbe>)→ThresholdResult` (ENGINE-6, AC-9), `assemble({required StartingPrior prior, ScreeningResult? screening, ArrangementResult? arrangement, ThresholdResult? threshold})→CvdEstimate` (FLOW-5), `band(double severity)→SeverityBand` (ENGINE-7, AC-11, pending G-4).
  - `ShellAssessmentEngine` is the trivial stand-in: `recordIntake`/`seedFromDiagnosis`→`StartingPrior.none`, `scoreScreening`→absent/red-green, `scoreThreshold`→severity 0, `assemble`→`CvdType.deutan`/severity 0 (passes prior + tier results through; `arrangementPresent = arrangement?.present ?? false`), `band`→`SeverityBand.mild`. Each behavior phase replaces one method with real scoring and keeps the rest trivial.
  - `SeverityBand.label` returns the band name; the severity→band mapping is `band()`, pinned at ENGINE-7 once G-4 fixes the 30/60/90 boundaries.
- **Verification commands** (unchanged from ENGINE-1, run from the worktree with `/Users/matthew.quirk/development/flutter/bin` on PATH): `flutter analyze`; `flutter test --coverage && dart run tool/coverage_gate.dart main`.
- **Next:** ENGINE-2's files unblock **FLOW-1** (shell) and **ITEST-1** once PROFILE-1 is also done; **PROFILE-1** (shell) is startable in parallel but needs **G-4** decided first. Behavior ENGINE-3..7 remain blocked by G-2 (acceptance tests, ITEST-4) and the shells.

## Phase 3 — AC-3: an intake answer contributes to the starting prior

- **Kind:** behavior · **Target AC:** AC-3 (full)
- **Depends on:** ITEST-4 (G-2), ENGINE-2 · **Blocks:** FLOW-5
- **Files:** `lib/onboarding/engine/assessment_engine.dart`; thin wiring in `lib/onboarding/onboarding_controller.dart` (FLOW-owned — merge-risky) so the intake step records the answer; `OnboardingReadEndpoint` exposes the prior.
- **Tasks:** implement `recordIntake` so "Often" to the reds/browns/greens question moves the prior toward red-green; wire the intake step's answer action to call it; expose the prior via the read endpoint.
- **Exit criteria + Acceptance gate:** un-pend AC-3; `self_assessment_test.dart` green (`TestAC03_*` + all earlier un-pended ACs), later ACs still pending; unit gate + 100% coverage on touched files; grade gate A.
- **Augments:** none.

## Phase 4 — AC-4: a prior clinical diagnosis entered at intake seeds the prior

- **Kind:** behavior · **Target AC:** AC-4 (full)
- **Depends on:** ITEST-4, ENGINE-2 (and ENGINE-3's controller intake wiring if it lands first — rebase) · **Blocks:** FLOW-5
- **Files:** `lib/onboarding/engine/assessment_engine.dart`; intake diagnosis path in `onboarding_controller.dart`.
- **Tasks:** implement `seedFromDiagnosis` so a reported deutan diagnosis seeds `prior.type == deutan`; wire the intake diagnosis control; read endpoint exposes the seeded prior.
- **Exit criteria + Acceptance gate:** un-pend AC-4; suite green; coverage 100% touched; grade A.
- **Augments:** none.

## Phase 5 — AC-5: screening yields presence and direction

- **Kind:** behavior · **Target AC:** AC-5 (full)
- **Depends on:** ITEST-4, ENGINE-2 · **Blocks:** FLOW-5
- **Files:** `lib/onboarding/engine/assessment_engine.dart`; screening step wiring in `onboarding_controller.dart`.
- **Tasks:** implement `scoreScreening` over the `screeningPlates` fixture → `present` + `direction` (redGreen | blueYellow); wire the screening step; expose the result. Graded against the harness direction reference.
- **Exit criteria + Acceptance gate:** un-pend AC-5; suite green; coverage 100% touched; grade A (distinguishes R-G/B-Y and present/absent — see catalogue controls).
- **Augments:** none.

## Phase 6 — AC-9: threshold probing yields a severity

- **Kind:** behavior · **Target AC:** AC-9 (full)
- **Depends on:** ITEST-4, ENGINE-2 · **Blocks:** FLOW-5
- **Files:** `lib/onboarding/engine/assessment_engine.dart`; threshold step wiring in `onboarding_controller.dart`.
- **Tasks:** implement `scoreThreshold` so the adaptive probe yields a `severity` (0..1) **along the confusion line** of the current type/direction; harder-threshold fixture → higher severity (monotonic). Wire the threshold step; expose the severity.
- **Exit criteria + Acceptance gate:** un-pend AC-9; suite green; coverage 100% touched; grade A (severity tied to the confusion line, monotonic control).
- **Augments:** none.

## Phase 7 — AC-11: the severity value sets a plain-language band

- **Kind:** behavior · **Target AC:** AC-11 (full; Scenario Outline over 30/60/90)
- **Depends on:** ITEST-4, ENGINE-2, FLOW-5 (result step reachable), **G-4** (band boundaries) · **Blocks:** PROFILE-2 (the "moderate" Given)
- **Files:** `lib/onboarding/engine/severity_band.dart` (the `band` function); result-step wiring in FLOW to display the band for the slider value.
- **Tasks:** implement `band(severity)` so 30→mild, 60→moderate, 90→strong (on the 0..100 slider; or 0.30/0.60/0.90 on 0..1) with monotonic boundaries (G-4); the result step shows the band text for the current severity. Unit-test each band region incl. boundaries.
- **Exit criteria + Acceptance gate:** un-pend AC-11; suite green over the 3 examples; coverage 100% touched; grade A (graded vs `referenceBand`; three distinct outputs).
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
