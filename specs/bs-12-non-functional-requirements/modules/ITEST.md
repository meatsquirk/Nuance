# Module ITEST — acceptance integration suite

**Status:** ✅ Done — ITEST-1/2/3/4 all done; G-2 approved 2026-10-14 by Matt Quirk (behaviour stage un-blocked)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs12/nfr_harness.dart`, `integration_test/bs12/nfr_test.dart`. Consumes (does not own) the reusable guards in `integration_test/nfr/` (GUARD + QUALITY) and the `integration_test/bs12/pending.dart` gate (created by GUARD-1).
**Depends on:** GUARD-2, QUALITY-1 (the shells) · **Blocks:** every behavior phase (via the test review G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ✅ Done | 7.3M | 17m 59s |
| ITEST-2 | acceptance-tests | AC-1,2,6,7,8,14,15,16,17 (pending) | ✅ Done | 27.1M | 1h 00m (3h 13m) |
| ITEST-3 | acceptance-tests | AC-3,4,9,10,11,12,13 (pending) | ✅ Done | 19.0M | 47m 22s |
| ITEST-4 | test-review | — (G-2) | ✅ Done | 1.89M | 4m 22s |

## Interface reconciliation

- **Boundary:** the real app via `buildApp(AppDependencies(...))` across every feature entry present on `main`; real engines, `ColorScience`, `deltaE00`, capture controller, and a test-executor-backed `drift` store (on-device SQLite semantics without a device file). Fakes: `FakeSpeech`, `FakeHaptics`, the `networkBlock` `HttpOverrides`, and the swap doubles `altMixingEngine`/`altConfusionCheck`. The control fixtures are deliberate — they exist only to prove each guard discriminates. **No colour math faked.**
- **Observation points:** the `networkBlock` attempt sink (AC-1/2/6/7/8); the feature read endpoints (flow completion, settling, out-of-gamut); `CaptureReadEndpoint` stated accuracy (AC-9); the single `deltaE00` over the synthetic set (AC-10/11/12); the source-guard offender lists (AC-16/17 + the AC-7/AC-8 dependency/path rules); `AppDependencies` call sites + source guard (AC-14/15); `Stopwatch` vs the CI budget (AC-3/4).
- **Pending gate:** `integration_test/bs12/pending.dart` — a `const Map<String,String> pendingACs` (AC → owning phase) + `Set<String> behaviorPhases`, keyed to `BS12_RUN_PENDING` (compile-time `--dart-define=BS12_RUN_PENDING=true` OR host env `=1`, matching bs02/03/04). `acTestWidgets(acId, desc, body)` passes `skip:` from `pendingSkipReason`, so pending ACs are **skipped, never failed**, by default. Un-pend = delete that AC's map entry. **16 ACs pending** at GUARD-1; **AC-5 never enters the gate** (pure-manual, D-3).
- **ITEST-2 harness additions** (`nfr_harness.dart`, ITEST-owned): `givenTheApp` gained pass-through optionals `paletteSource` (defaults to a seeded `nfrPalette` so the recipes flow returns candidates), `projectSource`, `sourcePhotoStore`, `pdfShareSink`; `NfrHarness` gained read-endpoint getters (`captureState`/`recipeState`/`projectController`) and when-actions (`whenLockCapture`/`whenCommitCapture`/`whenCaptureCommittedReading`/`whenOpenAndExportProject`); fixtures `nfrPalette` + `nfrSeededProject` + `givenPaletteWithSeededProject`; and the recording swap doubles `RecordingMixingEngine` / `RecordingConfusionCheck` (delegate to the shipped impls, count interface calls). A commit/navigation must be the final launch in a test — a navigating action bleeds into a subsequent fresh `pumpWidget` launch (observed), so AC-1/AC-6 isolate the capture-commit last (with a reset pump).
- **Source-guard scan signatures** (`nfr/guards/source_guard.dart`, GUARD-owned — extended by ITEST-2 under the user-approved "B-pending via fixtures" decision, **kept stubbed**): every rule scan gained an optional planted-input argument the real scan (GUARD-4/5/6) must honour — `conversionOffenders`/`deltaEOffenders`/`platformOffenders`/`offDeviceSenders({Iterable<String> roots = kDefaultSourceRoots})`, `forbiddenDependencies({Iterable<String>? resolvedNames})`, and a new `concreteTypeReferences(String typeName, {roots})` (+ `ruleConcreteTypeReference`) for AC-14/15. An AC test points a rule at `kControlFixturesRoot` (`integration_test/nfr/fixtures/controls/`) to assert a planted offender is flagged; the real invariant sweep uses the default `lib/` root. Planted control fixtures: `control_off_device_sender.dart` (AC-8), `control_stray_colour_math.dart` (AC-16), `control_platform_dart.dart` (AC-17), `control_bound_to_concrete.dart` (AC-14).

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | `acTestWidgets('AC-1', …)` | FAIL (as designed) | Then: control `sink.attempts > 0` (sink inert until GUARD-3); sweep of all 5 flows + capture-commit pass | GUARD-3 | A ✅ (ITEST-2) |
| AC-2 | `acTestWidgets('AC-2', …)` | FAIL (as designed) | Then: control `sink.attempts > 0` (GUARD-3); 5-flow completion sweep passes | GUARD-3 | A ✅ (ITEST-2) |
| AC-3 | `acTestWidgets('AC-3', …)` | **PASS (green at baseline)** | — bs-02's frame-settle + `stabilityKey` indicator already satisfy it: indicator visible, reaches `STABLE 12/12`, commits, within the 10s CI budget | QUALITY-5 (un-pend + guard) | A ✅ (ITEST-3) |
| AC-4 | `acTestWidgets('AC-4', …)` | **PASS (green at baseline)** | — bs-04's `topK=5` search already returns 3–5 ranked candidates + `hasRecipes`, within the 10s CI budget | QUALITY-5 (un-pend + guard) | A ✅ (ITEST-3) |
| AC-6 | `acTestWidgets('AC-6', …)` | FAIL (as designed) | Then: control `sink.attempts > 0` (GUARD-4); save+export (real `%PDF-` bytes to on-device sink) + capture-commit pass | GUARD-4 | A ✅ (ITEST-2) |
| AC-7 | `acTestWidgets('AC-7', …)` | FAIL (as designed) | Then: control — `forbiddenDependencies(resolvedNames: {…,'firebase_analytics'})` flags it (scan stub); real-sweep isEmpty + no-account pass | GUARD-4 | B pending GUARD-4 (ITEST-2) |
| AC-8 | `acTestWidgets('AC-8', …)` | FAIL (as designed) | Then: control — `offDeviceSenders(roots: [controls])` flags the planted sender (scan stub); real-sweep isEmpty passes | GUARD-4 | B pending GUARD-4 (ITEST-2) |
| AC-9 | `acTestWidgets('AC-9', …)` | FAIL (as designed) | Then: a low-light / unlocked-exposure reading, card-calibrated, commits `calibrated` — must be `approximate` (`commit` ignores `activeDowngradeReasons` until QUALITY-2); control (trustworthy stays calibrated) + low-light + unlocked branches drive the red; missing-card branch passes today (already approximate) | QUALITY-2 | B pending QUALITY-2 (ITEST-3) |
| AC-10 | `acTestWidgets('AC-10', …)` | FAIL (as designed) | Given: full card+controlled held-out set absent — seed set has 1 sample (`length ≥ 3` precondition names QUALITY-4); grades by independent `referenceDeltaE00` | QUALITY-4 | B pending QUALITY-4 (ITEST-3) |
| AC-11 | `acTestWidgets('AC-11', …)` | FAIL (as designed) | Given: full card-less daylight held-out set absent — seed 1 (`length ≥ 3` names QUALITY-4); asserts ≤ 8 + `expectApproximate` | QUALITY-4 | B pending QUALITY-4 (ITEST-3) |
| AC-12 | `acTestWidgets('AC-12', …)` | FAIL (as designed) | Given: full recipe-vs-swatch held-out set absent — seed 1 (`length ≥ 3` names QUALITY-4); asserts ≤ 5 | QUALITY-4 | B pending QUALITY-4 (ITEST-3) |
| AC-13 | `acTestWidgets('AC-13', …)` | **PASS (green at baseline)** | — bs-04 ENGINE-5 already flags the out-of-gamut target (`recipeState.outOfGamut` + shown `OUT OF GAMUT` marker + every recipe `outOfGamut`), and the in-gamut control is not flagged and returns recipes | QUALITY-3 (un-pend + guard) | A ✅ (ITEST-3) |
| AC-14 | `acTestWidgets('AC-14', …)` | FAIL (as designed) | Then: static control — `concreteTypeReferences('SubtractiveMixingEngine', roots: [controls])` flags the planted bound-to-concrete caller (scan stub); **dynamic swap proof** (alt `inverseCalls > 0` + recipes via the alt) passes | GUARD-5 | B pending GUARD-5 (ITEST-2) |
| AC-15 | `acTestWidgets('AC-15', …)` | FAIL (as designed) | Then: `confusableCalls > 0` — no primitive drives a CVD caller yet (GUARD-5 drives compare/display/onboarding) | GUARD-5 | B pending GUARD-5 (ITEST-2) |
| AC-16 | `acTestWidgets('AC-16', …)` | FAIL (as designed) | Then: controls — `conversionOffenders`/`deltaEOffenders(roots: [controls])` flag the planted stray maths (scan stub); real-lib sweep isEmpty passes | GUARD-6 | B pending GUARD-6 (ITEST-2) |
| AC-17 | `acTestWidgets('AC-17', …)` | FAIL (as designed) | Then: control — `platformOffenders(roots: [controls])` flags the planted platform code (scan stub); real-lib sweep isEmpty passes | GUARD-6 | B pending GUARD-6 (ITEST-2) |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| AC-9 (`acTestWidgets('AC-9', …)`) | ITEST-3 asserts all three conditions downgrade + the trustworthy control, but `commit` ignores `activeDowngradeReasons`, so the low-light & unlocked branches are red and the missing-card branch passes trivially (a card-less reading is already approximate) | QUALITY-2 | wire `commit` to downgrade to approximate on any active reason, so all three branches discriminate (missing-card labelled approximate *because of* the card) + `control_trustworthyPoor` stays calibrated | ⬜ Open |
| AC-10/11/12 (`acTestWidgets('AC-10'…/'AC-11'…/'AC-12'…)`) | the held-out set is QUALITY-1's 1-sample-per-condition seed (the `length ≥ 3` Given trips red) and the harness grades the fixture input directly, not the real pipeline | QUALITY-4 | the full synthetic held-out set (≥3/condition incl. a perturbation control that exceeds the bound) fed through the real capture / engine pipeline, graded by independent `referenceDeltaE00` — asserts ΔE00 ≤ 3 / ≤ 8 + approximate / ≤ 5 | ⬜ Open |
| TestAC07 | `forbiddenDependencies()` is a stub (empty), so the real-sweep is vacuous and only the planted-name control discriminates | GUARD-4 | the real resolved-pubspec/lockfile scan honouring `resolvedNames`, so the sweep is real and the planted `firebase_analytics` is flagged | ✅ Done (GUARD-4 2026-10-14) — real `pubspec.lock` scan + `resolvedNames` intersection; AC-7 re-graded A |
| TestAC08 | `offDeviceSenders()` is a stub (empty) | GUARD-4 | the real source scan honouring `roots`, so the sweep is real and `control_off_device_sender.dart` is flagged | ✅ Done (GUARD-4 2026-10-14) — real `_scanSource` over `lib/`/`roots` with comment-string masking; AC-8 re-graded A |
| TestAC14 | the **dynamic** swap is proven today, but no source scan yet enforces the **static** "no caller references the concrete `SubtractiveMixingEngine`" guarantee — only the planted control discriminates | GUARD-5 (using GUARD-6's scan infra) | implement `concreteTypeReferences` so the real-lib sweep is a real scan and `control_bound_to_concrete.dart` is flagged | ⬜ Open |
| TestAC15 | no harness primitive drives a CVD caller through the injected `ConfusionCheck` yet (needs a completed two-slot comparison / display flow) | GUARD-5 | drive a CVD caller so `confusableCalls > 0` + assert callers unchanged + the concrete `DichromatConfusionCheck` is not referenced by a caller | ⬜ Open |
| TestAC16 | `conversionOffenders()`/`deltaEOffenders()` are stubs (empty) | GUARD-6 | the real conversion/ΔE source scans honouring `roots`, so the sweep is real and `control_stray_colour_math.dart` is flagged | ⬜ Open |
| TestAC17 | `platformOffenders()` is a stub (empty) | GUARD-6 | the real platform source scan honouring `roots`, so the sweep is real and `control_platform_dart.dart` is flagged | ⬜ Open |

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
- **Result (✅ Done 2026-10-13):**
  - Nine *pending* AC tests added to `integration_test/bs12/nfr_test.dart` as `acTestWidgets('AC-n', …)` (group *bs-12 acceptance criteria — invariant guards (ITEST-2)*), each asserting its invariant over the **real** app/source **and** discriminated by a control that fails at baseline:
    - **AC-1 / AC-2 / AC-6 (offline + privacy, grade A):** sweep every `NfrFlow` under `runUnderNetworkBlock` — AC-1 reaches a terminal state per flow (readout name shown, recipes non-empty, projects loaded, + a capture committed last), AC-2 proves each settles without blocking, AC-6 drives save+export (real `%PDF-` bytes to an on-device `pdfShareSink`) + a committed capture. Each asserts `sink.attempts == 0` and is discriminated by the **counting control** (`sink.attempts > 0` after a deliberate refused touch) — red until the owning phase wires `sink.record()`.
    - **AC-7 / AC-8 (privacy source rules, B pending GUARD-4):** real-sweep `forbiddenDependencies()` / `offDeviceSenders()` isEmpty (+ no account surface); controls `forbiddenDependencies(resolvedNames: {…,'firebase_analytics'})` and `offDeviceSenders(roots: [controls])` flag the planted offender.
    - **AC-14 / AC-15 (swap seams, B pending GUARD-5):** AC-14 drives the real recipe caller through an injected `RecordingMixingEngine` (dynamic swap proof — `inverseCalls > 0` + recipes, passes today) + a static control that a bound-to-concrete caller is flagged (`concreteTypeReferences`, red); AC-15 asserts a CVD caller drives an injected `RecordingConfusionCheck` (`confusableCalls > 0`, red — no primitive drives one yet).
    - **AC-16 / AC-17 (one-library + portability, B pending GUARD-6):** real-lib sweeps isEmpty; controls over `kControlFixturesRoot` flag the planted stray-maths / platform fixtures.
  - **Verification:** `flutter analyze` → No issues (whole project). Unit `flutter test --coverage` → **1228 passed** (unchanged — integration tests). Coverage gate (`dart run tool/coverage_gate.dart main`) → **100%** on the 2 touched `lib/` files (QUALITY-1's AC-9 seam; ITEST-2 touched no `lib/`). Acceptance (device lock, booted iPhone 17 sim): default `flutter test integration_test/bs12/nfr_test.dart -d <udid>` → **+15 pass / ~9 skipped / exit 0** (suite green, the 9 ACs pending); run-pending `--dart-define=BS12_RUN_PENDING=true` → **+15 / −9 / exit 1** — all 9 fail on exactly their control / limit Then naming the owning phase (clean red baseline).
  - **Grade gate:** fresh independent adversarial subagent → **3 A / 6 B pending / 0 ordinary B — PASS** (A: AC-1/2/6; B pending GUARD-4: AC-7/8; GUARD-5: AC-14/15; GUARD-6: AC-16/17). The grader first flagged AC-14 as an ordinary B (its dynamic discriminator was drivable now); fixed by driving the recipes caller (dynamic proof) + a genuinely-pending static concrete-reference control, then re-verified → B pending GUARD-5. Grid: `../behavior-test-completeness-bs-12-non-functional-requirements.md` (§ ITEST-2).
  - **Augmentations:** six open rows (AC-7/8 → GUARD-4; AC-14/15 → GUARD-5; AC-16/17 → GUARD-6) — see the Test augmentations table; each planted control fixture is in place.
  - **Decision folded in:** per the user's "B-pending via fixtures" choice, the GUARD-owned source scans were extended with optional planted-input args (kept stubbed) + planted-offender fixtures under `integration_test/nfr/fixtures/controls/`; the four source-scan ACs grade *B pending* (not the plan's pre-seeded A), amended here.
  - **Fix passes:** 2/3 — (1) AC-1/AC-6 re-ordered so the capture-commit is the final launch (a navigating action bled into the next fresh launch); (2) AC-14 reworked from ordinary-B to the dynamic-proof + static-control design.
  - **Tokens / Time:** see Dashboard / master ledger (ITEST-2 row).
- **Checkpoint / Handoff:**
  - **Verification commands:** unchanged — `cd /Users/matthew.quirk/Nuance-bs12`; `export PATH=$PATH:/Users/matthew.quirk/development/flutter/bin`; `flutter analyze`; `flutter test --coverage`; `dart run tool/coverage_gate.dart main`; acceptance via `FNP_COORD_REPO=/Users/matthew.quirk/Nuance <scripts>/coord.sh with-lock bs-12-non-functional-requirements <PHASE> --wait 900 -- bash -c 'cd …/Nuance-bs12 && export PATH=… && flutter test integration_test/bs12/nfr_test.dart -d <booted-udid> [--dart-define=BS12_RUN_PENDING=true]'` (shared device lane → lock mandatory; booted `-d` mandatory; whole-suite redirect to a file, don't tail).
  - **Frozen for ITEST-3:** the harness surface above (import `nfr_harness.dart` alone). ITEST-3 writes `AC-3/4/9/10/11/12/13` in the **same** `nfr_test.dart` — **ITEST-2 and ITEST-3 share the file → ITEST-3 runs after ITEST-2 (done)**. The perf harness (`PerfHarness`, `kCaptureSettleCiBudget`, `isTopCandidateCount`, `kMin/MaxTopCandidates`) and accuracy harness + `syntheticAccuracySet` / `syntheticGamutTargets` are the ITEST-3 seams.
  - **Known gaps / next:** **ITEST-3 is next** (AC-3,4,9,10,11,12,13), then ITEST-4 (test review = **G-2**). All GUARD/QUALITY behaviour phases stay blocked on G-2. The six B-pending augmentations are owed by GUARD-4/5/6; the source scans are stubs returning empty (real-lib sweeps pass vacuously) until then — their owning phase makes the sweep a real scan honouring the planted-input args. Env gotchas unchanged (no `timeout` on macOS; teardown race on full-suite runs — not hit this session; the `nfr_test.dart`-only runs here were clean).

## Phase ITEST-3 — AC tests: quality targets (pending)

- **Kind:** acceptance-tests
- **Target AC:** AC-3, AC-4, AC-9, AC-10, AC-11, AC-12, AC-13 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · **shares test file w/ ITEST-2**
- **Tasks:** write `TestAC03/04/09/10/11/12/13_*` per the catalogue (AC-3/4 with the CI budget; AC-9 across the three conditions; AC-10/11/12 over the synthetic set with the independent reference ΔE; AC-13 with the in-gamut control). Run run-pending; record the red baseline.
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate (AC-9 → *B pending QUALITY-2*; AC-10/11/12 → *B pending QUALITY-4*; others A).
- **Result (✅ Done 2026-10-13):**
  - Seven *pending* AC tests added to `integration_test/bs12/nfr_test.dart` (group *bs-12 acceptance criteria — quality targets (ITEST-3)*) as `acTestWidgets('AC-n', …)`, each through the real assembled app / real engines:
    - **AC-3 / AC-4 (performance — hybrid, D-3; A, green at baseline):** AC-3 launches the Capture flow, asserts the `stabilityKey` indicator is visible and reflects the real settle state (`SETTLING n/12` / `STABLE 12/12`), then lock+commit reaches `STABLE 12/12` and lands `lastCommittedSample`, all under `PerfHarness.measure(kCaptureSettleCiBudget=10s)`. AC-4 times a recipe search and asserts `isTopCandidateCount` (3–5) + `hasRecipes` under `kRecipeSearchCiBudget`. Both are **satisfied by bs-02 / bs-04 behaviour already on `main`** → green at baseline (CI budget is a regression ceiling, NOT the device ~1–2s, which is owner evidence at SIGNOFF under G-3). AC-4 deliberately omits a ΔE-ordering assert (bs-04 ranks best-first by a composite incl. prefer-fewer, D-8).
    - **AC-9 (reliability; B pending QUALITY-2):** commits a reading under each of low-light / unlocked-exposure / missing-card and asserts the stated accuracy is downgraded to `approximate`, never trustworthy; control: a well-lit, locked, card-calibrated reading has no downgrade reason and stays `calibrated`. Red at baseline because `commit` ignores the (QUALITY-1-wired) `activeDowngradeReasons` seam — the low-light & unlocked branches commit `calibrated`.
    - **AC-10/11/12 (accuracy, D-2; B pending QUALITY-4):** grade the synthetic set per condition with the **independent** `referenceDeltaE00` (≤ 3 / ≤ 8 + approximate / ≤ 5). Red at baseline on a `length ≥ 3` Given precondition naming QUALITY-4 (QUALITY-1's seed set has one sample per condition).
    - **AC-13 (out-of-gamut; A, green at baseline):** drives the real engine toward the synthetic out-of-gamut target (new ITEST-owned `givenTheApp(recipeTarget:)` param) and asserts `recipeState.outOfGamut` + the shown `OUT OF GAMUT` marker + every recipe `outOfGamut`; control: the in-gamut target is not flagged, shows no marker, and returns recipes. **Satisfied by bs-04 ENGINE-5 already on `main`** → green at baseline.
  - **Harness additions (ITEST-owned, `nfr_harness.dart`):** `givenTheApp` gained a `recipeTarget` pass-through (AC-4/AC-13); the AC-9 condition scenes `nfrLowLightScene` / `nfrUnlockedScene` / `nfrMissingCardScene` / `nfrTrustworthyScene`; `NfrHarness.whenCalibrate()` (E17) and the `activeDowngradeReasons` getter (reads the capture controller's seam). No `lib/` product code (D-7).
  - **Verification:** `flutter analyze` → No issues. Unit `flutter test --coverage` → **1228 passed** (unchanged — integration tests only; one run hit the known full-suite teardown flake in `palette_screen_test`, 12/12 green in isolation and on re-run). Coverage gate (`dart run tool/coverage_gate.dart main`) → **100%** on the 2 touched `lib/` files (QUALITY-1's seam; ITEST-3 touched no `lib/`). Acceptance on the booted iPhone 17 sim under the device lock: default `flutter test integration_test/bs12/nfr_test.dart -d <udid>` → **+15 / ~16 skipped / exit 0** (suite green, all 16 ACs pending); run-pending `--dart-define=BS12_RUN_PENDING=true` → **+18 / −13** — the 4 ITEST-3 red tests fail on exactly their Then/Given naming the owning phase, and AC-3/AC-4/AC-13 pass (green at baseline), while the 9 ITEST-2 tests stay red (clean baseline).
  - **Grade gate:** fresh independent adversarial subagent (G1–G6) → **3 A / 4 B pending / 0 ordinary B — PASS** (A: AC-3/AC-4/AC-13; B pending QUALITY-2: AC-9; B pending QUALITY-4: AC-10/11/12). The grader first flagged AC-13's banner assertion as an ordinary B (`find.byKey(GamutBanner.regionKey)` does not discriminate — the key stays in the tree collapsed when in-gamut); fixed by asserting the shown `GamutBanner.markerText` (+ `findsNothing` in the in-gamut control) and re-verified green → A. Grid: `../behavior-test-completeness-bs-12-non-functional-requirements.md` (§ ITEST-3).
  - **Augmentations:** two open rows — AC-9 → QUALITY-2; AC-10/11/12 → QUALITY-4 (see the Test augmentations table). AC-3/AC-4/AC-13 are green-at-baseline A with no augmentation.
  - **Green-at-baseline note (flag for ITEST-4 / G-2):** AC-3, AC-4 and AC-13 need **no new behaviour** — bs-02 (frame-settle + indicator), bs-04 (`topK=5` search) and bs-04 ENGINE-5 (out-of-gamut) already satisfy them. Their owning phases (QUALITY-5 for AC-3/4, QUALITY-3 for AC-13) therefore become **un-pend + guard/coverage-confirm** phases, not new-behaviour builds; they still run to un-pend each AC and keep it green. The human may fold / retarget them at the test review.
  - **Fix passes:** 2/3 — (1) AC-3 harness error (`tester.widget<Text>` found nothing once the commit pushed Readout offstage → read the settle state through the endpoint + split lock/commit) and AC-4's incorrect ΔE-monotonic ranking assert removed; (2) AC-13 banner marker (ordinary-B fix).
  - **Tokens / Time:** see Dashboard / master ledger (ITEST-3 row).
- **Checkpoint / Handoff:**
  - **Verification commands:** unchanged — `cd /Users/matthew.quirk/Nuance-bs12`; `export PATH=$PATH:/Users/matthew.quirk/development/flutter/bin`; `flutter analyze`; `flutter test --coverage`; `dart run tool/coverage_gate.dart main`; acceptance via `FNP_COORD_REPO=/Users/matthew.quirk/Nuance <scripts>/coord.sh with-lock bs-12-non-functional-requirements <PHASE> --wait 1500 -- bash -c 'cd …/Nuance-bs12 && export PATH=… && flutter test integration_test/bs12/nfr_test.dart -d <booted-udid> [--dart-define=BS12_RUN_PENDING=true]'` (shared device lane → lock mandatory; booted `-d` mandatory).
  - **Frozen for ITEST-4 / the behaviour phases:** the harness surface above (import `nfr_harness.dart` alone) incl. the `recipeTarget` param, AC-9 scenes, `whenCalibrate`, `activeDowngradeReasons`. All 16 ACs stay pending (no un-pend in ITEST-3). ITEST-2 ∥ ITEST-3 are both done → `nfr_test.dart` holds all 16 AC tests; behaviour phases un-pend by deleting the AC's row in `bs12/pending.dart`.
  - **Known gaps / next:** **ITEST-4 is next** (test review = **G-2**) — assemble the packet (the catalogue, the red baseline incl. the 3 green-at-baseline ACs + the recommendation to reduce QUALITY-3/5 to un-pend+guard, the augmentations, the D-2/D-3 gaps), whole-suite grade grid, set G-2 awaiting a human decision. All GUARD/QUALITY behaviour phases stay blocked on G-2. Env gotchas unchanged (no `timeout` on macOS; full-suite teardown flake — not hit on the `nfr_test.dart`-only runs this session).

## Phase ITEST-4 — test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (the catalogue, the red baseline, the fixtures, what is real vs faked, the controls, the pre-seeded augmentations, the three known gaps D-2/D-3) for a human; whole-suite grade grid; set the gate awaiting a decision.
- **Exit criteria:** whole-suite grade grid all A (or *B pending <phase>*); packet written; **G-2 awaiting a human decision** (`/feature-next-phase --gate bs12 G-2 approved`).

### Review packet — G-2 (⏸ Awaiting review)

Reviewer, this is the gate before any bs-12 behaviour is coded. The suite is **16 pending acceptance tests**
(one per automated AC; AC-5 is pure-manual, D-3) over the **real assembled app** (`buildApp(deps)` across every
feature merged on `main` @ `ecd3a9e`), plus 15 never-pending harness/smoke tests. No colour math is faked.

**Look at these first (the three things the review is really deciding):**
1. **The green-at-baseline recommendation.** AC-3, AC-4, AC-13 already pass at baseline — bs-02's frame-settle +
   `stabilityKey` indicator (AC-3), bs-04's `topK=5` ranked search (AC-4) and bs-04 ENGINE-5's out-of-gamut flag
   (AC-13) already satisfy them. **Recommendation:** reduce their owning phases **QUALITY-5 (AC-3/4)** and
   **QUALITY-3 (AC-13)** from new-behaviour builds to **un-pend + guard/confirm** phases (delete the pending entry,
   add a regression guard, keep green). No new behaviour is owed for those three ACs. You may fold/retarget them.
2. **The two known gaps carried to sign-off** (not closable in bs-12): **D-2** — AC-10/11/12 are proven against a
   **synthetic** held-out dataset, *not* physical spectrophotometer/mixed-swatch ground truth (graded by the
   independent `referenceDeltaE00`, never the product metric against itself); **D-3** — AC-3/AC-4's literal
   "~1–2 s on target hardware" and **AC-5**'s live-preview frame rate are **owner on-device evidence at SIGNOFF
   (G-3)**; CI only gates the mechanism + a generous regression budget, never the device figure.
3. **The B-pending grades are all later-*behaviour* limits, never weak tests.** 10 of the 16 AC tests are
   *B pending `<phase>`*: their discriminating control exists and is correct but cannot go green until the named
   behaviour phase lands (a source scan, a downgrade trigger, the full synthetic set). Each has a Test-augmentations
   row naming the closing phase. Confirm you accept that coupling (it mirrors the approved bs-10/bs-11 pattern).

**Per-AC roster** (full Given/When/Then/Rejects in the master plan's *Test catalogue*; red-baseline detail in the
*Red baseline* table above). *G-at-B = green at baseline.*

| AC | Test (`acTestWidgets`) | What it proves · its control | Baseline | Grade | Closed / un-pended by |
|---|---|---|---|---|---|
| AC-1 | `AC-1` offline | every core flow completes under the network block, zero attempts · control touches the block | FAIL (as designed) | **A** | GUARD-3 |
| AC-2 | `AC-2` no-blocking | each flow settles without awaiting a connection · control cannot complete | FAIL (as designed) | **A** | GUARD-3 |
| AC-3 | `AC-3` settle+indicator | indicator → `STABLE 12/12`, commits, under CI budget | **PASS (G-at-B)** | **A** | QUALITY-5 (un-pend+guard) |
| AC-4 | `AC-4` search budget | 3–5 ranked candidates under CI budget | **PASS (G-at-B)** | **A** | QUALITY-5 (un-pend+guard) |
| AC-6 | `AC-6` on-device | save+export (real `%PDF-` bytes to on-device sink), zero network · counting control | FAIL (as designed) | **A** | GUARD-4 |
| AC-7 | `AC-7` no-account | `forbiddenDependencies()` empty + no account surface · planted `firebase_analytics` flagged | FAIL (as designed) | **B pending GUARD-4** | GUARD-4 |
| AC-8 | `AC-8` sync opt-in | `offDeviceSenders()` empty · planted off-device sender flagged | FAIL (as designed) | **B pending GUARD-4** | GUARD-4 |
| AC-9 | `AC-9` downgrade | low-light / unlocked / missing-card commit `approximate` · trustworthy control stays `calibrated` | FAIL (as designed) | **B pending QUALITY-2** | QUALITY-2 |
| AC-10 | `AC-10` ΔE≤3 | card+controlled set ≤ 3 by independent ref ΔE · perturbation control exceeds | FAIL (as designed) | **B pending QUALITY-4** | QUALITY-4 |
| AC-11 | `AC-11` ΔE≤8 | card-less daylight ≤ 8 + approximate label · mislabelled control fails | FAIL (as designed) | **B pending QUALITY-4** | QUALITY-4 |
| AC-12 | `AC-12` ΔE≤5 | recipe-vs-swatch in-gamut ≤ 5 · perturbation control exceeds | FAIL (as designed) | **B pending QUALITY-4** | QUALITY-4 |
| AC-13 | `AC-13` out-of-gamut | out-of-gamut target flagged + no recipe matched · in-gamut control not flagged, returns recipes | **PASS (G-at-B)** | **A** | QUALITY-3 (un-pend+guard) |
| AC-14 | `AC-14` engine swap | dynamic: alt engine drives recipes (passes now); static: no caller references concrete `SubtractiveMixingEngine` · planted bound-to-concrete flagged | FAIL (as designed) | **B pending GUARD-5** | GUARD-5 |
| AC-15 | `AC-15` CVD swap | a CVD caller drives the injected `ConfusionCheck` (`confusableCalls > 0`), callers unchanged | FAIL (as designed) | **B pending GUARD-5** | GUARD-5 |
| AC-16 | `AC-16` one lib | no file outside the two authorities computes a conversion/ΔE · planted stray maths flagged | FAIL (as designed) | **B pending GUARD-6** | GUARD-6 |
| AC-17 | `AC-17` portability | platform-conditional code only under `lib/capture/source/` · planted platform Dart flagged | FAIL (as designed) | **B pending GUARD-6** | GUARD-6 |
| AC-5 | — (no automated test) | live-preview frame rate | — | **manual (G-3)** | SIGNOFF-1 (user acceptance) |

**Red baseline (recorded at ITEST-2/3, no code changed since):** default run (pending skipped) →
**15 pass / 16 skipped / exit 0** — the whole suite is green with all 16 ACs pending. Run-pending
(`--dart-define=BS12_RUN_PENDING=true`) → the 3 green-at-baseline ACs (AC-3/4/13) pass and the other 13 fail on
**exactly** their control/limit `Then` (or a `Given` naming the owning phase) — a clean red baseline, no vacuous
passes. (ITEST-2 slice +15/−9; ITEST-3 slice +18/−13.)

**What is real vs faked:** real screens/flows via `buildApp`, real engines, `ColorScience`, `deltaE00`, capture
controller, and a test-executor-backed `drift` store (on-device SQLite without a device file). Faked only:
`FakeSpeech`, `FakeHaptics`, the `networkBlock` `HttpOverrides`, the swap doubles `altMixingEngine` /
`altConfusionCheck`. The planted **control fixtures** (`integration_test/nfr/fixtures/controls/*`) exist only to
prove each guard discriminates. No colour math is faked (D-7).

**Augmentations owed** (pre-seeded; each closed by the named behaviour phase — see the *Test augmentations*
table above): AC-9 → QUALITY-2 · AC-10/11/12 → QUALITY-4 · AC-7/8 → GUARD-4 · AC-14/15 → GUARD-5 · AC-16/17 →
GUARD-6. All 10 rows ⬜ Open.

**Whole-suite grade grid:** [`../behavior-test-completeness-bs-12-non-functional-requirements.md`](../behavior-test-completeness-bs-12-non-functional-requirements.md)
— §§ ITEST-1 / ITEST-2 / ITEST-3 + a **Whole-suite roll-up** verdict. Counts: **16 AC tests → 6 A / 10 B pending /
0 ordinary B**; plus **15 A / 0** harness-&-smoke tests (ITEST-1). All 16 ACs are A or *B pending `<phase>`* with an
augmentation row — **no ordinary B outstanding**. (ITEST-3's AC-13 ordinary-B was found and fixed **in-phase** to A,
grid § ITEST-3 + roll-up.)

**Decision:** approve the acceptance tests, or request changes.
`/feature-next-phase --gate bs12 G-2 approved | "<changes>"`. Approval un-blocks every behaviour phase
(GUARD-3..6, QUALITY-2..5). Changes requested → each item becomes an ITEST change phase + a fresh review.

- **G-2 decision:** ✅ **Approved 2026-10-14 07:41 EDT by Matt Quirk** — the 16-AC acceptance suite + whole-suite grid (6 A / 10 B pending / 0 ordinary B) accepted, incl. retargeting QUALITY-3 (AC-13) & QUALITY-5 (AC-3/4) to un-pend+guard and carrying D-2/D-3 to sign-off. Behaviour stage un-blocked.
- **Result (✅ Done 2026-10-14):**
  - **Packet assembled** (above): the per-AC roster (16 tests → grade + control + closing phase), the recorded red
    baseline (default 15 pass/16 skip/exit 0; run-pending clean), real-vs-faked, the 10 augmentation rows + their
    closing phases, the whole-suite grid path + counts, and the three review decisions surfaced first (green-at-baseline
    AC-3/4/13 → reduce QUALITY-3/5 to un-pend+guard; the D-2 synthetic / D-3 device-timing gaps carried to SIGNOFF;
    the B-pending-coupling acceptance).
  - **Whole-suite grade grid** reconciled across the three AC-test phases and a **Whole-suite roll-up** verdict appended:
    **6 A / 10 B pending / 0 ordinary B** over the 16 AC tests (+ 15 A / 0 harness/smoke). No ordinary B outstanding.
  - **No code run** — test-review is packet assembly; no `lib/` or test change this session, so the ITEST-3 red baseline
    and grades stand unchanged. No unit/coverage/acceptance gate applies to a test-review phase.
  - **Gate:** G-2 set **awaiting a human decision**; the phase is **⏸ Awaiting review**. Every behaviour phase stays blocked.
  - **Fix passes:** n/a (no gate run).
  - **Tokens / Time:** see Dashboard / master ledger (ITEST-4 row).
- **Checkpoint / Handoff:**
  - **State:** stage 3 complete pending the human decision. On **G-2 approved** the behaviour stage opens — GUARD-3
    (AC-1/2), GUARD-4 (AC-6/7/8), GUARD-5 (AC-14/15), GUARD-6 (AC-16/17), QUALITY-2 (AC-9), QUALITY-4 (AC-10/11/12),
    and QUALITY-3 (AC-13) + QUALITY-5 (AC-3/4) as **un-pend + guard** phases (unless the reviewer retargets them).
    Behaviour phases editing the shared `nfr_test.dart` / a shared guard file are merge-risky → sequence them;
    QUALITY-2 (the only `lib/capture` change) may run ∥ one GUARD phase.
  - **Verification commands (for the behaviour phases):** unchanged from ITEST-3 — `cd /Users/matthew.quirk/Nuance-bs12`;
    `export PATH=$PATH:/Users/matthew.quirk/development/flutter/bin`; `flutter analyze`; `flutter test --coverage`;
    `dart run tool/coverage_gate.dart main`; acceptance via `FNP_COORD_REPO=/Users/matthew.quirk/Nuance <scripts>/coord.sh
    with-lock bs-12-non-functional-requirements <PHASE> --wait 1500 -- bash -c 'cd …/Nuance-bs12 && export PATH=… &&
    flutter test integration_test/bs12/nfr_test.dart -d <booted-udid> [--dart-define=BS12_RUN_PENDING=true]'` (shared
    device lane → lock mandatory; booted `-d` mandatory; whole-suite redirect to a file, don't tail; no `timeout` on macOS;
    full-suite teardown flake → re-run the affected file alone).
  - **Un-pend mechanism:** a behaviour phase deletes its AC's entry in `integration_test/bs12/pending.dart` + makes its
    augmentation real, then the AC's test runs by default (no `--dart-define`) and must be green.
