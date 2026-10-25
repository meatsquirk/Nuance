# Module ITEST — Acceptance integration suite

**Status:** In progress — ITEST-4 review packet assembled; ⏸ awaiting the human's G-2 decision
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/ui_improvements/` (new), the `BS20_RUN_PENDING` pending gate for this suite
**Depends on:** all shell phases (A11Y-1, READOUT-2) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ✅ Done | 6,189,165 | 11m 09s |
| ITEST-2 | acceptance-tests | AC-1/2/3/4/5/9 | ✅ Done | 4,295,303 | 18m 44s |
| ITEST-3 | acceptance-tests | AC-6/7/8 | ✅ Done | 4,608,096 | 14m 06s |
| ITEST-4 | test-review | — (G-2) | ⏸ Awaiting review | | |

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

### Result — ITEST-3 (✅ Done)

Landed `integration_test/ui_improvements/settings_test.dart` — one **pending** test
per settings/Speak AC (AC-6/7/8) over the real `buildApp` via the ITEST-1 harness.
**No `lib/` change**, so the coverage gate is N/A ("nothing to gate" PASS vs
`148df14`).

- **Tests & Rejects (all grade A):**
  - **AC-6** default-off — opens the settings panel; Given re-asserted
    (`settings.accessibilityFeatures isFalse`); Then the keyed `SwitchListTile`
    is present (`findsOneWidget`) and `value isFalse`; **control** drives the set
    on and asserts the toggle reads `isTrue`. Rejects toggle-defaulting-on,
    toggle-absent, and a constant-off render.
  - **AC-7** Speak hidden while off — Given off re-asserted; Then
    `speakControl findsNothing`; **control** turns accessibility on and asserts
    Speak appears (pairs AC-8's direction, so off→hidden isn't vacuous). Rejects
    the always-shown actions bar and a never-rendered Speak.
  - **AC-8** Speak shown when on — Given off re-asserted; **control**
    `speakControl findsNothing` while off; When turns the named flag on (verified
    `isTrue`); Then `speakControl findsOneWidget`. Rejects Speak-absent-after-on
    and an always-shown Speak; binds to the named flag specifically.
- **Verification:** `flutter analyze` clean; default run **3/3 skipped** (suite
  green); run-pending (`--dart-define=BS20_RUN_PENDING=true`) **1 pass / 2 fail**:
  AC-7 fails on its primary Then and AC-8 on its control (both Speak-present-while-off,
  owner READOUT-7, no panic) — the red baseline. **AC-6 passes at baseline**
  (green at baseline — the A11Y-1 shell already ships default-off).
- **Grade gate:** fresh-subagent grade vs G1–G6 → **3 A / 0 B** (cumulative suite
  9 A / 0 B); grid `behavior-test-completeness-bs-20-ui-improvements.md`.
- **AC-6 green-at-baseline — kept pending, raised for G-2.** The "off by default"
  behaviour is already satisfied by the A11Y-1 shell. Per the red-baseline rule a
  green-at-baseline test is normally un-pended, but un-pending AC-6 would leave
  its owner A11Y-2 with no pending AC against the smoke "no dead phase" guard (and
  no honest basis to mark A11Y-2 complete before it runs). So AC-6 is left pending
  and surfaced to the ITEST-4 test review (G-2) to decide: keep A11Y-2 as a
  keep-green + unit-coverage phase, or accept AC-6 as shell-satisfied. This is a
  plan-shaping call for the human, not an AC-test-phase decision.
- **Augmentation closed in-phase.** The pre-seeded TestAC07_SpeakHidden
  augmentation is satisfied now — AC-7/AC-8 assert both directions as a pair, so
  no READOUT-7 test change is scheduled.
- **Fix passes: 0/3.** **Tokens 4,608,096 · Time 14m 06s.**

### Checkpoint / Handoff — ITEST-3

- **Frozen:** `settings_test.dart` is the settings/Speak AC contract. The
  contracts a behaviour phase must satisfy: AC-6 the accessibility toggle present
  and `value false` on a fresh app (already true in the shell); AC-7 no
  `ActionsBar.speakKey` while `accessibilityFeatures` is off; AC-8 the
  `ActionsBar.speakKey` present once it is on. Un-pend = delete the AC's row from
  `pendingACs` (and A11Y-2 / READOUT-7 add themselves to
  `completedBehaviorPhases` when they un-pend their last AC).
- **READOUT-7** owns AC-7 **and** AC-8 (the Speak gate, both directions). It must
  make the readout read `DisplayScope`'s `accessibilityFeatures` to show/hide
  `ActionsBar`'s Speak control; both tests then go green together. It also carries
  the bs-01 AC-8 reconciliation (D-3) and G-3.
- **A11Y-2** owns AC-6 (green at baseline) — pending the G-2 decision above.
- **Verification (reuse):** per-file `flutter test -d flutter-tester
  integration_test/ui_improvements/settings_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` for the red/un-pend run); flutter at
  `/Users/matthew.quirk/development/flutter/bin` (prepend PATH; no `timeout`).
- **Next:** ITEST-4 (test review, **G-2**) — now unblocked (ITEST-2 + ITEST-3
  both done). The packet must flag AC-6's green-at-baseline decision and the
  bs-01 AC-5/AC-8 reconciliations (D-3) for the reviewer.

## Phase ITEST-4 — Test review (G-2)

- **Kind:** test-review · **Target AC:** —
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (catalogue vs tests, red baseline, Rejects, augmentations, the bs-01 AC-5/AC-8 reconciliations D-3 called out for the reviewer); human decides **G-2**.
- **Exit criteria:** human records approved (or changes requested → ITEST change phases + re-review).
- **Status:** ⏸ Awaiting review — packet below; G-2 awaiting the reviewer's decision.

### Review packet — G-2 (⏸ Awaiting decision)

The nine acceptance tests that guard the behavior stage, put in front of a human before any
product code is written. Suite re-confirmed green at HEAD (`74a8477`): smoke **7/7**; default mode
`readout_test` **6/6 skipped**, `settings_test` **3/3 skipped** (per-file — the whole dir won't launch
at once, house gotcha). Grade grid **9 A / 0 B** —
[`behavior-test-completeness-bs-20-ui-improvements.md`](../behavior-test-completeness-bs-20-ui-improvements.md).

**⚑ Look at these two first (decisions this review must settle):**

1. **AC-6 is green at baseline.** The A11Y-1 shell already ships
   `DisplaySettings.accessibilityFeatures = false`, so "off by default" holds today. The test is
   tight (its in-test control drives the flag on and asserts the toggle reads `true`, rejecting a
   constant-off render — grade A), but it passes now rather than failing red. It was **kept pending**
   rather than un-pended, because un-pending it would leave its owner **A11Y-2** with no pending AC
   against the smoke "no dead phase" guard and no honest basis to mark A11Y-2 done before it runs.
   **Decide:** keep A11Y-2 as a keep-green + unit-coverage phase (default — un-pends AC-6, adds the
   controller-setter unit coverage the shell still lacks), **or** accept AC-6 as shell-satisfied and
   drop A11Y-2. Recommendation: **keep A11Y-2** — the shell toggle is inert; A11Y-2 is where its wiring
   earns unit coverage.
2. **The bs-01 reconciliations (D-3).** bs-20 supersedes two already-shipped bs-01 ACs, so the merged
   bs-01 suite must be reconciled as those phases land, or it reds:
   - **bs-01 AC-5 (space selector)** — AC-4 removes the one-at-a-time `SpaceSelector`. **READOUT-3**
     retires bs-01's selector acceptance test when it shows all four spaces at once.
   - **bs-01 AC-8 (Speak)** — AC-7 hides Speak while accessibility is off. **READOUT-7** updates bs-01's
     Speak test to turn accessibility on first. Tied to **G-3** (confirm hiding Speak by default does
     not violate bs-11 accessibility-conformance).
   **Decide:** confirm this reconciliation plan is the intended treatment of the bs-01 ACs (not a
   regression to flag).

**Per-AC catalogue vs test** (Given checked · When · Then / Rejects — all grade A):

| AC | Test | Given (checked via public surface) | When | Then / Rejects |
|---|---|---|---|---|
| AC-1 | `TestAC01_HeroCard` (READOUT-4) | `warmTerracotta` pumped via `buildApp`; readout renders | readout shown | L58 sits in a **bordered** ancestor **and** is the strictly largest reading paragraph (header + action-bar excluded). Rejects: plain row no card; a card not largest. |
| AC-2 | `TestAC02_ValueScale` (READOUT-5) | `value2Sample`; `find.text('Munsell value 2')` re-asserted | readout shown | eleven `0..10` step labels present; exactly one **selected `Semantics`** step containing `2`. Rejects: bare text no scale; no marked step; wrong step. |
| AC-3 | `TestAC03_EqualSwatches` (READOUT-4) | `anySample`; readout renders | readout shown | grayscale square size `equals` the displayed-colour `ColorChip`'s single `DecoratedBox`. Rejects: different size (16×16 vs 48×48 baseline). |
| AC-4 | `TestAC04_AllSpaces` (READOUT-3) | `warmTerracotta`; readout renders | readout shown | CIELCh, Munsell, sRGB **and** CIELAB signatures all present **in the all-spaces region** + `SpaceSelector findsNothing`. Rejects: only one shown; selector present. |
| AC-5 | `TestAC05_Definitions` (READOUT-6) | `warmTerracotta`, all four `ReadoutSpace.values`; openable-name precondition (names READOUT-3/6) | tap a space name | definition hidden→shown before/after pair + an `e.g.\|example\|for instance` example cue. Rejects: name not tappable; tap shows nothing; definition without example. |
| AC-6 | `TestAC06_DefaultOff` (A11Y-2) | fresh app; `settings.accessibilityFeatures isFalse` re-asserted | settings panel shown | keyed `SwitchListTile` present, `value isFalse`; **control** drives set-on → `isTrue`. Rejects: toggle-defaulting-on; toggle-absent; constant-off render. **⚑ green at baseline.** |
| AC-7 | `TestAC07_SpeakHidden` (READOUT-7) | off re-asserted | readout shown | `speakControl findsNothing`; **control** turns on → Speak appears (pairs AC-8, so off→hidden not vacuous). Rejects: always-shown actions bar; never-rendered Speak. |
| AC-8 | `TestAC08_SpeakShown` (READOUT-7) | off re-asserted; **control** `findsNothing` while off | turn named flag on (`isTrue` verified) | `speakControl findsOneWidget`. Rejects: Speak-absent-after-on; always-shown Speak; binds to the **named** flag. |
| AC-9 | `TestAC09_ColorSpelling` (READOUT-8) | `warmTerracotta`; readout renders | readout shown | scoped to readout `Scaffold`: `isNot(contains('colou'))` + `\bcolor\b` positive control. Rejects: any "Colour" left. |

**Red baseline** (run-pending, `--dart-define=BS20_RUN_PENDING=true`): AC-1/2/3/4/7/8/9 and AC-5 all
fail on their intended Then (or Given-precondition naming the owner) with no panics/compile errors;
AC-6 **green at baseline**. Full per-test table above under *Red baseline*.

**Augmentations:** one pre-seeded — `TestAC07_SpeakHidden` ("absent while off" could pass vacuously).
**Closed in ITEST-3**: AC-7 carries the on→shown control and AC-8 the off→hidden control in-test, so the
pair is non-vacuous now and **READOUT-7 makes no test change** — it just makes both go green. No open
augmentation rows remain.

**Two heuristic Thens the grader examined** (both held A): AC-5's example-marker regex (tightest proxy
for "an example accompanies the definition"; rejects a bare definition) and AC-2's `contains('2')`
(unique over the bounded 0..10 label domain). See the grid's Notes.

**Decision command:** `/feature-next-phase --gate bs-20-ui-improvements G-2 approved` — or
`/feature-next-phase --gate bs-20-ui-improvements G-2 "changes: <items>"` (each item becomes an ITEST
change phase before the behavior stage, then a fresh review).

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
| AC-6 | TestAC06_DefaultOff | ⚠ **green at baseline** (passes) | — the shell already ships `accessibilityFeatures = false`, so "off by default" holds today; kept pending for the G-2 review (see note) | A11Y-2 | A |
| AC-7 | TestAC07_SpeakHidden | ✅ fails (run-pending) | Then (primary): Speak present while off (`ActionsBar` is always shown, `readout_screen.dart:101`) — fails `findsNothing` | READOUT-7 | A |
| AC-8 | TestAC08_SpeakShown | ✅ fails (run-pending) | Then (control): Speak present while off — fails the `findsNothing` control that pairs the on→shown primary | READOUT-7 | A |
| AC-9 | TestAC09_ColorSpelling | ✅ fails (run-pending) | Then: readout copy still contains "colou" ("Displayed colour" present) | READOUT-8 | A |

## Test augmentations  <!-- pre-seeded in plan mode -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC07_SpeakHidden | with no Speak control in the new layout yet, "absent while off" can pass vacuously | ~~READOUT-7~~ (closed in ITEST-3) | assert Speak present when on (pair both directions) | ✅ Closed in ITEST-3 — AC-7 carries the on→shown control in-test and AC-8 the off→hidden control, so the pair is non-vacuous now; no READOUT-7 test change needed (READOUT-7 just makes both go green). |
