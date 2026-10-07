# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/comparison_test.dart` (AC tests), `integration_test/comparison_harness.dart`
(Given/When/Then vocabulary, fixtures, pending gate, `buildApp` driver with the comparison entry); reuses
bs-01's `integration_test/fakes/fake_speech.dart`.
**Depends on:** all shell phases (DIFF-1, CVD-1, COMPARE-2, SCREEN-1) · **Blocks:** every behavior phase (via G-3)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ⬜ Todo | | |
| 2 | acceptance-tests | AC-1,2,3,10,11,12 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-4,5,6,7,8,9 | ⬜ Todo | | |
| 4 | test-review | — (G-3) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the assembled app via bs-01's production `buildApp(deps)` with the comparison entry (D-8),
  driven by `WidgetTester`. Real: the `SampleSource` catalogue, `CvdProfile`, ΔE00/verdict, the LCh
  decomposition, the confusion detector, the controller, the screen and routing (incl. the bs-01 Readout).
  Faked (infrastructure only): bs-01's `FakeSpeech` (records utterances). No colour, ΔE00 or confusion math is
  faked.
- **Observation points:** AC-1/AC-2 — slot text + L/C/h; AC-3 — slot names + the re-expressed statement after
  swap; AC-4 — overall-difference text + the `deltaE00`/verdict on the read endpoint; AC-5/AC-6 — the three
  statement lines (text) + the read endpoint's decomposition; AC-7/AC-8 — the confusion-warning widget +
  `confusable` on the read endpoint; AC-9 — the `FakeSpeech` log (one utterance containing statement +
  warning); AC-10/AC-11 — the Readout route rendering the chosen sample's name; AC-12 — absence of the
  statement + the choose-B invite affordance.
- **Pending gate:** a `pendingACs` map (AC → owning phase) + `ac('AC-n')` calling `markTestSkipped('AC-n
  pending <phase>')` unless `BS03_RUN_PENDING=1`. Un-pending an AC = delete its map row. Default
  `flutter test integration_test/comparison_test.dart` skips pending; run-pending executes them.

## Open gates

- **G-3 (approve acceptance tests)** — recorded here on ITEST-4.
- **G-4 (spec-data reconciliation)** must be resolved before ITEST-3 pins AC-4's expected ΔE00 literal; until
  then AC-4's test is written with the literal as a `TODO(G-4)` placeholder and stays pending.

## Phase 1 — Harness (ITEST-1)

- **Kind:** acceptance-tests
- **Target AC:** — (harness)
- **Depends on:** DIFF-1, CVD-1, COMPARE-2, SCREEN-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/comparison_harness.dart`; reuse `integration_test/fakes/fake_speech.dart`.
- **Tasks:**
  1. A `buildApp` driver assembling the real app with the comparison entry (injected `SampleSource`
     `CATALOGUE`, a `CvdProfile`, `FakeSpeech`), opened on the Comparison screen.
  2. Given/When/Then helpers: `givenComparison({profile})`, `whenChooseA(name)`, `whenChooseB(name)`,
     `whenSwap()`, `whenSpeak()`, `whenOpenReadout(slot)`; the fixtures (`CATALOGUE`, `SAMPLE_A_TERRACOTTA`,
     `SAMPLE_B_SIENNA`, `SAMPLE_A_PRIME`, `SAMPLE_UMBER`, `SAMPLE_ULTRAMARINE`, `CVD_DEUTAN`) with their known
     coordinates; an **independent** reference ΔE00 (so AC-4/AC-7 don't grade the impl against itself).
  3. The pending gate with **all 12 ACs pending**, and a never-pending **smoke test** proving the shells wire
     end to end (the app boots to the Comparison screen and renders all five regions).
  4. Grade the scaffold tests: the pending map has exactly 12 keys each naming a real phase; the smoke test
     asserts concrete rendered regions; deterministic (`pumpAndSettle`/polling, no fixed sleeps).
- **Exit criteria:** `flutter test integration_test/comparison_test.dart` green (all AC tests pending, smoke
  passes); harness tests graded A.
- **Acceptance gate:** smoke green; pending gate in place (12 pending).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — AC-1,2,3,10,11,12 (ITEST-2)

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-3, AC-10, AC-11, AC-12 (selection / swap / open-readout / invite)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/comparison_test.dart` (these rows); may extend the harness vocabulary.
- **Tasks:** write one *pending* test per AC per the catalogue (exact Thens + Rejects); record the red
  baseline (run-pending) for each; grade each A (Given built via public flows and asserted; the Then at the
  step's grain; a real Rejects).
- **Exit criteria:** default suite green (these pending); run-pending shows each failing at its intended Then
  / precondition; grades recorded.
- **Acceptance gate:** *(acceptance-tests — suite green with new tests pending; red baseline recorded; grade
  gate passed)*

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — AC-4,5,6,7,8,9 (ITEST-3)

- **Kind:** acceptance-tests
- **Target AC:** AC-4, AC-5, AC-6, AC-7, AC-8, AC-9 (difference / decomposition / confusion / speak)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/comparison_test.dart` (these rows); harness fixtures.
- **Tasks:**
  1. Write one *pending* test per AC per the catalogue; record the red baseline.
  2. **Construct and verify** `SAMPLE_UMBER`/`SAMPLE_ULTRAMARINE` as a genuine deutan confusion-line pair
     (projected ΔE00 below the confusion threshold while normal ΔE00 is clearly-different); if no such pair
     can be found, raise it to the spec author.
  3. AC-4: write the expected ΔE00 literal as a `TODO(G-4)` placeholder until G-4 resolves; keep the pair's
     deltas (12/9/18) assertable regardless.
  4. Grade each A (ΔE00/confusion checked against the harness's independent reference, not the impl).
- **Exit criteria:** default suite green (these pending); run-pending shows each failing at its intended
  Then; grades recorded; the confusion-line pair verified.
- **Acceptance gate:** *(acceptance-tests — as ITEST-2)*

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — Test review (ITEST-4)

- **Kind:** test-review
- **Target AC:** — (G-3)
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (per-AC test + exact Thens + Rejects, the red baseline, the grade
  grid, the pre-seeded augmentation, the G-4 placeholder); run the full regression; present for the human
  decision (G-3).
- **Exit criteria:** packet assembled; full suite green (AC tests pending); grade grid complete.
- **Acceptance gate:** human records G-3.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_ChooseA | _TBD ITEST-2_ | | COMPARE-3 | |
| AC-2 | TestAC02_ChooseB | _TBD ITEST-2_ | | COMPARE-3 | |
| AC-3 | TestAC03_Swap | _TBD ITEST-2_ | | COMPARE-5 | |
| AC-4 | TestAC04_OverallDelta | _TBD ITEST-3_ | | DIFF-2 | |
| AC-5 | TestAC05_Decompose | _TBD ITEST-3_ | | DIFF-3 | |
| AC-6 | TestAC06_SameHue | _TBD ITEST-3_ | | DIFF-3 | |
| AC-7 | TestAC07_ConfusionFlagged | _TBD ITEST-3_ | | CVD-2 | |
| AC-8 | TestAC08_NotConfusable | _TBD ITEST-3_ | | CVD-2 | |
| AC-9 | TestAC09_SpeakIncludesWarning | _TBD ITEST-3_ | | CVD-3 | |
| AC-10 | TestAC10_OpenReadoutA | _TBD ITEST-2_ | | COMPARE-6 | |
| AC-11 | TestAC11_OpenReadoutB | _TBD ITEST-2_ | | COMPARE-6 | |
| AC-12 | TestAC12_InviteSecond | _TBD ITEST-2_ | | COMPARE-3 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC04 | one sample pair at write time cannot show the verdict tracks distance (a constant verdict string would pass) | DIFF-2 | a near-identical control pair asserting a **different** verdict band | ⬜ Open |
