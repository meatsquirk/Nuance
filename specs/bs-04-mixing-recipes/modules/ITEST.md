# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1..5 done (ITEST-5 retargeted `SAMPLE_DEEP_OLIVE` to a reachable olive, ΔE00 ≈ 3.34 ≤ 5, pinned tests updated + re-graded A); next ITEST-6 fresh review (G-6), which re-gates ENGINE-3/ENGINE-5
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
| 4 | test-review | — (G-2) | ✅ Done | 6,078,568 | 55m 56s (1h 01m) |
| 5 | acceptance-tests | AC-5, AC-9 (retarget) | ✅ Done | 10,631,343 | 18m 10s (18m 10s) |
| 6 | test-review | — (G-6) | ⬜ Next | | |

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

- **G-2 (approve the acceptance tests)** — ITEST-4's packet; blocked every behaviour phase. **✅ Resolved
  2026-10-09 04:25 EDT by Matt Quirk: approved** — the 12 pending AC tests accepted as the acceptance
  contract (grid all at the A bar, 0×B; five A-limited with scheduled augmentations). ITEST-4 ✅ Done; the
  behaviour stage is open (RECIPE-3 + ENGINE-2 startable).
- **G-4 (spec-data / engine reconciliation — spec author)** — ✅ Resolved 2026-10-08 by Matt Quirk: the
  pinned predicted L/C/h (AC-5 "L 42.6, C 27.1, h 106"; AC-10 "→ L 41.2, C 26.4, h 107") are **illustrative**
  and the ACs assert **behavioural properties** (D-13); v1 engine is subtractive (D-2); gamut ΔE00 > 5 (D-10);
  trace ~2% (D-12). ITEST-3 wrote AC-5/AC-10 as behavioural properties (small ΔE graded vs the independent
  reference + the "very close" verdict; a real wet→dry shift) — no follow-up needed; every fixture
  discriminated. G-4 still blocks the ENGINE behaviour phases only as a now-closed decision.
- **G-5 (spec-data / engine reachability — spec author)** — ✅ Resolved 2026-10-09 14:41 EDT by Matt Quirk:
  **(a) retarget `SAMPLE_DEEP_OLIVE` to a reachable olive** (a\* from −8.65 toward ~0, keeping an olive hue) so
  the earthy `PALETTE_MY_PAINTS` reaches it to ΔE00 ≤ 5 — the verified v1 engine (D-2) reaches the old target
  only to ΔE00 ≈ 9.31. This reshapes the approved ITEST-3, so a fresh test-review round is required: **ITEST-5**
  performs the retarget + updates every test pinning the old L42/C28/h108, and **ITEST-6** is the fresh review
  (G-6). The engine, the ΔE00 ≤ 5 "very close" contract (D-7/D-10) and the `gamutThreshold = 5.0` are
  unchanged.
- **G-6 (approve the retargeted acceptance tests — spec author)** — ⬜ Open: ITEST-6's packet, a fresh review
  of the retargeted AC-5/AC-9 (and the re-verified AC-1/AC-4/AC-11 whose pinned coordinates move with the
  fixture). **Blocks ENGINE-3, ENGINE-5.**

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

### Review packet (for the human G-2 decision)

The whole acceptance suite for bs-04 is below, assembled for review before any behaviour is coded. Twelve
*pending* AC tests (one per AC) drive the **real** assembled app through `recipes_harness.dart` and assert
only through the public surface — rendered region text, the `RecipeReadEndpoint` state seam, and the
`FakeSpeech` log. No colour/mixing/ΔE00 math is faked. Each AC un-pends in its owning behaviour phase.

**Look at first:** (1) the **G-4 behavioural-property** treatment — AC-5/AC-10 assert properties (a small
ΔE00 + the "very close" verdict; a real wet→dry shift), never the spec's *illustrative* pinned L/C/h; (2) the
**independent** `referenceDeltaE00` (inline CIEDE2000, validated against Sharma et al. 2005 + self-distance 0)
that AC-5 grades the engine's ΔE00 against, so AC-5 never grades the engine against itself; (3) the five
**A (limited)** tests and the augmentations each schedules onto the behaviour phase that lands the engine
output; (4) AC-9's genuinely out-of-gamut fixture geometry (the ITEST-1 guard proves "My paints" cannot reach
`SAMPLE_VIVID_TURQUOISE`).

Per-AC — test · Given · When · Then · Rejects (owning phase in the *Red baseline* table):

- **AC-1 · TestAC01_ChooseSavedTarget** — *Given* a saved "Deep Olive Green" (L 42 / C 28 / h 108) offered in
  the catalogue, opened on a **different** target (Warm Sand) as a control. *When* the painter chooses "Deep
  Olive Green". *Then* the target is Deep Olive at L 42 / C 28 / h 108 and the line "Recipe target: Deep Olive
  Green" renders. *Rejects* an inert/no-op picker (the control target would persist) and wrong coordinates.
- **AC-2 · TestAC02_ManualTargetRefused** — *Given* a known target, no `manualError`; a **control** first
  enters a valid L 50 (accepted, moves the target). *When* the painter enters L 140 (outside 0..100). *Then*
  `manualError` is raised and the valid L 50 target is kept. *Rejects* a reject-all/inert handler (separated by
  the valid-L50 control) and any clearing/replacing of the target.
- **AC-3 · TestAC03_PaletteConstrained** — *Given* palette "My paints" (naming Titanium White / Yellow Ochre /
  Ivory Black) and a mixable target. *When* recipes are solved (precond `recipes` non-empty → ENGINE-2).
  *Then* every component of every recipe is a palette paint, asserted by **id**. *Rejects* any recipe using a
  paint outside the selected palette.
- **AC-4 · TestAC04_TopRecipes** — *Given* Deep Olive over "My paints". *When* solved (precond non-empty →
  ENGINE-2). *Then* 3–5 recipes, each with positive `partsFraction` summing to 1 and a plausible CIELAB
  `predictedColor`, and the top recipe's paints render in the list region. *Rejects* <3 / >5 recipes, parts
  not summing to 1, an implausible predicted colour, or unrendered paints.
- **AC-5 · TestAC05_CloseVerdict** — *Given* a close recipe for Deep Olive (G-4: literals illustrative).
  *Then* the top recipe's `deltaE00` equals the **independent** `referenceDeltaE00(predicted, target)` within
  0.5, is ≤ the in-gamut ceiling (5), carries a verdict containing "very close", and that verdict renders.
  *Rejects* a stated ΔE that isn't a real CIEDE2000 of the predicted colour, a non-close recipe, a missing or
  other verdict. **A (limited)** → ENGINE-3 adds a farther recipe asserting a different, worse verdict band.
- **AC-6 · TestAC06_PreferFewer** — *Given* ≥2 ordered recipes (precond → ENGINE-2 solve + ENGINE-3 order).
  *Then* for every ranked pair i<j with `|ΔE_i − ΔE_j| ≤ 1.5`, `components[i].length ≤ components[j].length`.
  *Rejects* a muddier 4-paint mix ranked above a cleaner 2-paint mix at a similar ΔE. **A (limited)** →
  ENGINE-3 constructs the decisive 2-paint / 4-paint similar-ΔE pair and asserts the 2-paint mix ranks above.
- **AC-7 · TestAC07_TraceTouchOf** — *Given* recipes carrying a sub-2% component (precond recipes → ENGINE-2;
  a trace present → ENGINE-4). *Then* each trace is `isTrace` with a non-empty `techniqueNote`, each ≥2%
  component is **not** a trace (control: the flag isn't constant), and "a touch of" renders. *Rejects* a
  constant trace flag, a trace without a note, no "a touch of" render. **A (limited)** → ENGINE-4 pins a
  genuine sub-2% *Titanium White* trace and asserts the measured-part form is absent for it.
- **AC-8 · TestAC08_MuddyingFlag** — *Given* solved recipes (precond → ENGINE-2). *Then* both a `muddying` and
  a clean subset are non-empty (the flag is not constant) and "muddy" renders. *Rejects* a constant-true/false
  flag and a card that never surfaces it. **A (limited)** → ENGINE-4 pins a known complementary-crossing
  recipe flagged and a known non-crossing recipe unflagged.
- **AC-9 · TestAC09_OutOfGamut** — *Given* the unreachable "Vivid Turquoise" over "My paints" (the ITEST-1
  fixture guard proves the geometry). *Then* the banner shows "OUT OF GAMUT", every offered recipe is
  `outOfGamut` with ΔE00 > 5, and an in-gamut Deep Olive **control** shows no banner and no out-of-gamut
  recipe. *Rejects* a missing banner, a nearest mix offered as a match, a constant-on banner.
- **AC-10 · TestAC10_WetDry** — *Given* an oil target over the all-oil palette, opening wet (control). *When*
  the painter toggles wet→dry. *Then* `mode == dry` and the predicted colour shifts
  (`referenceDeltaE00(wet, dry) > 0`). *Rejects* an inert/no-op toggle. (G-4: asserts the property, not the
  illustrative dry L/C/h.)
- **AC-11 · TestAC11_SpeakTarget** — *Given* Deep Olive (L 42 / C 28 / h 108), nothing spoken (control).
  *When* the painter asks to speak the target. *Then* exactly one utterance states the name and 42 / 28 / 108.
  *Rejects* a wrong or omitted field, or no utterance.
- **AC-12 · TestAC12_SpeakRecipe** — *Given* a recipe over "My paints" (precond non-empty → ENGINE-2), nothing
  spoken. *When* the painter asks to speak the top recipe. *Then* one utterance names each
  `component.paint.name` and contains "part". *Rejects* a dropped paint or percentages spoken instead of parts.
  **A (limited)** → RECIPE-4 asserts each paint's parts **quantity** once the E25 speak format is frozen.

**Red baseline** (run-pending, `--dart-define=BS04_RUN_PENDING=true`): all 12 AC tests execute and each fails
**cleanly** — as a `TestFailure` at a Then, or at a Given precondition that names its owning behaviour phase —
with **no panics**. The default run stays green (the 11 never-pending scaffold/guard tests pass; the 12 AC
tests skip). Exact fail point, source line and owner per AC are in the *Red baseline* table below.

**Augmentations scheduled** (5, all ⬜ Open; closed by the named phase as it lands real engine output):
TestAC05 → ENGINE-3, TestAC06 → ENGINE-3, TestAC07 → ENGINE-4, TestAC08 → ENGINE-4, TestAC12 → RECIPE-4. Full
rows in *Test augmentations* below.

**Grade grid:** `specs/bs-04-mixing-recipes/behavior-test-completeness-bs-04-mixing-recipes.md`. Counts —
ITEST-1 **11×A** (scaffold/harness: smoke + guards); ITEST-2 **5×A** (AC-12 A, *limited*); ITEST-3 **7 at the
A bar** — 3×A (AC-4, AC-9, AC-10) + 4×A (limited) (AC-5, AC-6, AC-7, AC-8). All 12 AC tests and 11 guards at
the A bar; **0×B**. Each A (limited) carries a scheduled augmentation (above); none is docked.

### Result

ITEST-4 assembled the review packet above from both AC-test phases and ran the full regression; the suite is
green with all 12 ACs pending. The phase is now **⏸ Awaiting review** for the human **G-2** decision, which
unblocks every behaviour phase. No `lib/**` or test code changed — this phase is packet + regression + the
plan edits only.

- **Packet:** the per-AC Given/When/Then/Rejects (public-surface assertions), the clean red-baseline summary,
  the five scheduled augmentations and their owning phases, the grade-grid path and counts (12 AC tests + 11
  guards at the A bar, 0×B; five A-limited), and the four "look first" items (G-4 behavioural-property
  treatment, the independent `referenceDeltaE00`, the A-limited augmentations, the AC-9 out-of-gamut geometry).
- **Full regression (this session):** `flutter analyze` clean; unit **517 green**; coverage gate **PASS** —
  100% line coverage on all 15 touched `lib/**` files vs `main`; integration **green** on the iPhone 17 sim
  (`5AB9D06D-…`) under the verify lock — the 11 scaffold/guard tests pass, all 12 AC tests pending/skipped.
  (The carry-over const-constructor coverage flake did not bite this run.)
- **Grade grid complete** for the whole suite (ITEST-1/2/3), all at the A bar, 0×B; no new grading this phase.
- **Gate:** **G-2 awaiting the human decision.** Recorded via
  `/feature-next-phase --gate bs-04-mixing-recipes G-2 approved | "<changes>"`.
- **Fix passes: 0/3** (no code; regression green first run).
- **Tokens / Time:** 6,078,568 · 55m 56s active (1h 01m wall) — phase total over 2 sessions (packet
  assembled in one session while the independent full-regression run completed in the other), no subagents.

### Checkpoint / Handoff

- **G-2 blocks every behaviour phase.** On **approved**: this phase flips to ✅ Done and the behaviour stage
  opens — the startable phases are **RECIPE-3** (AC-1, AC-2) and **ENGINE-2** (AC-3, AC-4), which have no
  unmet dependency; RECIPE-4, ENGINE-3..6 follow their engine/controller dependencies. On **changes
  requested**: each item becomes an `ITEST` change phase before the behaviour stage, then a fresh review.
- **Un-pending protocol (each behaviour phase):** delete the AC's row in `integration_test/bs04/pending.dart`
  **and** add the AC to the pending-gate guard's `unpended` set in `recipes_test.dart` (the guard asserts the
  map is the exact complement). The un-pended test then runs and must pass. Close any augmentation the phase
  owns in the same session (ENGINE-3: AC-5/AC-6; ENGINE-4: AC-7/AC-8; RECIPE-4: AC-12).
- **Verification commands** unchanged (`export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze`
  · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under the verify lock on
  sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (always `-d <udid>`; no device ⇒ false green). Run-pending:
  `flutter test integration_test/recipes_test.dart -d <udid> --dart-define=BS04_RUN_PENDING=true` from the
  checkout the lock cd's to. **Note:** this sandbox blocks a foreground `sleep`, so `coord.sh … --wait` can't
  spin-wait here — wait on the holder pid in a backgrounded loop instead, or run when the lock is free.
- **Known gaps / notes:** behaviour not yet coded. Carry-over const-constructor coverage flake stands.
  Untracked bs-05..bs-14 specs + `docs/` are not part of bs-04.

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_ChooseSavedTarget | fails (run-pending) | precond — target picker lists no "Deep Olive Green" (`recipes_harness.dart:359`) | RECIPE-3 | A |
| AC-2 | TestAC02_ManualTargetRefused | fails (run-pending) | precond — no L/a/b manual fields on the valid-L50 control (`recipes_harness.dart:376`) | RECIPE-3 | A |
| AC-3 | TestAC03_PaletteConstrained | fails (run-pending) | precond — `state.recipes` empty, none to constrain (`recipes_test.dart:341`) | ENGINE-2 | A |
| AC-4 | TestAC04_TopRecipes | fails (run-pending) | precond — `state.recipes` empty, none to list (`recipes_test.dart:456`) | ENGINE-2 | A |
| AC-5 | TestAC05_CloseVerdict | fails (run-pending) | Then — `best.verdict` is null, `isNotNull` fails (`recipes_test.dart:582`). Refreshed ITEST-5: against the retargeted olive the solve returns recipes and the `deltaE00 ≤ gamutThreshold` assertion now **passes** (best ΔE00 ≈ 3.34 ≤ 5), so the test fails deeper, on the missing verdict — the exact Then ENGINE-3 fills | ENGINE-3 | A (limited) |
| AC-6 | TestAC06_PreferFewer | fails (run-pending) | Then — at a similar ΔE00 a 3-paint recipe is ranked above a 2-paint one, `3 ≤ 2` fails (`recipes_test.dart:625`). (Deeper than the ITEST-3 precond now that ENGINE-2 solves; the ΔE-only order lacks the prefer-fewer tie-break ENGINE-3 adds.) | ENGINE-3 | A (limited) |
| AC-7 | TestAC07_TraceTouchOf | fails (run-pending) | precond — `state.recipes` empty, none to trace (`recipes_test.dart:599`) | ENGINE-4 | A (limited) |
| AC-8 | TestAC08_MuddyingFlag | fails (run-pending) | precond — `state.recipes` empty, none to flag (`recipes_test.dart:658`) | ENGINE-4 | A (limited) |
| AC-9 | TestAC09_OutOfGamut | fails (run-pending) | Then — no "OUT OF GAMUT" banner, `findsOneWidget` 0 found (`recipes_test.dart:812`) | ENGINE-5 | A |
| AC-10 | TestAC10_WetDry | fails (run-pending) | precond — `state.recipes` empty, none to predict dry (`recipes_test.dart:759`) | ENGINE-6 | A |
| AC-11 | TestAC11_SpeakTarget | fails (run-pending) | Then — no utterance emitted, `hasLength(1)` (`recipes_test.dart:376`) | RECIPE-4 | A |
| AC-12 | TestAC12_SpeakRecipe | fails (run-pending) | precond — `state.recipes` empty, none to speak (`recipes_test.dart:396`) | RECIPE-4 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC05 | one near-target recipe cannot show the verdict *tracks* distance (a constant "very close" would pass) | ENGINE-3 | a farther recipe asserting a **different** (worse) verdict band | ⬜ Open |
| TestAC06 | the prefer-fewer invariant only bites where the engine's output holds a similar-ΔE pair of differing paint counts; the stub returns none, so the decisive pair can't be constructed in ITEST-3 (confirmed by ITEST-3) | ENGINE-3 | a concrete 2-paint vs 4-paint recipe pair at a similar ΔE00, asserting the 2-paint mix ranks above the 4-paint mix | ⬜ Open |
| TestAC07 | the trace test asserts *any* sub-2% component, not the spec's named **Titanium White** trace, and does not assert the measured-part form is **absent** for the traced paint (confirmed by ITEST-3) | ENGINE-4 | a recipe with a genuine sub-2% Titanium White trace, asserting it renders "a touch of" + note and **not** a measured part | ✅ Closed (ENGINE-4): retargeted to `SAMPLE_DEEP_UMBER` whose top recipe carries a ≈1.4% Titanium White trace; asserts the card renders "a touch of" + note for it and no measured `%`. Re-graded A |
| TestAC08 | the not-constant check (one muddying, one clean) does not verify the flagged recipe **actually** crosses a complementary hue pair — an arbitrary flag assignment would pass (confirmed by ITEST-3) | ENGINE-4 | a known complementary-crossing recipe asserted flagged and a known non-crossing recipe asserted unflagged | ✅ Closed (ENGINE-4): asserts the known Yellow Ochre + Ultramarine crossing is flagged `muddying` (+ renders) and a known non-crossing Yellow Ochre mix is not. Re-graded A |
| TestAC12 | the spoken recipe is checked for each paint's **name** and a single global `contains('part')`, not each paint's **parts quantity** — the "its parts" clause is half-covered until the E25 speak format is frozen (confirmed by ITEST-2) | RECIPE-4 | assert per-component that the utterance states that paint's parts value (its normalized parts rendering) | ✅ Closed (RECIPE-4): per-component `RegExp('<name> \d+ parts?')` for a measured paint, `RegExp('a touch of <name>')` for a trace — each paint stated with its parts quantity; a paint named without its parts, or a dropped paint, now fails. Re-graded A |
| TestAC11 | the spoken target was checked with **bare** `contains('42'/'28'/'108')`, so a chroma/hue (or L) **label swap** passed since all three numbers are present — closeable only once RECIPE-4 froze the E23 speak format (raised by ITEST-2 grid) | RECIPE-4 | assert **labelled** substrings `Lightness 42` / `chroma 28` / `hue 108`, binding each value to its field | ✅ Closed (RECIPE-4): the format is frozen (`'<name>. Lightness <L>, chroma <C>, hue <h> degrees.'`); the test now pins labelled substrings, so a C/h/L label swap fails. Re-graded A |
| TestAC10 | the red-baseline test asserted only that the dry prediction *differs* from wet (any direction) — a sign-flipped shift (dry *lighter*) would have passed, so the spec's **drying direction** was unasserted (raised by ENGINE-6) | ENGINE-6 | assert the dry prediction is **darker** (`lightness` ↓) and **less saturated** (chroma ↓) than wet, the drying direction | ✅ Closed (ENGINE-6): the AC-10 test now asserts `dry.lightness < wet.lightness` and `chroma(dry) < chroma(wet)` after the toggle; a sign-flipped shift fails. Per-medium magnitude (oil < acrylic, D-11) is covered decisively at the unit level. Re-graded A |

## Phase 5 — Retarget Deep Olive to a reachable olive (ITEST-5)

- **Kind:** acceptance-tests (change phase from G-5 (a))
- **Target AC:** AC-5, AC-9 (the reachability-sensitive ACs); re-verifies AC-1, AC-4, AC-11 whose pinned
  coordinates move with the fixture.
- **Depends on:** G-5 resolved (a) · **Blocks:** ITEST-6 (fresh review), and through it ENGINE-3, ENGINE-5.
- **Files:** `integration_test/recipes_harness.dart` (the `SAMPLE_DEEP_OLIVE` fixture + the ITEST-1 reachability
  guard), `integration_test/recipes_test.dart` (every test pinning L42/C28/h108). No `lib/**`.
- **Context — why:** the verified v1 engine (D-2) reaches the old `SAMPLE_DEEP_OLIVE` (L 42, a\* −8.65, b\* 26.63
  ≡ C 28 / h 108) only to ΔE00 ≈ 9.31 because `PALETTE_MY_PAINTS` has no green/phthalo pigment (a\* cannot go
  usefully negative). G-5 (a): move the fixture to an olive the earthy palette actually reaches — a\* toward ~0
  (a warm, slightly-neutral olive), keeping L and the olive character — so the ΔE00 ≤ 5 "very close" contract
  stays meaningful rather than being weakened.
- **Tasks:**
  1. Choose the new `SAMPLE_DEEP_OLIVE` L\*a\*b\* and **verify with the real `SubtractiveMixingEngine`** that its
     best recipe over `PALETTE_MY_PAINTS` is ΔE00 ≤ 5 (candidate: near the engine's own best-reachable point —
     predicted colour of Titanium White + Yellow Ochre + Ivory Black, a\* ≈ +1 — nudged to a clean olive). Record
     the achieved ΔE00.
  2. Update every test/fixture pinning the old coordinates: the fixture itself; **AC-1** `TestAC01` (done, green
     — re-verify it stays green with the new L/C/h); **AC-4** `TestAC04` (still a mixable target); **AC-5**
     `TestAC05` (now genuinely ≤ 5 + "very close"); **AC-9** `TestAC09` in-gamut **control** (Deep Olive shows no
     banner, no out-of-gamut recipe); **AC-11** `TestAC11` (speak target — pending, owner RECIPE-4: update its
     pinned L/C/h, keep it pending). Leave `SAMPLE_VIVID_TURQUOISE` (the out-of-gamut main path) unchanged.
  3. Refresh the **red baseline** rows for AC-5 and AC-9 against the new fixture (run-pending); keep the default
     run green. Keep the ITEST-1 reachability guard honest — it must still prove Vivid Turquoise unreachable and
     now prove the new Deep Olive **reachable** (≤ 5).
- **Exit criteria:** new fixture verified reachable ≤ 5 by the real engine; `flutter analyze` clean; unit suite
  green; coverage gate PASS (no `lib/**` touched); default integration green with AC-5/AC-9 pending and AC-1
  re-verified green; fresh red baseline recorded; grade grid re-checked for the changed tests.
- **Acceptance gate:** regression green (AC-5/AC-9 pending, AC-1 green); red baseline refreshed; grades held.
  No AC un-pended here (that stays with ENGINE-3/ENGINE-5 after G-6).

### Result

`SAMPLE_DEEP_OLIVE` retargeted to a reachable warm olive; every test pinning the old coordinates updated; a
new engine-backed reachability guard added. No `lib/**` touched (tests/fixtures only). No AC un-pended (that
stays with ENGINE-3/ENGINE-5 after G-6).

- **Chosen target (verified by the real engine):** L 42 / C 24 / h 93° = CIELAB (42, −1.2561, 23.9671). Keeps
  L exactly, moves a\* from −8.65 to ≈ −1.26 (toward ~0, per G-5 (a)), a muted deep olive-green. The real
  `SubtractiveMixingEngine` over `PALETTE_MY_PAINTS` (default `MixOptions`) reaches it at **best ΔE00 ≈ 3.34**
  (top recipe W 6% + YO 85% + BK 9%; 5 recipes returned) — comfortably inside the 5.0 in-gamut ceiling, so the
  "very close" contract (D-7/D-10) stays meaningful. The palette genuinely cannot reach the green side
  (no green/phthalo pigment), so a warmer olive near a\* ≈ 0 is the honest retarget, not a weakened one.
- **Updated (tests/fixtures only):** `recipes_harness.dart` — `SAMPLE_DEEP_OLIVE` coords + its doc comment
  (the retarget rationale). `recipes_test.dart` — the C/h recovery guard (now `C 24 / h 93`); **AC-1**
  `TestAC01` state pins (`closeTo(24, 0.05)` / `closeTo(93, 0.1)`) + comments; **AC-11** `TestAC11` spoken pins
  (`chroma 24` / `hue 93`, still pending RECIPE-4 — kept pending) + comments. **AC-4/AC-8/AC-12** (Deep Olive,
  no coord pins) stay green unchanged; `SAMPLE_VIVID_TURQUOISE` unchanged. **AC-8 structure preserved** — the
  new target still yields a Yellow Ochre + Ultramarine crossing recipe (muddying, index 2) and a non-crossing
  Yellow Ochre control (index 0), clean ranked above crossing.
- **Added:** an engine-backed reachability guard (`the real engine reaches Deep Olive but not Vivid Turquoise`)
  — runs the real `SubtractiveMixingEngine`, asserting best ΔE00 ≤ 5 for Deep Olive (3.34) and > 5 for Vivid
  Turquoise (22.68), with `isNotEmpty` before each `.first`. Non-vacuous and discriminating: reverting the
  retarget (old a\* −8.65, best ≈ 9.31) fails the `≤ 5` side, so the guard protects the G-5 (a) decision itself.
- **Gates:** `flutter analyze` clean; unit **566 green**; coverage gate **PASS** (no `lib/**` touched — the 16
  recipes lib files stay 100%); default integration **green** on the iPhone 17 sim under the verify lock —
  **+21 passed, ~3 pending** (AC-5, AC-6, AC-9), the retargeted AC-1/AC-11 pins + the new guard + AC-8 all green.
- **Red baseline refreshed (run-pending `--dart-define=BS04_RUN_PENDING=true`):** `+21 −3`; the three pending
  ACs fail cleanly at a Then naming their owner — **AC-5** at `recipes_test.dart:582` (`best.verdict` null → ENGINE-3;
  note the `deltaE00 ≤ 5` assertion now **passes**, 3.34 ≤ 5), **AC-6** at `:625` (3-paint ranked above 2-paint
  at similar ΔE → ENGINE-3 prefer-fewer), **AC-9** at `:812` (no OUT OF GAMUT banner → ENGINE-5). Rows updated
  in the *Red baseline* table.
- **Grade gate:** an independent grader (fresh context) re-graded the four changed tests (C/h recovery guard,
  the new reachability guard, AC-1, AC-11) — **4×A, 0×B — PASS**. It recomputed the fixture math
  (C 23.99999 / h 93.00009, both centred in their bands, rounding to 24 / 93), ran the real engine to confirm
  3.34 ≤ 5 < 22.68, and confirmed the labelled spoken substrings. Grid appended at
  `behavior-test-completeness-bs-04-mixing-recipes.md`. Grades held (AC-1/AC-11 A; AC-5/AC-9 unchanged test
  code, grades carry from ITEST-3).
- **Fix passes: 0/3** (green first run).
- **Tokens / Time:** 10,631,343 · 18m 10s active (18m 10s wall) — one session, 1 grader subagent included.

### Checkpoint / Handoff

- **ITEST-6 (next, the fresh G-6 review):** assemble the packet — the retargeted `SAMPLE_DEEP_OLIVE`
  (L 42 / C 24 / h 93°), the **achieved ΔE00 ≈ 3.34 ≤ 5 proof** from the real engine (+ the reachability
  guard that now encodes it), the updated AC-5/AC-9 Given/When/Then (AC-5's `deltaE00 ≤ 5` now passes; only the
  verdict is pending), the re-verified AC-1/AC-4/AC-11, the refreshed red baseline, the 4×A re-grade — then run
  the full regression and present for the human **G-6**. The point of the round: the human re-confirms the
  acceptance contract moved **honestly** (not weakened) when the fixture moved. ENGINE-3 and ENGINE-5 stay
  blocked until G-6 is approved.
- **No AC was un-pended here.** AC-5/AC-6 un-pend in ENGINE-3, AC-9 in ENGINE-5 — each after G-6. The pending
  gate (`bs04/pending.dart`) and the guard's `unpended` set are unchanged.
- **New target facts for ENGINE-3/ENGINE-5** (once unblocked): best Deep Olive recipe ΔE00 ≈ 3.34 (W 6% + YO
  85% + BK 9%); the "very close" band ENGINE-3 sets must cover ≈3.34 (the spec intent is ΔE00 ≤ 5 → "very
  close", D-7/D-10). The prefer-fewer order (AC-6) must float the 2-paint `YO 91% + BK 9%` (ΔE ≈ 3.37) above
  the 3-paint `W 6% + YO 85% + BK 9%` (ΔE ≈ 3.34) at their near-tie. ENGINE-5's gamut marking must leave Deep
  Olive in-gamut (3.34 ≤ 5, the AC-9 control) while marking Vivid Turquoise (22.68) out.
- **Verification commands** unchanged (`export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze`
  · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under the verify lock on
  sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (always `-d <udid>`; no device ⇒ false green). Run-pending:
  `flutter test integration_test/recipes_test.dart -d <udid> --dart-define=BS04_RUN_PENDING=true`.
- **Known gaps / notes:** behaviour for AC-5/AC-6/AC-9 not yet coded (ENGINE-3/ENGINE-5, after G-6). Carry-over
  const-constructor coverage flake stands. Untracked bs-05..bs-14 specs + `docs/` are not part of bs-04.

## Phase 6 — Fresh test review after retarget (ITEST-6)

- **Kind:** test-review
- **Target AC:** — (G-6)
- **Depends on:** ITEST-5 · **Blocks:** ENGINE-3, ENGINE-5 (via G-6)
- **Tasks:** assemble the fresh review packet — the retargeted `SAMPLE_DEEP_OLIVE`, the achieved ΔE00 ≤ 5 proof
  from the real engine, the updated AC-5/AC-9 Given/When/Then/Rejects, the re-verified AC-1/AC-4/AC-11, the
  refreshed red baseline, and the unchanged grade grid; run the full regression; present for the human **G-6**
  decision. The whole point of the round is that the human re-confirms the acceptance contract moved honestly
  (not weakened) when the fixture moved.
- **Exit criteria:** packet assembled; full suite green (AC-5/AC-9 pending); grade grid complete.
- **Acceptance gate:** human records **G-6**. On approved: ITEST-6 ✅ Done, ENGINE-3 then ENGINE-5 unblock. On
  changes requested: each item becomes an ITEST change phase before ENGINE-3/ENGINE-5, then another review.
