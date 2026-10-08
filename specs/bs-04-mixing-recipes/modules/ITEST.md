# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/recipes_test.dart` (AC tests + smoke/guards),
`integration_test/recipes_harness.dart` (Given/When/Then vocabulary, fixtures, the independent
`referenceDeltaE00`, the `buildApp` driver with the recipes entry); re-uses
`integration_test/fakes/fake_speech.dart`; re-exports `integration_test/bs04/pending.dart` (scaffolded in
RECIPE-1).
**Depends on:** all shell phases (ENGINE-1, RECIPE-2, SCREEN-1) · **Blocks:** every behaviour phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ⬜ Todo | | |
| 2 | acceptance-tests | AC-1,2,3,11,12 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-4,5,6,7,8,9,10 | ⬜ Todo | | |
| 4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the assembled app via `buildApp(deps)` with the recipes entry (D-6), driven by `WidgetTester`.
  Real: the `PaletteSource`, `SampleSource`, the `MixingEngine` (forward + inverse + verdict + trace + muddying
  + gamut + wet/dry), the `RecipeController`, the screen and routing. Faked (infrastructure only): bs-01's
  `FakeSpeech`. No colour, mixing or ΔE00 math is faked.
- **Observation points:** AC-1 — target region text + `state.target`; AC-2 — `state.manualError` + unchanged
  `state.target`; AC-3 — every `state.recipes[*].components[*].paint` ∈ the selected palette; AC-4 —
  `3 ≤ state.recipes.length ≤ 5` + rendered parts/predicted colour; AC-5 — `recipe.deltaE00` (vs
  `referenceDeltaE00`) + `recipe.verdict`; AC-6 — the order of `state.recipes` (2-paint index < 4-paint index);
  AC-7 — the trace component rendered "a touch of" + note; AC-8 — `recipe.muddying` + rendered flag (+ a
  non-crossing control); AC-9 — `state.outOfGamut` + the "OUT OF GAMUT" banner + the nearest labelled as
  nearest; AC-10 — the recipe's predicted colour before/after the wet/dry toggle; AC-11/AC-12 — the
  `FakeSpeech` utterance log.
- **Pending gate:** `integration_test/bs04/pending.dart` — a `pendingACs` map (AC → owning phase) + `acTestWidgets('AC-n', …)`
  skipping unless un-pended or `--dart-define=BS04_RUN_PENDING=true`. Un-pending an AC = delete its map row
  (and add it to the guard test's `unpended` set). Default `flutter test integration_test/recipes_test.dart -d <udid>`
  skips pending; run-pending executes them. **A device udid is required** or the run is a false green.

## Open gates

- **G-2 (approve the acceptance tests)** — ITEST-4's packet; blocks every behaviour phase. Open.
- **G-4 (spec-data / engine reconciliation — spec author)** — blocks ITEST-3 (the AC tests that would
  otherwise pin the spec's illustrative predicted colours). ITEST-3 writes AC-5/AC-10 against **behavioural
  properties** (a small ΔE + "very close"; dry ≠ wet in the drying direction) and, if a fixture cannot
  discriminate a pinned literal, raises a follow-up to the spec author (as bs-03's ITEST-3 did for G-4/G-5).

## Phase 1 — Harness (ITEST-1)

- **Kind:** acceptance-tests
- **Target AC:** — (harness)
- **Depends on:** ENGINE-1, RECIPE-2, SCREEN-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/recipes_harness.dart`; reuse `integration_test/fakes/fake_speech.dart`; re-export `bs04/pending.dart`.
- **Tasks:**
  1. A `givenRecipes(tester, {sampleSource, paletteSource, mixingEngine})` driver assembling the real app with the recipes entry (injected `CATALOGUE`, `PALETTE_MY_PAINTS`, the real `SubtractiveMixingEngine`, `FakeSpeech`), opened on the Recipes screen.
  2. Given/When/Then helpers: `whenChooseSavedTarget(name)`, `whenEnterManualTarget(l, a, b)`, `whenToggleWetDry()`, `whenSpeakTarget()`, `whenSpeakRecipe(index)`; the fixtures (`CATALOGUE`, `SAMPLE_DEEP_OLIVE`, `PALETTE_MY_PAINTS`, `SAMPLE_VIVID_TURQUOISE`, `PALETTE_OIL`/`SAMPLE_OIL_TARGET`) with their known coordinates; the **independent** `referenceDeltaE00` (CIEDE2000, so AC-5 doesn't grade the impl against itself).
  3. The pending gate seeded with **all 12 ACs** pending, and a never-pending **smoke test** proving the shells wire end to end (the app boots to the Recipes screen and renders all regions).
  4. Grade the scaffold tests: the pending map has exactly 12 keys each naming a real phase; the smoke test asserts concrete rendered regions; deterministic (`pumpAndSettle`, no fixed sleeps); `referenceDeltaE00` validated against published CIEDE2000 pairs + self-distance 0.
- **Exit criteria:** `flutter test integration_test/recipes_test.dart -d <udid>` green (all AC tests pending, smoke passes); harness tests graded A.
- **Acceptance gate:** smoke green; pending gate in place (12 pending).

## Phase 2 — AC-1,2,3,11,12 (ITEST-2)

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-3, AC-11, AC-12 (target selection / manual / palette constraint / speak)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/recipes_test.dart` (these rows); may extend the harness vocabulary.
- **Tasks:** one *pending* `acTestWidgets` per AC per the catalogue (exact Thens + Rejects); record the red baseline (run-pending) for each; grade each A (Given built via public flows and asserted; the Then at the step's grain; a real Rejects).
- **Exit criteria:** default suite green (these pending); run-pending shows each failing at its intended Then / precondition; grades recorded.
- **Acceptance gate:** *(acceptance-tests — suite green with new tests pending; red baseline recorded; grade gate passed)*

## Phase 3 — AC-4,5,6,7,8,9,10 (ITEST-3)

- **Kind:** acceptance-tests
- **Target AC:** AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10 (solve / verdict / rank / trace / muddy / gamut / wet-dry)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/recipes_test.dart` (these rows); harness fixtures.
- **Tasks:**
  1. Write one *pending* test per AC per the catalogue; record the red baseline.
  2. Write AC-5/AC-10 against **behavioural properties** (small ΔE + "very close"; dry ≠ wet in the drying direction), not the spec's illustrative pinned L/C/h (G-4). If a fixture cannot discriminate, raise a follow-up to the spec author.
  3. Construct the AC-6 2-paint/4-paint similar-ΔE pair, the AC-7 sub-2% trace recipe, the AC-8 complementary-crossing recipe (+ a non-crossing control), and the AC-9 out-of-gamut `SAMPLE_VIVID_TURQUOISE` case.
  4. Grade each A (ΔE checked against the independent reference, not the impl).
- **Exit criteria:** default suite green (these pending); run-pending shows each failing at its intended Then; grades recorded.
- **Acceptance gate:** *(acceptance-tests — as ITEST-2)*

## Phase 4 — Test review (ITEST-4)

- **Kind:** test-review
- **Target AC:** — (G-2)
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behaviour phase
- **Tasks:** assemble the review packet (per-AC test + exact Thens + Rejects, the red baseline, the grade grid, the pre-seeded augmentation, the G-4 behavioural-property treatment); run the full regression; present for the human G-2 decision.
- **Exit criteria:** packet assembled; full suite green (AC tests pending); grade grid complete.
- **Acceptance gate:** human records G-2.

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_ChooseSavedTarget | _pending ITEST-2_ | | RECIPE-3 | |
| AC-2 | TestAC02_ManualTargetRefused | _pending ITEST-2_ | | RECIPE-3 | |
| AC-3 | TestAC03_PaletteConstrained | _pending ITEST-2_ | | ENGINE-2 | |
| AC-4 | TestAC04_TopRecipes | _pending ITEST-3_ | | ENGINE-2 | |
| AC-5 | TestAC05_CloseVerdict | _pending ITEST-3_ | | ENGINE-3 | |
| AC-6 | TestAC06_PreferFewer | _pending ITEST-3_ | | ENGINE-3 | |
| AC-7 | TestAC07_TraceTouchOf | _pending ITEST-3_ | | ENGINE-4 | |
| AC-8 | TestAC08_MuddyingFlag | _pending ITEST-3_ | | ENGINE-4 | |
| AC-9 | TestAC09_OutOfGamut | _pending ITEST-3_ | | ENGINE-5 | |
| AC-10 | TestAC10_WetDry | _pending ITEST-3_ | | ENGINE-6 | |
| AC-11 | TestAC11_SpeakTarget | _pending ITEST-2_ | | RECIPE-4 | |
| AC-12 | TestAC12_SpeakRecipe | _pending ITEST-2_ | | RECIPE-4 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC05 | one near-target recipe cannot show the verdict *tracks* distance (a constant "very close" would pass) | ENGINE-3 | a farther recipe asserting a **different** (worse) verdict band | ⬜ Open |
