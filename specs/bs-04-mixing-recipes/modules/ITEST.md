# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 + ITEST-2 + ITEST-3 (AC tests) done; next ITEST-4 test review (G-2)
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
| 3 | acceptance-tests | AC-4,5,6,7,8,9,10 | ✅ Done | 7,282,541 | 41m 45s (1h 15m) |
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
- **G-4 (spec-data / engine reconciliation — spec author)** — ✅ Resolved 2026-10-08 by Matt Quirk: the
  pinned predicted L/C/h (AC-5 "L 42.6, C 27.1, h 106"; AC-10 "→ L 41.2, C 26.4, h 107") are **illustrative**
  and the ACs assert **behavioural properties** (D-13); v1 engine is subtractive (D-2); gamut ΔE00 > 5 (D-10);
  trace ~2% (D-12). ITEST-3 wrote AC-5/AC-10 as behavioural properties (small ΔE graded vs the independent
  reference + the "very close" verdict; a real wet→dry shift) — no follow-up needed; every fixture
  discriminated. G-4 still blocks the ENGINE behaviour phases only as a now-closed decision.

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

### Result

One pending `acTestWidgets` per AC for AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10 now lives in `recipes_test.dart` under the `ITEST-3 — AC-4..AC-10` group (a disjoint append below the ITEST-2 group); the suite stays green with all 12 ACs still pending. G-4 was resolved this session (illustrative L/C/h; the ACs assert behavioural properties), so AC-5/AC-10 are written as properties, never the spec's pinned literals.

- **Added (tests only — no `lib/**`):** seven pending AC tests driven through the public surface (the `RecipeReadEndpoint` state seam + rendered region text): **AC-4** 3–5 recipes, each with positive parts summing to 1 and a plausible predicted colour, paints rendered; **AC-5** the top recipe's `deltaE00` matches the **independent** `referenceDeltaE00(predictedColor, target)` (never the impl vs itself), is in gamut (≤ 5) and carries the "very close" verdict; **AC-6** the prefer-fewer ordering invariant (no recipe ranked above a fewer-paint one at a similar ΔE); **AC-7** a sub-2% component is `isTrace` + a technique note (with a non-trace control) and renders "a touch of"; **AC-8** a muddying recipe and a clean control both present (flag not constant) + the "muddy" render; **AC-9** `SAMPLE_VIVID_TURQUOISE` marked "OUT OF GAMUT" with every offered recipe `outOfGamut` and ΔE00 > 5, plus an in-gamut Deep-Olive control (banner absent); **AC-10** the oil target's top recipe predicted colour shifts on the wet→dry toggle (`mode == dry`, a real `referenceDeltaE00(wet,dry) > 0`). No harness vocabulary change was needed.
- **Gates:** `flutter analyze` clean; unit **517 green**; coverage gate **PASS** (ITEST-3 touches no `lib/**`; the 15 bs-04 lib files stay 100% vs `main`). Integration **default run green** — 11 scaffold tests pass, all 12 AC tests pending/skipped (`+11 ~12`) — on the iPhone 17 sim under the verify lock. **Red baseline (run-pending):** all 12 run (`+11 -12`); the seven new tests each fail cleanly as a `TestFailure` at a Then or a Given precondition, none panic (see the *Red baseline* table).
- **Grade gate:** an independent grader (fresh context) graded the seven **3×A (AC-4, AC-9, AC-10), 4×A (limited) (AC-5, AC-6, AC-7, AC-8), 0×B — PASS**; grid at `behavior-test-completeness-bs-04-mixing-recipes.md`. It re-verified `referenceDeltaE00`'s independence from the product metric and that `SAMPLE_VIVID_TURQUOISE` is geometrically unreachable from `PALETTE_MY_PAINTS`. The four *limited* tests each pre-seed/confirm an augmentation owned by the behaviour phase that lands the engine output (AC-5/AC-6 → ENGINE-3; AC-7/AC-8 → ENGINE-4).
- **Fix passes: 0/3** (green first run; grader found no B).
- **Tokens / Time:** 7,282,541 · 41m 45s active (1h 15m wall — the gap was the AskUserQuestion G-4 wait; 1 grader subagent included).

### Checkpoint / Handoff

- **All 12 AC tests are now registered** in `recipes_test.dart` (ITEST-2: AC-1,2,3,11,12; ITEST-3: AC-4..AC-10). The pending gate (`bs04/pending.dart`) and the guard's `unpended` set are **unchanged** — ITEST-3 un-pends nothing; the behaviour phases do, each deleting its `bs04/pending.dart` row and adding its AC to the guard's `unpended` set.
- **When each behaviour phase un-pends its AC** (owner in the *Red baseline* table): the pending test flips from skipped to run, so it must then pass. The ENGINE phases close the four augmentations as they land real engine output: **ENGINE-3** (AC-5 farther-recipe worse-verdict; AC-6 the decisive 2-paint/4-paint similar-ΔE pair); **ENGINE-4** (AC-7 a genuine sub-2% *Titanium White* trace + the measured-part absence; AC-8 a known complementary-crossing recipe vs a known clean control).
- **G-4 is resolved** (illustrative literals; behavioural properties; subtractive v1; gamut ΔE00 > 5; trace ~2%). The ENGINE phases build to those thresholds; `MixOptions` defaults already encode them (gamut 5.0, trace 0.02).
- **Verification commands** unchanged (SCREEN-1/ITEST-1/ITEST-2 handoff; `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under the verify lock on sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (always `-d <udid>`). Run-pending: `flutter test integration_test/recipes_test.dart -d <udid> --dart-define=BS04_RUN_PENDING=true`. **Note:** run the integration suite from the worktree (`cd <worktree> && flutter test …`) — `coord.sh with-lock` cd's to `FNP_COORD_REPO` (the primary checkout), and a `--dart-define` change needs a rebuilt kernel (the define is compiled in on-device; the host env var does not reach the device).
- **Known gaps / notes:** no behaviour yet. **G-2** (ITEST-4 review) still blocks every behaviour phase. The next phase is **ITEST-4** (assemble the review packet from both AC-test phases; present for the human G-2 decision). Carry-over const-constructor coverage flake stands. Untracked bs-05..bs-14 specs + `docs/` are not part of bs-04.

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
| AC-4 | TestAC04_TopRecipes | fails (run-pending) | precond — `state.recipes` empty, none to list (`recipes_test.dart:456`) | ENGINE-2 | A |
| AC-5 | TestAC05_CloseVerdict | fails (run-pending) | precond — `state.recipes` empty, none to verdict (`recipes_test.dart:508`) | ENGINE-3 | A (limited) |
| AC-6 | TestAC06_PreferFewer | fails (run-pending) | precond — `state.recipes.length` 0, < 2 to compare (`recipes_test.dart:558`) | ENGINE-3 | A (limited) |
| AC-7 | TestAC07_TraceTouchOf | fails (run-pending) | precond — `state.recipes` empty, none to trace (`recipes_test.dart:599`) | ENGINE-4 | A (limited) |
| AC-8 | TestAC08_MuddyingFlag | fails (run-pending) | precond — `state.recipes` empty, none to flag (`recipes_test.dart:658`) | ENGINE-4 | A (limited) |
| AC-9 | TestAC09_OutOfGamut | fails (run-pending) | Then — no "OUT OF GAMUT" banner, `findsOneWidget` 0 found (`recipes_test.dart:704`) | ENGINE-5 | A |
| AC-10 | TestAC10_WetDry | fails (run-pending) | precond — `state.recipes` empty, none to predict dry (`recipes_test.dart:759`) | ENGINE-6 | A |
| AC-11 | TestAC11_SpeakTarget | fails (run-pending) | Then — no utterance emitted, `hasLength(1)` (`recipes_test.dart:376`) | RECIPE-4 | A |
| AC-12 | TestAC12_SpeakRecipe | fails (run-pending) | precond — `state.recipes` empty, none to speak (`recipes_test.dart:396`) | RECIPE-4 | A (limited) |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC05 | one near-target recipe cannot show the verdict *tracks* distance (a constant "very close" would pass) | ENGINE-3 | a farther recipe asserting a **different** (worse) verdict band | ⬜ Open |
| TestAC06 | the prefer-fewer invariant only bites where the engine's output holds a similar-ΔE pair of differing paint counts; the stub returns none, so the decisive pair can't be constructed in ITEST-3 (confirmed by ITEST-3) | ENGINE-3 | a concrete 2-paint vs 4-paint recipe pair at a similar ΔE00, asserting the 2-paint mix ranks above the 4-paint mix | ⬜ Open |
| TestAC07 | the trace test asserts *any* sub-2% component, not the spec's named **Titanium White** trace, and does not assert the measured-part form is **absent** for the traced paint (confirmed by ITEST-3) | ENGINE-4 | a recipe with a genuine sub-2% Titanium White trace, asserting it renders "a touch of" + note and **not** a measured part | ⬜ Open |
| TestAC08 | the not-constant check (one muddying, one clean) does not verify the flagged recipe **actually** crosses a complementary hue pair — an arbitrary flag assignment would pass (confirmed by ITEST-3) | ENGINE-4 | a known complementary-crossing recipe asserted flagged and a known non-crossing recipe asserted unflagged | ⬜ Open |
| TestAC12 | the spoken recipe is checked for each paint's **name** and a single global `contains('part')`, not each paint's **parts quantity** — the "its parts" clause is half-covered until the E25 speak format is frozen (confirmed by ITEST-2) | RECIPE-4 | assert per-component that the utterance states that paint's parts value (its normalized parts rendering) | ⬜ Open |
