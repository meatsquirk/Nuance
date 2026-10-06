# Module ITEST — acceptance integration suite

**Status:** ⏸ Awaiting review — ITEST-1/2/3 done, ITEST-4 packet assembled; G-2 awaiting decision (blocks the behaviour stage)
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
| 3 | acceptance-tests | AC-8..AC-12 | ✅ Done | 6,061,969 | 17m 53s |
| 4 | test-review | — (G-2) | ⏸ Awaiting review | 1,057,046 | 2m 20s |

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
- **G-2 (approve acceptance tests)** — *awaiting decision* (ITEST-4 packet assembled 2026-10-06). This
  module's exit gate; blocks every behavior phase until a human records the decision via `--gate`.

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

### Result

- **Landed** in `integration_test/readout_test.dart` — the **actions group** (AC-8..AC-12), one pending test
  per AC via `acTestWidgets`, driving the real `buildApp` through the harness vocabulary (added
  `import app/router.dart` for `ComparisonSlot`, and a `_chroma` helper beside `_hueDegrees`). Each asserts the
  catalogue's Then tightly: **AC-8** — one utterance (`hasLength(1)`) stating name "Warm Terracotta", value
  "58", temperature "warm" (asserted against the **name-stripped** utterance so the name's "Warm" can't satisfy
  it), hue in words (`\b(orange|red)\b`), chroma "34", hue angle "42", with the fixture's L/hue/chroma asserted
  as Givens; **AC-9/AC-10** — a control pair asserting the Comparison screen with the sample in the chosen slot
  **and** the other slot `(empty)` (exact stub strings), rejecting "always slot X"; **AC-11** — the Recipes
  screen with the exact "Recipe target: Deep Olive Green"; **AC-12** — one haptic pulse on render
  (`confirmations == 1`) + a visible "just captured" marker, cleared after acknowledge, with a non-fresh control
  (fresh `FakeHaptics`, `confirmations == 0`, no marker).
- **Red baseline:** all 5 execute under `--dart-define=BS01_RUN_PENDING=true` and **fail on a Then** (none
  panics), each naming its owning phase — rows in the Red baseline table above (AC-8/AC-12 → A11Y-2,
  AC-9/10/11 → READOUT-6). All Givens pass today (sample shown; empty speech log; not-on-destination).
- **Acceptance gate:** default run green (5 harness/guard pass, **12** ACs pending-skipped); red baseline
  recorded. **Suites:** acceptance (this feature, both modes) on iPhone 17 sim (iOS 26.5); unit 92 green on
  host; coverage gate **PASS** (only `readout_test.dart` touched — test-only, nothing to gate); `flutter
  analyze` clean.
- **Test grades: A** (5×A, 0×B) — graded by a fresh independent subagent against G1–G6; grid at
  `specs/bs-01-color-readout/behavior-test-completeness-bs-01-color-readout.md`. **AC-8 was graded B (G5)** —
  `lower.contains('warm')` was vacuously satisfied by the name "Warm Terracotta"; **fixed** by asserting the
  temperature word against the name-stripped utterance, re-graded A. Augmentations: none new.
  Exclusions: none.
- **Fix passes: 1/3** — the AC-8 G5 fix (name-stripped temperature assertion). No code moved for the others.
- Tokens: 6,061,969 (claude-opus-4-8) · Time: 17m 53s active (17m 53s wall). **Phase total: 6,061,969 tokens, 17m 53s.**

### Checkpoint / Handoff

- **The whole AC catalogue (AC-1..AC-12) is now written and pending**, grade all A; ITEST-4 (test review, G-2)
  assembles the packet from the two grade summaries + the Red baseline table. No AC-test phases remain.
- **Behaviour-phase anchors added by ITEST-3** (assert against these exactly):
  - **AC-8 (A11Y-2 + COLOR-3):** the speak action produces **exactly one** `Speech.speak` call whose text
    contains the name, the value number `58`, the temperature word `warm` (**distinct from the name** — the
    test strips "Warm Terracotta" before checking), a hue word matching `orange|red`, the chroma `34` and the
    hue angle `42`. COLOR-3's `decompose(sample)` must emit all six components in one string.
  - **AC-9/AC-10/AC-11 (READOUT-6):** the compare/recipes actions navigate so the stub screens render —
    Comparison shows `Slot A: <name>` / `Slot B: <name>` (unfilled slot = `(empty)`); Recipes shows
    `Recipe target: <name>`. The actions must carry the sample into the **chosen** slot / as the target.
  - **AC-12 (A11Y-2):** a just-captured readout must (a) fire `Haptics.confirm()` **exactly once** on first
    render, and (b) render a visible "just captured" marker (text matching `just[ -]?captured`, case-insensitive
    — **no lib key exists for it yet; A11Y-2 must add the marker text/semantics**) that clears when
    `acknowledge()` runs. A non-fresh readout fires no haptic and shows no marker.
- **Run-pending mode unchanged:** `flutter test integration_test/ -d <udid> --dart-define=BS01_RUN_PENDING=true`
  (default run omits the define; export `PATH="$HOME/development/flutter/bin:$PATH"`, boot sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` first). CI's un-pend job must pass the dart-define.
- **Known gaps:** AC-8..AC-12 stay red until A11Y-2 / READOUT-6 land (behind G-2). No new augmentations; the
  one open augmentation (AC-5 sRGB triplet, READOUT-4) is unchanged.
- **Next phase:** ITEST-4 (test review, **G-2**) — the stage's last phase; it gates the whole behaviour stage.

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

### Packet

**For the reviewer — what this packet asks.** Approve (or request changes to) the 12 acceptance tests that
define "done" for bs-01-color-readout **before** any behaviour is coded. Each test is written and *pending*
(skipped in the default run; executed under `--dart-define=BS01_RUN_PENDING=true`). All 12 pass their Givens
today and fail on a Then that names the phase owing the behaviour (the Red baseline table below). The grade
grid (independent fresh grader, 2026-10-06) is **12×A, 0×B** —
`specs/bs-01-color-readout/behavior-test-completeness-bs-01-color-readout.md`.

**Boundary under test:** the real assembled app via the single production `buildApp(deps)`, driven by
`WidgetTester`. Real color-science (`ColorScienceImpl`), controllers, widgets, routing, provenance. Faked —
infrastructure only — `FakeSpeech` (records utterances) and `FakeHaptics` (counts pulses). Tests live in
`integration_test/readout_test.dart`; vocabulary + fixtures in `integration_test/harness.dart`.

**Look at first:** (1) **AC-5** — the one borderline A (sRGB triplet unasserted; hex only). Augmentation open,
assigned to READOUT-4 — confirm you accept shipping the hex-only assertion until then. (2) **AC-8** — hue
asserted as a *family* (`orange|red`), not an exact word; and it was caught+fixed from a B (the name
"Warm Terracotta" vacuously satisfied the "warm" check — now asserted against the name-stripped utterance).
(3) **AC-12** — the "just captured" marker is asserted by **visible text** (`just[ -]?captured`); no lib key
exists yet, so A11Y-2 must add the marker text/semantics.

Per-AC (test name · Given · When · Then + Rejects):

- **AC-1 · TestAC01_LightnessProminent** — *Given* SAMPLE_TERRACOTTA shown, `coordinates.lightness == 58`.
  *When* readout rendered. *Then* the Lightness reading (value `58`, grayscale swatch via `grayscaleKey`,
  Munsell value `5.5`) is the **strictly largest** body paragraph (name header + action labels excluded).
  *Rejects* not-largest, missing grayscale, missing Munsell value. Name prominence excluded (owned by AC-3).
- **AC-2 · TestAC02_ValueWord** — *Given* L58 on input. *When* rendered. *Then* a "middle" value word in the
  value region. *Rejects* "always middle" via dark (L15→`low|dark`) and light (L90→`high`) controls; collision
  handled (`high` not `light`; word boundaries on `low|dark`).
- **AC-3 · TestAC03_ColourName** — *Given* the sample carries **no** name (shell shows "Unnamed sample").
  *When* rendered. *Then* a **derived** name in the header, above the value region and `>=` every other body
  paragraph. *Rejects* name-absent, name-small, name-not-at-top, and any shell echoing `Sample.name`.
- **AC-4 · TestAC04_Temperature** — *Given* hue ≈ 42° on input, sample shown. *When* rendered. *Then* the
  **word** "warm" on the temperature line and `isNot(contains('42'))`. *Rejects* the hue angle (G4) and
  "always warm" via a cool (hue ≈ 250°) control.
- **AC-5 · TestAC05_ColourSpaceSelector** — *Given* sample shown. *When* `whenSelectSpace` for each space.
  *Then* the selected space's values present and the other three absent, via collision-safe signatures
  (`°|deg`, `10R`, `#`+6 hex, `25.27`). *Rejects* stale values after a switch. **Gap (borderline A):** sRGB
  triplet unasserted (hex only) — spec fixes no exact triplet → augmentation, not a rule failure.
- **AC-6 · TestAC06_MeasuredBadge** — *Given* `provenance.tier == measured`, "Measured Reading" shown.
  *When* rendered. *Then* exact badge word "Measured" and `isNot` the Estimated strings. *Rejects* badging
  every tier alike; pairs with AC-7.
- **AC-7 · TestAC07_EstimatedBadge** — *Given* estimated tier on input + surface. *When* rendered. *Then*
  "Estimated", "not yet verified", and the exact note "Seeded by a model. Treat as a starting point." with an
  in-test SAMPLE_MEASURED control showing no note. *Rejects* "Estimated without note", "Measured", "note on
  every reading".
- **AC-8 · TestAC08_SpeakReadout** — *Given* name shown, `speech.utterances` empty, L58/hue≈42/chroma≈34 on
  input. *When* `whenSpeak()`. *Then* **exactly one** utterance (`hasLength(1)`) containing the name, value
  `58`, temperature word `warm` (asserted against the **name-stripped** utterance), a hue word `orange|red`,
  chroma `34`, hue angle `42`. *Rejects* fragment streams and omission of any component. COLOR-3's
  `decompose(sample)` must emit all six in one string.
- **AC-9 · TestAC09_CompareAsA** — *Given* name shown, Comparison not already open. *When* `whenCompareAs(A)`.
  *Then* Comparison screen with "Slot A: Warm Terracotta" + "Slot B: (empty)". *Rejects* "always slot B",
  "fills both", "navigates without carrying". Control pair with AC-10.
- **AC-10 · TestAC10_CompareAsB** — mirror of AC-9 (slot B filled, A empty). The pair rejects any
  "always slot X" impl — each fails exactly one.
- **AC-11 · TestAC11_FindRecipes** — *Given* "Deep Olive Green" shown, Recipes not open. *When*
  `whenFindRecipes()`. *Then* Recipes screen with exact "Recipe target: Deep Olive Green". *Rejects*
  "no target set" (→ "(unnamed)") and "wrong sample".
- **AC-12 · TestAC12_JustCaptured** — *Given* a just-captured readout (`copyWith(justCaptured: true)`), name
  shown. *When* first render, then `whenAcknowledge()`. *Then* `haptics.confirmations == 1` on render and a
  visible "just captured" marker, cleared after acknowledge; a non-fresh control fires no haptic and shows no
  marker. *Rejects* "no haptic", "fires on every rebuild", marker-never-set/never-clears/always-on.

**Red baseline summary:** all 12 execute under the dart-define and fail on a **Then** (none panics), each
naming its owning phase — full table below. Givens (sample loaded, L/hue/chroma, tier, name-null, empty
speech/haptics, not-on-destination) all pass today.

**Augmentations:** one open — **AC-5 sRGB triplet**, closed by **READOUT-4** (add a three-int 0–255 pattern to
the sRGB present list once the format lands). The pre-seeded TestAC01 size augmentation was **dropped** in
ITEST-2 (AC-1 already out-ranks every reading). Full table below.

**Grid:** `specs/bs-01-color-readout/behavior-test-completeness-bs-01-color-readout.md` — 12 rows, **12×A**
(AC-5 borderline A), 0×B. One B was found and fixed during authoring (AC-8, G5).

**Decision requested (G-2):** approve these 12 tests to unblock the behaviour stage, or request changes.
Record with: `/feature-next-phase --gate bs-01-color-readout G-2 approved | "<changes>"`.

### Result

- **Assembled the ITEST-4 review packet** (above) from the two AC-test phases' Results, the whole-suite grade
  grid (12×A, 0×B; AC-5 borderline A), the Red baseline table (12/12 fail on a Then, each naming its owning
  phase) and the augmentations table (one open — AC-5 sRGB triplet → READOUT-4). No product or test code
  changed; this phase documents and gates.
- **Phase set `⏸ Awaiting review`; G-2 set *awaiting decision*.** Behaviour stage (COLOR-2/3, READOUT-2..6,
  A11Y-2) stays blocked until a human records the G-2 decision.
- **Gates:** acceptance/unit/coverage not re-run — no code touched; the suite state is the one ITEST-2/3
  recorded (default run green with 12 pending; unit 92 green; coverage PASS test-only).
- Tokens: 1,057,046 (claude-opus-4-8) · Time: 2m 20s active (2m 20s wall). **Phase total: 1,057,046 tokens, 2m 20s.**

### Checkpoint / Handoff

- **Awaiting the human G-2 decision.** On **approved**: G-2 resolves, this phase flips to ✅ Done, and the
  behaviour stage opens — COLOR-2 and COLOR-3 (enablers) are the first startable phases, then READOUT-2..6 and
  A11Y-2 un-pend their ACs (delete the AC's row from `pendingACs` in `harness.dart`). On **changes requested**:
  each item becomes an `ITEST` change phase before the behaviour stage, followed by a fresh review.
- **Un-pend contract:** delete the AC's row from `const pendingACs` in `integration_test/harness.dart`; the
  behaviour phase then un-skips and must pass. Behaviour phases run on the booted sim with
  `--dart-define=BS01_RUN_PENDING=true` for the ACs they un-pend; CI's acceptance job must pass the define.
- **Carry-forward augmentation:** AC-5 sRGB triplet, owned by READOUT-4.
- **Next phase:** none until G-2 is recorded. After approval → COLOR-2 ∥ COLOR-3 (enablers).

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
| AC-8 | AC-8 (SpeakReadout) | FAIL (Then) | `speech.utterances` length 0 ≠ 1 (speak action not wired) | A11Y-2 | A |
| AC-9 | AC-9 (CompareAsA) | FAIL (Then) | Comparison screen not shown (no nav handoff) | READOUT-6 | A |
| AC-10 | AC-10 (CompareAsB) | FAIL (Then) | Comparison screen not shown (no nav handoff) | READOUT-6 | A |
| AC-11 | AC-11 (FindRecipes) | FAIL (Then) | Recipes screen not shown (no nav handoff) | READOUT-6 | A |
| AC-12 | AC-12 (JustCaptured) | FAIL (Then) | `haptics.confirmations` 0 ≠ 1 (no haptic on render) | A11Y-2 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC01 | ~~until the colour-space readings render, fewer readings exist to prove Lightness is *largest*~~ | READOUT-4 | — | ❌ Dropped (ITEST-2): AC-1 already asserts L strictly larger than **every** body reading (incl. space readings once rendered); READOUT-4 adds no new assertion, so it fails the "would have failed before" discriminate test. |
| TestAC05 | the spec's sRGB row is "a triplet **and** a hex"; the test asserts the hex only (no exact triplet value in the spec, so G4 doesn't bite — graded A) | READOUT-4 | add a triplet pattern (three 0–255 ints) to the sRGB `present` list once READOUT-4 fixes the format | ⬜ Open |
