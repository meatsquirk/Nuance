# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/` — `harness.dart` (Given/When/Then vocabulary, fixtures, pending
gate, `buildApp` driver, fakes), `readout_test.dart` (the AC tests), `fakes/fake_speech.dart`,
`fakes/fake_haptics.dart`.
**Depends on:** all shell phases (CORE-2, COLOR-1, A11Y-1, READOUT-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ⬜ Todo | | |
| 2 | acceptance-tests | AC-1..AC-7 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-8..AC-12 | ⬜ Todo | | |
| 4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation
- **Boundary:** the assembled app via the one production `buildApp(deps)` entry, driven by `WidgetTester`.
  Real: color-science, controllers, widgets, routing, provenance. Faked (infrastructure only): `FakeSpeech`
  (records utterances) and `FakeHaptics` (records pulses) — the platform TTS/vibrator sinks.
- **Observation points:** AC-1/2/3/4/5/6/7 — rendered text, keys, relative font sizes on the Readout screen;
  AC-5 also asserts the other spaces' value strings are absent after a switch; AC-8 — the `FakeSpeech`
  utterance log; AC-9/10/11 — the current route = the stub Comparison/Recipes screen rendering the carried
  sample in the right slot/target; AC-12 — `FakeHaptics` log + the just-captured marker before/after acknowledge.
- **Pending gate:** a `pendingACs` map (AC → owning phase) + a helper `ac('AC-n')` that calls
  `markTestSkipped('AC-n pending <phase>')` unless `BS01_RUN_PENDING=1`. Un-pending an AC = delete its map row.
  Default `flutter test integration_test/` skips pending; run-pending executes them.

## Open gates
- **G-2 (approve acceptance tests)** is this module's exit gate (ITEST-4), blocking every behavior phase.

## Phase 1 — Harness

- **Kind:** acceptance-tests
- **Target AC:** — (harness)
- **Depends on:** CORE-2, COLOR-1, A11Y-1, READOUT-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/harness.dart`, `fakes/fake_speech.dart`, `fakes/fake_haptics.dart`.
- **Tasks:**
  1. A `buildApp` driver that assembles the real app with `FakeSpeech`/`FakeHaptics` injected.
  2. Given/When/Then helpers: `givenReadoutOf(sample)`, `whenSelectSpace(space)`, `whenSpeak()`,
     `whenCompareAs(slot)`, `whenFindRecipes()`, `whenAcknowledge()`; the fixtures (SAMPLE_*) from the plan.
  3. The pending gate with **all 12 ACs pending**, and a never-pending **smoke test** proving the shells wire
     end to end (app boots to the Readout route and renders every region).
  4. Grade the scaffold tests: no vacuous passes (assert the pending map has exactly 12 keys, each naming a
     real phase; the smoke test asserts concrete rendered regions); comments claim only what is checked;
     deterministic (`pumpAndSettle`/polling, no fixed sleeps).
- **Exit criteria:** `flutter test integration_test/` green (all AC tests pending, smoke passes); harness
  tests graded A.
- **Acceptance gate:** smoke green; pending gate in place (12 pending).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — AC tests: readout display (AC-1..AC-7)

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7 (all **pending**)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-3
- **Files:** `integration_test/readout_test.dart` (display group).
- **Tasks:** write the catalogue rows AC-1..AC-7 as pending tests (grade-A: every Given checked, When through
  the real UI, Then asserted tightly, each test rejects its wrong impl / carries its control — see the master
  catalogue). Run run-pending; record the **red baseline** row per test below.
- **Exit criteria:** default run green (these pending); run-pending shows each failing on a Then or a Given
  precondition naming its owning phase; grade grid all A (or *B pending <phase>* with an augmentation row).
- **Acceptance gate:** *(AC-test)* suite green with new tests pending; red baseline recorded; grade gate passed.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — AC tests: speak, navigation, just-captured (AC-8..AC-12)

- **Kind:** acceptance-tests
- **Target AC:** AC-8, AC-9, AC-10, AC-11, AC-12 (all **pending**)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Files:** `integration_test/readout_test.dart` (actions group — split file region to allow ∥ with ITEST-2).
- **Tasks:** write catalogue rows AC-8..AC-12 as pending tests, grade-A; AC-8 asserts each required spoken
  component against the `FakeSpeech` log; AC-9/AC-10 form the slot-A/slot-B control pair; AC-12 settles the
  negative Then (marker before/after acknowledge) with a control. Record the red baseline rows.
- **Exit criteria:** as ITEST-2.
- **Acceptance gate:** *(AC-test)* suite green with new tests pending; red baseline recorded; grade gate passed.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — Test review (G-2)

- **Kind:** test-review
- **Target AC:** —
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase (via G-2)
- **Preconditions:** ITEST-2 and ITEST-3 done; the whole-suite grade grid all A (or *B pending <phase>* with
  a row). Fix any other B here first.
- **Tasks:** assemble the review packet (below) — per AC: test name, Given checks, When, Then + Rejects (a
  line or two each); the red-baseline summary; the augmentations scheduled and which phase closes each; the
  grid path + counts; what to look at first. Set the phase `⏸ Awaiting review`, G-2 to *awaiting decision*,
  record the ledger row, commit, and stop with:
  `/feature-next-phase --gate bs-01-color-readout G-2 approved | "<changes>"`.
- **Exit criteria:** packet written; human decision recorded via `--gate`.
- **Acceptance gate:** *(decision — human)*

### Packet  <!-- filled by ITEST-4 -->

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_LightnessProminent | (to record) | Then: L largest / Munsell value | READOUT-2 | |
| AC-2 | TestAC02_ValueWord | (to record) | Then: value word present | READOUT-2 | |
| AC-3 | TestAC03_ColourName | (to record) | Then: large name header | READOUT-3 | |
| AC-4 | TestAC04_Temperature | (to record) | Then: temperature word | READOUT-3 | |
| AC-5 | TestAC05_ColourSpaceSelector | (to record) | Then: space values + exclusivity | READOUT-4 | |
| AC-6 | TestAC06_MeasuredBadge | (to record) | Then: "Measured" badge | READOUT-5 | |
| AC-7 | TestAC07_EstimatedBadge | (to record) | Then: "Estimated…" + note | READOUT-5 | |
| AC-8 | TestAC08_SpeakReadout | (to record) | Then: utterance components | A11Y-2 | |
| AC-9 | TestAC09_CompareAsA | (to record) | Then: slot A carries sample | READOUT-6 | |
| AC-10 | TestAC10_CompareAsB | (to record) | Then: slot B carries sample | READOUT-6 | |
| AC-11 | TestAC11_FindRecipes | (to record) | Then: Recipes target set | READOUT-6 | |
| AC-12 | TestAC12_JustCaptured | (to record) | Then: haptic + marker lifecycle | A11Y-2 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC01 | until the colour-space readings render (READOUT-4), fewer readings exist to prove Lightness is *largest* | READOUT-4 | assert L font size > each space reading too | ⬜ Open |
