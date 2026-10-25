# Module ITEST — Acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/ui_improvements/` (new), the `BS20_RUN_PENDING` pending gate for this suite
**Depends on:** all shell phases (A11Y-1, READOUT-2) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ⬜ Todo | | |
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
