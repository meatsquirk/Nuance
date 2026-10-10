# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 done (harness + fixtures + scenes + smoke); next ITEST-2 ∥ ITEST-3
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/correction_test.dart`, `integration_test/correction_harness.dart`, `integration_test/bs05/pending.dart`; reuses `integration_test/fakes/` (`fake_capture_source.dart`, `fake_speech.dart`, `fake_haptics.dart`)
**Depends on:** all shell phases (CORRECT-1, LOOP-2, SCREEN-1) · **Blocks:** every behaviour phase (via the pending tests they un-pend) and G-2

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness + smoke) | ✅ Done | 8,454,576 | 20m 21s |
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
- **Result (ITEST-1, ✅):** the acceptance harness + the smoke/guard scaffold over the wired shells. Landed: `integration_test/correction_harness.dart` (fixtures `SAMPLE_DEEP_OLIVE` target [starts `estimated` so AC-9 is a real promotion], the five `PAINT_*` + `PALETTE_MY_PAINTS`, `RECIPE_DEEP_OLIVE` [a real `SubtractiveMixingEngine.forward` mix, parts summing to 1]; scenes `SCENE_OFF`/`SCENE_CLOSE`/`SCENE_CLOSER`/`SCENE_OCHRE_TRACE` as `SceneSpec` ground truths; the independent `referenceDeltaE00`; the `CorrectionHarness` vocabulary `whenCheck`/`whenRephotograph`/`whenSpeakCorrection`/`whenSaveConfirmed` + `state`/`controller` off `CorrectionReadEndpoint`; `givenCorrection`) and `integration_test/correction_test.dart` (1 never-pending smoke + 11 guards). `bs05/pending.dart` was already seeded with all 10 ACs by LOOP-1 — unchanged. No `lib/` touched. **Gates:** analyze clean; unit **632 green** (`flutter test --coverage`); coverage gate **100%** on the 14 branch `lib/` files (`dart run tool/coverage_gate.dart main`) — ITEST-1 added no `lib/` code; integration **default green** on sim `5AB9D06D…` — full suite **98 green**, `correction_test.dart` alone **12 green** (smoke + guards; not a false green). **Grade gate: 12×A, 0×B** (independent grader, fresh context — grid `behavior-test-completeness-bs-05-mix-correction-loop.md`: `referenceDeltaE00` verified independent of the product metric + the 5 Sharma pairs recomputed; the target recovers C24/h93; all four scene distances/directions recomputed TRUE). No red baseline here (that's ITEST-2/3). Fix passes: 0/3 (two analyze fixes before the first full gate run — a missing `non_constant_identifier_names` ignore and two test imports — not gate fix passes).

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

## Checkpoint / Handoff (after ITEST-1)

- **Frozen interfaces (ITEST-2/3 build on these):**
  - `givenCorrection(tester, {target = SAMPLE_DEEP_OLIVE, Recipe? currentMix, palette = PALETTE_MY_PAINTS, SceneSpec scene = SCENE_OFF, List<Sample> catalogue = const []})` → opens the real app via `buildApp` with a `CorrectionEntry(target, currentMix ?? RECIPE_DEEP_OLIVE)` + a `FakeCaptureSource(scene)`; seeds `sampleSource` from `catalogue` and `paletteSource` from `[palette]`. Pumps `const SizedBox()` first (fresh app per call). Returns a `CorrectionHarness`.
  - `CorrectionHarness`: `controller` / `state` read off `find.byKey(CorrectionReadEndpoint.endpointKey)`; actions `whenCheck()` (E26 ElevatedButton 'Check my mix'), `whenRephotograph()` (E28 TextButton), `whenSpeakCorrection()` (E27 TextButton), `whenSaveConfirmed()` (E29 ElevatedButton) — each taps `warnIfMissed: false` (shell controls disabled) and names the owner phase; `source` (reconfigure for AC-8 re-photograph) + `speech` (AC-7 utterance log).
  - Fixtures: `SAMPLE_DEEP_OLIVE` (L42, a −1.2561, b 23.9671 = C24/h93, tier `estimated`), `PALETTE_MY_PAINTS` (5 paints), `RECIPE_DEEP_OLIVE` (parts py43 .55 / pbk9 .25 / pw6 .20, predicted via real forward model). Scenes (`SceneSpec.groundTruth`): `SCENE_OFF` (36, −12.202, 27.406 ≈ ΔE00 10, too dark by 6, toward green), `SCENE_CLOSE` (42.5, −1.0, 22.3 ≈ ΔE00 0.96, within tolerance), `SCENE_CLOSER` (39, −6.0, 25.5 ≈ ΔE00 4.95), `SCENE_OCHRE_TRACE` (42, −1.3, 18.5 ≈ ΔE00 2.81, short of yellow). `kToleranceDeltaE00 = 2.0`. `referenceDeltaE00` — independent CIEDE2000, grade ΔE against it, never the product metric.
  - **Region keys** for finders: `CheckRegion.regionKey` 'correction-check-region', `DifferenceRegion` …-difference-region, `CorrectionRegion` …-correction-region, `SpeakRegion` …-speak-region, `RephotographRegion` …-rephotograph-region, `SaveRegion` …-save-region. Target line text: `Correction target: <name>`.
- **How ITEST-2/3 add tests:** append one `acTestWidgets('AC-n', 'TestACnn_<Slug> — …', (tester) async {…})` per AC inside the marked ITEST-2 / ITEST-3 groups in `correction_test.dart` (keep the groups disjoint — they edit one shared file, coordinate). All 10 ACs are already pending in `bs05/pending.dart`; default run skips them, `--dart-define=BS05_RUN_PENDING=true` runs them for the red baseline. **G-4 gates ITEST-3** (AC-2..6 detail: verdict words, tolerance, trace threshold, label) — resolve it before finalizing ITEST-3's assertions.
- **Verification commands** (unchanged from the shell phases): `export PATH="$HOME/development/flutter/bin:$PATH"`; `flutter analyze`; `flutter test --coverage`; `dart run tool/coverage_gate.dart main`; integration under the verify lock on sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`:
  `$C with-lock bs-05-mix-correction-loop <PHASE> --wait 900 -- bash -c 'export PATH=…; cd /Users/matthew.quirk/Nuance-bs05 && flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685'`. Run-pending: append `--dart-define=BS05_RUN_PENDING=true` (and target `integration_test/correction_test.dart`).
- **Known gaps / notes:** the `const`-constructor coverage flake (bs-01..bs-05) still applies — re-run `flutter test --coverage` once if the gate flags an untouched file. Always pass `-d <booted-udid>` (no device ⇒ zero integration tests, false green). The shared `fake_speech.dart`/`fake_haptics.dart` doc comments still cite bs-03/bs-04 AC numbers (AC-8/AC-12) — cosmetic, in the shared fakes, not the bs-05 tests.
