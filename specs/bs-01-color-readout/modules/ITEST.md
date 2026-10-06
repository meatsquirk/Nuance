# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1, ITEST-2 done (AC-1..7 pending + red baseline, grade A); next ITEST-3 → ITEST-4
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/` — `harness.dart` (Given/When/Then vocabulary, fixtures, pending
gate, `buildApp` driver, fakes), `readout_test.dart` (the AC tests), `fakes/fake_speech.dart`,
`fakes/fake_haptics.dart`.
**Depends on:** all shell phases (CORE-2, COLOR-1, A11Y-1, READOUT-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ✅ Done | 7,980,954 | 29m 01s (1h 13m) |
| 2 | acceptance-tests | AC-1..AC-7 | ✅ Done | 6,226,248 | 27m 50s |
| 3 | acceptance-tests | AC-8..AC-12 | ⬜ Todo | | |
| 4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation
- **Boundary:** the assembled app via the one production `buildApp(deps)` entry, driven by `WidgetTester`.
  Real: color-science (`ColorScienceImpl` — no color math faked), controllers, widgets, routing, provenance.
  Faked (infrastructure only): `FakeSpeech` (records utterances) and `FakeHaptics` (counts pulses) — the
  platform TTS/vibrator sinks. A single import, `integration_test/harness.dart`, carries the whole vocabulary
  (it re-exports the fakes); `givenReadoutOf(tester, sample)` boots the app on a fixture and returns a
  `ReadoutHarness{tester, speech, haptics}` with the `when…` actions.
- **Runner (ITEST-1 finding; owner decision 2026-10-05):** `flutter test` routes anything under
  `integration_test/` to **on-device** execution — plain `flutter test integration_test/` finds no device and
  exits 0 having run **zero** tests (a false green). The suite therefore runs on a **booted iOS simulator**:
  `flutter test integration_test/ -d <udid>` (default — pending ACs skipped) and
  `flutter test integration_test/ -d <udid> --dart-define=BS01_RUN_PENDING=true` (run-pending). D-6
  (integration_test package) is kept; host-headless is not available here (the project has no desktop platform
  folder). **CI must add an emulator** and **pass the dart-define** for the run-pending/un-pend job before
  wiring the acceptance job (the `ci.yml` unit job is unaffected). *(ITEST-2 finding: the old env-var form
  `BS01_RUN_PENDING=1 flutter test …` silently skipped pending tests on-device — the simulator app process
  does not inherit the host shell env; `runPending` now reads the compile-time dart-define, with the host-env
  path kept for any host-process run.)*
- **Observation points:** AC-1/2/3/4/5/6/7 — rendered text, keys, relative font sizes on the Readout screen;
  AC-5 also asserts the other spaces' value strings are absent after a switch; AC-8 — the `FakeSpeech`
  utterance log; AC-9/10/11 — the current route = the stub Comparison/Recipes screen rendering the carried
  sample in the right slot/target; AC-12 — `FakeHaptics` log + the just-captured marker before/after acknowledge.
- **Pending gate (as built):** a `const pendingACs` map (AC → owning phase) + `acTestWidgets(acId,
  description, body)`, which registers the AC test through `testWidgets`' native `skip:` (cleaner than the
  planned `markTestSkipped`, and it stops a not-yet-built body from *running*, so a pending AC is skipped not
  failed). `pendingSkipReason(acId, {forceRunPending})` decides: an un-mapped AC always runs; a mapped AC runs
  only in run-pending mode (`BS01_RUN_PENDING=1`). **Un-pending an AC = delete its row from `pendingACs`.**

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

### Result

- **Landed** `integration_test/`: `harness.dart` — 5 fixtures (`SAMPLE_TERRACOTTA/OLIVE/COOL/MEASURED/
  ESTIMATED`, stored in canonical CIELAB; terracotta's a*/b* are the exact polar form of its CIELCh L58 C34
  h42); the pending gate (`const pendingACs` = all 12 ACs → owning phase, `acTestWidgets`, `pendingSkipReason`
  over native `skip:`); the Given/When/Then vocabulary (`givenReadoutOf`, `givenJustCapturedReadoutOf`,
  `ReadoutHarness.whenSelectSpace/whenSpeak/whenCompareAs/whenFindRecipes/whenAcknowledge`) driving the real
  `buildApp` with faked `Speech`/`Haptics` and real `ColorScienceImpl`. `fakes/fake_speech.dart` (records
  utterances) + `fakes/fake_haptics.dart` (counts confirms). `harness_test.dart` — never-pending smoke test
  (booted app renders every region/control anchor + empty speech/haptics log) and guard tests (pending map =
  exactly 12 ACs each owned by a real phase; mode gate both branches; fakes record).
- **Runner (owner decision):** `integration_test/` forces on-device, so the suite runs on a booted iOS
  simulator — `flutter test integration_test/ -d <udid>`; the old plain command was a false green (0 tests).
  D-6 kept; CI needs an emulator (see Interface reconciliation).
- **Acceptance gate:** smoke green on iPhone 17 sim (iOS 26.5); pending gate in place (12 pending); default
  run skips the 12, `BS01_RUN_PENDING=1` run executes them — both green (5 harness/guard tests).
- **Suites:** acceptance (this feature, both modes) on the sim; unit suite 92 green on host; coverage gate
  **PASS** (no `lib/` files touched — harness is test-only); `flutter analyze` clean.
- **Test grades: A** — graded by a fresh subagent against the scaffold rubric (no vacuous passes, honest
  comments, deterministic, discriminating); one strengthening applied post-grade (the mode test now asserts
  both gate branches env-independently via `forceRunPending`). Augmentations: none. Exclusions: none.
- **Fix passes: 0/3** — the suite was green the first time it actually ran; the only iteration was the runner
  discovery (false green → simulator, resolved by the owner decision, no code fix) and the post-grade test
  strengthening.
- Tokens: 7,980,954 (claude-opus-4-8) · Time: 29m 01s active (1h 13m wall; 44m waiting on the owner
  decision is excluded). **Phase total: 7,980,954 tokens, 29m 01s.**

### Checkpoint / Handoff

- **Frozen for ITEST-2/3** (one import — `import 'harness.dart';` — re-exports the fakes):
  - Fixtures: `SAMPLE_TERRACOTTA, SAMPLE_OLIVE, SAMPLE_COOL, SAMPLE_MEASURED, SAMPLE_ESTIMATED`.
  - Pending gate: `acTestWidgets('AC-n', '<desc>', (tester) async {…})` registers an AC test; **un-pend by
    deleting that AC's row from `pendingACs`** in `harness.dart`. `pendingSkipReason`/`runPending` back it.
  - Vocabulary: `await givenReadoutOf(tester, sample)` → `ReadoutHarness{tester, speech, haptics}`;
    `givenJustCapturedReadoutOf(tester, sample)` for AC-12; `ReadoutHarness.whenSelectSpace(space)` /
    `whenSpeak()` / `whenCompareAs(slot)` / `whenFindRecipes()` / `whenAcknowledge()`.
  - The AC tests go in `integration_test/readout_test.dart` (ITEST-2 = display group AC-1..7; ITEST-3 =
    actions group AC-8..12) — split file regions so the two phases stay ∥.
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  boot the sim `xcrun simctl boot <udid>` (iPhone 17 = `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`) then
  `xcrun simctl bootstatus <udid> -b`; `flutter analyze`; unit+coverage `flutter test --coverage` +
  `dart run tool/coverage_gate.dart <base>`; acceptance default `flutter test integration_test/ -d <udid>`;
  red-baseline `BS01_RUN_PENDING=1 flutter test integration_test/ -d <udid>`; shut down with
  `xcrun simctl shutdown <udid>`. First sim build is slow (~80s Xcode build); later runs ~20s.
- **Known gaps:** the AC tests don't exist yet (ITEST-2/3). `givenReadoutOf` renders safely because the shell
  calls no `ColorScience` method (the stub still throws until COLOR-2/3), so pending AC bodies will fail at the
  red baseline on Given/Then assertions — not on panics.
- **Next phase:** ITEST-2 (AC-1..7) ∥ ITEST-3 (AC-8..12) → ITEST-4 (test review, **G-2**). G-2 still blocks the
  whole behavior stage.

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

### Result

- **Landed** `integration_test/readout_test.dart` — the display group: one pending test per AC-1..AC-7 via
  `acTestWidgets`, driving the real `buildApp` through the harness vocabulary. Each asserts the catalogue's
  Then tightly and carries its control: AC-1 Lightness is the **strictly largest** body reading (every
  RichText except the name header + action labels) with grayscale + Munsell 5.5; AC-2 value word tied to L
  via dark(L15→"low/dark")/light(L90→"high") controls, rejecting "always middle"; AC-3 forces the name to be
  **derived** (input sample has no name → shell shows "Unnamed sample") and asserts top-position + largest
  font; AC-4 asserts the word "warm" and rejects the hue angle, with a cool (hue 250°) control; AC-5 selects
  each space and checks its values present + the other three absent via collision-safe signatures
  (`°`/`10R`/`#`hex/`25.27`); AC-6/AC-7 assert the exact Measured / "Estimated — not yet verified" +
  "Seeded by a model…" strings, each with a cross-tier control.
- **Harness fix (recorded):** the run-pending mode never actually executed a pending body on-device —
  `flutter test integration_test/` runs in the app process on the simulator, which does **not** inherit the
  host shell env, so `BS01_RUN_PENDING=1` never reached `runPending` there (ITEST-1's guard test only
  exercised the `forceRunPending` override, so the gap was latent). `harness.dart#runPending` now also honours
  a compile-time `--dart-define=BS01_RUN_PENDING=true`; the host-env path is kept. **Run-pending command is
  now:** `flutter test integration_test/ -d <udid> --dart-define=BS01_RUN_PENDING=true`.
- **Red baseline:** all 7 execute under the dart-define and **fail on a Then** (none panics), each naming its
  owning phase — rows below. Given preconditions (sample loaded, L58/hue42/tier, name-null) all pass today.
- **Acceptance gate:** default run green (5 harness/guard pass, 7 ACs pending-skipped); red baseline recorded.
  **Suites:** acceptance (this feature, both modes) on iPhone 17 sim; unit 92 green on host; coverage gate
  **PASS** (no `lib/` touched — test-only); `flutter analyze` clean.
- **Test grades: A** (7×A, 0×B) — graded by a fresh independent subagent against G1–G6; grid at
  `specs/bs-01-color-readout/behavior-test-completeness-bs-01-color-readout.md`. AC-5 is a borderline A (sRGB
  asserts the hex but not also a triplet — folded into READOUT-4 as an augmentation, below). The pre-seeded
  TestAC01 size augmentation is **dropped** — AC-1 already out-ranks every reading incl. the space readings.
- **Fix passes: 0/3** — the one iteration was the run-pending propagation discovery (harness dart-define fix),
  resolved before any grade.
- Tokens: 6,226,248 (claude-opus-4-8) · Time: 27m 50s active (27m 50s wall). **Phase total: 6,226,248 tokens, 27m 50s.**

### Checkpoint / Handoff

- **Frozen for ITEST-3 and the behaviour phases:**
  - `integration_test/readout_test.dart` has one `main()`; the **display group (AC-1..AC-7)** occupies the top
    region, and the helpers (`_paragraphsUnder` / `_paragraphsUnder2` → RichText render objects under a
    key/finder; `_plainTextUnder` → joined plain text; `_fontSize`; `_hueDegrees`; `_SpaceCase`) sit at the
    file bottom. ITEST-3 adds the **actions group (AC-8..AC-12)** inside `main()` at the marked region below
    the display group, reusing or extending these helpers.
  - **Un-pend contract unchanged:** delete the AC's row from `pendingACs` in `harness.dart`.
- **Run-pending mode (CHANGED):** use `--dart-define=BS01_RUN_PENDING=true`, **not** the env var, on-device.
  Full commands: default `flutter test integration_test/ -d <udid>`; red-baseline/un-pend
  `flutter test integration_test/ -d <udid> --dart-define=BS01_RUN_PENDING=true`. (Export
  `export PATH="$HOME/development/flutter/bin:$PATH"`; sim udid `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; boot
  first.) **CI's acceptance job must pass the dart-define** or pending ACs silently skip.
- **For the behaviour phases:** the display tests assert against these exact anchors — ValueRegion (`58`,
  `5.5`, grayscaleKey), NameHeader (derived name, largest + top), TemperatureLine (`warm`/`cool`, no angle),
  SpaceSelector.valuesKey (per-space values + exclusivity signatures `°`/`10R`/`#`hex/`25.27`),
  ProvenanceRegion (exact Measured / Estimated strings + note). READOUT-4 should render hue with a degree
  indicator and CIELAB a*/b* as `25.27`/`22.75` to satisfy AC-5, and add the sRGB triplet augmentation.
- **Known gaps:** AC-8..AC-12 not written yet (ITEST-3). The 7 display ACs stay red until their owning phases
  (READOUT-2/3/4/5, with COLOR-2/3 enablers) land.
- **Next phase:** ITEST-3 (AC-8..AC-12) → ITEST-4 (test review, **G-2**).

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
| AC-1 | AC-1 (LightnessProminent) | FAIL (Then) | Lightness 58 not rendered in value region | READOUT-2 | A |
| AC-2 | AC-2 (ValueWord) | FAIL (Then) | value word "middle" absent | READOUT-2 | A |
| AC-3 | AC-3 (ColourName) | FAIL (Then) | derived name not in header (Givens pass) | READOUT-3 | A |
| AC-4 | AC-4 (Temperature) | FAIL (Then) | word "warm" absent (shows "Temperature —") | READOUT-3 | A |
| AC-5 | AC-5 (ColourSpaceSelector) | FAIL (Then) | space values absent (shows "CIELCh values —") | READOUT-4 | A |
| AC-6 | AC-6 (MeasuredBadge) | FAIL (Then) | "Measured" absent (shows "Provenance —") | READOUT-5 | A |
| AC-7 | AC-7 (EstimatedBadge) | FAIL (Then) | "Estimated"/note absent (shows "Provenance —") | READOUT-5 | A |
| AC-8 | TestAC08_SpeakReadout | (to record) | Then: utterance components | A11Y-2 | |
| AC-9 | TestAC09_CompareAsA | (to record) | Then: slot A carries sample | READOUT-6 | |
| AC-10 | TestAC10_CompareAsB | (to record) | Then: slot B carries sample | READOUT-6 | |
| AC-11 | TestAC11_FindRecipes | (to record) | Then: Recipes target set | READOUT-6 | |
| AC-12 | TestAC12_JustCaptured | (to record) | Then: haptic + marker lifecycle | A11Y-2 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC01 | ~~until the colour-space readings render, fewer readings exist to prove Lightness is *largest*~~ | READOUT-4 | — | ❌ Dropped (ITEST-2): AC-1 already asserts L strictly larger than **every** body reading (incl. space readings once rendered); READOUT-4 adds no new assertion, so it fails the "would have failed before" discriminate test. |
| TestAC05 | the spec's sRGB row is "a triplet **and** a hex"; the test asserts the hex only (no exact triplet value in the spec, so G4 doesn't bite — graded A) | READOUT-4 | add a triplet pattern (three 0–255 ints) to the sRGB `present` list once READOUT-4 fixes the format | ⬜ Open |
