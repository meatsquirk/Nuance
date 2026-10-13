# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 ✅ done; next ITEST-2 ∥ ITEST-3 (share `nfr_test.dart` → sequence)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs12/nfr_harness.dart`, `integration_test/bs12/nfr_test.dart`. Consumes (does not own) the reusable guards in `integration_test/nfr/` (GUARD + QUALITY) and the `integration_test/bs12/pending.dart` gate (created by GUARD-1).
**Depends on:** GUARD-2, QUALITY-1 (the shells) · **Blocks:** every behavior phase (via the test review G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ✅ Done | 7.3M | 17m 59s |
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
- **Result (✅ Done 2026-10-13):**
  - **`nfr_harness.dart`** — the bs-12 Given/When/Then vocabulary over the real assembled app and the reusable NFR guards:
    - `enum NfrFlow {readout, capture, comparison, recipes, palette}` — the core flows the guards sweep (save-project + export both live on `palette`); `givenTheApp(tester, {flow, mixingEngine, confusionCheck, captureSource})` launches the real `buildApp` into the chosen flow through its `AppDependencies` entry (the one production assembly path, D-7), faking only `Speech`/`Haptics`, injecting the real `ColorScienceImpl`, and defaulting the two swap seams to the shipped impls (GUARD-5 passes the alternates). Returns `NfrHarness` {`tester`, `flow`, `speech`, `haptics`, `settle()`}.
    - Fixtures: `nfrRecipeTarget` (a reachable mid earth for the recipes flow), `nfrCaptureScene`/`nfrCaptureSource()` (a deterministic `FakeCaptureSource` scene).
    - **Re-exports** the pending gate (`acTestWidgets`), the platform fakes, and the six reusable guard/quality modules, so an AC test imports the harness alone. The guard/quality modules are `export`-only (the harness references none of their symbols directly — the AC tests do); offline/network use goes through the re-exported `runUnderNetworkBlock` wrapping a whole scenario body.
  - **`nfr_test.dart`** — the never-pending smoke + scaffold tests (ITEST-2/3 append the per-AC pending tests here):
    - **5 flow-launch smokes** — one per `NfrFlow`, asserting `buildApp` opens the expected home screen (`ReadoutScreen`/`CaptureHomeScreen`/`ComparisonHomeScreen`/`RecipesHomeScreen`/`PaletteHomeScreen`) + a real `MaterialApp` + inert sinks.
    - **6 guard/harness-wired tests** — offline guard runs a body & refuses an `HttpClient` (`NetworkBlockedException`), GUARD-2 sink inert; source guard's 5 scans empty over **populated** authorities (sizes/seam string pinned); accuracy harness grades the 3-sample seed set within bound by the independent `referenceDeltaE00`, ids & conditions pinned; perf harness `measure` within budget + `isTopCandidateCount` bounds; synthetic gamut one-in/one-out; swap harness assembles the real app.
    - **2 pending-gate guards** — the map is exactly the 16 automatable ACs {AC-1..4, AC-6..17} (AC-5 absent), count 16, every owner a real `behaviorPhase`; skip-by-default / run-in-run-pending (+ absent-AC always runs + ambient path agrees).
    - **2 fake-record tests** — `FakeSpeech` order, `FakeHaptics` count.
  - **Verification:** `flutter analyze` → No issues (whole project). Unit `flutter test --coverage` → **1228 passed** (unchanged; the new files are integration tests). Coverage gate (`dart run tool/coverage_gate.dart main`) → **100%** (no new `lib/` touched; the 2 QUALITY-1 `lib/capture` files still 100% vs `main`). Acceptance `flutter test integration_test/bs12/nfr_test.dart -d <iPhone 17 sim>` under `coord.sh with-lock` → **15 passed, exit 0** (all 16 ACs still pending, skipped by default; smoke green on the booted sim).
  - **Grade gate:** fresh independent subagent (adversarial, G1–G6 + scaffold rules) → **15 A / 0 B — PASS**; grid `../behavior-test-completeness-bs-12-non-functional-requirements.md`. Non-vacuous: source-guard pins authority contents/sizes/seam (not bare `isEmpty`), pending-map pins the exact 16-key set+count+ownership before its loop, flow smokes discriminate 5 distinct real home-screen types.
  - **Fix passes:** 0/3 (analyze + unit + coverage + acceptance + grade all green first pass).
  - **Tokens / Time:** see Dashboard / master ledger (ITEST-1 row).
- **Checkpoint / Handoff:**
  - **Verification commands:** `cd /Users/matthew.quirk/Nuance-bs12`; `export PATH=$PATH:/Users/matthew.quirk/development/flutter/bin`; `flutter analyze`; `flutter test --coverage`; `dart run tool/coverage_gate.dart main`; acceptance via `FNP_COORD_REPO=/Users/matthew.quirk/Nuance <scripts>/coord.sh with-lock bs-12 <PHASE> --wait 900 -- bash -c 'cd /Users/matthew.quirk/Nuance-bs12 && export PATH=… && flutter test integration_test/bs12/nfr_test.dart -d <booted-udid>'` (shared device lane → lock mandatory; booted `-d` mandatory — no `-d` ⇒ 0 tests/exit 0/false green; add `--dart-define=BS12_RUN_PENDING=true` for the ITEST-2/3 red baseline; whole-suite redirect to a file, don't tail). macOS has no `timeout`.
  - **Frozen for ITEST-2 / ITEST-3 (and the behaviour phases):**
    - `nfr_harness.dart`: `NfrFlow` {readout, capture, comparison, recipes, palette}, `givenTheApp(...)` → `NfrHarness` {tester, flow, speech, haptics, settle()}, fixtures `nfrRecipeTarget` / `nfrCaptureScene` / `nfrCaptureSource()`, and the re-exports (import the harness alone).
    - `nfr_test.dart`: AC tests register one `acTestWidgets('AC-n', …)` each in this file; ITEST-2 ∥ ITEST-3 **share this file → sequence them**. Run run-pending and record the red baseline (the table above).
  - **Known gaps / next:** **ITEST-2 is next** (AC-1,2,6,7,8,14,15,16,17 — the invariant guards, all pending), then ITEST-3 (AC-3,4,9,10,11,12,13), then ITEST-4 (test review = **G-2**). The guard/quality **behaviour** is still stubbed (offline sink inert, source scans empty, accuracy grades the fixture input directly, swap uses shipped impls), so each AC test lands red at baseline on its Then (or a Given naming its owning phase); the stubs are filled by GUARD-3..6 / QUALITY-2..5 **after G-2**. `givenTheApp` does not install the network block — a scenario that needs it wraps its whole body in `runUnderNetworkBlock`.

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
