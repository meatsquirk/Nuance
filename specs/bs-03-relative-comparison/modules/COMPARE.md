# Module COMPARE — comparison controller & assembly

**Status:** In progress — COMPARE-3 (AC-1, AC-2, AC-12) and COMPARE-6 (AC-10, AC-11) done; only COMPARE-5 (AC-3) remains, blocked on DIFF-3
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/compare/comparison_controller.dart`, `lib/compare/comparison_state.dart`,
`lib/compare/comparison_read_endpoint.dart`, `lib/compare/sample_source.dart` (interface + in-memory
catalogue). Replaces `lib/compare/compare_stub.dart`. Extends `lib/app/build_app.dart` (comparison entry) and
reuses `lib/app/router.dart` (`toComparison`, `toReadout`). Carries the scaffold (COMPARE-1).
**Depends on:** bs-01 domain/router/Speech/Readout, DIFF (`Comparison`), CVD (`CvdProfile`/`ConfusionCheck`) ·
**Blocks:** SCREEN, ITEST, every behaviour phase

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 2,185,042 | 9m 04s (42m 14s) |
| 2 | shell | — | ✅ Done | 12,364,300 | 25m 01s |
| 3 | behavior | AC-1, AC-2, AC-12 | ✅ Done | 11,695,533 | 22m 21s |
| 5 | behavior | AC-3 | ⬜ Todo | | |
| 6 | behavior | AC-10, AC-11 | ✅ Done | 9,095,859 | 19m 08s |

(Phase numbers skip to align with the feature-wide session log: DIFF/CVD own the other behaviour phases.)

## Interface reconciliation

- **`ComparisonController`** holds slot A / slot B (`Sample?` each) and derives a `Comparison?` via DIFF's
  `compare` + CVD's `confusable` — null when either slot is empty (drives AC-12). `swap()` exchanges the slots
  and the derived statement re-expresses automatically (AC-3). `openReadout(slot)` returns via
  `AppRouter.toReadout`.
- **`SampleSource`** (D-7): `List<Sample> savedSamples()`; the in-memory catalogue is the bs-03 impl, injected
  via `AppDependencies.sampleSource`. **bs-06** later supplies a persistent store behind this same interface.
- **`ComparisonReadEndpoint`** (D-6): an `InheritedWidget` (mirroring bs-02's `CaptureReadEndpoint`) exposing
  slot A/B and the derived `Comparison?` (ΔE00, verdict, the three lines, `confusable`) to the acceptance
  suite. Kept reachable across the Readout push (AC-10/11) so a test reading state after navigation doesn't
  throw.
- **Comparison entry** (D-8): `AppDependencies.comparisonEntry` (a sample source + profile) opens the app on
  the Comparison screen owning the controller, symmetric to bs-02's `captureSource`.

## Open gates

- None of this module's own (feature gates G-1/G-3 gate the scaffold and behaviour via the master plan).

## Phase 1 — Scaffold (COMPARE-1)

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (feature gate G-1 approve-spec, G-2 bs-01 merged) · **Blocks:** DIFF-1, CVD-1
- **Files:** branch only + `integration_test/bs03/pending.dart` (the pending runner); no product code.
- **Tasks:**
  1. Cut `feat/bs-03-relative-comparison` from `main` @ c793839 (confirm bs-01 foundation present).
  2. Baseline run: record unit + integration counts and coverage on a clean tree.
  3. Confirm the coverage gate (`tool/coverage_gate.dart`) passes clean and fails on a planted gap (prove both
     ways), as bs-01/bs-02 run it.
  4. Add the BS03 pending runner mirroring `integration_test/bs02/pending.dart` (env flag `BS03_RUN_PENDING`).
- **Exit criteria:** branch cut; baseline recorded; gate proven both ways; pending runner in place; existing
  suites green.
- **Acceptance gate:** *(scaffold — tooling works, baseline recorded)*

### Result

Scaffold complete; no product code (`lib/**`) touched.

- **Branch:** `feat/bs-03-relative-comparison` cut from `main` @ `c793839` (bs-01 signed-off foundation
  present; `b3bcc38` main tip is only the bs-02 gate-decision commit, no product code). bs-02 is in flight on
  its own branch and is **not** a prerequisite (D-1), so the bs-03 spec + plan files were brought across from
  `feat/bs-02-sample-capture` onto the clean bs-01 base (user-approved branch strategy).
- **Baseline (Flutter 3.47.6, stable):** `flutter analyze` clean; unit **196 green** (`flutter test
  --coverage`); integration **17 green** (`flutter test integration_test/` — bs-01 `readout_test` +
  `harness_test`, ran on iOS sim). Existing suites green.
- **Coverage gate proven both ways:** `dart run tool/coverage_gate.dart main` — PASS clean ("no touched
  lib/**.dart files", exit 0); FAIL on a planted untracked `lib/_gate_probe.dart` ("NO COVERAGE DATA", exit 1);
  probe removed.
- **BS03 pending runner:** `integration_test/bs03/pending.dart` added, mirroring `bs02/pending.dart` —
  mechanism only (`pendingACs` empty; ITEST-1 seeds the 12 ACs), `behaviorPhases` = the 7 bs-03 behaviour
  phases, keyed to `BS03_RUN_PENDING` (env var or `--dart-define`). Analyze clean with it present.
- Coverage gate: no `lib` touched ⇒ nothing to gate, PASS. Fix passes: 0/3 (passed first run).

### Checkpoint / Handoff

- **Frozen for shells:** pending-gate API — `pendingACs`, `behaviorPhases`, `runPending`,
  `pendingSkipReason(acId, {forceRunPending})`, `acTestWidgets(acId, description, body)` in
  `integration_test/bs03/pending.dart`. Un-pend flag `BS03_RUN_PENDING`; bs-03 integration test file is
  `integration_test/comparison_test.dart` (ITEST-1/2/3).
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `flutter test integration_test/` ·
  `dart run tool/coverage_gate.dart main` (base = `main`; equivalently `c793839`, no lib delta between them).
  Run-pending (on-device): `BS03_RUN_PENDING=1 flutter test integration_test/comparison_test.dart` (or
  `--dart-define=BS03_RUN_PENDING=true`).
- **Known gaps / notes:** no product code yet. Carry-over from bs-01 (master plan Known flakes): a const
  constructor line can intermittently read uncovered on `flutter test --coverage` — re-run once if the gate
  flags an untouched file. Untracked bs-04..bs-14 specs + `docs/` sit in the tree from the prior branch; not
  part of bs-03 and not committed by this phase.
- **Next:** DIFF-1 and CVD-1 (shells) are now unblocked (parallelisable); they do not need G-3/G-4.

## Phase 2 — Controller / state / source / endpoint / entry shell (COMPARE-2)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** DIFF-1, CVD-1 · **Blocks:** SCREEN-1
- **Files:** `lib/compare/comparison_controller.dart`, `comparison_state.dart`, `comparison_read_endpoint.dart`,
  `sample_source.dart`; `lib/app/build_app.dart` (comparison entry); remove/replace `compare_stub.dart` behind
  `AppRouter.toComparison`.
- **Tasks:**
  1. `ComparisonState` (slots + derived `Comparison?`) and `ComparisonController` (selectA/selectB/swap/
     openReadout) wired to DIFF/CVD, all returning the shells' placeholders.
  2. `SampleSource` interface + an empty in-memory catalogue impl.
  3. `ComparisonReadEndpoint` exposing the state; comparison entry in `buildApp`; route `toComparison` to the
     real (empty) screen shell host.
  4. Keep behaviour unchanged: with no real math, the screen shows empty slots and no statement.
- **Exit criteria:** `flutter analyze` clean; unit gate 100% on new files; the app assembles and opens on the
  comparison entry; existing suites green.
- **Acceptance gate:** *(shell — none)*

### Result

Shell landed; behaviour unchanged (empty catalogue ⇒ empty slots, no statement).

- **New (`lib/compare/`):** `sample_source.dart` (`SampleSource` interface + `InMemorySampleSource`, empty
  default, read-only `savedSamples()`), `comparison_state.dart` (`ComparisonState`: slots + derived
  `Comparison?` + `confusable` + `hasBothSlots`, value equality), `comparison_controller.dart`
  (`ComparisonController extends ChangeNotifier`: derives the pair via DIFF `compare` + CVD
  `confusable` — the one wiring seam; `selectA`/`selectB`/`swap`/`openReadout` declared and throw,
  deferred to COMPARE-3/5/6 per their Files lists), `comparison_read_endpoint.dart`
  (`ComparisonReadEndpoint` InheritedWidget, mirrors bs-02's `CaptureReadEndpoint`, `endpointKey` +
  `of`).
- **`build_app.dart`:** `AppDependencies.sampleSource` (D-7, empty default) + `comparisonEntry`
  (`ComparisonEntry?`, D-8); `buildApp` opens on `ComparisonHomeScreen` when the entry is set, else the
  Readout; `ComparisonHomeScreen` owns the controller + wraps the subtree in the read endpoint, body is a
  placeholder rendering the two slots (SCREEN-1 swaps in the real `ComparisonScreen`).
- **`router.dart`:** `toComparison` now routes to `ComparisonHomeScreen` (carried sample via
  `initialA`/`initialB`), replacing the deleted `compare_stub.dart`.
- **Gate:** `flutter analyze` clean; unit **241 green** (was 215); coverage **100% on all 9 touched files**
  (`dart run tool/coverage_gate.dart main` PASS); integration **17 green** on iOS sim (incl. bs-01 AC-9/AC-10
  now hitting the real screen — behaviour preserved). Shell kind ⇒ no acceptance/grade gate. **Fix passes: 1/3**
  (first run: 1 widget-test read the endpoint from an ancestor context — fixed to a descendant; 1 const-ctor
  line uncovered — fixed with a runtime construction).
- **Tests:** +`test/compare/{sample_source,comparison_state,comparison_controller,comparison_read_endpoint}_test.dart`;
  extended `build_app_test.dart` (entry branch, screen, defaults); updated `router_test.dart`
  (`ComparisonHomeScreen`); deleted `compare_stub{,_test}.dart`.
- **Deviations (reported):** (1) `openReadout` needs `AppRouter.toReadout`, which bs-01 does **not** provide
  (gap-analysis says it does) — deferred to COMPARE-6, which adds `toReadout`. (2) `ComparisonHomeScreen`
  takes its deps as explicit params (not `AppScope.of`) because the handoff route is pushed outside an
  `AppScope` in bs-01's `router_test`/`actions_bar_test`; the comparison-entry path passes `deps.*`. (3)
  `comparisonEntry` is a marker; the sample source + profile it "carries" (D-8) are the top-level deps
  (`sampleSource` D-7, `cvdProfile`/`confusionCheck` from CVD-1).

### Checkpoint / Handoff

- **Frozen for SCREEN-1 / behaviour phases:**
  - `ComparisonController({required sampleSource, required confusionCheck, required profile, Sample? initialA,
    Sample? initialB})` — `state` (`ComparisonState`), `savedSamples`. `_state` is `final` in the shell;
    **COMPARE-3** makes it mutable and adds an `emit`/notify path when it wires `selectA`/`selectB`.
  - `ComparisonState(slotA, slotB, comparison, confusable)` + `hasBothSlots`; derivation is null/false
    unless both slots set (drives AC-12).
  - `ComparisonReadEndpoint` (`endpointKey` `'comparison-read-endpoint'`, `of(context)`) — read it from a
    context **below** the endpoint (it is a descendant of `ComparisonHomeScreen`).
  - `AppDependencies.sampleSource` + `comparisonEntry` (`ComparisonEntry()` opts into the comparison home);
    `buildApp` switches home on `comparisonEntry != null`.
  - `AppRouter.toComparison` → `ComparisonHomeScreen(initialA/initialB)`. `AppRouter.toReadout` is **not yet
    added** — COMPARE-6 adds it for `openReadout`.
- **SCREEN-1 next:** replace `_ComparisonShellBody` in `build_app.dart` (the placeholder two-slot body) with
  `ComparisonScreen(controller: ...)` composing the five region widgets; keep `ComparisonHomeScreen`'s
  controller ownership + the read-endpoint wrap. The real screen must still render the slots as findable text
  so the handoff route tests stay green (or update those bs-01 tests deliberately).
- **Verification commands** (export PATH first): `flutter analyze` · `flutter test --coverage` ·
  `dart run tool/coverage_gate.dart main` · integration on the iOS sim:
  `flutter test integration_test/ -d <iPhone sim id>` (run under the verify lock — shared device). Base =
  `main` (≡ this phase's `d3c8c44`, no lib delta vs `main` beyond committed DIFF-1/CVD-1).
- **Known gaps / notes:** catalogue is empty in the shell (COMPARE-3 seeds it). Carry-over bs-01 const-line
  coverage flake still applies (re-run `--coverage` once if an untouched file flags). Untracked bs-04..bs-14
  specs + `docs/` remain in the tree, not part of bs-03.

## Phase 3 — Sample selection + invite (COMPARE-3)

- **Kind:** behavior
- **Target AC:** AC-1, AC-2, AC-12
- **Depends on:** ITEST-4 (G-3) · **Blocks:** COMPARE-5, COMPARE-6, DIFF-2, CVD-2 (Givens)
- **Files:** `sample_source.dart` (populate the catalogue), `comparison_controller.dart` (selectA/selectB),
  `slots_region.dart` (picker E3/E5/E49 + slot-A/B render), `statement_region.dart` (the empty-B choose-B
  invite).
- **Tasks:**
  1. Populate the in-memory catalogue with the named saved samples (the fixtures' subjects).
  2. Implement selectA/selectB placing a chosen sample into its slot; render the slot name + "L n, C n, h n
     degrees" (LCh via bs-01 `labToCielch`, rounded).
  3. When slot B is empty, render no relational statement and a findable, enabled choose-sample-B invite
     (AC-12).
- **Exit criteria:** unit gate 100% on touched code; `TestAC01_ChooseA`, `TestAC02_ChooseB`,
  `TestAC12_InviteSecond` green run-pending; the smoke + earlier green stay green.
- **Acceptance gate:** un-pend AC-1, AC-2, AC-12; suite green for those tests.

### Result

Behaviour landed: the painter can now choose saved samples into slots A and B, each slot shows its CIELCh
reading, and a single-sample screen suppresses the statement and invites a second sample. AC-1, AC-2, AC-12
un-pended and green.

- **`slots_region.dart`** — Choose sample A / B (E3/E5) are now enabled and open a `showDialog` sample picker
  (E49) listing `controller.savedSamples` (a `SimpleDialogOption` per sample); choosing one calls
  `selectA`/`selectB`. Each set slot renders its name line **and** a reading line `L n, C n, h n degrees`
  from bs-01's pure `labToCielch(sample.coordinates)`, rounded. Empty slot: name line only. `Sample picker`
  and `Swap A and B` stay inert (swap is COMPARE-5).
- **`comparison_controller.dart`** — `_state` made mutable; `selectA`/`selectB` re-derive the state via the
  existing `_derive` seam (preserving the other slot) and `_emit` (sets state + `notifyListeners`). One slot
  ⇒ `comparison` stays null (drives AC-12); both ⇒ the pair reads through DIFF/CVD (placeholders until
  DIFF-2/3, CVD-2).
- **`statement_region.dart`** — when `comparison == null` it renders no decomposition line and an invite
  (`"Choose a second sample to compare."`); when both slots are set it keeps the `—` placeholder DIFF-3
  fills. (The AC-12 *enabled control* the test asserts is the slots region's Choose-B button; the statement
  invite text is the user-facing prompt.)
- **`sample_source.dart`** — unchanged: the shell's `InMemorySampleSource(samples:)` already holds a seeded
  catalogue; the acceptance suite injects `CATALOGUE`, and the picker lists it through
  `controller.savedSamples`. The shipped default stays empty (persistent catalogue is bs-06, D-7) — reported
  deviation from the plan's "populate the catalogue" task, with no AC impact.
- **Gates.** `flutter analyze` clean. Unit **254 green** (was 247; +7 selection/picker/invite/render tests;
  rewired the two SCREEN-1 shell tests that asserted inert Choose controls / the statement placeholder).
  Coverage gate **PASS** — 100% line coverage on all 15 touched `lib/**` files
  (`dart run tool/coverage_gate.dart main`). Acceptance (iOS sim, under the verify lock): default
  `flutter test integration_test/comparison_test.dart` **17 pass / 9 pending** — AC-1, AC-2, AC-12 un-pended
  and green; full `flutter test integration_test/` **34 pass / 9 pending** (bs-01 handoff AC-9/AC-10 still
  green with the new slot reading line). **Test grades: 3×A, 0×B** — AC-1/AC-2/AC-12 graded by an independent
  fresh-context grader against G1–G6 (grid: `../behavior-test-completeness-bs-03-relative-comparison.md`,
  *COMPARE-3* section). **Fix passes: 1/3** (first run: one bare-`SlotsRegion` widget test asserted the
  re-rendered slot text without a `ListenableBuilder` — switched those picker tests to pump the full
  `ComparisonScreen`). No coverage exclusions. No augmentations assigned to AC-1/2/12.
- **Tokens / time:** 11,695,533 · 22m 21s (active = wall), one session.

### Checkpoint / Handoff

- **Frozen for the remaining behaviour phases:**
  - `ComparisonController.selectA(Sample)` / `selectB(Sample)` place a sample into the slot, preserve the
    other, re-derive via `_derive` and `_emit` (notifies). `_state` is now mutable; `_emit(next)` is the one
    mutation path — **COMPARE-5**'s `swap` should route through it too.
  - `SlotsRegion` owns the picker (`_choose` → `showDialog<Sample>` over `controller.savedSamples`) and the
    slot render (`_slot`: name line + `L n, C n, h n degrees` via `labToCielch`). COMPARE-5 adds the E4 swap
    control here; the `Swap A and B` button is present but `onPressed: null` — wire it to `controller.swap`.
  - `StatementRegion` branches on `controller.state.comparison`: null ⇒ invite; non-null ⇒ the `—`
    placeholder. **DIFF-3** replaces the non-null branch with the three decomposition lines and keeps the
    null branch's invite intact (AC-12 must stay green).
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration on the
  iOS sim under the verify lock:
  `$C with-lock <FEATURE> <PHASE> --wait 900 -- bash -c "export PATH=…; cd <repo> && flutter test integration_test/ -d <iPhone-sim-id>"`
  (booted sim this session: iPhone 17 `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`). Run-pending:
  `--dart-define=BS03_RUN_PENDING=true`. Base = `main` (the gate measures the whole bs-03 lib delta).
- **Known gaps / notes:** the both-slots statement/difference/confusion regions still show placeholders
  (DIFF-2/3, CVD-2 fill them). The shipped `AppDependencies.sampleSource` default is empty (bs-06). Carry-over
  bs-01 const-line coverage flake still applies (re-run `--coverage` once if an untouched file flags).
  Untracked bs-04..bs-14 specs + `docs/` remain in the tree, not part of bs-03.
- **Next:** COMPARE-6 (AC-10, AC-11 — open readout; `actions_bar.dart` + `comparison_controller.openReadout`,
  wires `AppRouter.toReadout`), DIFF-2 (AC-4), CVD-2 (AC-7/8) run in parallel (file-disjoint) now that
  selection exists.

## Phase 5 — Swap A / B (COMPARE-5)

- **Kind:** behavior
- **Target AC:** AC-3
- **Depends on:** DIFF-3 (a statement to re-express) · **Blocks:** SIGNOFF-1
- **Files:** `comparison_controller.dart` (`swap`), the E4 swap control in `slots_region.dart`.
- **Tasks:**
  1. `swap()` exchanges slots A and B; the derived `Comparison` recomputes so the statement re-expresses
     new-A → new-B (a direction flips, e.g. "Lighter by 12" → "Darker by 12").
  2. Wire the E4 control.
- **Exit criteria:** unit gate 100% on touched code; `TestAC03_Swap` green run-pending; earlier ACs green.
- **Acceptance gate:** un-pend AC-3; suite green for that test and all earlier ACs.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 6 — Open readout for A / B (COMPARE-6)

- **Kind:** behavior
- **Target AC:** AC-10, AC-11
- **Depends on:** COMPARE-3 · **Blocks:** SIGNOFF-1
- **Files:** `comparison_controller.dart` (`openReadout`), the E7/E8 controls in `actions_bar.dart`.
- **Tasks:**
  1. Wire E7 → `AppRouter.toReadout(slotA)` and E8 → `toReadout(slotB)`; keep the read endpoint reachable
     across the push (D-6).
  2. Controls enabled only when the corresponding slot is set.
- **Exit criteria:** unit gate 100% on touched code; `TestAC10_OpenReadoutA`, `TestAC11_OpenReadoutB` green
  run-pending; earlier ACs green.
- **Acceptance gate:** un-pend AC-10, AC-11; suite green for those tests and all earlier ACs.

### Result

Behaviour landed: the painter can open either compared sample in its full Readout from the comparison. AC-10,
AC-11 un-pended and green.

- **`router.dart`** — new `AppRouter.toReadout(sample)` returns a `MaterialPageRoute` building bs-01's
  `ReadoutScreen(sample:)`; the screen reads its services from the enclosing `AppScope` (the production
  assembly wraps the navigator in one), symmetric to `toComparison`. The COMPARE-2 deviation — `openReadout`
  needed a `toReadout` bs-01 didn't provide — is now closed.
- **`comparison_controller.dart`** — `openReadout(slot)` implemented: `router.toReadout(sampleIn(slot)!)`.
  Added `sampleIn(slot)` (the sample in a slot, or null) and `slotFilled(slot)` (the actions bar's enabled
  predicate), and injected `AppRouter router` (default `const AppRouter()`; the assembly passes
  `AppDependencies.router`). `swap` stays deferred to COMPARE-5.
- **`actions_bar.dart`** — E7/E8 ("Open readout for A/B") wired: each `onPressed` pushes
  `controller.openReadout(slot)` and is enabled only when `controller.slotFilled(slot)` (AC-10/AC-11). Speak
  (E6) stays inert until CVD-3. The whole screen sits in a `ListenableBuilder` on the controller, so the
  controls' enabled state tracks the slots.
- **`build_app.dart`** — `ComparisonHomeScreen` gains a `router` field (default `const AppRouter()`) threaded
  into the controller; `buildApp` passes `deps.router`.
- **Gates.** `flutter analyze` clean. Unit **260 green** (was 254; +6: openReadout/sampleIn/slotFilled, the
  two actions-bar tap handoffs via a stub router, the toReadout route; rewrote the actions-bar inert test).
  Coverage gate **PASS** — 100% line coverage on all 15 touched `lib/**` files
  (`dart run tool/coverage_gate.dart main`). Acceptance (iOS sim, under the verify lock): default
  `flutter test integration_test/comparison_test.dart` **19 pass / 7 pending** — AC-10, AC-11 un-pended and
  green; full `flutter test integration_test/` **36 pass / 7 pending** (bs-01 handoffs still green with the new
  `toReadout`). **Test grades: 5×A, 0×B** — the un-pended AC-1/2/10/11/12 graded by an independent
  fresh-context grader against G1–G6 (grid: `../behavior-test-completeness-bs-03-relative-comparison.md`,
  *COMPARE-6* section). **Fix passes: 1/3** (first run: the ITEST-1 complement guard failed because AC-10/11
  were un-pended — updated its `unpended` set to {AC-1,AC-2,AC-10,AC-11,AC-12}; a bookkeeping guard, not an AC
  test). No coverage exclusions. No augmentations assigned to AC-10/AC-11, and the open-readout behaviour gives
  no already-green AC test (AC-1/2/12 — selection, a different region) anything new to assert (G6).
- **Tokens / time:** 9,095,859 · 19m 08s (active = wall), one session.

### Checkpoint / Handoff

- **Frozen for the remaining behaviour phases:**
  - `ComparisonController.openReadout(ComparisonSlot)` → `router.toReadout(sampleIn(slot)!)`; `sampleIn(slot)`
    and `slotFilled(slot)` are the public slot accessors; `router` is injected
    (`AppDependencies.router` → `ComparisonHomeScreen.router` → the controller). Called only for a filled slot
    (the control is disabled otherwise).
  - `AppRouter.toReadout(Sample)` → `ReadoutScreen(sample:)`; the pushed route must sit under an `AppScope`
    (the real assembly provides it) — bs-01's `ReadoutScreen` reads `colorScience`/`speech`/`haptics`/`router`
    from it in `didChangeDependencies`.
  - `ComparisonActionsBar` E7/E8 are wired (enabled per `slotFilled`); "Speak whole comparison" is still
    `onPressed: null` — **CVD-3** wires it to the spoken comparison.
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration on the
  iOS sim under the verify lock:
  `$C with-lock <FEATURE> <PHASE> --wait 900 -- bash -c "export PATH=…; cd <repo> && flutter test integration_test/ -d <iPhone-sim-id>"`
  (booted sim this session: iPhone 17 `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`). Run-pending:
  `--dart-define=BS03_RUN_PENDING=true`. Base = `main` (the gate measures the whole bs-03 lib delta).
- **Known gaps / notes:** Speak (E6) inert until CVD-3; the both-slots difference/statement/confusion regions
  still show placeholders (DIFF-2/3, CVD-2). COMPARE-5 (swap, AC-3) stays blocked on DIFF-3. Carry-over bs-01
  const-line coverage flake still applies (re-run `--coverage` once if an untouched file flags). Untracked
  bs-04..bs-14 specs + `docs/` remain in the tree, not part of bs-03.
- **Next:** DIFF-2 (AC-4) and CVD-2 (AC-7/8) remain startable in parallel (file-disjoint); DIFF-3 follows
  DIFF-2, then COMPARE-5 (swap) and CVD-3 unblock.
