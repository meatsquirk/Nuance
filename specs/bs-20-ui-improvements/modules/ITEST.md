# Module ITEST — Acceptance integration suite

**Status:** In progress — ITEST-2 (readout AC tests) done; next ITEST-3 (settings/Speak AC tests), then ITEST-4 test review (G-2)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/ui_improvements/` (new), the `BS20_RUN_PENDING` pending gate for this suite
**Depends on:** all shell phases (A11Y-1, READOUT-2) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ✅ Done | 6,189,165 | 11m 09s |
| ITEST-2 | acceptance-tests | AC-1/2/3/4/5/9 | ✅ Done | 4,295,303 | 18m 44s |
| ITEST-3 | acceptance-tests | AC-6/7/8 | ⬜ Todo | | |
| ITEST-4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** pumps the real `ReadoutScreen` and `DisplaySettingsScreen` through production wiring (`buildApp` / `DisplayScope`). Fakes only the leaf sinks already faked by bs-01's suite (`Speech`, `Haptics`, `AppRouter`) and supplies the sample — all infrastructure, not behaviour under test.
- **Observation points:** widget finders (keyed anchors from the READOUT-2 / A11Y-1 shells) prove every Then. AC-7/AC-8 drive `DisplayController.setAccessibilityFeatures` and re-pump. No new read endpoint needed (presentation is directly observable).
- **Pending gate:** a `pendingACs` map (AC → owning phase) in `integration_test/ui_improvements/pending.dart`, keyed by `BS20_RUN_PENDING`; un-pend = delete one row. The smoke test never pends.

## Open gates

- **G-2** (test review, ITEST-4) blocks every behavior phase.

## Phase ITEST-1 — Harness

- **Kind:** acceptance-tests · **Target AC:** —
- **Depends on:** A11Y-1, READOUT-2 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/ui_improvements/harness.dart`, `pending.dart`, `smoke_test.dart`
- **Tasks:** shared pump harness (readout + settings via production wiring, fixtures); pending map with all **9** ACs pending; default (skip) + `BS20_RUN_PENDING=true` targets; a non-vacuous smoke test (asserts the readout pumps and the pending map is exactly the 9 ACs with real owners).
- **Exit criteria:** smoke green in both modes; whole dir / per-file launch confirmed.

### Result — ITEST-1 (✅ Done)

Landed the bs-20 acceptance-suite plumbing — **no `lib/` change**, so the
coverage gate is N/A ("nothing to gate" PASS vs `b905acb`).

- **`pending.dart`** — the `BS20_RUN_PENDING` gate mirroring `bs14/pending.dart`:
  `pendingACs` (all 9 ACs → owning phase, per the AC-coverage table),
  `behaviorPhases`, `completedBehaviorPhases` (empty), `allACs`,
  `pendingSkipReason(forceRunPending:)` and `acTestWidgets` (ITEST-2/3 register
  every AC through it).
- **`harness.dart`** — fixtures `warmTerracotta` (L58/10R 5.5/6; AC-1/4/5/9),
  `value2Sample` (L20 → Munsell value 2; AC-2), `anySample` (AC-3/7/8); the
  `UiHarness` driver (`givenReadoutOf` pumps the real app via `buildApp` with an
  injected `DisplayController` + faked `FakeSpeech`/`FakeHaptics`, real
  `ColorScienceImpl`; `whenOpenSettings`, `whenSetAccessibilityFeatures`, and the
  keyed finders from the READOUT-2 / A11Y-1 shells). Re-exports the gate, the
  fakes and `ReadoutSpace`.
- **`smoke_test.dart`** — 7 never-pending checks: readout renders every shell
  anchor through production wiring; the chrome opens the settings panel to the
  accessibility toggle; the AC universe is exactly AC-1..AC-9; the canonical
  owner map is nine ACs with real owners; every pending row names a real phase +
  the planned owner; no behaviour phase is dead/typo'd; the gate skips by default
  and runs under run-pending (both asserted via `forceRunPending`).
- **Grade:** scaffold self-check (no AC tests this phase — the AC grade grid
  lands in ITEST-2/3). Non-vacuous (asserts the stable AC universe + owner
  validity, holds as the gate empties — no "all 9 still pending" assertion);
  comments claim only what is checked; deterministic (pumpAndSettle, no sleeps).
- **Verification:** `flutter analyze integration_test/ui_improvements/` clean;
  smoke **7/7** default **and** `--dart-define=BS20_RUN_PENDING=true`; whole-dir
  launch green (one file today); coverage gate PASS. **Fix passes: 0/3.**
  **Tokens 6,189,165 · Time 11m 09s.**

### Checkpoint / Handoff — ITEST-1

- **Import surface:** an AC test imports only `harness.dart` (it re-exports
  `pending.dart`, the fakes and `ReadoutSpace`). `main()` begins with
  `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.
- **Frozen vocabulary:** `givenReadoutOf(tester, sample, {initialSettings})` →
  `UiHarness{ speech, haptics, controller, settings }`; `whenOpenSettings`,
  `whenCloseSettings`, `whenSetAccessibilityFeatures({required bool on})`;
  finders `valueRegion / heroCard / grayscaleSwatch / displayedColorChip /
  valueScale / allSpaces / spaceName(space) / spaceDefinition(space) /
  speakControl / settingsEntry / settingsPanel / accessibilityToggle`.
- **Fixtures:** `warmTerracotta`, `value2Sample`, `anySample` (above). ITEST-2/3
  must re-assert each fixture's derived Given (e.g. `value2Sample`'s Munsell
  value 2) through the public readout before the Then — not assume it.
- **Pending gate:** un-pend an AC = delete its row from `pendingACs`; a phase
  that un-pends its last AC adds itself to `completedBehaviorPhases` (keeps the
  smoke "no dead phase" guard green).
- **Verification (reuse):** `flutter` at
  `/Users/matthew.quirk/development/flutter/bin` (prepend PATH; no `timeout` on
  macOS); per-file `flutter test -d flutter-tester
  integration_test/ui_improvements/<file>_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` to run pending).
- **Next:** ITEST-2 (`readout_test.dart`, AC-1/2/3/4/5/9) ∥ ITEST-3
  (`settings_test.dart`, AC-6/7/8) — pending AC tests + red baseline, then
  ITEST-4 (test review, G-2).

## Phase ITEST-2 — Readout AC tests

- **Kind:** acceptance-tests · **Target AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-9 (pending)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/ui_improvements/readout_test.dart`
- **Tasks:** one pending test per AC per the master catalogue (Given/When/Then/Rejects); record the red baseline (each fails on its Then at `BS20_RUN_PENDING=true`, skips by default).
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate passed (each test rejects its plausible wrong impl).

### Result — ITEST-2 (✅ Done)

Landed `integration_test/ui_improvements/readout_test.dart` — one **pending** test
per readout AC (AC-1/2/3/4/5/9) over the real `buildApp` via the ITEST-1 harness.
**No `lib/` change**, so the coverage gate is N/A ("nothing to gate" PASS vs
`d1fa315`).

- **Tests & Rejects (all grade A):**
  - **AC-1** hero card — asserts Lightness 58 sits in a **bordered** ancestor
    (`_isBordered`: BoxDecoration border / ShapeDecoration side / Card) *and* is
    the strictly largest reading paragraph in the readout Scaffold (NameHeader +
    ActionsBar excluded). Rejects both: plain row no card, and a card not largest.
  - **AC-2** value scale — all eleven `0..10` step labels present under
    `valueScale`, and exactly one **selected `Semantics`** step whose label/text
    contains `2`. Rejects bare text (no scale), no marked step, wrong step.
    Given re-asserts `find.text('Munsell value 2')` (fixture → value 2, confirmed
    live at baseline).
  - **AC-3** equal swatches — `tester.getSize` of the grayscale keyed square vs
    the single `DecoratedBox` inside the displayed-colour `ColorChip` (margin-free
    painted boxes); `equals()` rejects different size (16×16 vs 48×48 baseline).
  - **AC-4** all spaces — four mutually-distinct signatures (°, `10R`, hex,
    r,g,b triplet, CIELAB `25.27`/`22.75`) **inside the all-spaces region only**
    + `SpaceSelector findsNothing`. Rejects only-one-shown and selector-present.
  - **AC-5** definitions — Scenario Outline over all four `ReadoutSpace.values`;
    openable-name precondition (checked before the tap → clean pending failure,
    no zero-size tap panic), definition hidden→shown before/after pair, and an
    `e.g.|example|for instance` example cue. Rejects un-tappable name, tap shows
    nothing, definition without example.
  - **AC-9** "Color" copy — scoped to the readout `Scaffold`:
    `isNot(contains('colou'))` (rejects any Colour left) + `\bcolor\b` positive
    control.
- **Verification:** `flutter analyze` clean; default run **6/6 skipped** (suite
  green); run-pending (`--dart-define=BS20_RUN_PENDING=true`) **6/6 fail** each on
  the intended Then (AC-1/2/3/4/9) or Given-precondition naming its owner (AC-5) —
  no panics/compile/harness errors. Red baseline recorded above.
- **Grade gate:** fresh-subagent `/behavior-test-check`-style grade vs G1–G6 →
  **6 A / 0 B**; grid `behavior-test-completeness-bs-20-ui-improvements.md`.
- **Fix passes: 0/3.** **Tokens 4,295,303 · Time 18m 44s.**

### Checkpoint / Handoff — ITEST-2

- **Frozen:** `readout_test.dart` is the readout AC contract. Behaviour phases
  un-pend by deleting the AC's row from `pendingACs` (harness). The contracts a
  behaviour phase must satisfy: AC-1 a **bordered** card around L58 that is the
  largest reading; AC-2 eleven `0..10` labels + one **selected `Semantics`** step
  labelled/containing the sample's value; AC-3 the displayed swatch `DecoratedBox`
  == the grayscale square size; AC-4 all four spaces' values **in the all-spaces
  region** and the `SpaceSelector` gone; AC-5 each space name an openable label
  revealing a definition whose text carries an `e.g.|example|for instance` cue;
  AC-9 no "colou" anywhere in the readout Scaffold copy.
- **Reused helpers:** ported `_parasUnder`/`_fontSize`/`_plainTextUnder`/
  `_isBordered` (bs-01 readout suite style).
- **Verification (reuse):** per-file `flutter test -d flutter-tester
  integration_test/ui_improvements/readout_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` for the red/un-pend run); flutter at
  `/Users/matthew.quirk/development/flutter/bin` (prepend PATH; no `timeout`).
- **Next:** ITEST-3 (`settings_test.dart`, AC-6/7/8) — still startable, disjoint
  file; then ITEST-4 (test review, **G-2**). ITEST-4's packet is unblocked once
  ITEST-3 lands.

## Phase ITEST-3 — Settings / Speak AC tests

- **Kind:** acceptance-tests · **Target AC:** AC-6, AC-7, AC-8 (pending)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/ui_improvements/settings_test.dart`
- **Tasks:** pending tests for default-off (AC-6), Speak-hidden-when-off (AC-7), Speak-shown-when-on (AC-8); AC-7/AC-8 written as a pair so "hidden" isn't vacuous (augmentation closed by READOUT-7).
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate passed.

## Phase ITEST-4 — Test review (G-2)

- **Kind:** test-review · **Target AC:** —
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (catalogue vs tests, red baseline, Rejects, augmentations, the bs-01 AC-5/AC-8 reconciliations D-3 called out for the reviewer); human decides **G-2**.
- **Exit criteria:** human records approved (or changes requested → ITEST change phases + re-review).

## Interface reconciliation (extras)
- **Boundary / Observation / Pending gate:** above.

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_HeroCard | ✅ fails (run-pending) | Then: Lightness 58 not in a *bordered* card (ancestor-border predicate found 0; shell renders a plain `KeyedSubtree` row) | READOUT-4 | A |
| AC-2 | TestAC02_ValueScale | ✅ fails (run-pending) | Then: scale step label `0` absent (shell `ValueScale` is `SizedBox.shrink`; also no selected-`Semantics` marked step) — Given "Munsell value 2" passes | READOUT-5 | A |
| AC-3 | TestAC03_EqualSwatches | ✅ fails (run-pending) | Then: swatch sizes unequal — displayed 16×16 vs grayscale 48×48 | READOUT-4 | A |
| AC-4 | TestAC04_AllSpaces | ✅ fails (run-pending) | Then: CIELCh signature absent in the all-spaces region (shell region empty; `SpaceSelector` still present) | READOUT-3 | A |
| AC-5 | TestAC05_Definitions | ✅ fails (run-pending) | Given-precond (names READOUT-3/6): CIELCh name not shown as an openable label (shell `SpaceDefinition` is empty) — fails before the tap, no panic | READOUT-6 | A |
| AC-6 | TestAC06_DefaultOff | (ITEST-3) | Then: toggle value false | A11Y-2 | |
| AC-7 | TestAC07_SpeakHidden | (ITEST-3) | Then: Speak absent while off | READOUT-7 | |
| AC-8 | TestAC08_SpeakShown | (ITEST-3) | Then: Speak present when on | READOUT-7 | |
| AC-9 | TestAC09_ColorSpelling | ✅ fails (run-pending) | Then: readout copy still contains "colou" ("Displayed colour" present) | READOUT-8 | A |

## Test augmentations  <!-- pre-seeded in plan mode -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC07_SpeakHidden | with no Speak control in the new layout yet, "absent while off" can pass vacuously | READOUT-7 | assert Speak present when on (pair both directions) | ⬜ Open |
