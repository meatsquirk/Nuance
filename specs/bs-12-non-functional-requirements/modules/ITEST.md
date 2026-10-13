# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs12/nfr_harness.dart`, `integration_test/bs12/nfr_test.dart`. Consumes (does not own) the reusable guards in `integration_test/nfr/` (GUARD + QUALITY) and the `integration_test/bs12/pending.dart` gate (created by GUARD-1).
**Depends on:** GUARD-2, QUALITY-1 (the shells) · **Blocks:** every behavior phase (via the test review G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ⬜ Todo | | |
| ITEST-2 | acceptance-tests | AC-1,2,6,7,8,14,15,16,17 (pending) | ⬜ Todo | | |
| ITEST-3 | acceptance-tests | AC-3,4,9,10,11,12,13 (pending) | ⬜ Todo | | |
| ITEST-4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the real app via `buildApp(AppDependencies(...))` across every feature entry present on `main`; real engines, `ColorScience`, `deltaE00`, capture controller, and a test-executor-backed `drift` store (on-device SQLite semantics without a device file). Fakes: `FakeSpeech`, `FakeHaptics`, the `networkBlock` `HttpOverrides`, and the swap doubles `altMixingEngine`/`altConfusionCheck`. The control fixtures are deliberate — they exist only to prove each guard discriminates. **No colour math faked.**
- **Observation points:** the `networkBlock` attempt sink (AC-1/2/6/7/8); the feature read endpoints (flow completion, settling, out-of-gamut); `CaptureReadEndpoint` stated accuracy (AC-9); the single `deltaE00` over the synthetic set (AC-10/11/12); the source-guard offender lists (AC-16/17 + the AC-7/AC-8 dependency/path rules); `AppDependencies` call sites + source guard (AC-14/15); `Stopwatch` vs the CI budget (AC-3/4).
- **Pending gate:** `integration_test/bs12/pending.dart` — a `const Map<String,String> pendingACs` (AC → owning phase) + `Set<String> behaviorPhases`, keyed to `BS12_RUN_PENDING` (compile-time `--dart-define=BS12_RUN_PENDING=true` OR host env `=1`, matching bs02/03/04). `acTestWidgets(acId, desc, body)` passes `skip:` from `pendingSkipReason`, so pending ACs are **skipped, never failed**, by default. Un-pend = delete that AC's map entry. **16 ACs pending** at GUARD-1; **AC-5 never enters the gate** (pure-manual, D-3).

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_OfflineCoreFunctionsWork | FAIL | Then: zero-attempts / flow terminal (offline guard stub) | GUARD-3 | A |
| AC-2 | TestAC02_NoFunctionBlocksOnConnectivity | FAIL | Then: no-wait (stub) | GUARD-3 | A |
| AC-3 | TestAC03_ReadingSettlesWithIndicator | FAIL | Then: STABLE + budget (perf harness stub) | QUALITY-5 | A |
| AC-4 | TestAC04_RecipeSearchReturnsTopCandidates | FAIL | Then: 3–5 + budget (stub) | QUALITY-5 | A |
| AC-6 | TestAC06_PhotosAndSamplesStayOnDevice | FAIL | Then: zero-attempts + local-only (stub) | GUARD-4 | A |
| AC-7 | TestAC07_NoAccountNoTelemetry | FAIL | Then: no forbidden dep (source guard stub) | GUARD-4 | A |
| AC-8 | TestAC08_FutureSyncIsOptIn | FAIL | Then: no off-device sender (stub) | GUARD-4 | A |
| AC-9 | TestAC09_PoorConditionsDowngradeAccuracy | FAIL | Then: exposure/card downgrade (triggers absent) | QUALITY-2 | B pending QUALITY-2 |
| AC-10 | TestAC10_CardControlledMeetsDeltaE3 | FAIL | Given: synthetic set absent | QUALITY-4 | B pending QUALITY-4 |
| AC-11 | TestAC11_CardlessDaylightApproximateUnder8 | FAIL | Given: synthetic set absent | QUALITY-4 | B pending QUALITY-4 |
| AC-12 | TestAC12_RecipePredictionUnder5InGamut | FAIL | Given: synthetic set absent | QUALITY-4 | B pending QUALITY-4 |
| AC-13 | TestAC13_OutOfGamutNoFalseRecipe | FAIL | Then: identified + no-false-recipe (harness stub) | QUALITY-3 | A |
| AC-14 | TestAC14_MixingEngineSwappable | FAIL | Then: callers-unchanged (swap harness stub) | GUARD-5 | B pending GUARD-5 |
| AC-15 | TestAC15_CvdModelSwappable | FAIL | Then: callers-unchanged (stub) | GUARD-5 | B pending GUARD-5 |
| AC-16 | TestAC16_OneColourScienceLibrary | FAIL | Then: zero offenders (source guard stub) | GUARD-6 | A |
| AC-17 | TestAC17_OnlyNativeCaptureDiffersPerPlatform | FAIL | Then: zero offenders (stub) | GUARD-6 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC09 | the exposure/card downgrade triggers don't exist yet, so only lighting discriminates | QUALITY-2 | assert all three poor conditions downgrade + `control_trustworthyPoor` rejected | ⬜ Open |
| TestAC10/11/12 | `syntheticAccuracySet` + the accuracy harness are stubs | QUALITY-4 | the full synthetic set + the ΔE00 ≤ 3 / ≤ 8+approx / ≤ 5 asserts + perturbation controls | ⬜ Open |
| TestAC14/15 | the swap injection path is stubbed (callers not yet exercised through the alt impl) | GUARD-5 | inject the alt impl + assert callers unchanged + `control_boundToConcrete` fails | ⬜ Open |

## Phase ITEST-1 — harness + smoke

- **Kind:** acceptance-tests
- **Target AC:** — · **Depends on:** GUARD-2, QUALITY-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/bs12/nfr_harness.dart`, `integration_test/bs12/nfr_test.dart`
- **Tasks:** build the harness vocabulary (launch `buildApp` to each core flow; the `networkBlock`, `syntheticAccuracySet`, swap-double and control fixtures) over the GUARD/QUALITY stubs; wire the pending gate; a **never-pending smoke test** that calls each guard/harness stub and asserts it returns a populated (stub) result — proving the shells + harness are wired — plus that `pendingACs` keys name real phases and the count is exactly 16 (no vacuous pass).
- **Exit criteria:** suite green with all 16 ACs pending; smoke passes on a booted `-d`; grade gate on the harness/smoke (no vacuous passes, deterministic — poll, no fixed sleeps).

## Phase ITEST-2 — AC tests: invariant guards (pending)

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-6, AC-7, AC-8, AC-14, AC-15, AC-16, AC-17 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · **seq w/ ITEST-3**
- **Tasks:** write `TestAC01/02/06/07/08/14/15/16/17_*` per the master catalogue — each asserting the invariant holds over the real app/source **and** its control fixture fails. Run run-pending; record the red baseline.
- **Exit criteria:** suite green with these pending; red baseline recorded (each fails on its Then or a Given naming its phase); grade gate (all A, or *B pending <phase>* with an augmentation row — AC-14/15 → B pending GUARD-5).

## Phase ITEST-3 — AC tests: quality targets (pending)

- **Kind:** acceptance-tests
- **Target AC:** AC-3, AC-4, AC-9, AC-10, AC-11, AC-12, AC-13 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · **shares test file w/ ITEST-2**
- **Tasks:** write `TestAC03/04/09/10/11/12/13_*` per the catalogue (AC-3/4 with the CI budget; AC-9 across the three conditions; AC-10/11/12 over the synthetic set with the independent reference ΔE; AC-13 with the in-gamut control). Run run-pending; record the red baseline.
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate (AC-9 → *B pending QUALITY-2*; AC-10/11/12 → *B pending QUALITY-4*; others A).

## Phase ITEST-4 — test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (the catalogue, the red baseline, the fixtures, what is real vs faked, the controls, the pre-seeded augmentations, the three known gaps D-2/D-3) for a human; whole-suite grade grid; set the gate awaiting a decision.
- **Exit criteria:** whole-suite grade grid all A (or *B pending <phase>*); packet written; **G-2 awaiting a human decision** (`/feature-next-phase --gate bs12 G-2 approved`).
