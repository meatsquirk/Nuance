# Module ENGINE — the mixing engine

**Status:** ✅ Done — **ENGINE-5 done** (AC-9 out-of-gamut: target marked OUT OF GAMUT, nearest mix offered as nearest not a match, D-10; 12×A grade). All six ENGINE phases complete; all 12 bs-04 ACs coded, un-pended and green. G-4/G-5/G-6 resolved. Next: SIGNOFF-1
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/domain/paint.dart` (`Paint`, `PaintMedium`), `lib/recipes/engine/mixing_engine.dart`
(`MixingEngine` interface, `Recipe`, `RecipeComponent`, `MixOptions`), `lib/recipes/engine/subtractive_engine.dart`
(the v1 impl: forward, inverse solver, verdict, trace, muddying, gamut, wet/dry). Reuses `lib/compare/difference.dart`'s
`deltaE00` and `lib/color_science/` (conversions, `words.dart`).
**Depends on:** bs-03 color-science (`deltaE00`, `ColorScience`, `words.dart`) · **Blocks:** RECIPE-2 (needs the
types), ENGINE's own behaviour phases, every recipe-detail AC

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 6,408,543 | 21m 15s |
| 2 | behavior | AC-3, AC-4 | ✅ Done | 19,431,437 | 50m 12s |
| 3 | behavior | AC-5, AC-6 | ✅ Done | 12,441,399 | 27m 36s |
| 4 | behavior | AC-7, AC-8 | ✅ Done | 19,391,961 | 38m 16s |
| 5 | behavior | AC-9 | ✅ Done | 11,054,873 | 21m 45s |
| 6 | behavior | AC-10 | ✅ Done | 12,666,200 | 18m 55s |

## Interface reconciliation

- **`MixingEngine` (SI D3, swappable).** `List<Recipe> inverse(Sample target, PaintPalette palette, MixOptions opts)`
  and `ColorCoordinates forward(Map<Paint,double> partsByVolume, {bool dry})`. The v1 `SubtractiveMixingEngine`
  implements it; the measured-pigment `CustomKmEngine` (`docs/custom-mixing-engine-design.md`) is the deferred
  upgrade behind the same interface. Spectral.js is the SI-named v1 basis; the **exact forward formula** is a
  G-4 item — the interface and the solver do not change with it.
- **ΔE00 is the shipped `deltaE00`** (`lib/compare/difference.dart:138`), not a new copy — the solver minimises
  it and each recipe reports it. The acceptance suite grades it against an **independent** `referenceDeltaE00`.
- **`Recipe` shape** consumed by RECIPE (controller) and SCREEN (list): `medium`, `components:
  List<RecipeComponent>` (each `{paint, partsFraction, isTrace, techniqueNote}`), `predictedColor:
  ColorCoordinates`, `deltaE00`, `verdict`, `outOfGamut: bool`, `muddying: bool`. Recipes never span media
  (engine-design cross-medium rule).
- **Muddying** reads each paint's masstone hue via the warm/cool model in `words.dart`; no new hue model.

## Open gates

- **G-4 (spec-data / engine reconciliation — spec author)** ✅ resolved 2026-10-08: pinned predicted colours
  are illustrative (ACs assert behavioural properties, D-13); v1 subtractive forward+inverse (D-2); gamut
  ΔE00 > 5 (D-10), trace ~2% (D-12).
- **G-5 (spec-data / engine reachability — spec author) — ✅ RESOLVED 2026-10-09 14:41 EDT (a) retarget, by
  Matt Quirk; raised by ENGINE-2. Had blocked ENGINE-3 (AC-5)
  and ENGINE-5 (AC-9 in-gamut control).** The v1 subtractive engine (D-2), built and verified in ENGINE-2,
  **cannot reach `SAMPLE_DEEP_OLIVE` (L 42, a\* −8.65, b\* 26.63) within the in-gamut ceiling the approved ACs
  assert.** Best achievable ΔE00 ≈ **9.31** (Titanium White 21% + Yellow Ochre 70% + Ivory Black 9%; predicted
  a\* ≈ +1), because `PALETTE_MY_PAINTS` has no green/phthalo pigment and Ultramarine + Yellow Ochre mix to a
  grey-olive, not a green a\* < 0 — a limit robust across KM and geometric-mean subtractive mixing, not a
  calibration quirk. But `recipes_test.dart` hard-codes `const gamutThreshold = 5.0` and asserts
  **AC-5** `best.deltaE00 ≤ 5` + verdict "very close", and **AC-9**'s control asserts Deep Olive is *not*
  out-of-gamut (so its best must be ≤ 5). For reference: Vivid Turquoise ΔE00 ≈ 22.68 (correctly unreachable,
  AC-9 main path fine); Studio Olive oil ΔE00 ≈ 0.11 (AC-10 fine). The spec author must choose one, and it
  reshapes ITEST-3 (an approved test, so a test-review round) or a fixture/palette:
  (a) retarget `SAMPLE_DEEP_OLIVE` to an olive the earthy palette actually reaches (a\* nearer 0);
  (b) add a green/phthalo pigment to `PALETTE_MY_PAINTS` so the olive-green is mixable;
  (c) raise the in-gamut ceiling the ACs assert (changes the approved `gamutThreshold`); or
  (d) accept a measured-pigment engine for v1 (deferred per D-2/SI D3). Until G-5 resolves, ENGINE-3 and
  ENGINE-5 cannot pass their acceptance gates; **ENGINE-4 (AC-7 trace, AC-8 muddying)** and the RECIPE phases
  are unaffected and can proceed.

  **Resolution (a), 2026-10-09 14:41 EDT — Matt Quirk:** retarget `SAMPLE_DEEP_OLIVE` to a reachable olive
  (a\* −8.65 → ~0, olive hue kept) so `PALETTE_MY_PAINTS` reaches it to ΔE00 ≤ 5. The engine, the "very close"
  verdict band (D-7) and the `gamutThreshold = 5.0` are **unchanged** — the ΔE ≤ 5 contract is kept, not
  weakened; only the over-claiming fixture moves. This reshapes the approved ITEST-3, so a fresh test-review
  round runs before the blocked behaviour phases: **ITEST-5** (retarget the fixture + update every test pinning
  the old L42/C28/h108, incl. the done AC-1 and the pending AC-11) → **ITEST-6** fresh review (**G-6**) →
  ENGINE-3, then ENGINE-5. Full phase defs in [ITEST.md](ITEST.md) (Phases 5–6).
- **G-6 (approve the retargeted acceptance tests — spec author)** — ✅ **RESOLVED 2026-10-09 16:46 EDT approved,
  by Matt Quirk.** The retargeted suite moves the contract honestly (best ΔE00 ≈ 3.34 ≤ 5 vs the real engine;
  ≤ 5 ceiling and `gamutThreshold = 5.0` unchanged; engine-backed discriminating guard). **ENGINE-3 (AC-5,
  AC-6) and ENGINE-5 (AC-9) are now unblocked.**

## Phase 1 — Engine types + interface + stub (ENGINE-1)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** RECIPE-1 · **Blocks:** RECIPE-2, ENGINE-2
- **Files:** `lib/domain/paint.dart`, `lib/recipes/engine/mixing_engine.dart`, `lib/recipes/engine/subtractive_engine.dart`;
  wire `mixingEngine` into `lib/app/build_app.dart` (`AppDependencies`).
- **Tasks:**
  1. `Paint` (`id`, `name`, `medium`, `masstone: ColorCoordinates`, optional `pigmentIndex`/`opacity`) + `PaintMedium {acrylic, oil}` — value-equal, `const`.
  2. `MixingEngine` interface: `forward(Map<Paint,double>, {bool dry})`, `inverse(Sample target, PaintPalette palette, MixOptions opts)`; `Recipe`/`RecipeComponent`/`MixOptions` (maxPaints, topK, gamut + trace thresholds) — value-equal, `const` where possible.
  3. `SubtractiveMixingEngine` (`const`) implementing the interface with **stubbed** methods (return `const []` / throw `UnimplementedError` behind a documented stub marker) — no behaviour yet.
  4. Add `mixingEngine` to `AppDependencies` (default `const SubtractiveMixingEngine()`); no screen uses it yet.
  5. Unit-test the types (equality/round-trip) and the stub's shape; keep behaviour unchanged.
- **Exit criteria:** `flutter analyze` clean; unit gate green; 100% coverage on the touched files; the existing suites stay green.
- **Acceptance gate:** *(shell — unit gate + existing suite green)*

### Result

Shell landed; all four engine types + the stub engine wired into production assembly. Behaviour unchanged.

- **Files:** `lib/domain/paint.dart` (`Paint` + `PaintMedium {acrylic, oil}`, value-equal `const`),
  `lib/recipes/engine/mixing_engine.dart` (`MixingEngine` interface; `MixOptions`/`RecipeComponent`/`Recipe`
  value-equal `const`), `lib/recipes/engine/subtractive_engine.dart` (`const SubtractiveMixingEngine`,
  **stubbed** — `forward` throws `UnimplementedError`, `inverse` returns `const []`), `lib/app/build_app.dart`
  (`AppDependencies.mixingEngine`, default `const SubtractiveMixingEngine()`; no screen reads it yet).
- **Coordination deviation (flagged):** the frozen interface `inverse(Sample, PaintPalette, MixOptions)`
  references `PaintPalette`, which RECIPE-2 owns — but ENGINE-1 precedes RECIPE-2. So ENGINE-1 introduces the
  **minimal** `PaintPalette` (`lib/recipes/palette.dart`, the pinned `{name, List<Paint>}`) as the enabler the
  interface needs. **RECIPE-2 adds `palette_source.dart` over it and must NOT recreate `PaintPalette`.**
- **Gates:** `flutter analyze` clean; unit **480 green** (`flutter test --coverage`, +45 over the 430
  baseline); **100% line coverage on all 5 touched files** (`dart run tool/coverage_gate.dart main` PASS);
  existing integration suite **62 green** (`flutter test integration_test/ -d 5AB9D06D…` under the verify lock,
  incl. bs-01 AC-11 handoff — the `RecipesStubScreen` is untouched).
- **Note:** `MixingEngine.forward(Map<Paint,double>)` keys a **runtime** map on `Paint` (value-equal); const
  maps with `Paint` keys are rejected by the analyzer, so callers build the parts map non-const.
- **Fix passes: 2/3** — (1) dropped `const` from two test maps keyed on `Paint` (analyzer
  `const_map_key_not_primitive_equality`); (2) added a non-const construction per type so the `const`
  constructor line executes at runtime (coverage — the documented const-canonicalisation gap).
- **Tokens / Time:** 6,408,543 · 21m 15s.

### Checkpoint / Handoff

- **Frozen for RECIPE-2 / SCREEN / ITEST / behaviour:**
  - `Paint({id, name, medium, masstone, pigmentIndex?, opacity?})`, `enum PaintMedium {acrylic, oil}`.
  - `PaintPalette({name, paints = const []})` — minimal; **RECIPE-2 extends with `PaletteSource`, not by
    editing `PaintPalette`**.
  - `MixingEngine`: `ColorCoordinates forward(Map<Paint,double> partsByVolume, {bool dry})`;
    `List<Recipe> inverse(Sample target, PaintPalette palette, MixOptions opts)`.
  - `MixOptions({maxPaints=4, topK=5, gamutThreshold=5.0, traceThreshold=0.02})` — threshold literals are
    D-10/D-12 defaults pending **G-4**; the solver reads them, the ACs assert properties (D-13).
  - `Recipe({medium, components, predictedColor, deltaE00, verdict?, outOfGamut=false, muddying=false})`;
    `RecipeComponent({paint, partsFraction, isTrace=false, techniqueNote?})`.
  - `AppDependencies.mixingEngine` (default `const SubtractiveMixingEngine()`) — RECIPE-2 passes it to the
    `RecipeController`; the controller never computes mixing math.
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under
  the verify lock: `$C with-lock bs-04-mixing-recipes <PHASE> --wait 900 -- bash -c "export PATH=…; cd <repo>
  && flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685"`.
- **Next phase:** RECIPE-2 (shell) — `PaletteSource`/`InMemoryPaletteSource` over the existing `PaintPalette`,
  `RecipeController`/state, `RecipeReadEndpoint`, recipes entry in `buildApp`, replace `RecipesStubScreen`.
- **Known gaps:** the engine is a shell — `forward` throws, `inverse` returns `[]`; the subtractive forward
  model + inverse solver + verdict/ordering/trace/muddying/gamut/wet-dry land in ENGINE-2..6 (behind G-4). The
  `const`-constructor coverage quirk (master-plan *Known flakes*) applies to every new value type — covered
  here with a non-const construction per type.

## Phase 2 — Palette-constrained solver + top 3–5 (ENGINE-2)

- **Kind:** behavior
- **Target AC:** AC-3 (recipes use only palette paints), AC-4 (top 3–5 with parts + predicted colour)
- **Depends on:** RECIPE-3 (target selection), ENGINE-1 · **Blocks:** ENGINE-3, ENGINE-4, ENGINE-5, ENGINE-6, RECIPE-4
- **Files:** `lib/recipes/engine/subtractive_engine.dart` (forward + inverse). RECIPE binds `selectedPalette` + triggers the solve on target set; SCREEN renders the list — those edits are owned by RECIPE-3's follow-on wiring / SCREEN region, coordinated here.
- **Tasks:**
  1. **Forward**: parts-by-volume → predicted CIELAB (the v1 subtractive model, D-2 / G-4).
  2. **Inverse**: enumerate subsets of the selected palette by ascending size (≤ `maxPaints`), optimise volumes to minimise `deltaE00(forward, target)`, return the top `3..5` as `Recipe`s with parts + predicted colour. Palette-constrained by construction (AC-3).
  3. Wire the controller to solve over `selectedPalette` when a target is set; render the list (parts + predicted colour).
  4. Un-pend AC-3, AC-4; write unit tests for the solver (palette constraint, count bound 3–5, determinism) and every branch.
- **Exit criteria:** `BS04_RUN_PENDING` AC-3/AC-4 green; default suite green; unit gate + 100% coverage on touched files.
- **Acceptance gate:** un-pend AC-3, AC-4; `flutter test integration_test/recipes_test.dart -d <udid>` green (`TestAC03_*`, `TestAC04_*` + all earlier ACs); grade gate passed.

### Result

Forward + inverse landed; AC-3 and AC-4 un-pended and green end-to-end.

- **Engine** (`lib/recipes/engine/subtractive_engine.dart`): a self-contained Kubelka–Munk–class v1. Each
  masstone CIELAB is lifted to a smooth reflectance (illuminant-E, analytic CIE-1931 CMFs — Wyman 2013; a
  three-Gaussian reflectance basis solved to match XYZ, so a single paint round-trips its own masstone).
  **forward** mixes reflectances by single-constant KM (volume-weighted K/S, inverted to reflectance) →
  CIELAB — subtractive, so yellow + blue darken toward green. `dry: true` throws (ENGINE-6). **inverse**
  enumerates palette subsets by ascending size within a medium (recipes never span media), optimises each
  subset's volumes (coarse simplex grid → coordinate descent) to minimise the shipped `deltaE00`, drops
  zeroed paints, dedups by paint-set and returns the top `topK` best-first with parts + predicted colour.
- **Wiring**: `RecipeController` solves over the selected palette **on open** and on `selectPalette`
  (`_solve`/`_emit` added — the first real mutation path); `RecipeListRegion` renders a card per recipe
  (paints as parts, predicted colour, an inert "Speak recipe" per card for RECIPE-4). Controller `selectTarget`
  / `enterManualTarget` (RECIPE-3), `setMode` (ENGINE-6) and `speak*` (RECIPE-4) stay deferred.
- **Un-pended** AC-3, AC-4 — row deleted in `integration_test/bs04/pending.dart` **and** added to the
  `unpended` guard set in `recipes_test.dart` (shared with RECIPE-3's AC-1/AC-2 un-pend — distinct lines).
- **ITEST smoke change (recorded):** `recipes_test.dart`'s never-pending smoke test asserted the shell
  snapshot `state.recipes isEmpty` / `hasRecipes isFalse`; ENGINE-2 solves on open (as AC-3/AC-4's
  `givenRecipes` → `state.recipes isNotEmpty` require), so those two lines were flipped to `isNotEmpty` /
  `isTrue` with a comment. No AC test weakened; no AC assertion changed.
- **Gates:** `flutter analyze` clean; **unit 531 green** (`flutter test --coverage`, +14 net over 517 after
  replacing the ENGINE-1 shell-stub tests); **100% line coverage on all touched files** (`coverage_gate.dart
  main` PASS); **integration recipes suite green** (`-d 5AB9D06D…` under the verify lock: `TestAC03_*`,
  `TestAC04_*` + smoke pass, the 10 still-pending ACs skip) and the **bs-01/02/03 capture+comparison suites
  stay green** (full-suite run; recipes re-run after the smoke fix confirmed +13 ~10 -0).
- **Fix passes: 1/3** — the first integration run failed only on the smoke test's stale shell assertion
  (recipes now solved on open); flipping those two lines fixed it. The engine/solver passed first time.
- **Grade gate:** AC-3 / AC-4 graded **A** (behavioural properties — palette constraint by paint id; 3–5
  distinct recipes with positive parts summing to 1 and a rendered predicted colour; no literal pinned, D-13).
- **Raised G-5 (blocks ENGINE-3 / ENGINE-5):** the verified engine reaches Deep Olive only to ΔE00 ≈ **9.31**
  (earthy palette has no green pigment), but the approved ACs assert an in-gamut ceiling of 5.0 — see
  *Open gates* above. ENGINE-4 and the RECIPE phases are unaffected.
- **Tokens / Time:** 19,431,437 · 50m 12s.

### Checkpoint / Handoff

- **Frozen for ENGINE-3..6 / RECIPE / SCREEN:**
  - `SubtractiveMixingEngine.forward(Map<Paint,double>, {bool dry})` (wet implemented; `dry:true` throws —
    ENGINE-6 fills the per-medium transform there) and `inverse(Sample, PaintPalette, MixOptions)` (returns
    best-first, deduped, ≤ `topK`, positive parts summing to 1, `verdict`/`outOfGamut`/`muddying` at
    defaults). The `_Spectral` pipeline and the `_optimise` solver are internal; downstream phases layer on
    top via the returned `Recipe`s, not by re-deriving the math.
  - `RecipeController` solves on open and on `selectPalette`, through `_solve(engine, target, palette)` and
    `_emit(state)`. **RECIPE-3** routes its `selectTarget` / `enterManualTarget` re-solve through the same
    `_solve`/`_emit` (merge note below). **ENGINE-6** adds the mode re-predict through `_emit`.
  - `RecipeListRegion` renders `state.recipes` as a card each; ENGINE-3 adds the verdict + ΔE line, ENGINE-4
    the "a touch of" trace + muddying, ENGINE-5 the out-of-gamut label, RECIPE-4 wires each card's speak
    control.
- **Parallel merge notes (shared files, reconcile at RECONCILE):** `recipe_controller.dart` (RECIPE-3 also
  edits it — it adds `selectTarget`/`enterManualTarget`; ENGINE-2 added `_solve`/`_emit`/`selectPalette` +
  the solving constructor), `integration_test/bs04/pending.dart` and `recipes_test.dart`'s `unpended` set
  (RECIPE-3 removes AC-1/AC-2; ENGINE-2 removed AC-3/AC-4 — distinct lines), and the `recipes_test.dart`
  smoke-test lines. Re-read before merging.
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under
  the lock: `$C with-lock bs-04-mixing-recipes <PHASE> --wait 900 -- bash -c "export PATH=…; cd <worktree> &&
  flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685"`.
- **Next phase:** **G-5 must be resolved before ENGINE-3 / ENGINE-5.** ENGINE-4 (AC-7 trace, AC-8 muddying)
  is startable now (serial on `subtractive_engine.dart`); RECIPE-3 / RECIPE-4 independent. Reachability data
  for the gate: Deep Olive 9.31, Vivid Turquoise 22.68, Studio Olive (oil) 0.11.
- **Known gaps:** `verdict` null, `outOfGamut`/`muddying` false, `isTrace` false on every component, `dry`
  unimplemented — all land in ENGINE-3..6. The ΔE reachability limit (G-5) is the one blocking issue.

## Phase 3 — ΔE00 + verdict + prefer fewer paints (ENGINE-3)

- **Kind:** behavior
- **Target AC:** AC-5 (small ΔE + plain verdict "very close"), AC-6 (prefer fewer paints)
- **Depends on:** ENGINE-2, **ITEST-5 (retarget) + G-6 (fresh review)** · **Blocks:** ENGINE-4
- **Files:** `lib/recipes/engine/subtractive_engine.dart` (**serial** with ENGINE-2/4/5/6).
- **Tasks:**
  1. Per-recipe `deltaE00` (already the solve metric) + a plain `verdict` band reusing `_verdictBand`'s pattern, adding a "very close" band for small ΔE (D-7).
  2. Ordering: ascending ΔE, tie-broken toward fewer paints / lower added chroma (D-8), so a cleaner 2-paint mix ranks above a muddier 4-paint at similar ΔE.
  3. Un-pend AC-5, AC-6; **augment `TestAC05`** with a farther recipe reading a worse band (verdict tracks distance); unit-test the bands + ordering (incl. the fewer-paints tie-break).
- **Exit criteria:** AC-5/AC-6 green; default suite green; unit gate + 100% coverage touched.
- **Acceptance gate:** un-pend AC-5, AC-6; suite green (`TestAC05_*`, `TestAC06_*` + earlier); TestAC05 augmentation made; grade gate passed.
- **Augments:** `TestAC05`: add a farther recipe asserting a **different** (worse) verdict band.

### Result

Per-recipe ΔE00 + verdict (D-7) and prefer-fewer-paints ranking (D-8) landed; AC-5 and AC-6 un-pended and green end-to-end.

- **Engine** (`subtractive_engine.dart`): `inverse` now sets `Recipe.verdict` via `_verdictBand(de)` — a plain
  match band (`an almost exact match` < 1, `very close` < 5, `close` < 10, `in the ballpark` < 20, else `far
  off`), the same ascending-band pattern `compare/difference.dart` uses (D-7), with "very close" as the pinned
  in-gamut phrase. Ranking moved from pure ascending ΔE to `_rankCompare(a, b, target)` (D-8): ΔE00 bucketed to
  `_tieGrain = 1.0` (a just-noticeable difference), ties broken toward fewer paints, then lower added chroma
  (`_addedChroma` = predicted chroma over target, floored at 0), then the finer ΔE00. Lexicographic over crisp
  keys → a deterministic total order (no fuzzy within-tolerance comparator). `forward` unchanged.
- **Render** (`recipe_list_region.dart`): each card now shows an `ΔE00 <x.x> — <verdict>` line under the
  predicted colour.
- **Un-pended** AC-5, AC-6 (rows deleted in `bs04/pending.dart`; added to `recipes_test.dart`'s `unpended` set).
- **AC-5 augmentation (made):** asserts the farthest returned recipe (Deep Olive #4, ΔE00 ≈ 20.5 → "far off")
  reads a verdict that is non-null, not "very close", and `isNot(best.verdict)` — so a constant verdict (or the
  pre-ENGINE-3 null) fails; picked by ΔE00 not rank, so it strengthens AC-5's verdict only (G6).
- **AC-6 augmentation (made):** the decisive near-tie the retargeted solve produces — 2-paint {Ochre, Black}
  (ΔE00 ≈ 3.37) vs 3-paint {White, Ochre, Black} (ΔE00 ≈ 3.34). The 3-paint has the **lower** ΔE00 yet ranks
  below the 2-paint, so the pass comes only from the prefer-fewer tie-break. **Change from the plan** (recorded
  per the "tests serve the AC" rule): the ITEST-3 plan sketched a 2-vs-4-paint pair; after the G-5 retarget no
  4-paint mix is competitive for this olive, so the real decisive pair is 2-vs-3 — still discriminating against
  the pre-ENGINE-3 ΔE-only order, still AC-6-only. The ITEST *Test augmentations* row records the same.
- **Updated two ENGINE-2 generic unit assertions** the new contract changes: the ordering test (was "strictly
  ascending ΔE00") now asserts the D-8 order (ascending beyond a tie, fewer paints within a tie); the generic
  recipe test (was `verdict isNull`) now asserts `verdict isNotNull`/`isNotEmpty`. Both legitimate — ENGINE-3
  owns the engine and fills the verdict / sets the order.
- **Gates:** `flutter analyze` clean; **unit 570 green** (+4 ENGINE-3 tests: verdict-tracks-distance, the sub-1
  closest band, the prefer-fewer near-tie, and a full-tie determinism case that exercises the chroma/ΔE
  fallbacks); **100% line coverage on all 16 touched files** (`coverage_gate.dart main` PASS); **recipes
  acceptance suite green** under the verify lock (`-d 5AB9D06D…`: `TestAC05_*`, `TestAC06_*` + AC-1..AC-4,7,8,
  10,11,12 run and pass; only AC-9 skips, pending ENGINE-5).
- **Grade gate:** an independent grader (fresh context) graded the full un-pended suite **11×A, 0×B**; AC-5 and
  AC-6 **upgraded from A (limited) to full A** (augmentations now decisive), and confirmed no neighbour weakened
  (AC-8's clean-above-crossing ranking still holds under the new order). Grid § *ENGINE-3 re-grade*.
- **Fix passes: 0/3** — engine, tests and render passed on the first full run.
- **G-5/G-6 settled** (retarget + fresh review already approved); nothing reopened.
- **Tokens / Time:** 12,441,399 · 27m 36s.

### Checkpoint / Handoff

- **Frozen for ENGINE-5 / SIGNOFF:**
  - `inverse` fills `Recipe.verdict` (via `_verdictBand`) and ranks by `_rankCompare` (D-8 total order,
    `_tieGrain = 1.0`). **ENGINE-5** adds `outOfGamut` on top of the same per-recipe build and the gamut label
    in the card — it must **not** re-derive the verdict or the ordering. When a target is out of gamut the best
    ΔE00 exceeds 5, so its verdict naturally reads a worse band ("close"/"in the ballpark"/"far off"); ENGINE-5
    adds the OUT OF GAMUT marking, it does not change the verdict text.
  - `RecipeListRegion._RecipeCard` renders, in order: components (trace or measured) → `Predicted colour:` →
    `ΔE00 <x.x> — <verdict>` → `Liable to muddy`? → Speak. ENGINE-5's gamut label goes inside the same card;
    keep `cardKey(i)`.
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under
  the lock: `$C with-lock bs-04-mixing-recipes <PHASE> --wait 900 -- bash -c "export PATH=…; cd <repo> &&
  flutter test integration_test/recipes_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685"`.
- **Next phase:** **ENGINE-5** (AC-9 out-of-gamut + nearest-not-a-match) — the last behaviour phase, serial on
  `subtractive_engine.dart`; AC-9 is the only still-pending AC. Then **SIGNOFF-1**. Reachability data for AC-9:
  Vivid Turquoise best ΔE00 ≈ 22.68 (> 5, out of gamut); Deep Olive ≈ 3.34 (the in-gamut control).
- **Known gaps:** `outOfGamut` is still `false` on every recipe (ENGINE-5). No other gaps — verdict, ordering,
  trace, muddying and wet/dry are all in.

## Phase 4 — Trace "a touch of" + muddying flag (ENGINE-4)

- **Kind:** behavior
- **Target AC:** AC-7 (trace "a touch of" + technique note), AC-8 (muddying flag)
- **Depends on:** ENGINE-2 (ordering not required) · **Blocks:** ENGINE-5
- **Files:** `lib/recipes/engine/subtractive_engine.dart` (**serial**).
- **Tasks:**
  1. Flag a component under ~2% by volume as `isTrace` with a static `techniqueNote` (D-12); SCREEN renders "a touch of" + the note rather than a measured part.
  2. `muddying` = the recipe's paints span a complementary hue pair (masstone-hue opposition beyond a threshold, via `words.dart`, D-9).
  3. Un-pend AC-7, AC-8; unit-test the trace threshold boundary and the muddying detector (a crossing recipe flagged; a non-crossing recipe not — the in-test control).
- **Exit criteria:** AC-7/AC-8 green; default suite green; unit gate + 100% coverage touched.
- **Acceptance gate:** un-pend AC-7, AC-8; suite green (`TestAC07_*`, `TestAC08_*` + earlier); grade gate passed.

### Result

Trace "a touch of" + muddying landed; AC-7 and AC-8 un-pended and green end-to-end.

- **Engine** (`subtractive_engine.dart`): `inverse` now flags each component below `MixOptions.traceThreshold`
  (2%, D-12) `isTrace` with a static `techniqueNote`, and sets `Recipe.muddying` when a mix pairs a chromatic
  **warm** with a chromatic **cool** paint — warm/cool from `words.dart`'s `temperatureWord` (poles 60°/240°,
  i.e. complementary), paints below masstone chroma 10 excluded as achromatic (D-9). `forward` unchanged.
- **Render** (`recipe_list_region.dart`): a trace renders "`<paint> — a touch of`" + its note (never a measured
  `%`); a muddying recipe shows a "Liable to muddy" flag; each card carries `RecipeListRegion.cardKey(i)` so the
  suite scopes assertions to one recipe.
- **Un-pended** AC-7, AC-8 (row deleted in `bs04/pending.dart`; added to `recipes_test.dart`'s `unpended` set).
- **AC-7 augmentation (made):** retargeted the test to a new `SAMPLE_DEEP_UMBER` fixture (CIELAB 33,0,12) whose
  top recipe is Yellow Ochre + Ivory Black with a genuine ≈1.4% **Titanium White** trace; asserts that recipe's
  card renders "a touch of" + the note for Titanium White and **no** measured `%` for it, plus the general
  trace-vs-measured-control invariant across every recipe.
- **AC-8 augmentation (made):** on Deep Olive / My paints, asserts a **known** Yellow Ochre + Ultramarine
  crossing is `muddying` (+ renders the flag) and a **known** non-crossing Yellow Ochre mix is not — decisive
  over an arbitrary flag assignment.
- **Gates:** `flutter analyze` clean; **unit 551 green** (+8 over 543); **100% line coverage on all 15 touched
  files** (`coverage_gate.dart main` PASS — const-ctor line re-covered with a non-const construction, the
  Known-flakes quirk); **recipes acceptance suite green** under the verify lock (`-d 5AB9D06D…`: `TestAC07_*`,
  `TestAC08_*` + AC-1..AC-4 run and pass; the 6 later-phase ACs skip). Also updated the ENGINE-2 generic unit
  test that asserted `muddying isFalse` (ENGINE-4 now sets it).
- **Grade gate:** an independent grader (fresh context) graded **AC-7 A (full)** and **AC-8 A (full)** — both
  upgraded from A (limited), their augmentations now decisive; **0×B**. Grid § *ENGINE-4 behaviour re-grade*.
- **Fix passes: 1/3** — the first region widget test overflowed the unscrolled test Scaffold with 5 cards;
  wrapped it in a `SingleChildScrollView` (as the screen's `ListView` does). Engine/solver passed first try.
- **G-5 untouched** (ENGINE-4 does not bear on reachability).
- **Tokens / Time:** 19,391,961 · 38m 16s.

### Checkpoint / Handoff

- **Frozen for ENGINE-5/6 / RECIPE / SCREEN:**
  - `inverse` sets `isTrace`/`techniqueNote` (static `_traceTechniqueNote`) per `MixOptions.traceThreshold` and
    `Recipe.muddying` via `_isMuddying` (warm+cool chromatic crossing through `temperatureWord`,
    `_achromaticChroma` = 10). ENGINE-5 adds `outOfGamut`, ENGINE-6 the `dry` transform — both layer on the same
    per-component / per-recipe build; do **not** re-derive trace or muddying.
  - `RecipeListRegion.cardKey(i)` is the per-card anchor; `_TraceComponent` renders "a touch of" + note; the
    muddying flag text is "Liable to muddy". ENGINE-3 adds the verdict + ΔE line, ENGINE-5 the gamut label —
    both inside `_RecipeCard`; keep the key.
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under
  the lock: `$C with-lock bs-04-mixing-recipes <PHASE> --wait 900 -- bash -c "export PATH=…; cd <repo> &&
  flutter test integration_test/recipes_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685"`.
- **Next phase:** **G-5 still blocks ENGINE-3 (AC-5) and ENGINE-5 (AC-9 in-gamut control).** Startable now:
  **ENGINE-6** (AC-10 wet/dry — serial on `subtractive_engine.dart`) and **RECIPE-4** (AC-11/AC-12 speak —
  file-disjoint). After G-5: ENGINE-3, ENGINE-5.
- **Known gaps:** `verdict` null (ENGINE-3), `outOfGamut` false (ENGINE-5), `forward(dry: true)` throws
  (ENGINE-6). The new `SAMPLE_DEEP_UMBER` harness fixture is used only by AC-7.

## Phase 5 — Out-of-gamut (ENGINE-5)

- **Kind:** behavior
- **Target AC:** AC-9 (out-of-gamut identified without a false recipe)
- **Depends on:** ENGINE-2, **ITEST-5 (retarget) + G-6 (fresh review)** · **Blocks:** ENGINE-6
- **Files:** `lib/recipes/engine/subtractive_engine.dart` (**serial**).
- **Tasks:**
  1. When the best achievable recipe's `deltaE00` exceeds the gamut threshold (D-10 / G-4), mark the result `outOfGamut` and present the nearest mix labelled *as nearest*, never as a match (no match verdict on it).
  2. Un-pend AC-9; unit-test the threshold boundary (an in-gamut target is not flagged; an unreachable one is, and still returns a nearest).
- **Exit criteria:** AC-9 green; default suite green; unit gate + 100% coverage touched.
- **Acceptance gate:** un-pend AC-9; suite green (`TestAC09_*` + earlier); grade gate passed.

### Result

Out-of-gamut marking landed; AC-9 un-pended and green end-to-end. The feature's **last behaviour
phase** — all 12 ACs are now coded and un-pended.

- **Engine** (`subtractive_engine.dart`): `inverse` computes `bestDeltaE00` = the **minimum** ΔE00 over
  all candidates (not `ranked.first`, which the D-8 tie-break can set to a marginally-farther *cleaner*
  mix); when it exceeds `opts.gamutThreshold` (5.0, D-10) every returned recipe is flagged via the new
  `Recipe.asOutOfGamut()` (`mixing_engine.dart`) — the nearest possible, never a claimed match. The verdict
  band is unchanged (at ΔE00 > 5 it already reads "close"/"in the ballpark"/"far off", never "very close"),
  so the flag is the honest signal, not a rewritten verdict.
- **State / UI**: `RecipeState.outOfGamut` (derived getter, mirrors `hasRecipes`) drives `GamutBanner`,
  which renders "OUT OF GAMUT" (with a screen-reader semantics label) when out of gamut and collapses to
  its keyed anchor otherwise; `_RecipeCard` adds "Nearest possible — not an exact match" when the recipe is
  out of gamut.
- **Un-pended** AC-9 (row deleted in `bs04/pending.dart`; added to `recipes_test.dart`'s `unpended` set —
  all 12 now un-pended, `pendingACs` empty).
- **Harness fix (recorded):** `givenRecipes` now resets the tree (`pumpWidget(SizedBox)` + `pump()`) before
  each app pump. AC-9 is the only AC test that opens the app twice (out-of-gamut target, then in-gamut
  control); `RecipesHomeScreen._controller` is `late final`, so the 2nd pump reused the 1st controller and
  the control saw the turquoise banner. Invisible at the shell baseline (banner always hidden). Fail-closed
  (without it the control *fails*, never spuriously passes); no AC assertion weakened — graded a legitimate
  isolation fix.
- **Changed unit assertion (recorded):** `subtractive_engine_test.dart`'s AC-3/AC-4 property test asserted
  `_target.outOfGamut isFalse`; the pre-retarget `_target` (a\* −8.65) is genuinely out of gamut under the
  real engine (best ΔE00 ≈ 9.31 > 5), so it now asserts `isTrue`. The in-gamut path + threshold-tracking are
  covered by the new out-of-gamut unit group (reachable olive; a threshold-driven control proving the
  boundary is `MixOptions.gamutThreshold`, not a constant).
- **Gates:** `flutter analyze` clean; **unit 579 green** (+9: engine out-of-gamut group ×3, `asOutOfGamut`
  copier, state getter, banner out/in-gamut ×2, card label + control ×2); **100% line coverage on all 16
  touched files** (`coverage_gate.dart main` PASS); **recipes acceptance suite green** under the verify lock
  (`-d 5AB9D06D…`: +24, every AC incl. `TestAC09_*`, nothing pending).
- **Grade gate:** an independent grader (fresh context) graded the full un-pended suite **12×A, 0×B** — AC-9
  **full A** (in-gamut control present, nothing deferred); the harness reset judged a legitimate isolation
  fix; no neighbour weakened (the flag is applied after ranking/topK, so AC-4/5/6/7/8/10 are untouched).
  Grid § *ENGINE-5 re-grade*.
- **Fix passes: 1/3** — the first integration run failed only on AC-9's in-gamut control (the stale-controller
  harness flaw); the `givenRecipes` reset fixed it. The engine, state and UI passed on the first run.
- **Tokens / Time:** 11,054,873 · 21m 45s.

### Checkpoint / Handoff

- **Frozen for SIGNOFF-1:**
  - `inverse` flags `Recipe.outOfGamut` on every returned recipe when `min ΔE00 > opts.gamutThreshold`
    (D-10), via `asOutOfGamut()`; `RecipeState.outOfGamut` = `recipes.isNotEmpty && recipes.first.outOfGamut`;
    `GamutBanner` renders `GamutBanner.markerText` ('OUT OF GAMUT'); `_RecipeCard` shows the
    nearest-not-a-match label. Verdict, ordering, trace, muddying and wet/dry are unchanged.
  - **All 12 ACs are coded, un-pended and green; `pendingACs` is empty.** No known gaps.
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under
  the lock: `$C with-lock bs-04-mixing-recipes <PHASE> --wait 900 -- bash -c "export PATH=…; cd <repo> &&
  flutter test integration_test/recipes_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685"`. **SIGNOFF-1 runs
  the full cross-feature regression** (every feature's acceptance suite).
- **Next phase:** **SIGNOFF-1** — the sign-off packet + summary page + human approval. No behaviour phases
  remain.

## Phase 6 — Wet/dry transform (ENGINE-6)

- **Kind:** behavior
- **Target AC:** AC-10 (view the predicted dry colour)
- **Depends on:** ENGINE-2 · **Blocks:** SIGNOFF-1
- **Files:** `lib/recipes/engine/subtractive_engine.dart` (`forward(..., {dry})`, per-medium drying transform) (**serial**); the E24 toggle wiring in the controller / SCREEN region is coordinated with RECIPE/SCREEN.
- **Tasks:**
  1. A per-medium wet→dry transform in `forward` (`dry: true`): oil shifts less than acrylic (D-11); the toggle re-predicts the recipe's colour.
  2. Un-pend AC-10; unit-test that the dry prediction differs from wet in the drying direction and is a pure function of the medium + wet prediction.
- **Exit criteria:** AC-10 green; default suite green; unit gate + 100% coverage touched.
- **Acceptance gate:** un-pend AC-10; suite green (`TestAC10_*` + earlier); grade gate passed.

### Result

Per-medium wet→dry transform landed; AC-10 un-pended and green end-to-end.

- **Engine** (`subtractive_engine.dart`): `forward(parts, dry: true)` now returns the wet mix shifted by
  `_dryPrediction(wet, medium)` — L\*/a\*/b\* scaled by `(1 − shift)` (darker + slightly muted), a pure
  function of the wet prediction and the medium. `_acrylicDryingShift` = 0.04, `_oilDryingShift` = 0.015
  (oil shifts far less on its first-shot dry, D-11). `_singleMedium` rejects a mixed-medium dry mix (recipes
  never span media). Wet `forward` and `inverse` unchanged.
- **Re-render seam** (`mixing_engine.dart`): `Recipe.withPredictedColor` copies a recipe with only its
  predicted colour replaced — parts, ΔE00, verdict and flags unchanged.
- **Controller** (`recipe_controller.dart`): `setMode(mode)` re-predicts every recipe via
  `mixingEngine.forward(partsByVolume, dry:)` (the controller computes no mixing math itself, D-6) and emits
  the new mode; reversible — toggling back to wet reproduces the wet colour exactly.
- **Wiring** (`controls_region.dart`): the E24 `SegmentedButton`'s `onSelectionChanged` drives
  `controller.setMode(selection.first)` (was inert/null).
- **Un-pended** AC-10 (row deleted in `bs04/pending.dart`; added to `recipes_test.dart`'s `unpended` set).
- **AC-10 augmentation (made, this phase):** the red-baseline test asserted only that the dry prediction
  *differs* from wet. Strengthened to assert the **drying direction** — `dry.lightness < wet.lightness` and
  `chroma(dry) < chroma(wet)` — so a sign-flipped shift fails. Per-medium magnitude (oil < acrylic) is
  covered decisively at the unit level. ITEST *Test augmentations* row added (✅ Closed).
- **Gates:** `flutter analyze` clean; **unit 558 green** (+7 over 551); **100% line coverage on all touched
  files** (`coverage_gate.dart main` PASS); **recipes acceptance suite green** under the verify lock
  (`-d 5AB9D06D…`: `TestAC10_*` + AC-1..AC-4, AC-7, AC-8 run and pass; the 5 later-phase ACs skip).
- **Grade gate:** an independent grader (fresh context) re-graded **AC-10 A** against the implemented
  behaviour (upgraded from A-limited once the drying-direction augmentation was made); **0×B**. Grid
  § *ENGINE-6 behaviour re-grade*.
- **Fix passes: 0/3** — analyze, unit, coverage and the acceptance suite all passed first run; the
  A-limited→A augmentation was a strengthening, not a gate failure.
- **G-5 untouched** (ENGINE-6 does not bear on reachability; ENGINE-3/ENGINE-5 remain blocked).
- **Tokens / Time:** 12,666,200 · 18m 55s.

### Checkpoint / Handoff

- **Frozen for SIGNOFF-1 / RECIPE / SCREEN:**
  - `SubtractiveMixingEngine.forward(parts, {dry})`: `dry: true` returns the per-medium dried colour
    (`_dryPrediction`); a mixed-medium mix throws when `dry`. The drying shifts (acrylic 0.04, oil 0.015) are
    internal constants; the exact dry L/C/h are illustrative (G-4) — the asserted property is darker/muted,
    oil < acrylic.
  - `Recipe.withPredictedColor` is the re-render copy used by the toggle; `RecipeController.setMode(mode)`
    re-predicts all recipes through it and emits the mode, reversibly. `RecipeListRegion` already renders
    `predictedColor`, so it shows the dry colour after the toggle with no further change.
  - `ControlsRegion` E24 toggle is wired (single-select; the callback set holds exactly the chosen mode).
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under
  the lock: `$C with-lock bs-04-mixing-recipes <PHASE> --wait 900 -- bash -c "export PATH=…; cd <repo> &&
  flutter test integration_test/recipes_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685"`.
- **Next phase:** **RECIPE-4** (AC-11/AC-12 speak — file-disjoint from the ENGINE phases) is startable now.
  **G-5 still blocks ENGINE-3 (AC-5) and ENGINE-5 (AC-9 in-gamut control).** After G-5: ENGINE-3, ENGINE-5;
  then SIGNOFF-1 (needs all ACs or a recorded gap).
- **Known gaps:** `verdict` null (ENGINE-3), `outOfGamut` false (ENGINE-5) still outstanding. The const-ctor
  coverage quirk (Known flakes) applies to the new `withPredictedColor` path — covered by a direct unit test.
