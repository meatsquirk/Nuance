# Module FLOW — onboarding controller, screens, flow

**Status:** In progress — FLOW-1 (shell), FLOW-3 (AC-2), FLOW-4 (AC-6/7/8), FLOW-5 (enabler), FLOW-6 (AC-10), FLOW-7 (AC-12), FLOW-8 (AC-1) ✅ Done; FLOW-2 (AC-14) blocked by G-5; result-step AC remaining: PROFILE-2 (AC-13)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/onboarding/onboarding_controller.dart`, `onboarding_state.dart`, `onboarding_read_endpoint.dart`, `onboarding_steps.dart`; `lib/onboarding/screens/` (host + lighting, intake, screening, arrangement, threshold, result step widgets with keyed regions); route wiring in `lib/app/router.dart` + `lib/palette/self_assessment_entry_screen.dart` (replaced). Behavior phases in ENGINE/PROFILE add thin controller calls here (merge-risky — rebase before editing).
**Depends on:** ENGINE (estimate types + scoring), PROFILE (save seam) · **Blocks:** ITEST, SIGNOFF

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | | |
| 2 | behavior | AC-14 | ⬜ Todo | | |
| 3 | behavior | AC-2 | ✅ Done | 8,229,212 | 16m 09s |
| 4 | behavior | AC-6, AC-7, AC-8 | ✅ Done | 14,878,591 | 25m 54s |
| 5 | behavior | — (enabler) | ✅ Done | 11,668,942 | 18m 21s (18m 21s) |
| 6 | behavior | AC-10 | ✅ Done | 10,189,552 | 20m 24s |
| 7 | behavior | AC-12 | ✅ Done | 12,947,153 | 25m 37s |
| 8 | behavior | AC-1 | ✅ Done | 7.46M | 13m 45s |

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

### Result — Phase 3 (FLOW-3, AC-2) ✅ Done

- **Landed:**
  - `onboarding_state.dart` — added `copyWith` (the forward primitive the behaviour phases move the state through; nullable fields set-only, documented — no bs-07 phase clears one).
  - `onboarding_controller.dart` — `confirmLightingCheck(check, {confirmed})` sets the matching Tier 0 flag and notifies; `tryContinue()` now gates the Tier 0 → testing transition on `lightingConfirmed` — an unconfirmed Continue is a no-op (no notify), all three confirmed advances `stepIndex` by one (clamped to the last step) and sets `testingStarted` (AC-2). FLOW-2 generalises the advance across later steps.
  - `screens/lighting_step.dart` — the three `CheckboxListTile`s drive `confirmLightingCheck`; Continue is always tappable and wired to `tryContinue` (the gate lives in the controller — the negative-Then settle point AC-2 relies on).
- **AC un-pended:** AC-2 (deleted its row in `integration_test/bs07/pending.dart`).
- **Gate:** `flutter analyze` clean · unit **967 passed** (+10: 5 controller lighting-gate + 4 lighting-step widget + 3 state `copyWith`, −2 removed throw-tests) · coverage gate vs `main` **100% on all 23 touched lib files** · acceptance (sim iPhone 17 `5AB9D06D…`, default run) **11 passed / 13 skipped** — AC-2 now runs and passes, the other 13 ACs still pending · grade **A** for AC-2 (fresh subagent, G1–G6; test body unchanged — the pass comes from production code). **Fix passes: 0/3** (first full run green).
- **Updated tests (recorded per ground rule — not weakened):** `onboarding_controller_test.dart` (the two `throws` cases for `confirmLightingCheck`/`tryContinue` replaced by behaviour tests); `onboarding_host_test.dart` (the shell "controls inert" test drops the lighting-continue `onPressed==null` assertion — FLOW-3 wires it — keeping save/severity); `self_assessment_test.dart` scaffold guard (`expected` set shrinks by AC-2; the skip-reason loop now iterates `pendingACs.keys` and adds an explicit AC-2-runs assertion). New: `test/onboarding/screens/lighting_step_test.dart`.
- **Augmentations:** none.
- **Tokens / time:** 8,229,212 · 16m 09s.

### Checkpoint / Handoff (FLOW-3)

- **Frozen for later phases:** `OnboardingState.copyWith(...)` is the state-forward primitive (all fields optional; nullable fields can be set but not cleared to null). `confirmLightingCheck`/`tryContinue` are live; `tryContinue` advances only while `lightingConfirmed`. The lighting step's controls are wired; `LightingStep.continueKey` / the three checkbox titles (`Screen brightness turned up` / `Night-light turned off` / `In daylight`) are stable.
- **For FLOW-2 (AC-14, blocked on G-5):** generalise `tryContinue`'s advance beyond the Tier 0 gate (later steps have no lighting requirement) and render the "N of 4" progress; it can reuse this `tryContinue` as the Tier 0 case. The 0-based `stepIndex` is smoke-frozen (index 0 → "Step 1 of 4").
- **Verification commands** (worktree, `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · device acceptance `coord.sh with-lock bs-07-cvd-self-assessment <PHASE> --wait 600 -- bash -c "cd <worktree> && … flutter test integration_test/self_assessment_test.dart -d 5AB9D06D-… > log 2>&1"` (FNP_COORD_REPO=/Users/matthew.quirk/Nuance; `-d` mandatory; redirect, don't tail).
- **Known gaps:** FLOW-3 touches only the Tier 0 gate; the step count stays provisional until G-5/FLOW-2.

### Result — Phase 4 (FLOW-4, AC-6/7/8) ✅ Done

- **Landed:**
  - `onboarding_state.dart` — top-level `const arrangementCaps = [3,0,4,1,5,2]` (the fixed Tier 3 cap set, scrambled order); the `arrangementPool` default now = `arrangementCaps` (the pool *is* the unplaced caps, so it starts full — `const OnboardingState()` carries it, so the smoke test's `state == const OnboardingState()` stays green); new derived getter `arrangementResult` → `ArrangementResult(present: true)` once every cap is placed (pool emptied, ≥1 arranged) and `null` while in progress **or** skipped (skip guard checked first).
  - `onboarding_controller.dart` — `placeCap(capId)` moves a pooled cap to the end of `arrangedCaps` and out of the pool, notifying; a cap not in the pool (already placed / unknown id) is a no-op (no notify), so no duplicate/corrupt order. `startOver()` restores the pool to `arrangementCaps` and empties `arrangedCaps`. `skipArrangement()` sets `arrangementSkipped` (leaving `arrangementResult` absent). All three replaced their `UnimplementedError` bodies.
  - `screens/arrangement_step.dart` — the pool renders one keyed `TextButton` per unplaced cap (`ArrangementStep.capKey(id)` = `onboarding-arrangement-cap-$id`) driving `placeCap`; start-over and skip wired to the controller (were inert). Kept the `Arranged: N` readout.
- **ACs un-pended:** AC-6, AC-7, AC-8 (deleted their rows in `integration_test/bs07/pending.dart`).
- **Augmentations closed (re-graded A):** TestAC06/07/08 — FLOW-4 added `whenPlaceCap(capId)` + the `arrangementResult` observable, so the place grain (AC-6: `arranged.last==placed`, +1/−1, pool no longer contains it; second cap takes the next position), start-over (AC-7: all caps return, pool==full set), and skip-vs-complete discrimination (AC-8: skip records no result, a completed arrangement does) are all now driven. AC-8 observes the arrangement result via the new `arrangementResult` getter (not the estimate's `arrangementPresent` — FLOW-5 assembles the estimate later; the ITEST observation point is "arrangement-present" directly).
- **Gate:** `flutter analyze` clean · unit **997 passed** (+30 vs FLOW-3: arrangement controller/state/widget tests + the `arrangementResult` getter branches, −3 removed throw-tests) · coverage gate vs `main` **100% on all 23 touched lib files** · acceptance (sim iPhone 17 `5AB9D06D…`, default run) **16 passed / 8 skipped** — AC-6/7/8 now run and pass, the other 8 ACs still pending · grade **A** for AC-6, AC-7, AC-8 (fresh independent subagent, G1–G6; AC-2/3/4 confirmed still A). **Fix passes: 1/3** (first run: the `whenSkipArrangement` tap landed off-screen at the top of the scroll view — the skip button is below the fold with nothing scrolled; added `ensureVisible` to the skip/start-over drivers, as `whenPlaceCap` already had; green on rerun).
- **Updated tests (recorded per ground rule — not weakened):** `onboarding_controller_test.dart` (the three `throws` cases for `placeCap`/`startOver`/`skipArrangement` replaced by behaviour tests); `onboarding_state_test.dart` (default `arrangementPool` now asserts `arrangementCaps`; new `arrangementResult` group covering in-progress/completed/skipped); `onboarding_host_test.dart` (the shell "controls inert" test drops the `Pool: 0 caps` text assertion — FLOW-4 renders cap controls — and asserts a cap control + `Arranged: 0` instead); `self_assessment_test.dart` scaffold-guard `expected` set shrinks by AC-6/7/8; harness `self_assessment_harness.dart` gained `whenPlaceCap` + `arrangementResult` and `ensureVisible` on the skip/start-over drivers. New: `test/onboarding/screens/arrangement_step_test.dart`.
- **Tokens / time:** 14,878,591 · 25m 54s.

### Checkpoint / Handoff (FLOW-4)

- **Frozen for later phases:** `OnboardingController.placeCap/startOver/skipArrangement` are live. The arrangement pool starts as `arrangementCaps` (full); `arrangedCaps` is the placed order; `OnboardingState.arrangementResult` is present only when completed and not skipped. `ArrangementStep.capKey(id)` is the per-cap control key; `whenPlaceCap(capId)` / `whenStartOver` / `whenSkipArrangement` are the drivers (all `ensureVisible` before tapping — the arrangement sits below the fold in the shell's single scroll view).
- **For FLOW-5 (enabler — the result-step barrier):** assemble `CvdEstimate` from the tier results present (prior + screening + the arrangement result + threshold) via `AssessmentEngine.assemble` and advance to the result step. The arrangement contributes `arrangementResult` (present/absent) — a skip leaves it absent. FLOW-5 is `depends on` ENGINE-3/4/5/6 + FLOW-4 (all but ENGINE-5/6 now done).
- **Verification commands** (worktree, `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · device acceptance `coord.sh with-lock bs-07-cvd-self-assessment <PHASE> --wait 900 -- bash -c "cd <worktree> && … flutter test integration_test/self_assessment_test.dart -d 5AB9D06D-… > log 2>&1"` (FNP_COORD_REPO=/Users/matthew.quirk/Nuance; `-d` mandatory; redirect, don't tail).
- **Known gaps:** the four-step count stays provisional until G-5/FLOW-2; a live `estimate`/`band` arrive with FLOW-5/ENGINE-7; `save` writes nothing until PROFILE-2. AC-8's acceptance test chooses skip-instead-of-complete, so the getter's `arrangementSkipped` guard is pinned by a unit test (`onboarding_state_test.dart`) rather than the acceptance test (optional future hardening: a complete-then-skip acceptance case).

### Result — Phase 5 (FLOW-5, enabler — assemble + advance to result) ✅ Done

- **Landed (enabler — un-pends no AC; makes "on the result step with an estimate" real):**
  - `lib/onboarding/engine/assessment_engine.dart` — `TieredAssessmentEngine.assemble` (override, replacing the inherited shell stand-in) folds the prior + available tiers into a `CvdEstimate` (D-7): **direction** = a *present* Tier 2 screening (measured, wins) → else the prior's lean → else red-green (shell default); **type** = an authoritative reported-diagnosis `prior.type` kept as-is → else the direction narrowed (red-green→deutan, blue-yellow→tritan); **severity** = the measured Tier 4 threshold when probing ran → else the prior's self-report weight, clamped 0..1. Arrangement contributes presence only (a skip leaves it absent). Three private static helpers (`_estimatedDirection`/`_estimatedType`/`_estimatedSeverity`).
  - `lib/onboarding/onboarding_controller.dart` — `advanceToResult()` (replaced its `UnimplementedError`): gathers the current tier state (prior, screening, `arrangementResult`, threshold), folds through `engine.assemble`, sets `state.estimate`, advances `stepIndex` to the last top-level step (the result step), notifies. A result is always reachable even with no tier run (assembles the default).
  - `lib/onboarding/screens/onboarding_screen.dart` — a keyed "See my result" control (`OnboardingScreen.seeResultKey` = `onboarding-see-result`) between the threshold and result steps, wired to `controller.advanceToResult` (always present — the shell lays every step out at once).
  - `lib/onboarding/screens/result_step.dart` — now renders the assembled estimate when present (`Estimated type: <name>` + `Estimated severity: <0..100>`), the severity slider reflects `severity*100` (still inert until FLOW-7); shows the `Result` placeholder while `estimate` is null (shell/pre-advance).
- **ACs un-pended:** none (enabler). `integration_test/bs07/pending.dart` unchanged; the pending set stays `{AC-1, AC-10, AC-11, AC-12, AC-13, AC-14}`.
- **Harness/tests:** `self_assessment_harness.dart` gained `whenAdvanceToResult()` (taps "See my result", `ensureVisible` first — it sits below the fold) + the `OnboardingScreen` import. The 5 result-step AC Givens in `self_assessment_test.dart` now drive the flow to the result step (driving lines only; **no Then changed**): AC-1/11/12 tap `whenAdvanceToResult`; AC-10 reports a deutan diagnosis then advances (estimate.type deutan via the real seam, G2); AC-13 reports deutan + probes `thresholdProbesStrong` (→ severity 0.6 = moderate) then advances ({deutan, moderate}).
- **Gate:** `flutter analyze` clean · unit **1033 passed** (+~16: engine `assemble` group, controller `advanceToResult` group, new `onboarding_screen_test.dart` + `result_step_test.dart`, −1 removed `advanceToResult throws`) · coverage gate vs `main` **100% on all 23 touched lib files** · acceptance (sim iPhone 17 `5AB9D06D…`): **default 18 pass / 6 skip** (suite green); **run-pending 19 pass / 5 fail** — the 5 result-step ACs now **reach the result step** and fail on their *own* downstream Then (AC-1→FLOW-8 caveat, AC-10→FLOW-6 protan, AC-11→ENGINE-7 band, AC-12→FLOW-7 calibration, AC-13→PROFILE-2 save); **no failure cites the FLOW-5 `estimate isNotNull` precondition** (the enabler gate). AC-14 passes. Grade grid unchanged **12 A / 2 B-pending** (AC-10→FLOW-6, AC-13→PROFILE-2). **Fix passes: 0/3** (first full run met the gate).
- **Tokens / time:** 11,668,942 · 18m 21s (18m 21s).

### Checkpoint / Handoff (FLOW-5)

- **Frozen for the result-step phases:** `OnboardingController.advanceToResult()` is live — `state.estimate` is a non-null `CvdEstimate` on the result step. `AssessmentEngine.assemble` is the fold (direction/type/severity rules above); only `band` (ENGINE-7) stays the trivial shell default now. The "See my result" control key is `OnboardingScreen.seeResultKey`; the harness driver is `whenAdvanceToResult()`. `ResultStep` renders `Estimated type:`/`Estimated severity:` and reflects severity on the inert slider.
- **For ENGINE-7 (AC-11 band):** override `TieredAssessmentEngine.band(severity)` with the G-4 cut-offs (D-5: mild `[0,0.45)`, moderate `[0.45,0.75)`, strong `[0.75,1.0]`) and render the band label on the result step (`SeverityBand.label`); AC-11 grades it against the independent `referenceBand`.
- **For FLOW-6 (AC-10):** add the by-hand type choices (make `whenAdjustType` select protan explicitly — the current driver only *opens* the control) and wire `setType`; un-pend AC-10, its B-pending augmentation closes.
- **For FLOW-7 (AC-12):** wire the severity slider (`setSeverity`/`confirmCalibration`) + the simulated/original pair; `calibratedSeverity` is the kept value.
- **For FLOW-8 (AC-1):** fill the caveat area with the `approximate estimate` label + `anomaloscope` clinical-test recommendation.
- **For PROFILE-2 (AC-13):** wire `save` to project the estimate onto a `CvdProfile` and write through `profileStore`; add the live-pipeline assertion (its B-pending augmentation).
- **Verification commands** (worktree `../Nuance-bs07`, `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · device acceptance via `coord.sh with-lock bs-07-cvd-self-assessment <PHASE> --wait 900 -- bash -c "cd <worktree> && … flutter test integration_test/self_assessment_test.dart -d 5AB9D06D-… [--dart-define=BS07_RUN_PENDING=true] > log 2>&1"` (FNP_COORD_REPO=/Users/matthew.quirk/Nuance; `-d` mandatory; redirect, don't tail).
- **Known gaps:** the four-step count stays provisional until G-5/FLOW-2; `band` is the trivial default until ENGINE-7; the result controls (type/slider/save) stay inert until FLOW-6/7/8/PROFILE-2. `advanceToResult` sets `stepIndex` to the last step, but presentation is not yet stepwise (FLOW-2) so all regions stay laid out at once.

### Result — Phase 6 (FLOW-6, AC-10) ✅ Done

- **Landed:**
  - `lib/onboarding/onboarding_controller.dart` — `setType(CvdType)` (replaced its `UnimplementedError`): overrides the assembled estimate's `type` with the painter's chosen one regardless of what the tiers computed, keeping the rest of the estimate (severity/prior/screening/threshold/arrangementPresent) intact, then notifies. A no-op (no notify) before the estimate is assembled — the result step is the only place the control is live. `CvdEstimate` imported (reconstructed via its const ctor — it has no `copyWith`).
  - `lib/onboarding/screens/result_step.dart` — replaced the single inert "Adjust type" `TextButton` with a by-hand **type picker**: a `Wrap` keyed `ResultStep.typeKey` holding one `TextButton` per `CvdType` (protan/deutan/tritan) keyed `ResultStep.typeChoiceKey(type)`. Live (wired to `controller.setType`) once the estimate is assembled; inert in the placeholder branch (no estimate). Added `typeChoiceKey`.
- **AC un-pended:** AC-10 (deleted its row in `integration_test/bs07/pending.dart`).
- **Augmentation closed (re-graded A):** TestAC10 — the harness driver `whenAdjustType(CvdType type)` now carries a type argument and taps the specific choice `ResultStep.typeChoiceKey(type)`; the AC-10 test selects **protan** explicitly (`whenAdjustType(CvdType.protan)` → `estimate!.type == protan`, rejecting tritan/deutan) with a deutan control — closing the former G4/G5 "bare tap can't discriminate a 3-way picker" limit (B pending FLOW-6 → A).
- **Gate:** `flutter analyze` clean · unit **1047 passed** (+4 vs ENGINE-7: 3 `setType` controller tests + 2 result_step picker tests, −1 removed `setType throws`) · coverage gate vs `main` **100% on all 23 touched lib files** · acceptance (sim iPhone 17 `5AB9D06D…`): **default 20 pass / 4 skip** (AC-10 now runs and passes; AC-1/12/13/14 still pending) · **run-pending 21 pass / 3 fail** — AC-10 passes; the 3 fails (AC-1→FLOW-8 caveat, AC-12→FLOW-7 calibration, AC-13→PROFILE-2 save) each fail on their **own** downstream Then (no harness/compile error from the shared result-step change) · grade **A** for AC-10, fresh independent subagent, G1–G6; AC-2/3/4/5/6/7/8/9/11 re-confirmed still A (AC-11 specifically checked — the picker above the slider adds type-name text only, no Slider/band-label collision). Grade grid **13 A / 1 B-pending** (AC-13 → PROFILE-2). **Fix passes: 0/3** (first full run met every gate).
- **Updated tests (recorded per ground rule — not weakened):** `onboarding_controller_test.dart` (the `setType throws (FLOW-6)` case replaced by a behaviour group: override-keeping-the-rest+notify, override-wins-over-computed, no-op-before-estimate); `self_assessment_test.dart` (AC-10 calls now pass `CvdType.protan`/`CvdType.deutan` — the augmentation closure; scaffold-guard `expected` set shrinks by AC-10 + an AC-10-runs assertion added); harness `self_assessment_harness.dart` (`whenAdjustType` gained the `CvdType` argument + `ensureVisible`). New picker cases in `test/onboarding/screens/result_step_test.dart`.
- **Tokens / time:** 10,189,552 · 20m 24s (20m 24s).

### Checkpoint / Handoff (FLOW-6)

- **Frozen for later phases:** `OnboardingController.setType(CvdType)` is live — overrides `estimate.type`, keeps the rest, no-op without an estimate. `ResultStep.typeChoiceKey(type)` is the per-type control key; the picker `Wrap` carries `ResultStep.typeKey`. Harness `whenAdjustType(CvdType)` selects a specific type.
- **For FLOW-7 (AC-12, next startable):** wire the severity slider (`setSeverity`/`confirmCalibration`) + the simulated/original pair; `calibratedSeverity` is the kept value. **Owns the result slider:** route ENGINE-7's now-live slider (the view-local `_working` in `result_step.dart`) through `controller.setSeverity`, and have the band read `calibratedSeverity ?? estimate.severity`. The type picker sits above the slider — leave it intact.
- **For FLOW-8 (AC-1):** fill the caveat area (`approximate estimate` + `anomaloscope`).
- **For PROFILE-2 (AC-13):** wire `save` + the live-pipeline augmentation (its B-pending augmentation — the last one open).
- **Verification commands** (worktree `../Nuance-bs07`, `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · device acceptance via `coord.sh with-lock bs-07-cvd-self-assessment <PHASE> --wait 900 -- bash -c "cd <worktree> && … flutter test integration_test/self_assessment_test.dart -d 5AB9D06D-… [--dart-define=BS07_RUN_PENDING=true] > log 2>&1"` (FNP_COORD_REPO=/Users/matthew.quirk/Nuance; `-d` mandatory; redirect, don't tail).
- **Known gaps:** the four-step count stays provisional until G-5/FLOW-2; the slider (`setSeverity`/`confirmCalibration`) and save stay un-wired until FLOW-7/PROFILE-2; presentation is not yet stepwise (FLOW-2) so all regions stay laid out at once.

### Result — Phase 7 (FLOW-7, AC-12) ✅ Done

- **Landed:**
  - `lib/onboarding/onboarding_controller.dart` — `setSeverity(double)` (replaced its `UnimplementedError`): keeps the painter's chosen severity (0..1, clamped) as `state.calibratedSeverity` and notifies; a no-op (no notify) before the estimate is assembled. `confirmCalibration()` (replaced its throw): if the slider was never moved (`calibratedSeverity` null) it keeps the assembled estimate's own severity as the calibration (D-6, the value that becomes the profile severity); idempotent (a value already chosen stands, no notify); no-op before the estimate.
  - `lib/onboarding/screens/result_step.dart` — converted from `StatefulWidget` (the view-local `_working`) to a pure `StatelessWidget`: the working/kept severity now lives on the controller as `calibratedSeverity`. The estimate branch reads `severity = calibratedSeverity ?? estimate.severity`; the slider is wired `onChanged: (v)=>controller.setSeverity(v/100)` + `onChangeEnd: (_)=>controller.confirmCalibration()`; the band reads `engine.band(severity)` off the same value. Added the **simulated-versus-original colour pair** (E41, keys `ResultStep.pairKey`/`pairOriginalKey`/`pairSimulatedKey`): two swatches whose *simulated* one collapses toward the fixed *original* as the severity rises (`Color.lerp` toward grey — an illustrative bs-07 stand-in; the real per-channel CVD projection is bs-08/bs-10 behind `ConfusionCheck`). The FLOW-6 type picker is left intact above the slider.
- **AC un-pended:** AC-12 (deleted its row in `integration_test/bs07/pending.dart`).
- **Augmentations:** none (AC-12 had no augmentation row; it closed as a clean implemented A).
- **Gate:** `flutter analyze` clean · unit **1055 passed** (+8 vs FLOW-6: 7 controller self-calibration tests + 4 result_step tests [calibration round-trip, unmoved-confirm, pair re-render, pair-absent] − 2 removed throw-tests − 1 flipped ENGINE-7 boundary guard) · coverage gate vs `main` **100% on all touched lib files** (incl. `result_step.dart`, `onboarding_controller.dart`) · acceptance (sim iPhone 17 `5AB9D06D…`): **default 21 pass / 3 skip** (AC-12 now runs and passes; AC-1/13/14 still pending) · **run-pending 22 pass / 2 fail** — AC-12 passes; the 2 fails (AC-1→FLOW-8 caveat, AC-13→PROFILE-2 save) each fail on their **own** downstream Then (no harness/compile error from the shared result-step change) · grade **A** for AC-12 (fresh independent subagent, G1–G6, clean implemented A); AC-10 and AC-11 re-confirmed A against the rewired `result_step.dart` (no regression — the pair labels don't collide with band labels; `setSeverity`/`confirmCalibration` never touch `estimate.type`). Grade grid **13 A / 1 B-pending** (AC-13 → PROFILE-2). **Fix passes: 1/3** (first on-device run: `whenSetSeverity` tapped the slider without `ensureVisible`, so below-the-fold the tap missed and `calibratedSeverity` stayed null — AC-11 had masked this by tolerating a non-moving slider; added `ensureVisible` to the driver, as FLOW-4/FLOW-6 did for their below-fold drivers; green on rerun).
- **Updated tests (recorded per ground rule — not weakened):** `onboarding_controller_test.dart` (the `setSeverity throws`/`confirmCalibration throws` cases replaced by a self-calibration behaviour group: keep-on-set+notify, tracks-latest, clamps, no-op-before-estimate, confirm-keeps-estimate-severity, confirm-leaves-chosen-value, confirm-no-op-before-estimate); `result_step_test.dart` (the ENGINE-7 boundary guard "moving the slider does not persist a calibration (that is FLOW-7)" **flipped** to FLOW-7 behaviour "moving the slider keeps the chosen severity", plus unmoved-confirm + the sim/original pair cases); harness `self_assessment_harness.dart` (`whenSetSeverity` gained `ensureVisible` — scroll-only, strengthens the driver); `self_assessment_test.dart` scaffold guard (`expected` set shrinks by AC-12 + an AC-12-runs assertion added).
- **Tokens / time:** 12,947,153 · 25m 37s (25m 37s).

### Checkpoint / Handoff (FLOW-7)

- **Frozen for later phases:** `OnboardingController.setSeverity(double)` keeps `calibratedSeverity` (0..1, clamped) live; `confirmCalibration()` keeps the estimate's severity if the slider was never moved (D-6). `ResultStep` is a `StatelessWidget` reading `calibratedSeverity ?? estimate.severity` for the slider, the band and the simulated/original pair (`ResultStep.pairKey`/`pairOriginalKey`/`pairSimulatedKey`). Harness `whenSetSeverity` now `ensureVisible`s the slider. The result slider is fully wired — only the caveat (FLOW-8) and save (PROFILE-2) remain inert.
- **For FLOW-8 (AC-1, next startable):** fill the caveat area (`SizedBox(key: ResultStep.caveatKey)`) with the `approximate estimate` label + the `anomaloscope` clinical-test recommendation, and set `state.caveatShown`. The read endpoint `caveatShown` is the observable. Un-pend AC-1.
- **For PROFILE-2 (AC-13):** wire `save` to project the estimate (type + `calibratedSeverity ?? estimate.severity`, D-6) onto a `CvdProfile`, write it through `profileStore`, set `state.saved`; add the live-pipeline augmentation (the last open B-pending — assert the live `AppDependencies.cvdProfile`/confusion pipeline reflects the saved profile).
- **For FLOW-2 (AC-14, blocked on G-5):** fix the concrete four steps and the stepwise progress once G-5 resolves.
- **Verification commands** (worktree `../Nuance-bs07`, `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · device acceptance via `coord.sh with-lock bs-07-cvd-self-assessment <PHASE> --wait 900 -- bash -c "cd <worktree> && … flutter test integration_test/self_assessment_test.dart -d 5AB9D06D-… [--dart-define=BS07_RUN_PENDING=true] > log 2>&1"` (FNP_COORD_REPO=/Users/matthew.quirk/Nuance; `-d` mandatory; redirect, don't tail).
- **Known gaps:** the four-step count stays provisional until G-5/FLOW-2; `save` stays un-wired until PROFILE-2 (so AC-13 keeps its B-pending augmentation); presentation is not yet stepwise (FLOW-2) so all regions stay laid out at once. The simulated/original pair is an illustrative stand-in (grey-collapse), not the real CVD projection (bs-08/bs-10).

### Result — Phase 8 (FLOW-8, AC-1) ✅ Done

- **Landed:**
  - `lib/onboarding/screens/result_step.dart` — new `_caveat()` widget (keyed `ResultStep.caveatKey`) rendered in the **estimate branch** (replacing the empty `SizedBox` placeholder there): a `Column` of two `Text`s — "This is an approximate estimate, not a clinical diagnosis." + "For ground truth, a clinical anomaloscope test is recommended." — so the result carries both the **approximate-estimate** label and the **clinical anomaloscope** recommendation (AC-1). The placeholder branch (no estimate, e.g. the shell) keeps the empty `SizedBox(key: caveatKey)` so the anchor still exists but no caveat is shown before a result.
  - `lib/onboarding/onboarding_controller.dart` — `advanceToResult()` now also sets `caveatShown: true` in its `copyWith`: reaching the result is when the result is *shown*, so the estimate never appears without the caveat beside it. The `OnboardingState.caveatShown` field (frozen at FLOW-1) is the read-endpoint observable AC-1 asserts.
- **AC un-pended:** AC-1 (deleted its row in `integration_test/bs07/pending.dart`; scaffold-guard `expected` set shrank to `{AC-13, AC-14}` + AC-1-runs assertion added).
- **Augmentations:** none (AC-1 had no augmentation row; it closed as a clean implemented A).
- **Gate:** `flutter analyze` clean · unit **1057 passed** (+2 vs FLOW-7: 1 controller caveat-on-advance test + 1 result_step caveat-present test, and the placeholder test gained caveat-absent assertions) · coverage gate vs `main` **100% on all 24 touched lib files** · acceptance (sim iPhone 17 `5AB9D06D…`): **default 22 pass / 2 skip** (AC-1 now runs and passes; AC-13/AC-14 still pending) · **run-pending 23 pass / 1 fail** — AC-1 passes; the single fail (AC-13→PROFILE-2 save: "exactly one profile is written" expected 1, actual 0 — `save` throws `UnimplementedError`) fails on its **own** downstream Then (no harness/compile error from the shared result-step change; AC-14 is green at baseline, un-pends at FLOW-2) · grade **A** for AC-1 (fresh independent subagent, G1–G6, design-A → implemented A); AC-10/AC-11/AC-12 re-confirmed A against the shared `result_step.dart` (no regression — no text-finder collides with the new caveat Texts: band labels mild/moderate/strong are not substrings of the caveat strings; AC-10/12 use key finders; `caveatShown` never touches `estimate.type`/severity). Grade grid **13 A / 1 B-pending** (AC-13 → PROFILE-2). **Fix passes: 0/3** (first full run met every gate).
- **Updated tests (recorded per ground rule — not weakened):** `onboarding_controller_test.dart` (new caveat-on-advance test in the `advanceToResult` group: `caveatShown` false before, true after, estimate non-null); `result_step_test.dart` (new caveat-present test + the placeholder test now asserts caveat-absent); `self_assessment_test.dart` scaffold guard (`expected` set shrinks by AC-1 + an AC-1-runs assertion added). No acceptance test body changed — the pass comes from production code.
- **Tokens / time:** 7,458,547 · 13m 45s.

### Checkpoint / Handoff (FLOW-8)

- **Frozen for later phases:** the result caveat is live — `OnboardingController.advanceToResult()` raises `OnboardingState.caveatShown`, and `ResultStep._caveat()` (keyed `ResultStep.caveatKey`) renders the `approximate estimate` label + `anomaloscope` recommendation whenever an estimate is present. The placeholder branch keeps an empty `caveatKey` anchor. Only `save` (PROFILE-2) remains inert on the result step.
- **For PROFILE-2 (AC-13, the last startable result-step phase):** wire `save` to project the estimate (type + `calibratedSeverity ?? estimate.severity`, D-6) onto a `CvdProfile`, write it through `profileStore`, set `state.saved`; close AC-13's B-pending augmentation (assert the live `AppDependencies.cvdProfile`/confusion pipeline reflects the saved profile). It shares `result_step.dart` + `OnboardingController` + `self_assessment_test.dart` with the FLOW phases — run it in its own session, not parallel.
- **For FLOW-2 (AC-14, blocked on G-5):** fix the concrete four steps and the stepwise progress once G-5 resolves.
- **Verification commands** (worktree `../Nuance-bs07`, `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · device acceptance via `coord.sh with-lock bs-07-cvd-self-assessment <PHASE> --wait 900 -- bash -c "cd <worktree> && … flutter test integration_test/self_assessment_test.dart -d 5AB9D06D-… [--dart-define=BS07_RUN_PENDING=true] > log 2>&1"` (FNP_COORD_REPO=/Users/matthew.quirk/Nuance; `-d` mandatory; redirect, don't tail).
- **Known gaps:** the four-step count stays provisional until G-5/FLOW-2; `save` stays un-wired until PROFILE-2 (so AC-13 keeps its B-pending augmentation); presentation is not yet stepwise (FLOW-2) so all regions stay laid out at once.
