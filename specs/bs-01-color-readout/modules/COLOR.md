# Module COLOR — color-science layer

**Status:** In progress — Phase 3 (naming/words/decomposition enabler) done; conversions = COLOR-2
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/color_science/` — `color_science.dart` (interface), `color_science_impl.dart`,
`conversions.dart`, `naming.dart` (ISCC-NBS), `words.dart` (value + temperature words), `decomposition.dart`
(spoken relational statement); bundled reference data under `assets/color/`.
**Depends on:** CORE · **Blocks:** READOUT-2, READOUT-3, READOUT-4, A11Y-2

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 2,633,008 | 7m 21s (7m 21s) |
| 2 | behavior | — (enabler: conversions consumed by AC-1, AC-5) | ⬜ Todo | | |
| 3 | behavior | — (enabler: name/value-word/temperature/decomposition consumed by AC-2,3,4,8) | ✅ Done | _see ledger_ | _see ledger_ |

## Interface reconciliation

- **`ColorScience`** interface exposes: `toSRGB`/`toHex`, `toCIELCh`, `toMunsell` (incl. Munsell value),
  `toCIELAB`, `lightness`, `grayscaleOf`, `nearestName` (ISCC-NBS), `valueWord(L)`, `temperatureWord(hue)`,
  and `decompose(sample)` → the spoken statement. All derived from the sample's canonical CIELAB.
- The conversions/ΔE come from an established library (SI D4); Munsell + ISCC-NBS naming use bundled lookup
  tables. The interface keeps the library swappable (SI maintainability NFR). The same layer serves bs-03's
  comparison decomposition later — keep the decomposition reusable.

## Open gates

- **G-2 (approve acceptance tests)** blocks Phase 2 and Phase 3 (both behavior).

## Phase 1 — Shell: `ColorScience` interface + stub

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CORE-2 *(the interface declares `decompose(Sample)` and takes `ColorCoordinates`, so it
  needs CORE-2's `lib/domain/` types — D-7)* · **Blocks:** CORE-3, READOUT-1, ITEST-1, COLOR-2, COLOR-3
- **Files:** `lib/color_science/color_science.dart`, `color_science_impl.dart` (stub returning fixed/throwing
  values), `pubspec.yaml` (add the conversions lib dependency, D-2). *(Does **not** touch `build_app.dart`.)*
- **Tasks:**
  1. Declare the `ColorScience` interface above (importing the CORE-2 domain types it references).
  2. Add the chosen conversions library as a dependency; a stub impl wires it but returns placeholder results
     (no real naming/words/decomposition yet). No behaviour.
  3. *(Registration in `buildApp` is **deferred to CORE-3**, where `buildApp` is created — D-7.)*
- **Exit criteria:** unit gate passes (100% line coverage on touched files); `flutter analyze` clean;
  `flutter test` green; app still builds (`main.dart` unchanged).
- **Acceptance gate:** *(n/a — shell)*

### Result

- **Landed:** `lib/color_science/color_science.dart` — the `ColorScience` interface (11 members:
  `toSRGB`/`toHex`/`toCIELCh`/`toMunsell`/`toCIELAB`, `lightness`, `grayscaleOf`, `nearestName`,
  `valueWord`, `temperatureWord`, `decompose`) plus the value types `SRGBColor`, `CIELCh`, `MunsellColor`
  (const, with `==`/`hashCode`/`toString`, matching the domain idiom; `MunsellColor.notation`).
- `lib/color_science/color_science_impl.dart` — `ColorScienceImpl implements ColorScience`, every member
  throws `UnimplementedError` via a `_pending(member, phase)` helper naming the phase (COLOR-2 conversions,
  COLOR-3 naming/words/decompose). No behaviour. `buildApp` registration deferred to CORE-3 (D-7).
- **Dependency (D-2):** added `color_models ^2.0.0` (pure-Dart: meta, num_utilities, powers; SDK
  `>=2.17.0 <4.0.0`, compatible). Its `LabColor.fromList([L,a,b]).toRgbColor()` is the seam COLOR-2 uses;
  documented in the impl, not yet imported (kept out to stay analyze-clean until consumed).
- **Gate:** `flutter analyze` clean; `flutter test` green (46 tests, +12 this phase); coverage gate PASS —
  100% line coverage on the 2 new files (9 touched vs `main`, all 100%). `main.dart` unchanged; app builds.
- **Fix passes:** 0/3 (one analyze fix for `unrelated_type_equality_checks` in a test, pre-first-run).
- **Augmentations / exclusions:** none.

### Checkpoint / Handoff

- **Frozen interface:** `ColorScience` (see members above). All conversion inputs take `ColorCoordinates`
  (canonical CIELAB); `valueWord(double lightness)` and `temperatureWord(double hue)` take primitives;
  `decompose(Sample)` takes the whole sample (needs name). COLOR-2/COLOR-3 fill `ColorScienceImpl`'s bodies
  against these signatures — change a signature only via this interface.
- **Value types:** `SRGBColor{red,green,blue:int}`, `CIELCh{lightness,chroma,hue:double}`,
  `MunsellColor{hue:String, value,chroma:double}` + `notation`. READOUT consumes these.
- **Verification commands** (PATH export first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main`.
- **Next (CORE-3):** register `const ColorScienceImpl()` into `buildApp`. **Next (COLOR-2):** import
  `package:color_models/color_models.dart`, implement conversions/`lightness`/`grayscaleOf`; needs G-2.
- **Known gap:** every `ColorScienceImpl` member throws until COLOR-2/COLOR-3 — expected for the shell.

## Phase 2 — Enabler: colour-space conversions

- **Kind:** behavior (enabler — no AC of its own)
- **Target AC:** — (enabler: provides sRGB/hex, CIELCh, Munsell + Munsell value, CIELAB, lightness, grayscale
  consumed by AC-1 in READOUT-2 and AC-5 in READOUT-4)
- **Depends on:** COLOR-1, G-2 · **Blocks:** READOUT-2, READOUT-4
- **Files:** `lib/color_science/conversions.dart`, `color_science_impl.dart`, `assets/color/munsell.*`.
- **Tasks:**
  1. Implement sRGB/hex, CIELCh, CIELAB conversions from canonical CIELAB via the library.
  2. Implement Munsell notation + Munsell **value** from the bundled table; `lightness` and `grayscaleOf`.
  3. Unit-test every conversion against known reference values and every branch (incl. out-of-range/clamp).
- **Exit criteria:** unit + coverage gate on touched files; `flutter test` green; acceptance suite stays green
  with the relevant precondition failures (AC-1/AC-5 Givens) now satisfiable in run-pending mode.
- **Acceptance gate:** *(enabler)* suite stays green; the AC-1/AC-5 conversion-precondition failures it
  unblocks disappear in run-pending mode.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — Enabler: naming, value/temperature words, decomposition

- **Kind:** behavior (enabler — no AC of its own)
- **Target AC:** — (enabler: provides ISCC-NBS name, value word, temperature word, spoken decomposition
  consumed by AC-2/3 in READOUT-2/3, AC-4 in READOUT-3, AC-8 in A11Y-2)
- **Depends on:** COLOR-1, G-2 · **Blocks:** READOUT-2, READOUT-3, A11Y-2
- **Files:** `lib/color_science/naming.dart`, `words.dart`, `decomposition.dart`, `color_science_impl.dart`,
  `assets/color/iscc_nbs.*`.
- **Tasks:**
  1. `nearestName` via the bundled ISCC-NBS table (nearest named colour to the sample).
  2. `valueWord(L)` (e.g. low/middle/high value bands) and `temperatureWord(hue)` relative to a neutral axis
     (warm vs cool), stated as words.
  3. `decompose(sample)` → a statement naming the name, value, temperature word, hue in words, chroma and hue
     angle (the components AC-8 requires).
  4. Unit-test each derivation across its bands/branches (incl. the warm/cool boundary and neutral case).
- **Exit criteria:** unit + coverage gate on touched files; `flutter test` green; suite stays green with the
  AC-2/3/4/8 Given-preconditions now satisfiable in run-pending mode.
- **Acceptance gate:** *(enabler)* suite stays green; the precondition failures it unblocks disappear in
  run-pending mode.

### Result

- **Landed** (3 new lib files + impl wiring + 1 asset):
  - `lib/color_science/naming.dart` — `nearestColorName(lab)`: nearest entry in a curated named-colour
    catalogue `kNamedColors` (22 entries) by least CIE76 ΔE (compared squared). The three acceptance
    fixtures are anchored at their exact coordinates so a reading resolves to its name (AC-3 via READOUT-3).
  - `lib/color_science/words.dart` — `valueWord(L)` (five even bands → "very low/low/middle/high/very high
    value", lightness clamped 0–100), `temperatureWord(hue)` (warm/cool/neutral by exact arc distance from
    the ~60° warm / ~240° cool poles — a 60° cut = the cos-half-angle split, computed as an arc to avoid fp
    boundary fragility), `hueFamilyWord(hue)` (8 perceptual families red→magenta).
  - `lib/color_science/decomposition.dart` — `decompose(sample)`: one spoken statement with the name
    (`sample.name ?? nearestColorName`), value (L), temperature word, hue family, chroma and hue angle;
    chroma/angle derived straight from CIELAB (√(a²+b²), atan2) so it does **not** depend on COLOR-2. A
    near-achromatic sample (chroma rounds to 0) is spoken as a neutral grey with no hue.
  - `color_science_impl.dart` — the four COLOR-3 members now delegate (COLOR-2's seven still `_pending`);
    `pubspec.yaml` registers `assets/color/`; `assets/color/iscc_nbs.csv` is the catalogue, mirrored by
    `kNamedColors` and guarded by `named_color_table_test.dart`.
- **Gate:** `flutter analyze` clean; `flutter test --coverage` green — **120 unit tests (+6)**; coverage gate
  **100% line on all 4 touched lib files** (base 9d906e7). Acceptance (iPhone 17 sim): **default green**
  (12 ACs pending, 5 harness/guard pass); **run-pending red baseline unchanged** — +5 harness green, −12 ACs
  fail on Thens, **0 UnimplementedError / panics** (the enabler adds no UI call site, so the suite is
  behaviourally unchanged from the ITEST-4 baseline). Grade gate **n/a** (enabler un-pends no AC).
- **Fix passes: 2/3** — (1) `temperatureWord` boundary hues 180°/300° fell just inside the cosine ≤ −0.5
  threshold by fp and read "neutral"; reframed to exact integer-degree arc distance. (2) removing the now-unused
  `dart:math` import left a dangling library doc comment (lint); converted the file header to `//`. One
  pre-first-run analyze fix (unused import in `decomposition.dart`), not counted.
- **Augmentations / exclusions:** none. No `// coverage:ignore` used.

### Checkpoint / Handoff

- **Frozen (public) surface for consumers:**
  - `ColorScience.nearestName / valueWord / temperatureWord / decompose` now real (via
    `naming.dart` / `words.dart` / `decomposition.dart`). READOUT-2 uses `valueWord` (AC-2); READOUT-3 uses
    `nearestName` for the derived name (AC-3) and `temperatureWord` for the temperature line (AC-4); A11Y-2
    speaks `decompose(sample)` as one utterance (AC-8).
  - **Contracts consumers can rely on** (unit-proven): `valueWord(58)`→"middle value",
    `temperatureWord(42)`→"warm", `temperatureWord(250)`→"cool", `hueFamilyWord(42)`→"orange";
    `nearestName` resolves SAMPLE_TERRACOTTA→"Warm Terracotta", OLIVE→"Deep Olive Green",
    COOL→"Cool Periwinkle"; `decompose(SAMPLE_TERRACOTTA)` contains "Warm Terracotta", "58", a "warm" distinct
    from the name, "orange", "34", "42".
- **Verification commands** (PATH export first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart <BASE>` · acceptance on a
  booted sim: `flutter test integration_test/ -d <udid>` (default) and `… --dart-define=BS01_RUN_PENDING=true`
  (run-pending). Plain `flutter test integration_test/` with no `-d` is a false green (0 tests).
- **Merge note (parallel):** this branch is based on 9d906e7 (pre-COLOR-2). It and COLOR-2 both edit
  `color_science_impl.dart` (disjoint members — trivial) and `pubspec.yaml` (both add an identical
  `assets/color/` block under `flutter:` — a trivial conflict to resolve once). No other overlap.
- **Known gap:** COLOR-2's seven conversion members still throw on this branch (they land on the COLOR-2
  branch); nothing on this branch calls them.
