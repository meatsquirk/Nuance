# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs11/accessibility_harness.dart`, `integration_test/bs11/accessibility_test.dart`, `integration_test/bs11/pending.dart` (created at CONF-1). Consumes (does not own) the reusable check in `integration_test/conformance/` and the domain in `lib/a11y/conformance/`.
**Depends on:** all shell phases (A11Y-1, GATE-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ⬜ Todo | | |
| ITEST-2 | acceptance-tests | AC-1,2,4,5,6 (pending) | ⬜ Todo | | |
| ITEST-3 | acceptance-tests | AC-3,7,8,9,11 (pending) | ⬜ Todo | | |
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
| AC-1 | TestAC01_ColourCarriesNonColourCue | FAIL | Then: cue rule passes on every screen | A11Y-5 | — |
| AC-2 | TestAC02_StatusNotBareColourDot | FAIL | Then: no-bare-dot rule | A11Y-5 | — |
| AC-3 | TestAC03_FontScale200NoBreak | FAIL | Then: no overflow at 2.0 | A11Y-4 | — |
| AC-4 | TestAC04_TapTargetMin48 | FAIL | Then: tap-target guideline | A11Y-3 | — |
| AC-5 | TestAC05_ContrastFloorAA | FAIL | Then: contrast guideline | A11Y-2 | — |
| AC-6 | TestAC06_ControlHasMeaningfulLabel | FAIL | Then: labelled-control rule | A11Y-6 | — |
| AC-7 | TestAC07_EyesFreeWalkthroughCompletes | FAIL | Then: task reaches terminal state | GATE-2 | — |
| AC-8 | TestAC08_NothingAutoDismisses | FAIL | Then: notice persists after advance | A11Y-7 | — |
| AC-9 | TestAC09_FailedAutomatedCheckNotAccepted | FAIL | Then: notAccepted (aggregate stub) | GATE-3 | B pending GATE-3 |
| AC-11 | TestAC11_RecordedFloorIsWcag22AA | FAIL | Then: recordedLevel aa22 (stub) | GATE-4 | B pending GATE-4 |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC09 | the aggregate `acceptanceDecision` cannot discriminate until every sub-rule exists (A11Y-2..7, GATE-2) | GATE-3 | compose all rules; assert a partially-failing result ⇒ notAccepted and a fully-passing one ⇒ accepted | ⬜ Open |
| TestAC11 | `recordedLevel` is stubbed until the aggregate result exists | GATE-4 | assert a passing result records `aa22`, a failing one `below`, and thresholds equal the WCAG 2.2 AA constants | ⬜ Open |
