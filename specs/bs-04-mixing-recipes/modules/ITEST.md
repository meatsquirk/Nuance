# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 (harness) + ITEST-2 (AC-1,2,3,11,12) done; next ITEST-3 (AC-4..10), then ITEST-4 review
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
| 1 | acceptance-tests | — (harness) | ✅ Done | 10,067,182 | 18m 44s (4h 40m) |
| 2 | acceptance-tests | AC-1,2,3,11,12 | ✅ Done | 6,819,011 | 25m 09s (25m 09s) |
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

### Result

The acceptance harness is in place; the real app is drivable end to end and the pending gate holds all 12 ACs.

- **Added:** `integration_test/recipes_harness.dart` — the `givenRecipes(tester, {target, catalogue, palette,
  mixingEngine})` driver assembling the real app via `buildApp` with the recipes entry (injected `CATALOGUE` /
  `PALETTE_MY_PAINTS` / real `SubtractiveMixingEngine` / `FakeSpeech`); the `RecipesHarness` vocabulary
  (`whenOpenTargetSelector`, `whenChooseSavedTarget`, `whenEnterManualTarget`, `whenToggleWetDry`,
  `whenSpeakTarget`, `whenSpeakRecipe` — each drives the real control and names its owning phase in a
  precondition, since the controls are inert in the SCREEN-1 shell); the fixtures (`SAMPLE_DEEP_OLIVE`,
  `SAMPLE_WARM_SAND`, `SAMPLE_VIVID_TURQUOISE` out-of-gamut control, `SAMPLE_OIL_TARGET` + the paints +
  `PALETTE_MY_PAINTS` / `PALETTE_OIL`); and the **independent** `referenceDeltaE00` (inline CIEDE2000, no import
  of `lib/compare/difference.dart`). Re-exports `bs04/pending.dart` + the fakes.
- **Added:** `integration_test/recipes_test.dart` — a never-pending **smoke** test (boots to Recipes, asserts
  all four region keys + the read endpoint + the "Recipe target: Deep Olive Green" render + the opened state)
  and the guards: the pending-gate complement (exactly 12, each owner ∈ `behaviorPhases`; skip/run-pending
  modes), `FakeSpeech` ordering, the fixtures carry their coordinates (Deep Olive recovers C 28 / h 108; "My
  paints" names its five paints; Vivid Turquoise is a genuine out-of-gamut control; the oil palette is all
  oil), and `referenceDeltaE00` vs the five Sharma et al. published pairs + self-distance 0. **No per-AC tests
  yet** (ITEST-2/3 register them).
- **Seeded:** `integration_test/bs04/pending.dart` — `pendingACs` now maps all 12 ACs to their owning phase
  (AC-1/2 → RECIPE-3, AC-3/4 → ENGINE-2, AC-5/6 → ENGINE-3, AC-7/8 → ENGINE-4, AC-9 → ENGINE-5, AC-10 →
  ENGINE-6, AC-11/12 → RECIPE-4). No `lib/**` touched.
- **Gates:** `flutter analyze` clean; unit **517 green**; coverage gate **PASS** (100% on touched lib — ITEST-1
  touches none; the 7 shell files stay fully covered); integration **73 green** on the iPhone 17 sim under the
  verify lock (62 prior bs-01/02/03 + **11 new** recipes scaffold tests; all AC tests pending). **Red baseline:
  none recorded — ITEST-1 registers no AC tests** (ITEST-2/3 fill the *Red baseline* table).
- **Grade gate:** an independent grader (fresh context) graded the scaffold **11×A, 0×B — PASS**; grid at
  `behavior-test-completeness-bs-04-mixing-recipes.md`. It independently recomputed the fixture math
  (Deep Olive → C 27.9996 / h 107.995°), confirmed every guard threshold, and verified `referenceDeltaE00`
  imports nothing from the product metric.
- **Fix passes: 0/3** (green first run).
- **Tokens / Time:** 10,067,182 · 18m 44s active (4h 40m wall — the gap was the AskUserQuestion wait).

### Checkpoint / Handoff

- **Frozen for ITEST-2 / ITEST-3:** import only `recipes_harness.dart`. `givenRecipes(tester, {target =
  SAMPLE_DEEP_OLIVE, catalogue = CATALOGUE, palette = PALETTE_MY_PAINTS, mixingEngine = SubtractiveMixingEngine})`
  → `RecipesHarness`. Read seams: `harness.controller` / `harness.state` (over `RecipeReadEndpoint`),
  `harness.speech.utterances`. When-helpers as above. Fixtures: `SAMPLE_DEEP_OLIVE` (C 28 / h 108), `SAMPLE_WARM_SAND`,
  `SAMPLE_VIVID_TURQUOISE` (AC-9 out-of-gamut), `SAMPLE_OIL_TARGET` + `PALETTE_OIL` (AC-10), `PALETTE_MY_PAINTS`
  (AC-3; paints named + id'd), the independent `referenceDeltaE00` (grade AC-5 against this, never the impl).
- **Register AC tests** with `acTestWidgets('AC-n', '<desc>', (tester) async { … })` in `recipes_test.dart`
  (ITEST-2: AC-1,2,3,11,12 below a header; ITEST-3: AC-4,5,6,7,8,9,10). Each is *pending* until its row is
  deleted from `bs04/pending.dart`. **Update the pending-gate guard's `unpended` set as rows are un-pended**
  (it is empty now; the guard asserts `pendingACs` is the exact complement).
- **Harness vocabulary may be extended** by ITEST-2/3 (the plan allows it) — e.g. refine `whenEnterManualTarget`
  to RECIPE-3's shipped manual form if it differs from the 3-TextField + done-action shape assumed here.
- **Red-baseline note:** when ITEST-2/3 run `--dart-define=BS04_RUN_PENDING=true`, each new AC test must fail on
  a Then or a Given precondition naming its owning phase (never panic). The current when-helpers fail at a
  precondition until the behaviour lands (picker lists nothing → RECIPE-3; no recipes → ENGINE-2; etc.).
- **Verification commands** unchanged (SCREEN-1 handoff; `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under the
  lock on sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (always `-d <udid>`; no device ⇒ false green). Run-pending:
  `flutter test integration_test/recipes_test.dart -d <udid> --dart-define=BS04_RUN_PENDING=true`.
- **Known gaps / notes:** no AC tests and no behaviour yet. `{ITEST-2 ∥ ITEST-3}` both edit
  `recipes_test.dart` — **merge-risky**; coordinate the shared file (append disjoint AC groups under their
  headers). **G-4** must be decided before ITEST-3 pins any predicted-colour literal (ITEST-3 writes AC-5/AC-10
  as behavioural properties regardless). Carry-over const-constructor coverage flake stands. Untracked
  bs-05..bs-14 specs + `docs/` are not part of bs-04.

## Phase 2 — AC-1,2,3,11,12 (ITEST-2)

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-3, AC-11, AC-12 (target selection / manual / palette constraint / speak)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/recipes_test.dart` (these rows); may extend the harness vocabulary.
- **Tasks:** one *pending* `acTestWidgets` per AC per the catalogue (exact Thens + Rejects); record the red baseline (run-pending) for each; grade each A (Given built via public flows and asserted; the Then at the step's grain; a real Rejects).
- **Exit criteria:** default suite green (these pending); run-pending shows each failing at its intended Then / precondition; grades recorded.
- **Acceptance gate:** *(acceptance-tests — suite green with new tests pending; red baseline recorded; grade gate passed)*

### Result

One pending `acTestWidgets` per AC for AC-1, AC-2, AC-3, AC-11, AC-12 now lives in `recipes_test.dart` under the `ITEST-2 — AC-1, AC-2, AC-3, AC-11, AC-12` group (a disjoint append, leaving AC-4..10 for ITEST-3); the suite stays green with all 12 ACs still pending.

- **Added (tests only — no `lib/**`):** `integration_test/recipes_test.dart` gains five pending AC tests driven entirely through the public surface (rendered text + the `RecipeReadEndpoint` state seam + the `FakeSpeech` log): **AC-1** chooses a saved target from a *different* starting target (Warm Sand → Deep Olive) and asserts identity + L 42 / C 28 / h 108 + the rendered line; **AC-2** refuses an out-of-range manual L 140 and keeps the target, with a valid-L50 **control** separating range-validation from a reject-all/inert handler; **AC-3** asserts every component of every recipe is a palette paint by **id**; **AC-11** asserts one spoken utterance states the name + L/C/h; **AC-12** speaks the real top recipe and asserts each paint name + that parts are spoken. No harness vocabulary change was needed (the 3-field manual form assumed by `whenEnterManualTarget` was sufficient).
- **Gates:** `flutter analyze` clean; unit **517 green**; coverage gate **PASS** (ITEST-2 touches no `lib/**`; the 15 bs-04 lib files stay 100%). Integration **default run green** — 11 scaffold tests pass, the 5 new AC tests pending/skipped — on the iPhone 17 sim under the verify lock. **Red baseline (run-pending):** all 5 fail cleanly at a Then or a Given precondition naming the owner, none panic (see the *Red baseline* table).
- **Grade gate:** an independent grader (fresh context) graded the 5 tests; AC-2 came back **B (G3)** — the kept-target Then lacked a control separating range-validation from a reject-all/inert handler — and was fixed in-phase with the valid-L50 control, then re-graded **A** by a second fresh grader. Final **5×A, 0×B** (AC-12 A, *limited* — a RECIPE-4 augmentation row added for per-paint parts quantity). Grid: `behavior-test-completeness-bs-04-mixing-recipes.md`.
- **Fix passes: 1/3** (one grade-fix pass for AC-2; integration green first run both times).
- **Tokens / Time:** 6,819,011 · 25m 09s active (25m 09s wall) — one session, 2 grader subagents included.

### Checkpoint / Handoff

- **AC tests registered for AC-1, AC-2, AC-3, AC-11, AC-12** in `recipes_test.dart`; **AC-4..AC-10 remain for ITEST-3** (append under a second disjoint header, same file — still **merge-risky** if run concurrently). The pending gate (`bs04/pending.dart`) and the guard's `unpended` set are **unchanged** — ITEST-2 un-pends nothing; the behaviour phases do.
- **Red baseline is clean for these five.** When a behaviour phase un-pends its AC, deleting the `bs04/pending.dart` row and adding the AC to the guard's `unpended` set: **RECIPE-3** (AC-1/AC-2) wires `selectTarget` / `enterManualTarget` (range-validating; a valid entry moves the target, L 140 sets `manualError` and keeps it); **ENGINE-2** (AC-3) makes `state.recipes` non-empty on open over the selected palette; **RECIPE-4** (AC-11/AC-12) wires `speakTarget` (one utterance: name + L/C/h) and `speakRecipe` (one utterance naming each paint + its parts — and must close the **TestAC12 augmentation** by asserting each paint's parts quantity once the E25 format is frozen).
- **AC-11/AC-12 format notes for RECIPE-4:** AC-11 asserts the utterance `contains` '42'/'28'/'108' (a C/h label swap would still pass — tighten to labelled substrings if the spoken format makes that cheap). AC-12 asserts each `component.paint.name` + a global `contains('part')`; the augmentation wants per-paint parts quantities.
- **Verification commands** unchanged (SCREEN-1/ITEST-1 handoff; `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under the verify lock on sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (always `-d <udid>`). Run-pending: `flutter test integration_test/recipes_test.dart -d <udid> --dart-define=BS04_RUN_PENDING=true`.
- **Known gaps / notes:** no behaviour yet. **G-4** still blocks ITEST-3's pinning of predicted-colour literals (it writes AC-5/AC-10 as behavioural properties regardless). **G-2** (ITEST-4 review) still blocks every behaviour phase. Carry-over const-constructor coverage flake stands. Untracked bs-05..bs-14 specs + `docs/` are not part of bs-04.

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
| AC-1 | TestAC01_ChooseSavedTarget | fails (run-pending) | precond — target picker lists no "Deep Olive Green" (`recipes_harness.dart:359`) | RECIPE-3 | A |
| AC-2 | TestAC02_ManualTargetRefused | fails (run-pending) | precond — no L/a/b manual fields on the valid-L50 control (`recipes_harness.dart:376`) | RECIPE-3 | A |
| AC-3 | TestAC03_PaletteConstrained | fails (run-pending) | precond — `state.recipes` empty, none to constrain (`recipes_test.dart:341`) | ENGINE-2 | A |
| AC-4 | TestAC04_TopRecipes | _pending ITEST-3_ | | ENGINE-2 | |
| AC-5 | TestAC05_CloseVerdict | _pending ITEST-3_ | | ENGINE-3 | |
| AC-6 | TestAC06_PreferFewer | _pending ITEST-3_ | | ENGINE-3 | |
| AC-7 | TestAC07_TraceTouchOf | _pending ITEST-3_ | | ENGINE-4 | |
| AC-8 | TestAC08_MuddyingFlag | _pending ITEST-3_ | | ENGINE-4 | |
| AC-9 | TestAC09_OutOfGamut | _pending ITEST-3_ | | ENGINE-5 | |
| AC-10 | TestAC10_WetDry | _pending ITEST-3_ | | ENGINE-6 | |
| AC-11 | TestAC11_SpeakTarget | fails (run-pending) | Then — no utterance emitted, `hasLength(1)` (`recipes_test.dart:376`) | RECIPE-4 | A |
| AC-12 | TestAC12_SpeakRecipe | fails (run-pending) | precond — `state.recipes` empty, none to speak (`recipes_test.dart:396`) | RECIPE-4 | A (limited) |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC05 | one near-target recipe cannot show the verdict *tracks* distance (a constant "very close" would pass) | ENGINE-3 | a farther recipe asserting a **different** (worse) verdict band | ⬜ Open |
| TestAC12 | the spoken recipe is checked for each paint's **name** and a single global `contains('part')`, not each paint's **parts quantity** — the "its parts" clause is half-covered until the E25 speak format is frozen (confirmed by ITEST-2) | RECIPE-4 | assert per-component that the utterance states that paint's parts value (its normalized parts rendering) | ⬜ Open |
