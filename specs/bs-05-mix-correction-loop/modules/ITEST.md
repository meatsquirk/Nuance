# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/correction_test.dart`, `integration_test/correction_harness.dart`, `integration_test/bs05/pending.dart`; reuses `integration_test/fakes/` (`fake_capture_source.dart`, `fake_speech.dart`, `fake_haptics.dart`)
**Depends on:** all shell phases (CORRECT-1, LOOP-2, SCREEN-1) · **Blocks:** every behaviour phase (via the pending tests they un-pend) and G-2

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness + smoke) | ⬜ Todo | | |
| 2 | acceptance-tests | AC-1, AC-7, AC-8, AC-9, AC-10 (pending) | ⬜ Todo | | |
| 3 | acceptance-tests | AC-2, AC-3, AC-4, AC-5, AC-6 (pending) | ⬜ Todo | | |
| 4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the whole app via `buildApp(AppDependencies(..., correctionEntry: CorrectionEntry(target:, currentMix:)))`. Real: capture path, `CorrectionEngine`, `MixingEngine.forward`, `deltaE00`, controller, screen, routing, `Provenance`, `SampleSource`. Faked (infrastructure only): `FakeCaptureSource` (configured ground-truth scene), `FakeSpeech`, `FakeHaptics`.
- **Observation points:** `CorrectionReadEndpoint` (target, `mixedSwatch`, `Difference`, `Correction`, within-tolerance, promoted provenance); the rendered regions by `regionKey`; `FakeSpeech.utterances` (AC-7); the `SampleSource` saved sample's provenance + a later `ReadoutScreen`'s `ProvenanceBadge` (AC-9/AC-10). ΔE00 graded against the independent `referenceDeltaE00`.
- **Pending gate:** `integration_test/bs05/pending.dart`, flag `BS05_RUN_PENDING`, `acTestWidgets(acId, desc, body)` skips an AC while its id is in `pendingACs`; **un-pend = delete that row**. Default run skips pending; `--dart-define=BS05_RUN_PENDING=true` runs them. Mirror `bs04/pending.dart` exactly (device process does not inherit host env — the dart-define is required).

## Phase 1 — Harness + fixtures + scenes + smoke (ITEST-1)

- **Kind:** acceptance-tests
- **Tasks:** `correction_harness.dart` with `givenCorrection(tester, {target, currentMix, palette, scene, ...})` (pump `const SizedBox()` first, then `buildApp` with the correction entry + a `FakeCaptureSource` configured to `scene`); the fixtures (`SAMPLE_DEEP_OLIVE`, `RECIPE_DEEP_OLIVE`, `PALETTE_MY_PAINTS`, `SCENE_OFF`/`SCENE_CLOSE`/`SCENE_CLOSER`/`SCENE_OCHRE_TRACE`) and the independent `referenceDeltaE00`; a `CorrectionHarness` vocabulary (`whenCheck()`, `whenRephotograph()`, `whenSpeakCorrection()`, `whenSaveConfirmed()`, `state`/`controller` getters off the endpoint); `correction_test.dart` with a never-pending smoke test (boots the app, every `regionKey` present, initial state null) + `bs05/pending.dart` seeding all 10 ACs.
- **Exit criteria:** analyze clean; unit green; integration default green (10 pending), smoke green; grade gate pass.

## Phase 2 — AC-1, AC-7, AC-8, AC-9, AC-10 (pending) + red baseline (ITEST-2)

- **Kind:** acceptance-tests
- **Tasks:** one pending `acTestWidgets` per AC per the master catalogue (the loop/provenance ACs); record the run-pending red baseline (each fails cleanly at its owner-naming Then/precondition). `∥ ITEST-3` — disjoint rows in the shared `correction_test.dart`/harness (coordinate edits).
- **Exit criteria:** analyze clean; unit green; integration default green (all pending) / run-pending these 5 fail cleanly; grade gate pass; red baseline recorded below.

## Phase 3 — AC-2, AC-3, AC-4, AC-5, AC-6 (pending) + red baseline (ITEST-3)

- **Kind:** acceptance-tests
- **Depends on:** also needs **G-4** resolved (verdict words/tolerance/trace threshold/amounts) before the detail assertions are final.
- **Tasks:** one pending `acTestWidgets` per AC per the catalogue (the difference/correction detail ACs); seed `TestAC02`'s within-tolerance control as an augmentation owned by CORRECT-4; AC-4's forward-score control in-test. Record the run-pending red baseline.
- **Exit criteria:** analyze clean; unit green; integration default green (all pending) / run-pending these 5 fail cleanly; grade gate pass; red baseline recorded below.

## Phase 4 — Test review (ITEST-4, G-2)

- **Kind:** test-review
- **Tasks:** assemble the review packet (the 10 AC tests + guards, the grade grid, the red baseline, the augmentation schedule); run the full regression (analyze; unit; coverage; integration default + run-pending under the lock). A human decides **G-2**. Approval flips ITEST-4 done and opens the behaviour stage; "changes requested" becomes ITEST change phases + a fresh review.
- **Exit criteria:** packet complete; regression green; **G-2** recorded by a human.

## Red baseline  <!-- filled by ITEST-2/3 -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_CheckPhotographsAndCompares | | | LOOP-3 | |
| AC-2 | TestAC02_DeltaEAndVerdict | | | CORRECT-2 | |
| AC-3 | TestAC03_ValueLeadingDecomposition | | | CORRECT-2 | |
| AC-4 | TestAC04_ConcreteCorrection | | | CORRECT-3 | |
| AC-5 | TestAC05_TouchOf | | | CORRECT-3 | |
| AC-6 | TestAC06_WithinTolerance | | | CORRECT-4 | |
| AC-7 | TestAC07_SpeakCorrection | | | LOOP-4 | |
| AC-8 | TestAC08_RephotographRechecks | | | LOOP-5 | |
| AC-9 | TestAC09_SaveConfirmed | | | LOOP-6 | |
| AC-10 | TestAC10_ConfirmedInReadout | | | LOOP-6 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behaviour phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC02 | one off-reading cannot show the verdict tracks distance (it could be a constant "noticeably off") | CORRECT-4 | a within-tolerance reading that reads "very close" (decisive control) | ⬜ Open |
