# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-3 done (AC-3,7,8,9,11 pending + red baseline; 3 A / 2 B-pending); next ITEST-4 test review (G-2, the module's last phase)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs11/accessibility_harness.dart`, `integration_test/bs11/accessibility_test.dart`, `integration_test/bs11/pending.dart` (created at CONF-1). Consumes (does not own) the reusable check in `integration_test/conformance/` and the domain in `lib/a11y/conformance/`.
**Depends on:** all shell phases (A11Y-1, GATE-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ✅ Done | 7,883,599 | 17m 28s |
| ITEST-2 | acceptance-tests | AC-1,2,4,5,6 (pending) | ✅ Done | 5,523,993 | 14m 07s |
| ITEST-3 | acceptance-tests | AC-3,7,8,9,11 (pending) | ✅ Done | 7,854,428 | 26m 55s |
| ITEST-4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the public surface is the assembled app via `buildApp(deps)` across every entry marker (the real screens), plus the reusable `runConformanceCheck`/`eyesFreeComplete` test-support and the pure-domain `acceptanceDecision`/`recordedLevel`. Production wiring reused; only `FakeSpeech`/`FakeHaptics` faked. The non-compliant **control** screens are in-harness fixtures that exist only to prove each rule discriminates.
- **Observation points:** the `ConformanceResult` per rule (contrast/target/scaling/cue/label/no-timeout); widget-tree exceptions (scaling overflow) and `meetsGuideline` matcher outcomes; the feature read endpoints for the eyes-free terminal state; `acceptanceDecision`/`recordedLevel` return values.
- **Pending gate:** `integration_test/bs11/pending.dart` — a `const Map<String,String> pendingACs` (AC → owning phase) plus `ac(tester, "AC-n")` keyed to `BS11_RUN_PENDING` (compile-time `--dart-define=BS11_RUN_PENDING=true` OR host env `=1`, matching bs02/03/04). Un-pend = delete that AC's map entry. **10 ACs pending** at CONF-1; AC-10/AC-12 never enter the gate (manual, D-2).

## Open gates

**G-2** — approve the acceptance tests (ITEST-4's packet). Blocks every behavior phase. Decided via `--gate bs-11 G-2 …`.

## Phase ITEST-1 — harness + fixtures + smoke

- **Kind:** acceptance-tests
- **Target AC:** — · **Depends on:** A11Y-1, GATE-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/bs11/accessibility_harness.dart`, `integration_test/bs11/accessibility_test.dart`
- **Tasks:**
  1. Given/When/Then vocabulary: `givenScreen(entry)` (launch each real screen via `buildApp`), `givenControl(fixture)` (a control screen), `whenCheckedForConformance` (run `runConformanceCheck`), `whenScaledTo(2.0)`, `whenWaited(duration)`.
  2. Fixtures: `realScreens` (every `buildApp` entry on `main`), `compliantReference`, and the control fixtures (`control_lowContrast`, `control_smallTarget`, `control_bareDot`, `control_unlabelled`, `control_autoDismiss`, `control_overflow200`, `control_partialFail`).
  3. A never-pending smoke test: the check runs on `compliantReference` and returns a populated result (proves the shells + harness are wired); assert the pending map's keys all name real phases and the expected AC count (no vacuous pass).
- **Exit criteria:** suite green with every AC pending; smoke test passes with a booted `-d`; grade gate on the harness/smoke (no vacuous passes, deterministic — poll, no fixed sleeps).

## Phase ITEST-2 — AC tests: structural rules

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-4, AC-5, AC-6 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/bs11/accessibility_test.dart` (shared w/ ITEST-3 → sequential)
- **Tasks:** write `TestAC01_ColourCarriesNonColourCue`, `TestAC02_StatusNotBareColourDot`, `TestAC04_TapTargetMin48`, `TestAC05_ContrastFloorAA`, `TestAC06_ControlHasMeaningfulLabel` per the master catalogue — each asserting the rule passes on every real screen + `compliantReference` and fails on its control. Run run-pending; record the red baseline.
- **Exit criteria:** suite green with these pending; red baseline recorded (each fails on its Then or a precondition naming its phase); grade gate (all A, or *B pending <phase>* with an augmentation row).

## Phase ITEST-3 — AC tests: scaling, eyes-free, timing, gate, floor

- **Kind:** acceptance-tests
- **Target AC:** AC-3, AC-7, AC-8, AC-9, AC-11 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/bs11/accessibility_test.dart` (shared w/ ITEST-2 → sequential)
- **Tasks:** write `TestAC03_FontScale200NoBreak`, `TestAC07_EyesFreeWalkthroughCompletes`, `TestAC08_NothingAutoDismisses`, `TestAC09_FailedAutomatedCheckNotAccepted`, `TestAC11_RecordedFloorIsWcag22AA` per the catalogue (AC-8 with its settle point; AC-9/AC-11 over the aggregate result). Run run-pending; record the red baseline.
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate (AC-9 → *B pending GATE-3*, AC-11 → *B pending GATE-4*; others A).

## Phase ITEST-4 — test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the packet (per AC: test name, Given checks, When, Then + Rejects, in a line or two; red baseline summary; augmentation schedule; grid path + counts; what to look at first — the "every real screen" sweep assertions and the control fixtures). Set the phase `⏸ Awaiting review`, G-2 *awaiting decision*, record the ledger row, commit, and stop with: `/feature-next-phase --gate bs-11 G-2 approved | "<changes>"`.
- **Exit criteria:** whole-suite grade grid all A (or *B pending <phase>*); packet written; G-2 awaiting a human decision.

## Interface reconciliation / Observation — see top.

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_ColourCarriesNonColourCue | FAIL | Then: cue rule passes on every screen | A11Y-5 | A |
| AC-2 | TestAC02_StatusNotBareColourDot | FAIL | Then: no-bare-dot rule | A11Y-5 | A |
| AC-3 | TestAC03_FontScale200NoBreak | FAIL | Then: `fontScale200` null on first real screen (sweep) | A11Y-4 | A |
| AC-4 | TestAC04_TapTargetMin48 | FAIL | Then: tap-target guideline | A11Y-3 | A |
| AC-5 | TestAC05_ContrastFloorAA | FAIL | Then: contrast guideline | A11Y-2 | A |
| AC-6 | TestAC06_ControlHasMeaningfulLabel | FAIL | Then: labelled-control rule | A11Y-6 | A |
| AC-7 | TestAC07_EyesFreeWalkthroughCompletes | FAIL | When: `eyesFreeComplete` stub throws `UnimplementedError` (names GATE-2) | GATE-2 | A |
| AC-8 | TestAC08_NothingAutoDismisses | FAIL | Then: `noTimeout` null on first real screen (sweep) | A11Y-7 | A |
| AC-9 | TestAC09_FailedAutomatedCheckNotAccepted | FAIL | Given: `control_partialFail` has no failing rule (empty result) — precondition names GATE-3 + sub-rules | GATE-3 | B pending GATE-3 |
| AC-11 | TestAC11_RecordedFloorIsWcag22AA | FAIL | Given: reference `result.passed` false (empty result) — precondition names GATE-4 | GATE-4 | B pending GATE-4 |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC09 | the aggregate `acceptanceDecision` cannot discriminate until every sub-rule exists (A11Y-2..7, GATE-2) | GATE-3 | compose all rules; assert a partially-failing result ⇒ notAccepted and a fully-passing one ⇒ accepted | ⬜ Open (confirmed ITEST-3) |
| TestAC11 | `recordedLevel` is stubbed until the aggregate result exists | GATE-4 | assert a passing result records `aa22`, a failing one `below`, and thresholds equal the WCAG 2.2 AA constants | ⬜ Open (confirmed ITEST-3) |

### Result  <!-- one block per phase -->

**ITEST-3 — AC tests: scaling, eyes-free, timing, gate, floor (AC-3, AC-7, AC-8, AC-9, AC-11)** (✅ Done)

- **`integration_test/bs11/accessibility_test.dart`** — added the group
  `bs-11 acceptance criteria — scaling, eyes-free, timing, gate, floor (ITEST-3)`
  with five *pending* `acTestWidgets` (`AC-3`/`AC-7`/`AC-8`/`AC-9`/`AC-11`), each
  driving the one public surface:
  - **AC-3** `fontScale200` — sweeps all six real screens + `compliantReference`
    (rule passes) and `control_overflow200` (rule fails). The 200%-scale pump +
    overflow capture live **inside the A11Y-4 rule** (per A11Y task 2: "pump at
    textScaler 2.0; assert `takeException()==null`"), so the test runs the check
    over the *unscaled* subject and reads the outcome — pre-scaling in the test
    would surface a raw `RenderFlex` overflow before the check could capture it,
    dirtying the baseline. (`whenScaledTo` stays available for A11Y-4's own
    rule-level tests.)
  - **AC-7** eyes-free via `whenCompletedEyesFree` — launches Readout, asserts
    the entry control present *by label* (`find.bySemanticsLabel('Speak this
    readout')`), drives the task by semantic label only, asserts completion;
    control = a step whose label is exposed on no control cannot progress (D-6,
    rejects a coordinate-fallback driver).
  - **AC-8** `noTimeout` — sweeps all six real screens (rule passes), then the
    **G3 settle point**: `whenWaited(10s)` past the SnackBar 4s window — the
    reference `AccessibleNotice` is *still present after the advance* and the
    rule passes; change-control `control_autoDismiss`'s SnackBar *is gone* after
    the same advance and the rule flags it.
  - **AC-9** `acceptanceDecision` over `control_partialFail` (≥1 failing + ≥1
    passing ⇒ notAccepted) with the fully-passing reference ⇒ accepted control.
  - **AC-11** `recordedLevel` over the fully-passing reference (⇒ `aa22`) with a
    failing-result control (⇒ `below`).
  - Added import: `widgets/accessible_notice.dart` (AC-8 finds the notice). No
    harness or production code touched.
- **Gates:** `flutter analyze integration_test/bs11/` clean. **Default** run
  (pending-skipped) **9/9 green** on booted iPhone 17 sim (udid `5AB9D06D…`) via
  `coord.sh with-lock` (exit 0) — suite stays green with all 10 ACs pending.
  **Red baseline** (`--dart-define=BS11_RUN_PENDING=true`): **9 pass / 10 fail**
  (the 5 ITEST-2 + these 5), each new test failing exactly as designed — AC-3
  Then `fontScale200` null (sweep), AC-8 Then `noTimeout` null (sweep), AC-7 When
  `UnimplementedError … GATE-2 (AC-7)`, AC-9 Given "≥1 failing rule" (empty)
  naming GATE-3, AC-11 Given reference `passed` false naming GATE-4. Coverage
  gate `dart run tool/coverage_gate.dart main` **PASS 100%** — ITEST-3 touched
  only `integration_test/**`, so the 9 branch-touched `lib/**` files are
  unchanged from GATE-1. **Grade gate 3 A / 2 B-pending** (independent
  adversarial grader in a fresh subagent; grid section appended) — AC-3/AC-7/AC-8
  **A**; AC-9 **B pending GATE-3**, AC-11 **B pending GATE-4** (both legitimate:
  the aggregate verdict + a genuinely partial/passing result need every sub-rule,
  each has a matching augmentation row). **Fix passes:** 0/3 (analyze + both runs
  clean on the first pass).
- **Augmentations:** confirmed the two pre-seeded rows (TestAC09 → GATE-3,
  TestAC11 → GATE-4), both ⬜ Open. No test weakened. Grader note (optional, not a
  required fix): AC-3's reference leg omits a `compliantReferenceFinder
  findsOneWidget` assertion the other tests carry — graded A regardless (the
  discriminating Givens are all checked; honest-red on a null Then). Handed to
  A11Y-4 as an optional symmetry touch-up.

**ITEST-2 — AC tests: structural rules (AC-1, AC-2, AC-4, AC-5, AC-6)** (✅ Done)

- **`integration_test/bs11/accessibility_test.dart`** — added the group
  `bs-11 acceptance criteria — structural rules (ITEST-2)` with five *pending*
  `acTestWidgets` (`AC-1`/`AC-2`/`AC-4`/`AC-5`/`AC-6`). Each drives the one public
  surface — `runConformanceCheck` over the rendered screen — and asserts its rule
  **passes on every real screen (the D-1 sweep over all six `buildApp` entries)
  and on `compliantReference`, and fails on its discriminating control**: AC-1
  `colourCue` (reference shows a `ColorChip`; control `control_bareDot`), AC-2
  `noBareDot` (reference shows a `StatusBadge`; control `control_bareDot`), AC-4
  `tapTarget48` (reference 48dp `IconButton`; control `control_smallTarget`), AC-5
  `contrastAA` (control `control_lowContrast`), AC-6 `meaningfulLabel` (reference
  labelled `IconButton`; control `control_unlabelled`). AC-5 additionally pins
  **G2**: every swept screen's `Theme.of(…).colorScheme == AppTheme.light().colorScheme`,
  so contrast comes from the shipped (AA-tunable) theme, not a test-injected one.
  Added imports: `material.dart`, `AppTheme`, `ColorChip`, `StatusBadge`.
- **Gates:** `flutter analyze integration_test/bs11/` clean. Default acceptance
  run (pending-skipped) **9/9 green** on booted iPhone 17 sim via `coord.sh
  with-lock` (exit 0) — suite stays green with the 5 ACs pending. **Red baseline**
  (`--dart-define=BS11_RUN_PENDING=true`): **9 pass / 5 fail**, each AC test failing
  on its first positive-sweep **Then** (`Expected: true, Actual: <null>` — the
  GATE-1 stub `runConformanceCheck` returns `ConformanceResult.empty`), reason
  naming the owning phase (AC-1/AC-2→A11Y-5, AC-4→A11Y-3, AC-5→A11Y-2,
  AC-6→A11Y-6). Coverage gate `dart run tool/coverage_gate.dart main` **PASS 100%**
  — ITEST-2 touched only `integration_test/**`, so the 9 branch-touched `lib/**`
  files are unchanged from GATE-1. **Grade gate 5 A / 0 B** (independent
  adversarial grader in a fresh subagent; grid
  `behavior-test-completeness-bs-11-accessibility-conformance.md`) — all five
  carry the mandated discriminating shape, check every Given before the When,
  assert the exact `ConformanceRuleId` at step grain, one AC each, deterministic,
  honest GATE-1-stub comments; G3 N/A (structural rules). **Fix passes:** 0/3
  (analyze + both runs clean on the first pass).
- **Augmentations:** none for these five (the AC-9/AC-11 augmentation rows below
  are owned by ITEST-3's tests, GATE-3/GATE-4). No test weakened.

**ITEST-1 — harness + fixtures + smoke** (✅ Done)

- **`integration_test/bs11/accessibility_harness.dart`** — the bs-11 acceptance vocabulary over the real `buildApp` assembly (D-7), faking only Speech/Haptics:
  - `realScreens` — the **six** `buildApp` home entries on `main` (Readout, Capture, Comparison, Recipes, Correction, Palette), each launched by *reusing its own feature harness's production `given…` launcher*, imported with a prefix (`cap`/`cmp`/`cor`/`rec`/`pal`/`ro`) so their re-exports and the two duplicate `givenComparison` never collide. Each `RealScreen` carries a `Finder` (the home widget type) for the check to run over. bs-07/bs-08 add layers/chrome, not new home entries, so they are swept within every screen.
  - `compliantReference` (positive control: `ColorChip` + `StatusBadge` + a 48dp labelled `IconButton` + `AccessibleNotice`) and the **seven** `control_*` fixtures (`control_lowContrast`/`_smallTarget`/`_bareDot`/`_unlabelled`/`_autoDismiss`/`_overflow200`/`_partialFail`), each a keyed `AppTheme` app so a check targets exactly its subtree. `control_partialFail` carries one failing rule (a 24dp target) among compliant widgets for AC-9.
  - vocabulary: `givenScreen`/`givenControl`/`givenCompliantReference`, `whenCheckedForConformance` (→ reusable `runConformanceCheck`), `whenScaledTo` (sets the binding text-scale the whole tree reads — AC-3), `whenWaited` (clock advance — AC-8 settle point), `whenCompletedEyesFree` (→ `eyesFreeComplete` — AC-7). Re-exports `pending.dart`, the conformance check / eyes-free driver and the pure-domain result/verdict types, so an AC test imports only this harness.
- **`integration_test/bs11/accessibility_test.dart`** — never-pending guards + smoke (no AC tests yet; ITEST-2/3 add them):
  - pending-gate guards: the map is exactly the 10 automated ACs `{AC-1..9, AC-11}` (`hasLength(10)`); AC-10/AC-12 absent (manual, D-2); every owner ∈ `behaviorPhases`; each pending AC skips default / runs under `--dart-define=BS11_RUN_PENDING=true` (both via explicit `forceRunPending`, so deterministic). Non-vacuous (asserts the exact set + size).
  - harness-fixture guards: `realScreens` is exactly the six named screens (unique); `controlFixtures` is exactly the seven named controls (unique).
  - smoke (`-d` sim): every real screen opens through `buildApp`, renders with no exception, and `runConformanceCheck` runs over it returning a `ConformanceResult` (asserts a result is produced — stays true when GATE-3 populates it, rather than asserting the stub's emptiness); the compliant reference renders + checks; every control fixture renders.
- **Gates:** `flutter analyze` (both new files) clean. Acceptance suite **9/9 green** on booted iPhone 17 sim via `coord.sh with-lock` (default pending-skipped run; exit 0). No AC tests registered yet ⇒ **no red baseline** at ITEST-1 (ITEST-2/3 record it). Coverage gate `dart run tool/coverage_gate.dart main` **PASS 100%** — ITEST-1 touched only `integration_test/**`, so the branch's 9 touched `lib/**` files are unchanged from GATE-1. Grade gate **12 A / 0 B** (independent grader; grid `behavior-test-completeness-bs-11-accessibility-conformance.md`) — 4 pending-gate guards + 2 fixture guards + 3 smoke tests + 3 artifact rows; no vacuous passes (fixture guards pin each list's exact size+identity; pending map pinned exactly), honest comments (smoke asserts a result is produced, not that it passes), deterministic (pumpAndSettle + tree-reset, `forceRunPending`, `addTearDown` clears the scale override, fake-clock `whenWaited`). **Fix passes:** 0/3 (analyze: 2 trivial fixes — add `non_constant_identifier_names` ignore for the `final control_*`, import `ConformanceResult` since a re-export is not an in-file import; both before the first suite run).

### Checkpoint / Handoff

**After ITEST-3 (branch `feat/bs-11-accessibility-conformance`):**

- **All AC tests landed.** `accessibility_test.dart` now holds **all 10 automated AC tests** — group `… structural rules (ITEST-2)` (AC-1/2/4/5/6) and group `… scaling, eyes-free, timing, gate, floor (ITEST-3)` (AC-3/7/8/9/11) — plus the ITEST-1 guards + smoke. Both groups are **closed**; no further AC-test phase remains. Stage 3's one remaining phase is **ITEST-4 (test review, G-2)**.
- **ITEST-4 (next) — assemble the review packet** per the phase's task + `references/acceptance-suite.md` § *Test review*: per AC (all 10) a line or two — test name, Given checks, When, Then + Rejects; the red-baseline summary (9 pass / 10 fail; where each fails); the augmentation schedule (TestAC09→GATE-3, TestAC11→GATE-4); the grid path + counts (now **10 A-equivalent / 2 B-pending**: ITEST-2 5 A, ITEST-3 3 A + AC-9/AC-11 B-pending). Reviewer should look first at the **"every real screen" sweep** assertions (D-1) and the **control fixtures** (each rule's discriminator). Then set ITEST-4 `⏸ Awaiting review`, G-2 *awaiting decision*, record the ledger row, commit, and stop with: `/feature-next-phase --gate bs-11 G-2 approved | "<changes>"`. **Precondition check for ITEST-4:** whole-suite grade grid is all A or *B pending <phase>* — satisfied (no ordinary B).
- **Verification commands** (from `../Nuance-bs11`, `flutter` at `/Users/matthew.quirk/development/flutter/bin`): analyze `flutter analyze integration_test/bs11/`; acceptance `flutter test integration_test/bs11/accessibility_test.dart -d <booted-udid>` under `coord.sh with-lock bs-11-accessibility-conformance <PHASE> --wait 1800 -- bash -c "cd <worktree> && …"` (booted `-d` mandatory — no `-d` ⇒ false green; the verify lock keys off the shared git common-dir ⇒ machine-wide across all bs worktrees, currently contended by bs-12; `cd` into the worktree inside the `bash -c`); red-baseline adds `--dart-define=BS11_RUN_PENDING=true` (exceeds 120s ⇒ redirect to a file, don't tail); coverage gate `dart run tool/coverage_gate.dart main`. ITEST-4 is a test-review (no new run required) — it reads the ITEST-3 red baseline recorded above.
- **Known gaps / next:** **ITEST-4** (test review, **G-2**) is next and startable now (depends on ITEST-2+ITEST-3, both done). G-2's approval un-blocks the whole behaviour stage (A11Y-2..7, GATE-2/3/4). Optional symmetry touch-up for A11Y-4: add a `compliantReferenceFinder findsOneWidget` to AC-3's reference leg (grader-noted, not required).
