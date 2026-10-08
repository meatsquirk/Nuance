# Module MIX — Mixing engine (forward) + color-science

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/recipes/mixing_engine.dart` (interface + `Paint`/`Recipe`/`MixOptions`/`Medium` types), `lib/recipes/spectral_engine.dart` (Spectral.js KM forward), `lib/recipes/verdict.dart` (recipe verdict bands), `lib/recipes/wet_dry.dart` (per-medium transform), `lib/color_science/delta_e.dart` + a `deltaE00` method on the `ColorScience` interface
**Depends on:** bs-01 color-science (`labToCielch`, `toSRGB`), RECIPES-1 (scaffold) · **Blocks:** SOLVER (forward), SCREEN/RECIPES (recipe types)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 (MIX-1) | shell | — | ⬜ Todo | | |
| 2 (MIX-2) | behavior | AC-5 | ⬜ Todo | | |
| 3 (MIX-3) | behavior | AC-10 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `MixingEngine` — `Color forward(Map<String,double> mix)` / a `Recipe forwardRecipe(...)`,
  `List<Recipe> inverse(target, palette, MixOptions)` (SOLVER implements the inverse body on the same
  class), `Spectrum reflectanceOf(mix)` for debugging. `Paint { id, name, medium, Spectrum k, s, opacity,
  provenance }`; `Recipe { medium, Map<String,double> parts, ColorCoordinates predicted, double deltaE00,
  String verdict, bool muddying, bool outOfGamut, Provenance provenance }`. `deltaE00(a, b)` on
  `ColorScience` (D-5). `WetDryTransform` per `Medium` (D-9).
- **Consumes:** bs-01 `ColorScience` (LCh/sRGB conversions), `ColorCoordinates`, `Provenance`.
- **Reconciliation:** ΔE00 is net-new in the shared color-science layer; bs-03's compare-local `_deltaE00`
  is unmerged and not reused (D-5). The `MixingEngine` interface keeps the measured-pigment KM engine a
  later drop-in (SI D3).

## Open gates

- **G-4** blocks MIX-1 (the `Paint` type's shipped `K`,`S` data) and MIX-2 (forward needs real `K`,`S`).
- **G-3** blocks MIX-2 (AC-5's pinned ΔE00) and MIX-3 (AC-10's pinned wet→dry values).

## Phase 1 (MIX-1) — Engine interface + types + forward/color stubs

- **Kind:** shell
- **Target AC:** —
- **Depends on:** RECIPES-1 · **Blocks:** SOLVER-1, RECIPES-2, MIX-2
- **Files:** `lib/recipes/mixing_engine.dart`, `lib/recipes/spectral_engine.dart`,
  `lib/recipes/verdict.dart`, `lib/recipes/wet_dry.dart`, `lib/color_science/delta_e.dart`, and the
  `deltaE00` signature on `lib/color_science/color_science.dart` (+ impl stub)
- **Tasks:**
  1. Define `Medium`, `Paint`, `Recipe`, `MixOptions` value types (immutable, `==`/`hashCode`/`toString`).
  2. Declare the `MixingEngine` interface (forward, inverse, reflectanceOf) and a `SpectralEngine`
     implementing it with **stubbed** bodies (forward returns a placeholder, inverse returns `[]`).
  3. Add `deltaE00(ColorCoordinates a, ColorCoordinates b)` to the `ColorScience` interface + a stub in
     `color_science_impl.dart`; create `lib/color_science/delta_e.dart` with the pure `deltaE00` stub.
  4. Declare `recipeVerdict(double deltaE00)` (verdict.dart) and `WetDryTransform`/`wetDryFor(Medium)`
     (wet_dry.dart) as stubs.
  5. Keep the `Paint` K/S fields shaped for G-4's data (placeholder constants until G-4 resolves).
- **Exit criteria:** `flutter analyze` clean; the types compile and are referenced nowhere behaviorally;
  unit suite green; 100% coverage on the touched files (stubs exercised by trivial unit tests); the existing
  integration suite unchanged.
- **Acceptance gate:** *(n/a — shell)*

## Phase 2 (MIX-2) — Forward KM + ΔE00 + verdict bands (AC-5)

- **Kind:** behavior
- **Target AC:** AC-5 (full)
- **Depends on:** MIX-1, RECIPES-3 (a target set for the shown recipe); **needs G-3, G-4** · **Blocks:** SOLVER-2, MIX-3
- **Files:** `lib/recipes/spectral_engine.dart` (real forward), `lib/color_science/delta_e.dart` +
  `color_science_impl.dart` (real `deltaE00`), `lib/recipes/verdict.dart` (real bands)
- **Tasks:**
  1. Implement the Spectral.js forward: RGB→38-bin reflectance (LHTSS), mix in K/S over the paints' `K`,`S`,
     reflectance→XYZ→sRGB with OKLab gamut mapping; expose the predicted `ColorCoordinates`.
  2. Implement canonical CIEDE2000 `deltaE00` in the color-science layer (verify against the published
     Sharma et al. worked examples).
  3. Implement `recipeVerdict` bands over ΔE00 (e.g. "very close" at small ΔE00; record the exact
     boundaries in the Result). Pin AC-5's ΔE00 to the engine-computed value for `RECIPE_YO_IB` (G-3).
- **Exit criteria:** forward is deterministic; ΔE00 matches reference examples in unit tests.
- **Acceptance gate:** un-pend AC-5; `flutter test integration_test/recipes_test.dart` green with
  `TestAC05_CloseVerdict` passing (AC-1/AC-2 already un-pended by RECIPES-3); later ACs still pending.
- **Augments:** `TestAC05_CloseVerdict`: add the verdict-discrimination control — a clearly-distant recipe
  for the same target reads a **different** verdict band (so a constant verdict fails).

## Phase 3 (MIX-3) — Wet/dry transform + toggle (AC-10)

- **Kind:** behavior
- **Target AC:** AC-10 (full)
- **Depends on:** MIX-2 (forward predicts the wet colour), SCREEN-1 (the E24 toggle shell); **needs G-3** · **Blocks:** SIGNOFF-1
- **Files:** `lib/recipes/wet_dry.dart` (real per-medium transform), `lib/recipes/wet_dry_toggle.dart`
  (E24 wiring into the controller/screen)
- **Tasks:**
  1. Implement the per-medium wet→dry transform (oil: the documented 7-day offset, D-9); apply it to a
     recipe's predicted colour when the mode is dry.
  2. Wire the E24 toggle to the controller's wet/dry mode; the read endpoint exposes the mode and the
     currently-shown (wet or dry) predicted colour.
  3. Pin AC-10's dry value to `wetDryFor(oil)` applied to the wet fixture (G-3).
- **Exit criteria:** switching the mode changes the shown predicted colour by exactly the transform; wet is
  the default.
- **Acceptance gate:** un-pend AC-10; suite green with `TestAC10_WetDry` passing; later/other ACs as pending.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
