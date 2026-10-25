# Module ITEST — Acceptance integration suite

**Status:** In progress — ITEST-1 (harness) done; next ITEST-2 ∥ ITEST-3
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/ui_improvements/` (new), the `BS20_RUN_PENDING` pending gate for this suite
**Depends on:** all shell phases (A11Y-1, READOUT-2) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ✅ Done | 6,189,165 | 11m 09s |
| ITEST-2 | acceptance-tests | AC-1/2/3/4/5/9 | ⬜ Todo | | |
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
| AC-1 | TestAC01_HeroCard | (to record) | Then: hero card is largest | READOUT-4 | |
| AC-2 | TestAC02_ValueScale | (to record) | Then: 0–10 scale + marked step | READOUT-5 | |
| AC-3 | TestAC03_EqualSwatches | (to record) | Then: equal swatch size | READOUT-4 | |
| AC-4 | TestAC04_AllSpaces | (to record) | Then: all four + no selector | READOUT-3 | |
| AC-5 | TestAC05_Definitions | (to record) | When: name not tappable | READOUT-6 | |
| AC-6 | TestAC06_DefaultOff | (to record) | Then: toggle value false | A11Y-2 | |
| AC-7 | TestAC07_SpeakHidden | (to record) | Then: Speak absent while off | READOUT-7 | |
| AC-8 | TestAC08_SpeakShown | (to record) | Then: Speak present when on | READOUT-7 | |
| AC-9 | TestAC09_ColorSpelling | (to record) | Then: no "Colour" in copy | READOUT-8 | |

## Test augmentations  <!-- pre-seeded in plan mode -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC07_SpeakHidden | with no Speak control in the new layout yet, "absent while off" can pass vacuously | READOUT-7 | assert Speak present when on (pair both directions) | ⬜ Open |
