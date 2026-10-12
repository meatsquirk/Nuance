# Module FLOW — onboarding controller, screens, flow

**Status:** In progress — FLOW-1 (shell) ✅ Done; next FLOW-2 (AC-14) blocked by G-2 + G-5
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/onboarding/onboarding_controller.dart`, `onboarding_state.dart`, `onboarding_read_endpoint.dart`, `onboarding_steps.dart`; `lib/onboarding/screens/` (host + lighting, intake, screening, arrangement, threshold, result step widgets with keyed regions); route wiring in `lib/app/router.dart` + `lib/palette/self_assessment_entry_screen.dart` (replaced). Behavior phases in ENGINE/PROFILE add thin controller calls here (merge-risky — rebase before editing).
**Depends on:** ENGINE (estimate types + scoring), PROFILE (save seam) · **Blocks:** ITEST, SIGNOFF

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | | |
| 2 | behavior | AC-14 | ⬜ Todo | | |
| 3 | behavior | AC-2 | ⬜ Todo | | |
| 4 | behavior | AC-6, AC-7, AC-8 | ⬜ Todo | | |
| 5 | behavior | — (enabler) | ⬜ Todo | | |
| 6 | behavior | AC-10 | ⬜ Todo | | |
| 7 | behavior | AC-12 | ⬜ Todo | | |
| 8 | behavior | AC-1 | ⬜ Todo | | |

## Interface reconciliation

- **Replace, don't re-route.** bs-07 replaces `SelfAssessmentEntryScreen` behind the existing `AppRouter.toSelfAssessment()`; keep the stable anchor `ValueKey('self-assessment-entry-screen')` (bs-06's vision-profile card nav and its acceptance test observe it) and add it to the new host so the bs-06 suite stays green.
- **Four steps vs five tiers (D-4, G-5).** The progress model is `onboarding_steps.dart` — a `List<OnboardingStep>` with a current index. The **count** of top-level steps is what AC-14 asserts ("four"). Proposed: steps = [Setup/lighting, Intake, Vision tests, Result], with screening (Tier 2) and threshold (Tier 4) nested inside the Vision-tests step alongside the arrangement. FLOW-1 builds the list generically; the concrete four are fixed at FLOW-2 once **G-5** resolves.
- **Read endpoint is the Then surface.** `OnboardingReadEndpoint` exposes: `stepIndex`, `stepTotal`, lighting flags + `testingStarted`, `prior`, `screening`, arrangement `pool`/`arranged`, `threshold`, `estimate` (type/severity), `band`, `caveatShown`, `calibratedSeverity`. Keyed widgets render the same state for finder-based assertions.
- **Estimate assembly is the barrier (FLOW-5).** Result-step ACs (AC-1/10/11/12 and PROFILE-2's AC-13) need "on the result step with an estimate" as a Given. FLOW-5 (enabler) makes the controller assemble `CvdEstimate` from whatever tier results exist and advance to the result step; before it, those tests fail on a precondition naming FLOW-5.
- **Severity normalization (D-5).** The result slider is 0..100; the controller stores `severity = value/100` on the estimate and (at save) the profile.

## Open gates

- **G-5** (decision) blocks **FLOW-2**: which tiers are the four counted steps (proposed D-4).
- **G-2** (ITEST-4) blocks every behavior phase here.

## Phase 1 — shell: controller, state, read endpoint, screens, route

- **Kind:** shell
- **Target AC:** —
- **Depends on:** ENGINE-2, PROFILE-1 · **Blocks:** ITEST-1, FLOW-2..8
- **Files:** `lib/onboarding/onboarding_controller.dart`, `onboarding_state.dart`, `onboarding_read_endpoint.dart`, `onboarding_steps.dart`, `lib/onboarding/screens/*`, `lib/app/router.dart`, `lib/palette/self_assessment_entry_screen.dart`
- **Tasks:**
  1. `OnboardingState` (step index, lighting flags, prior, screening, arrangement pool/arranged, threshold, estimate, calibratedSeverity, saved) and `OnboardingController` with **stub** methods (no behaviour): `confirmLightingCheck`, `tryContinue`, `answerIntake`, `reportDiagnosis`, `scoreScreening`, `placeCap`, `startOver`, `skipArrangement`, `scoreThreshold`, `advanceToResult`, `setType`, `setSeverity`, `confirmCalibration`, `save`.
  2. `OnboardingReadEndpoint` surfacing the state fields above.
  3. Screens under `lib/onboarding/screens/`: a host that renders the current step + a progress indicator, and keyed step widgets — lighting (E36 checks + E43 continue), intake (E37), screening, arrangement (E38 pool/placed + E39 start-over + E43 skip/continue), threshold, result (E40 type control + E41 slider + save E43 + caveat area). All render state; **no wired behaviour** (controls present but inert / call stubs).
  4. Replace `SelfAssessmentEntryScreen` to build the host behind `toSelfAssessment()`, preserving `ValueKey('self-assessment-entry-screen')`.
- **Exit criteria:** unit gate green; 100% coverage on touched files; existing suites (incl. bs-06 palette suite) green; the host + all keyed regions render; ITEST-1's smoke test can drive the flow end-to-end against stubs.

## Phase 2 — AC-14: the current step is shown against the total

- **Kind:** behavior · **Target AC:** AC-14 (full)
- **Depends on:** ITEST-4 (G-2), FLOW-1, **G-5** (the four steps) · **Blocks:** —
- **Files:** `onboarding_steps.dart` (fix the four steps), `onboarding_controller.dart` (step advance), progress widget in `screens/`
- **Tasks:** fix the four top-level steps (per G-5); implement step advance; the progress indicator renders "N of 4"; read endpoint `stepIndex`/`stepTotal`.
- **Acceptance gate:** un-pend AC-14; suite green; coverage 100% touched; grade A (control: advancing again reads 3 of 4).
- **Augments:** none.

## Phase 3 — AC-2: lighting setup confirmed before testing begins

- **Kind:** behavior · **Target AC:** AC-2 (full)
- **Depends on:** ITEST-4, FLOW-1 · **Blocks:** —
- **Files:** `onboarding_controller.dart` (`confirmLightingCheck`, gated `tryContinue`), lighting screen in `screens/`
- **Tasks:** track the three checks (brightness, night-light off, daylight); `tryContinue` advances only when all three are confirmed; read endpoint `testingStarted` + flags; a negative-Then settle point (the continue event is processed, then assert still on the lighting step).
- **Acceptance gate:** un-pend AC-2; suite green; coverage 100% touched; grade A (control: all confirmed → advances; G3 settle for the negative Then).
- **Augments:** none.

## Phase 4 — AC-6/7/8: arrangement place, start-over, skip

- **Kind:** behavior · **Target AC:** AC-6, AC-7, AC-8 (slice — one arrangement widget + state machine)
- **Depends on:** ITEST-4, FLOW-1 · **Blocks:** FLOW-5
- **Files:** `onboarding_controller.dart` (`placeCap`, `startOver`, `skipArrangement`, arrangement state), arrangement screen (E38/E39/E43)
- **Tasks:** `placeCap` appends to `arranged` (next position) and removes from `pool`; `startOver` returns all caps to `pool` and empties `arranged`; `skipArrangement` advances with `arrangementResult` absent. Read endpoint exposes `pool`/`arranged`/arrangement-present.
- **Acceptance gate:** un-pend AC-6, AC-7, AC-8; suite green (all three tests); coverage 100% touched; grade A each (G4 per-item assertions; G6 — each test asserts only its own AC).
- **Augments:** none.

## Phase 5 — enabler: assemble estimate + advance to result step

- **Kind:** behavior · **Target AC:** — (enabler: makes "on the result step with an estimate" real for AC-1/10/11/12/13)
- **Depends on:** ITEST-4, ENGINE-3, ENGINE-4, ENGINE-5, ENGINE-6, FLOW-4 · **Blocks:** ENGINE-7, FLOW-6, FLOW-7, FLOW-8, PROFILE-2
- **Files:** `onboarding_controller.dart` (`advanceToResult`, estimate assembly via `AssessmentEngine.assemble`), result screen render of type/severity
- **Tasks:** assemble `CvdEstimate` from the tier results present (prior + screening direction + optional arrangement + optional threshold) via the engine; advance to the result step; the result shows the estimated type + severity; read endpoint `estimate`.
- **Acceptance gate (enabler):** the suite stays green; the **precondition failures** the result-step tests show in run-pending (naming FLOW-5) **disappear** — those tests now reach the result step and fail on their own Then instead. Coverage 100% touched; grade gate on any test touched.
- **Augments:** none (it enables, it does not strengthen an assertion).

## Phase 6 — AC-10: the painter adjusts the estimated type by hand

- **Kind:** behavior · **Target AC:** AC-10 (full)
- **Depends on:** ITEST-4, FLOW-5 · **Blocks:** —
- **Files:** `onboarding_controller.dart` (`setType`), result screen type control (E40)
- **Tasks:** `setType(protan)` overrides the estimate's type regardless of the computed value; read endpoint `estimate.type`.
- **Acceptance gate:** un-pend AC-10; suite green; coverage 100% touched; grade A (control: set back to deutan).
- **Augments:** none.

## Phase 7 — AC-12: severity slider doubles as subjective self-calibration

- **Kind:** behavior · **Target AC:** AC-12 (full)
- **Depends on:** ITEST-4, FLOW-5 · **Blocks:** —
- **Files:** `onboarding_controller.dart` (`setSeverity`, `confirmCalibration`), result screen slider + simulated/original pair (E41)
- **Tasks:** show a simulated-vs-original pair that re-renders with the slider; `confirmCalibration` keeps the chosen severity as `calibratedSeverity` (= the value that becomes the profile severity, D-6); read endpoint `calibratedSeverity`.
- **Acceptance gate:** un-pend AC-12; suite green; coverage 100% touched; grade A (control: a different set value is the one kept).
- **Augments:** none.

## Phase 8 — AC-1: the estimate is labelled approximate; clinical test recommended

- **Kind:** behavior · **Target AC:** AC-1 (full)
- **Depends on:** ITEST-4, FLOW-5 · **Blocks:** —
- **Files:** result screen caveat area; read endpoint `caveatShown`
- **Tasks:** the result labels the estimate an **approximate estimate** and recommends a **clinical anomaloscope test** for ground truth; both strings rendered and exposed.
- **Acceptance gate:** un-pend AC-1; suite green; coverage 100% touched; grade A (both the approximate label and the clinical-test recommendation asserted — G4).
- **Augments:** none.

### Result — ✅ Done (shell)

- **Landed (FLOW-1 shell):**
  - `lib/onboarding/onboarding_steps.dart` — `OnboardingStep` (value type) + `defaultOnboardingSteps` (the provisional four: Setup / Intake / Vision tests / Result — D-4 proposal, **pinned at FLOW-2 once G-5 resolves**).
  - `lib/onboarding/onboarding_state.dart` — `OnboardingState` immutable snapshot (stepIndex; the three lighting flags + `testingStarted`; `prior`; `screening`; `arrangementPool`/`arrangedCaps`/`arrangementSkipped`; `threshold`; `estimate`; `calibratedSeverity`; `caveatShown`; `saved`) with value equality (lists compared element-wise) and `lightingConfirmed`.
  - `lib/onboarding/onboarding_controller.dart` — `OnboardingController extends ChangeNotifier` over an injected `AssessmentEngine` (default `ShellAssessmentEngine`) + optional `CvdProfileStore`; `state`/`steps`/`stepTotal` getters. The 14 action methods (`confirmLightingCheck`, `tryContinue`, `answerIntake`, `reportDiagnosis`, `scoreScreening`, `placeCap`, `startOver`, `skipArrangement`, `scoreThreshold`, `advanceToResult`, `setType`, `setSeverity`, `confirmCalibration`, `save`) **throw `UnimplementedError`** until their behaviour phase fills them (the bs-02/bs-03 shell convention). `LightingCheck` enum added.
  - `lib/onboarding/onboarding_read_endpoint.dart` — `OnboardingReadEndpoint` InheritedWidget over the controller (`of`/`endpointKey`/`updateShouldNotify`), the assessment-state observation seam.
  - `lib/onboarding/screens/` — `OnboardingHost` (stateful; owns the controller, resolves `CvdProfileStore` from the enclosing `AppScope` or an in-memory fallback, mounts **both** `CvdProfileReadEndpoint` and `OnboardingReadEndpoint`), `OnboardingScreen` (pure view; `SingleChildScrollView`+`Column` so every keyed region is an eager anchor; AppBar "CVD self-assessment"; carries the entry `scaffoldKey`), and keyed step widgets `progress_region.dart` ("Step N of M"), `lighting_step.dart` (E36 + E43), `intake_step.dart` (E37), `screening_step.dart`, `arrangement_step.dart` (E38 pool/arranged + E39 + E43), `threshold_step.dart`, `result_step.dart` (E40 + E41 slider + E43 save + caveat area). All controls inert (`onPressed`/`onChanged: null`).
  - `lib/palette/self_assessment_entry_screen.dart` (replaced) — now builds `OnboardingHost(scaffoldKey: screenKey)`; the stable `ValueKey('self-assessment-entry-screen')` anchor is preserved (now on the host's scaffold). `lib/app/router.dart` doc updated (route unchanged).
- **Gate (shell):** `flutter analyze` clean · unit **957 passed** (+34: steps/state/controller/endpoint/host + updated entry-screen test) · coverage gate vs `main` **100% on all 23 touched lib files** · integration host suite **134 passed** (bs-06 palette suite incl.) — existing cross-feature suite green. No acceptance/grade gate (shell). **Fix passes: 1/3** (first full run: 2 host-test failures from the lazy `ListView` not building below-the-fold step regions → switched to `SingleChildScrollView`+`Column`; green on rerun).
- **Updated test:** `test/palette/self_assessment_entry_screen_test.dart` rewritten (the bs-06 placeholder it asserted is replaced) to assert the onboarding host renders behind the preserved anchor. `test/app/router_test.dart` and `test/palette/vision_profile_card_test.dart` unchanged and green (the entry screen boots without an `AppScope`).
- **Tokens / time:** 13,152,941 · 26m 57s.

### Checkpoint / Handoff

- **Frozen interfaces** (behaviour phases implement against these; the step widgets' `onPressed`/`onChanged` and the controller method bodies are what they fill):
  - `OnboardingController({AssessmentEngine engine = const ShellAssessmentEngine(), CvdProfileStore? profileStore, List<OnboardingStep> steps = defaultOnboardingSteps})`; `state`/`steps`/`stepTotal`; the 14 action methods above (signatures frozen — bodies throw). `LightingCheck {brightness, nightLight, daylight}`.
  - `OnboardingState` fields + `lightingConfirmed`; severity 0..1. `OnboardingReadEndpoint` (`endpointKey` `onboarding-read-endpoint`, `of`). `CvdProfileReadEndpoint` is mounted by the host (store = `CvdProfileStore(deps.store)`), satisfying PROFILE-1's handoff.
  - Region/control keys (behaviour phases drive these): progress `onboarding-progress-region`; lighting `onboarding-lighting-step` + continue `onboarding-lighting-continue`; intake `onboarding-intake-step`; screening `onboarding-screening-step`; arrangement `onboarding-arrangement-step` + `-pool`/`-arranged`/`-start-over`/`-skip`; threshold `onboarding-threshold-step`; result `onboarding-result-step` + `-type`/`-severity`/`-caveat`/`-save`.
- **Verification commands** (worktree `../Nuance-bs07`, `export PATH="$PATH:/Users/matthew.quirk/development/flutter/bin"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · `flutter test integration_test/` (host).
- **For FLOW-2 (AC-14, next — blocked by G-2 + G-5):** fix the concrete four steps (per G-5), implement the step advance (replace `tryContinue`'s throw / add step navigation), render the progress "N of 4" and expose `stepIndex`/`stepTotal`. The shell lays out all regions at once; FLOW-2 may move to a stepwise presentation.
- **Known gaps:** every controller action throws and every control is inert (behaviour phases wire them); `band` and a live `estimate` arrive with FLOW-5/ENGINE-7; `save` writes nothing until PROFILE-2; the four-step count is provisional until G-5.
