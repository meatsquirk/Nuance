# Module ENGINE — assessment domain (+ feature scaffold)

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/onboarding/engine/` (`assessment_engine.dart`, `tier_results.dart`, `cvd_estimate.dart`, `severity_band.dart`); the feature scaffold (branch, baseline, coverage-gate confirmation, `integration_test/bs07/pending.dart`, runner target). Behavior phases also wire a thin controller call in `lib/onboarding/onboarding_controller.dart` (FLOW-owned file — noted per phase; merge-risky with FLOW).
**Depends on:** — · **Blocks:** PROFILE, FLOW, ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ⬜ Next | | |
| 2 | shell | — | ⬜ Todo | | |
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
