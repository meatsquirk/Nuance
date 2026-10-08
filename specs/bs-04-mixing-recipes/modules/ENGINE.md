# Module ENGINE — the mixing engine

**Status:** Not started
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
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-3, AC-4 | ⬜ Todo | | |
| 3 | behavior | AC-5, AC-6 | ⬜ Todo | | |
| 4 | behavior | AC-7, AC-8 | ⬜ Todo | | |
| 5 | behavior | AC-9 | ⬜ Todo | | |
| 6 | behavior | AC-10 | ⬜ Todo | | |

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

- **G-4 (spec-data / engine reconciliation — spec author)** blocks ENGINE-2..6: confirm the pinned predicted
  colours are illustrative (ACs assert behavioural properties, D-13), the v1 subtractive forward approach
  (D-2), the gamut threshold (D-10) and the ~2% trace threshold (D-12). Until resolved, ENGINE behaviour
  phases code the behaviour but pin no spec literal.

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

## Phase 3 — ΔE00 + verdict + prefer fewer paints (ENGINE-3)

- **Kind:** behavior
- **Target AC:** AC-5 (small ΔE + plain verdict "very close"), AC-6 (prefer fewer paints)
- **Depends on:** ENGINE-2 · **Blocks:** ENGINE-4
- **Files:** `lib/recipes/engine/subtractive_engine.dart` (**serial** with ENGINE-2/4/5/6).
- **Tasks:**
  1. Per-recipe `deltaE00` (already the solve metric) + a plain `verdict` band reusing `_verdictBand`'s pattern, adding a "very close" band for small ΔE (D-7).
  2. Ordering: ascending ΔE, tie-broken toward fewer paints / lower added chroma (D-8), so a cleaner 2-paint mix ranks above a muddier 4-paint at similar ΔE.
  3. Un-pend AC-5, AC-6; **augment `TestAC05`** with a farther recipe reading a worse band (verdict tracks distance); unit-test the bands + ordering (incl. the fewer-paints tie-break).
- **Exit criteria:** AC-5/AC-6 green; default suite green; unit gate + 100% coverage touched.
- **Acceptance gate:** un-pend AC-5, AC-6; suite green (`TestAC05_*`, `TestAC06_*` + earlier); TestAC05 augmentation made; grade gate passed.
- **Augments:** `TestAC05`: add a farther recipe asserting a **different** (worse) verdict band.

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

## Phase 5 — Out-of-gamut (ENGINE-5)

- **Kind:** behavior
- **Target AC:** AC-9 (out-of-gamut identified without a false recipe)
- **Depends on:** ENGINE-2 · **Blocks:** ENGINE-6
- **Files:** `lib/recipes/engine/subtractive_engine.dart` (**serial**).
- **Tasks:**
  1. When the best achievable recipe's `deltaE00` exceeds the gamut threshold (D-10 / G-4), mark the result `outOfGamut` and present the nearest mix labelled *as nearest*, never as a match (no match verdict on it).
  2. Un-pend AC-9; unit-test the threshold boundary (an in-gamut target is not flagged; an unreachable one is, and still returns a nearest).
- **Exit criteria:** AC-9 green; default suite green; unit gate + 100% coverage touched.
- **Acceptance gate:** un-pend AC-9; suite green (`TestAC09_*` + earlier); grade gate passed.

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
