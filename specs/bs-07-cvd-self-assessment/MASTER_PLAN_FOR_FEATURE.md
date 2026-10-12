# Master Plan — CVD self-assessment (onboarding)

**Spec:** [bs-07-cvd-self-assessment.feature](../bs-07-cvd-self-assessment.feature)
**Status:** Not started — next ENGINE-1, now **startable** (G-1 ✅ spec approved, G-3 ✅ bs-05/bs-06 merged to main @ cd1c86b)
**Architecture:** [docs/paint-color-app-solution-intent.md](../../docs/paint-color-app-solution-intent.md) §"CVD self-assessment (onboarding)" (tiers 0–4) + §"CVD pipeline"; wireframe `Paint Color Assistant.dc.html` region S1.R1 (E36–E41, E43); reuses `lib/a11y/cvd/cvd_profile.dart` (bs-03) and `lib/store/PersistentStore` (bs-06).
**Code home:** /Users/matthew.quirk/Nuance · remote https://github.com/meatsquirk/Nuance · base `main` after the bs-05 + bs-06 merge (G-3) · extends the bs-01..bs-06 foundation (confirmed by Matt Quirk via sibling *Code home* lines, 2026-10-11)

## Gap analysis (against `main` after bs-05+bs-06 merge; seams read from feat/bs-06 @ `6ab1440`)

| AC | Exists today | Missing |
|---|---|---|
| AC-1 result caveat | `SelfAssessmentEntryScreen` placeholder only | A result step that labels the estimate approximate and recommends a clinical anomaloscope test |
| AC-2 Tier 0 lighting gate | — | Lighting/display setup step; a continue action gated until brightness/night-light/daylight checks confirmed |
| AC-3 Tier 1 intake prior | — | Intake question step; an answer recorded toward a starting prior in the engine |
| AC-4 intake diagnosis seed | — | Intake path for a reported prior diagnosis that seeds the prior (e.g. deutan) |
| AC-5 Tier 2 screening | — | Pseudoisochromatic plate screening scored to presence + R-G/B-Y direction |
| AC-6 arrangement place | — | Arrangement step: cap pool → placing a cap takes the next arranged position and leaves the pool |
| AC-7 arrangement start-over | — | Start-over returns every cap to the pool |
| AC-8 arrangement skip | — | Skip continues the flow without an arrangement result |
| AC-9 Tier 4 threshold | — | Adaptive threshold probing scored to a severity along the confusion line |
| AC-10 adjust type | — | Result step control that overrides the estimated `CvdType` by hand |
| AC-11 severity band | — | Severity value → plain-language band (mild/moderate/strong) shown on the result |
| AC-12 self-calibration | — | Severity slider over a simulated/original pair; the chosen severity kept as the subjective calibration |
| AC-13 save profile | `CvdProfile` value type exists; `AppDependencies.cvdProfile` is a const default; `PersistentStore` exists; **no profile is persisted** | Persist one profile via `PersistentStore`; wire the live dependency so bs-03 confusion check + (future) bs-08/bs-10 read the measured profile |
| AC-14 progress | — | A step-progress indicator showing current step of the total |

## Build order

| Stage | Phases |
|---|---|
| 1 Scaffold | ENGINE-1 |
| 2 Component shells | ENGINE-2, PROFILE-1, FLOW-1 |
| 3 Acceptance tests | ITEST-1, ITEST-2, ITEST-3, ITEST-4 (test review, G-2) |
| 4 Behavior | FLOW-2, FLOW-3, ENGINE-3, ENGINE-4, ENGINE-5, FLOW-4, ENGINE-6, FLOW-5 *(enabler)*, ENGINE-7, FLOW-6, FLOW-7, FLOW-8, PROFILE-2 |
| 5 Sign-off | SIGNOFF-1 |

## Acceptance criteria coverage

| AC | Scenario | Integration test (ITEST) | Behavior phases | Status |
|---|---|---|---|---|
| AC-1 | The estimate is labelled approximate and a clinical test is recommended | ITEST-2 `TestAC01_EstimateLabelledApproximate` | FLOW-8 | ⬜ Todo |
| AC-2 | The lighting setup must be confirmed before testing begins | ITEST-2 `TestAC02_LightingConfirmedBeforeTesting` | FLOW-3 | ⬜ Todo |
| AC-3 | An intake answer contributes to the starting prior | ITEST-3 `TestAC03_IntakeAnswerToPrior` | ENGINE-3 | ⬜ Todo |
| AC-4 | A prior clinical diagnosis entered at intake seeds the prior | ITEST-3 `TestAC04_DiagnosisSeedsPrior` | ENGINE-4 | ⬜ Todo |
| AC-5 | Screening yields presence and the red-green versus blue-yellow direction | ITEST-3 `TestAC05_ScreeningPresenceAndDirection` | ENGINE-5 | ⬜ Todo |
| AC-6 | The painter places colour caps in hue order | ITEST-3 `TestAC06_PlaceCapNextPosition` | FLOW-4 | ⬜ Todo |
| AC-7 | Starting over clears the arrangement | ITEST-3 `TestAC07_StartOverClearsArrangement` | FLOW-4 | ⬜ Todo |
| AC-8 | The painter skips the arrangement for now | ITEST-3 `TestAC08_SkipArrangement` | FLOW-4 | ⬜ Todo |
| AC-9 | Threshold probing yields a severity along the confusion line | ITEST-3 `TestAC09_ThresholdSeverity` | ENGINE-6 | ⬜ Todo |
| AC-10 | The painter adjusts the estimated type by hand | ITEST-2 `TestAC10_AdjustTypeByHand` | FLOW-6 | ⬜ Todo |
| AC-11 | The severity value sets a plain-language band | ITEST-2 `TestAC11_SeverityBand` | ENGINE-7 | ⬜ Todo |
| AC-12 | The severity slider doubles as subjective self-calibration | ITEST-2 `TestAC12_SelfCalibration` | FLOW-7 | ⬜ Todo |
| AC-13 | Saving the profile configures simulation, daltonization and confusion warnings | ITEST-2 `TestAC13_SaveConfiguresPipeline` | PROFILE-2 | ⬜ Todo |
| AC-14 | The current step is shown against the total | ITEST-2 `TestAC14_ProgressStepOfTotal` | FLOW-2 | ⬜ Todo |

14 ACs (AC-11 is a Scenario Outline tested over its 3 examples: 30→mild, 60→moderate, 90→strong). Every AC → one integration test → ≥1 behavior phase.

## Design decisions

| # | Decision | Why |
|---|---|---|
| D-1 | Reuse `CvdProfile {CvdType type, double severity 0..1}` unchanged; bs-07 only populates measured values, no schema change | The profile's own doc-comment designates bs-07 as the "populate" change; bs-03/bs-08/bs-10 already consume this value type |
| D-2 | Persist the one profile as a single document — collection `cvd_profile`, id `current` — over `PersistentStore`, matching `source_photo_store.dart`; body `{type: <name>, severity: <double>}` | One stored profile (spec); reuses the bs-06 generic document store; no new persistence engine |
| D-3 | Load `AppDependencies.cvdProfile` from the store at app assembly, defaulting to the const default when absent; saving updates both the store and the live dependency | So the measured profile flows to bs-03's `ConfusionCheck` and the `projectDichromat` seam bs-08/bs-10 reuse |
| D-4 | The onboarding presents **four** top-level steps (progress = N of 4); tiers 2 (screening) and 4 (threshold) nest inside a step rather than adding to the count — **proposed, pending G-5** | AC-14 says "four steps"; the wireframe draws four (lighting, intake, arrangement, result); screening+threshold are in-scope-but-undrawn tiers |
| D-5 | UI severity slider is 0..100; stored `severity = value/100`. Band anchors 30→mild, 60→moderate, 90→strong; boundaries monotonic (proposed <40 mild / 40–75 moderate / >75 strong) — **confirm boundaries at G-4** | AC-11 examples fix three anchors; the profile stores 0..1 |
| D-6 | Self-calibration (AC-12) is kept **as** the profile severity — the painter-tuned slider value is the subjective calibration; no separate field | AC-12's "kept as the subjective self-calibration" with a profile that has only type+severity |
| D-7 | The engine assembles the estimate from whatever tier results are present (prior + screening direction + arrangement + threshold); the result step shows type+severity even when a tier was skipped (AC-8) | Tiers are optional/fastest-first; the flow must reach a result without every tier |
| D-8 | AC-13 "configures simulation and daltonization" is verified at the **shared profile seam** (the single source all three consumers read), since bs-08/bs-10 are not built; confusion-warning configuration is asserted behaviourally via bs-03's `ConfusionCheck`. Behavioural sim/dalt assertions are a known gap owned by bs-08/bs-10 | Those features do not exist yet; the profile is the one thing they all read |
| D-9 | Each tier's scoring lives in `AssessmentEngine` (pure, unit-tested to 100%); the controller calls the engine and read endpoints expose state; no scoring in widgets | Keeps domain testable and the UI thin |

## Acceptance integration test plan

Module plan: [modules/ITEST.md](modules/ITEST.md).

**Where it lives and how it runs:** `integration_test/self_assessment_harness.dart` (vocabulary + fixtures + wiring) and `integration_test/self_assessment_test.dart` (runner). Default target (pending skipped): `flutter test integration_test/self_assessment_test.dart -d <booted-udid>`. Run-pending / red baseline: add `--dart-define=BS07_RUN_PENDING=true`. **A booted sim udid (`-d`) is mandatory** — without it the run executes zero tests and exits 0 (false green; see Known flakes). Single exclusive lane via `coord.sh with-lock` in parallel sessions.
**Where assertions look:** the rendered widget tree (keyed region finders for E36–E41, E43 and the progress indicator); `OnboardingReadEndpoint` (live controller state: step index/total, lighting flags, prior, screening result, arrangement pool/placed, threshold, assembled estimate, band, caveat shown, calibrated severity); `CvdProfileReadEndpoint` (the persisted profile); bs-03's `ConfusionCheck` behaviour on a fixed colour pair (for AC-13); `FakeSpeech` log if a step speaks.
**What is real and what is faked:** the whole app assembled through `buildApp(deps)`; real engine, controller, screens, profile store contract, confusion check and `projectDichromat`. Faked infrastructure only: `FakeSpeech`, `FakeHaptics`, and an `InMemoryPersistentStore` double exercising the same `PersistentStore` write-side contract. No scoring/colour/ΔE math faked — band and direction are graded against an independent in-harness reference.

**Fixtures:**

| Fixture | Shape |
|---|---|
| `bootedDevice` | A booted simulator udid passed via `-d`; mandatory for every acceptance run |
| `fakeSpeech` / `fakeHaptics` | Infrastructure doubles recording spoken/haptic events |
| `memoryStore` | `InMemoryPersistentStore` behind the production `PersistentStore` interface; starts empty (no profile persisted) |
| `intakeAnswers` | The intake questions and answer options, incl. the "reds/browns/greens mixed up?" item (AC-3) and the prior-diagnosis path (AC-4) |
| `screeningPlates` | An openly-licensed plate set whose scoring yields presence + R-G vs B-Y direction (AC-5) |
| `capPool` | The unordered colour-cap pool for the arrangement (AC-6/7/8) |
| `thresholdProbe` | The adaptive probe sequence whose scoring yields a severity on the confusion line (AC-9) |
| `referenceBand` | Independent in-harness severity→band mapping to grade AC-11 against (not the product function) |
| `fixedPair` | A colour pair confusable only under a specific CVD type/severity, to prove the saved profile reconfigures bs-03's confusion check (AC-13) |

**Test catalogue:**

| AC | Given: built via public flows → checked by | When | Then: exact assertions | Rejects |
|---|---|---|---|---|
| AC-1 | Complete the flow to the result step → read endpoint shows the result step reached | result shown | result text labels it an **approximate estimate** (exact phrase present) **and** recommends a **clinical anomaloscope test** for ground truth (both present) | a result that states the type/severity with no approximate-estimate label or no clinical-test recommendation |
| AC-2 | On the lighting step with brightness/night-light/daylight **not all** confirmed → read endpoint shows the three flags not-all-true and testing not started | tap Continue (E43) | testing does **not** begin — still on the lighting step after a settle (the continue event is processed; read endpoint: step unchanged, testing-started false). Control: confirm all three, Continue → advances | a Continue that advances regardless of the checks |
| AC-3 | On the intake step asked "Do reds, browns and greens get mixed up?" → read endpoint shows the question asked and prior at baseline | answer "Often" | the answer is recorded toward the starting prior — read endpoint prior reflects the "Often" contribution (changed from baseline, toward red-green). Control: a neutral/"Never" answer moves it the other way or not at all | an intake that discards the answer (prior unchanged) |
| AC-4 | At intake report a prior diagnosis of **deutan** → read endpoint shows the diagnosis captured | intake recorded | starting prior is **seeded as deutan** (read endpoint prior.type == deutan). Control: a protan diagnosis seeds protan | ignoring the diagnosis (prior not seeded / default) |
| AC-5 | Complete the plate screening with a fixture that is R-G deficient → read endpoint shows screening completed | screening scored | reports **present == true** **and** **direction == redGreen**. Controls: a B-Y fixture → blueYellow; a no-deficiency fixture → present false | a scorer that always returns present, or that can't distinguish R-G from B-Y (graded vs `referenceBand`/direction reference) |
| AC-6 | Arrangement step showing a pool of unplaced caps → read endpoint: pool full, arranged empty | place a cap from the pool | that cap takes the **next** position in the arranged order (arranged.last == the placed cap; arranged length +1) **and** it is **removed from the pool** (pool no longer contains it; length −1) | a place that appends to a wrong index, duplicates, or leaves the cap in the pool |
| AC-7 | Place several caps → read endpoint: arranged length ≥ 2, pool reduced | start over (E39) | **all** caps return to the pool and **none** are placed (arranged empty; pool == full set) | a reset that clears only the last placement or leaves some arranged |
| AC-8 | Have not placed all caps (arranged partial) → read endpoint shows the arrangement incomplete | skip the arrangement (E43) | the flow continues **without** an arrangement result — read endpoint: advanced past arrangement, arrangementResult absent/null. Control: completing instead records a result | a skip that blocks, or that fabricates an arrangement result |
| AC-9 | Complete the adaptive threshold probing with a fixture → read endpoint shows probing completed | probing scored | yields a **severity value along the painter's confusion line** — read endpoint threshold severity in range and tied to the confusion line of the current type/direction. Control: an easier-threshold fixture yields a lower severity than a harder one | a scorer returning a constant, or a severity not tied to the confusion line (graded vs reference) |
| AC-10 | Reach the result step estimating **deutan** (via FLOW-5 enabler + deutan-leaning inputs) → read endpoint: estimate.type == deutan | set the type to **protan** (E40) | profile/estimate **type is protan** (read endpoint type == protan). Control: setting it back to deutan reads deutan | a control that ignores the override (type stays deutan) |
| AC-11 | On the result step setting severity (FLOW-5 reached) → read endpoint: on result step | set severity to 30 / 60 / 90 (E41) | result reads **"mild" / "moderate" / "strong"** respectively (exact band string per example row) | a mapping returning one band for all values, inverted, or off-by-one (graded vs `referenceBand`; the three distinct outputs are the control) |
| AC-12 | A simulated-vs-original pair shown with the severity slider on the result → read endpoint: pair shown, calibration unset | set severity until the pair stops looking different (set a value, confirm) | the chosen severity is **kept as the subjective self-calibration** — read endpoint calibratedSeverity == the set value, and it is the value saved as profile severity. Control: a different set value is kept instead | discarding the slider value / keeping a default severity |
| AC-13 | Result of **deutan-type, moderate** on the result step (FLOW-5 + ENGINE-7); store empty; `fixedPair` not confusable under the default profile → read endpoint: no profile persisted, confusion check uses default | save the profile (E43) | **one** stored CVD profile is written (`CvdProfileReadEndpoint` count == 1, {deutan, moderate-severity}); the live `AppDependencies.cvdProfile` now equals it; bs-03's `ConfusionCheck` on `fixedPair` changes to reflect the saved profile (control: before save it used the default). Sim/daltonization verified at the shared seam only (D-8, known gap) | a save that writes nothing, writes >1, or leaves the pipeline on the default profile |
| AC-14 | A self-assessment of four steps; advance to the second step → read endpoint: stepTotal == 4, stepIndex == 2 | on the second step | the progress indicator shows the **second of four** steps as current (rendered indicator reads 2 of 4; read endpoint stepIndex==2, stepTotal==4). Control: advancing again reads 3 of 4 | an indicator hard-coded to a step, or showing the wrong total |

**Red baseline** and **test augmentations:** tracked in [modules/ITEST.md](modules/ITEST.md).
Pre-seeded augmentations: AC-13's confusion-check behavioural assertion is confirmed once bs-03's check reads the live dependency after save (within PROFILE-2); no intra-feature test is green-at-baseline — each fails on its Then or on a precondition naming its behavior phase. Sim/dalt behavioural assertions are a **known gap** owned by bs-08/bs-10 (not a bs-07 augmentation row).

## Modules

| Module | Plan | Purpose | Depends on | Status |
|---|---|---|---|---|
| ENGINE | [modules/ENGINE.md](modules/ENGINE.md) | Scaffold + pure assessment domain: tier scoring (intake prior, screening presence/direction, threshold severity), estimate assembly inputs, severity→band | — | ⬜ Todo |
| PROFILE | [modules/PROFILE.md](modules/PROFILE.md) | Persist the one CVD profile over `PersistentStore`; wire `AppDependencies.cvdProfile` to the store; the save path | ENGINE | ⬜ Todo |
| FLOW | [modules/FLOW.md](modules/FLOW.md) | Onboarding controller + state + four-step flow + screens (lighting/intake/screening/arrangement/threshold/result) + read endpoint + route; estimate assembly; result-step behaviours | ENGINE, PROFILE | ⬜ Todo |
| ITEST | [modules/ITEST.md](modules/ITEST.md) | Acceptance integration suite: one pending test per AC, and its review | all shell phases | ⬜ Todo |

## Dependency graph

```mermaid
graph LR
  ENGINE-1 --> ENGINE-2 & PROFILE-1
  ENGINE-2 & PROFILE-1 --> FLOW-1
  FLOW-1 --> ITEST-1 --> ITEST-2 & ITEST-3
  ITEST-2 & ITEST-3 --> ITEST-4
  ITEST-4 --> FLOW-2 & FLOW-3 & ENGINE-3 & ENGINE-4 & ENGINE-5 & FLOW-4 & ENGINE-6
  ENGINE-3 & ENGINE-4 & ENGINE-5 & ENGINE-6 & FLOW-4 --> FLOW-5
  FLOW-5 --> ENGINE-7 & FLOW-6 & FLOW-7 & FLOW-8
  FLOW-5 & ENGINE-7 --> PROFILE-2
  ENGINE-7 & FLOW-6 & FLOW-7 & FLOW-8 & PROFILE-2 --> SIGNOFF-1
```

**Parallel windows:** ENGINE-2 ∥ PROFILE-1 (disjoint files). ITEST-2 ∥ ITEST-3 share `self_assessment_test.dart` → **merge-risky; run sequentially** (or split into two files included by the runner). Behavior phases mostly touch the shared `OnboardingController`/screens → run sequentially; ENGINE-3/4/5/6 are domain-heavy but each also wires a controller call, so pair any parallel run cautiously (merge-risky on the controller). FLOW-5 is a barrier before the result-step phases.

## Open gates

| Gate | Kind | Decision needed | Blocks | Status |
|---|---|---|---|---|
| G-1 | decision | Approve the spec (record approval as its first line, replacing the Draft banner) | ENGINE-1 | ✅ Resolved 2026-10-11 21:46 EDT: spec approved; Draft banner replaced with approval line — Matt Quirk |
| G-2 | decision | Approve the acceptance tests (ITEST-4's packet) | every behavior phase | Open |
| G-3 | dependency | bs-05 **and** bs-06 signed off and merged to `main` (the `PersistentStore`, the `self_assessment` entry seam and the pubspec superset land on main) — closed by the human merging `feat/bs-05` and `feat/bs-06` | ENGINE-1 | ✅ Resolved 2026-10-11 21:46 EDT: `feat/bs-05` (990a67a→merge 9760a4f) + `feat/bs-06` (e998bac→merge cd1c86b) merged to `main`; `persistent_store.dart`, `self_assessment_entry_screen.dart`, `router.toSelfAssessment()`, pubspec superset (drift/path_provider/printing) confirmed present; analyze clean + 849 unit tests green post-merge — Matt Quirk |
| G-4 | decision | Pin the profile persistence + scales: (a) persist via `PersistentStore` collection `cvd_profile`/id `current`, reusing `CvdProfile` unchanged; (b) slider 0..100 → severity 0..1; (c) band boundaries around the 30/60/90 anchors | PROFILE-1, ENGINE-7 | Open |
| G-5 | decision | Reconcile the four-step progress (AC-14) with the five tiers: which tiers are the four counted steps, and where screening (Tier 2) and threshold (Tier 4) sit (proposed D-4) — routed to the spec author | FLOW-2 | Open |

Resolved: `✅ Resolved <date time>: <decision, one line> — <who>`.

## Known flakes

| Test | Symptom | Rate (runs) | Measured at | Owner | Status |
|---|---|---|---|---|---|
| coverage_gate — const-constructor line | `flutter test --coverage` intermittently records a const-folded constructor line in `lib/**` as uncovered, so the gate may FAIL on a file this phase never touched | intermittent | first bs-01 `88c5add` | re-run `flutter test --coverage` once; green on re-run ⇒ ignore | Open |
| integration suite — no `-d <udid>` | `flutter test integration_test/…` with no booted device runs zero tests and still exits 0 (false green) | deterministic | bs-05/bs-06 | always pass `-d <booted-udid>` | Open |

## Session log

| # | Phase | Target | Status | Tokens | Time | Notes |
|---|---|---|---|---|---|---|
| 1 | ENGINE-1 | scaffold: branch from merged main, baseline, coverage gate confirm, bs07 pending runner (14 ACs) | ⬜ Next | | | G-1 ✅ · G-3 ✅ — startable |
| 2 | ENGINE-2 | shell: assessment domain types + `AssessmentEngine` interface | ⬜ Todo | | | ∥ PROFILE-1 |
| 3 | PROFILE-1 | shell: `CvdProfileStore` + `CvdProfileReadEndpoint` + `AppDependencies` wiring | ⬜ Todo | | | ∥ ENGINE-2 · G-4 |
| 4 | FLOW-1 | shell: `OnboardingController`/state + `OnboardingReadEndpoint` + screen host & keyed step widgets + route (replace placeholder) | ⬜ Todo | | | |
| 5 | ITEST-1 | acceptance-tests: harness, fixtures, pending gate (14 ACs), smoke test | ⬜ Todo | | | |
| 6 | ITEST-2 | acceptance-tests: AC-1,2,10,11,12,13,14 (pending) + red baseline | ⬜ Todo | | | seq before/after ITEST-3 |
| 7 | ITEST-3 | acceptance-tests: AC-3,4,5,6,7,8,9 (pending) + red baseline | ⬜ Todo | | | shares test file w/ ITEST-2 |
| 8 | ITEST-4 | test-review: packet; G-2 | ⬜ Todo | | | |
| 9 | FLOW-2 | AC-14 progress indicator | ⬜ Todo | | | G-5 |
| 10 | FLOW-3 | AC-2 lighting gate (Tier 0) | ⬜ Todo | | | |
| 11 | ENGINE-3 | AC-3 intake answer → prior (Tier 1) | ⬜ Todo | | | |
| 12 | ENGINE-4 | AC-4 diagnosis seeds prior (Tier 1) | ⬜ Todo | | | |
| 13 | ENGINE-5 | AC-5 screening presence + direction (Tier 2) | ⬜ Todo | | | |
| 14 | FLOW-4 | AC-6/7/8 arrangement place/start-over/skip (Tier 3) | ⬜ Todo | | | slice |
| 15 | ENGINE-6 | AC-9 threshold severity (Tier 4) | ⬜ Todo | | | |
| 16 | FLOW-5 | enabler: assemble estimate + advance to result step | ⬜ Todo | | | barrier before result-step ACs |
| 17 | ENGINE-7 | AC-11 severity → band (result) | ⬜ Todo | | | G-4 |
| 18 | FLOW-6 | AC-10 adjust type by hand (result) | ⬜ Todo | | | |
| 19 | FLOW-7 | AC-12 severity slider self-calibration (result) | ⬜ Todo | | | |
| 20 | FLOW-8 | AC-1 result caveat (result) | ⬜ Todo | | | |
| 21 | PROFILE-2 | AC-13 save profile configures the pipeline | ⬜ Todo | | | |
| 22 | SIGNOFF-1 | sign-off: packet + summary page + manual approval | ⬜ Todo | | | |

*Tokens* / *Time* = the phase totals from the *Token usage* ledger (Time = active, wall in brackets), filled when the row is marked done.

## Next phase

**ENGINE-1** (scaffold) is **startable** — both blocking gates are closed (G-1 ✅ spec approved; G-3 ✅ bs-05/bs-06 merged to `main` @ cd1c86b). Next session: branch `feat/bs-07-cvd-self-assessment` from `main` @ cd1c86b and run ENGINE-1 (baseline, coverage-gate confirm, bs07 pending runner over the 14 ACs). No `lib/` product code.

Still to decide, before the phases they block (not blocking ENGINE-1): **G-4** (persistence + severity/band scales; blocks PROFILE-1 & ENGINE-7) and **G-5** (four-step vs five-tier reconciliation; blocks FLOW-2). G-2 (approve acceptance tests) is decided later at ITEST-4.

## Token usage

<!-- One row per session, appended as that session's last edit (SKILL.md § Token usage). -->

| Phase / activity | Session | Start | End | Wall | Active | Model(s) | Input | Cache write | Cache read | Output | Total | Outcome |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PLAN | 7a934388 | 2026-10-11 21:04 EDT | 21:20 | 15m 39s | 15m 39s | claude-opus-4-8 | 56 | 194,229 | 1,861,476 | 56,221 | 2,111,982 | plan written |
| GATE-DECISION | 6e88f0bc | 2026-10-11 21:45 EDT | 21:58 | 13m 16s | 13m 16s | claude-opus-4-8 | 104 | 106,275 | 4,977,129 | 51,472 | 5,134,980 | G-1 approved (spec), G-3 resolved (bs-05 merge 9760a4f + bs-06 merge cd1c86b to main; analyze clean, 849 unit tests green) |
| **Feature total** |  | **2026-10-11 21:04 EDT** | **2026-10-11 21:58** | **28m 55s** | **28m 55s** |  | **160** | **300,504** | **6,838,605** | **107,693** | **7,246,962** |  |

## Sign-off

| Round | Packet | At code | Grades | Decision |
|---|---|---|---|---|
| 1 | [signoff/round-1.md](signoff/round-1.md) | `<commit>` | | ⏸ Not yet created |
