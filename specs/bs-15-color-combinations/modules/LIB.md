# Module LIB — Wada reference library

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `assets/combinations/sanzo_wada.json` (+ `pubspec.yaml` asset entry) · `lib/combinations/wada_color.dart` · `lib/combinations/color_combination.dart` · `lib/combinations/combination_library.dart` (interface + `CombinationSuggestion`) · `lib/combinations/asset_combination_library.dart` (v1 impl: loader + suggest/browse/search) · scaffold: branch, `integration_test/bs15/pending.dart`
**Depends on:** bs-01 `lib/compare/difference.dart` (`deltaE00`), `lib/domain/color_coordinates.dart` · **Blocks:** COMBO (needs the types + interface), ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ⬜ Next | | |
| 2 | shell | — | ⬜ Todo | | |
| 3 | behavior | AC-3, AC-4 | ⬜ Todo | | |
| 4 | behavior | AC-9, AC-10 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `WadaColor {String name; ColorCoordinates lab; String hex; int group}`;
  `ColorCombination {int id; int size; List<WadaColor> colours}`;
  `CombinationSuggestion {ColorCombination combination; double anchorDistance; WadaColor nearest}`;
  `abstract CombinationLibrary { List<CombinationSuggestion> suggestFor(ColorCoordinates anchor, {double maxDeltaE}); List<ColorCombination> browse(int size); List<ColorCombination> search(String query); List<ColorCombination> all(); List<WadaColor> colours(); }`.
- **Consumes:** the shipped `deltaE00(a,b)` (CIEDE2000) for ranking; `ColorCoordinates` as the colour atom.
- **Asset shape (D-2):** `sanzo_wada.json` = `{"groups":[["I","Reds"],…], "colours":[{"n","lab":[L,a,b],"hex","g"},…×159], "combinations":[[i,j],[i,j,k],…×348]}`, extracted from the catalogue's `DATA` block (its `l` array is `[L,a,b]`; combination arrays are 0-based colour indices). Licence/attribution string shipped in the JSON header and in `NOTICE`.
- **Reconciliation:** the catalogue stores colours only as CMYK→CIELAB/hex; bs-15 ships the CIELAB (canonical) and hex, drops CMYK (print-only, unused). Combination arrays carry **book order**, preserved as listing order.

## Open gates

- **G-4** (threshold + provenance wording) blocks **LIB-3** (the `maxDeltaE` inclusion threshold for `suggestFor`). LIB-2/LIB-1 are unblocked.

## Phase 1 — Scaffold (LIB-1)

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1) · **Blocks:** LIB-2
- **Files:** branch `feat/bs-15-color-combinations` from `main` @ `ac3bd09`; `integration_test/bs15/pending.dart` (12-AC pending runner mirroring `bs04/pending.dart`); no product code
- **Tasks:**
  1. Branch `feat/bs-15-color-combinations` from `main` @ `ac3bd09`.
  2. Record the baseline: `flutter analyze`, `flutter test` (unit) and the existing `integration_test` all green; note counts.
  3. Confirm the coverage gate (`tool/coverage_gate.dart`) passes on the clean tree and **fails on a planted uncovered line** (prove both ways).
  4. Add `integration_test/bs15/pending.dart` + the `BS15_RUN_PENDING` define plumbing (one pending entry per AC-1..12), mirroring `bs04/pending.dart`.
- **Exit criteria:** baseline recorded (unit + integ counts); coverage gate proven clean-pass / planted-fail; BS15 pending runner present; no `lib/` change.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — Shell: dataset, types, library interface (LIB-2)

- **Kind:** shell
- **Target AC:** — (read surface for the suggest/browse/search the tests observe)
- **Depends on:** LIB-1 · **Blocks:** COMBO-1, ITEST-1
- **Files:** `assets/combinations/sanzo_wada.json` (+ `pubspec.yaml`), `lib/combinations/wada_color.dart`, `lib/combinations/color_combination.dart`, `lib/combinations/combination_library.dart`, `lib/combinations/asset_combination_library.dart` (stub), `lib/app/build_app.dart` (register a `CombinationLibrary` dependency)
- **Tasks:**
  1. Extract the catalogue `DATA` block → `assets/combinations/sanzo_wada.json` (D-2 shape); add the asset to `pubspec.yaml`; ship the MIT licence/attribution.
  2. Define `WadaColor`, `ColorCombination`, `CombinationSuggestion` (value-equal, `const`-friendly).
  3. Define the `CombinationLibrary` interface (suggest/browse/search/all/colours).
  4. `AssetCombinationLibrary`: load + parse the asset into `WadaColor`/`ColorCombination` (resolving combination index lists to colours); suggest/browse/search **throw `UnimplementedError`** (behaviour is LIB-3/LIB-4) but `all()`/`colours()` return the parsed data.
  5. Register one `CombinationLibrary` in `AppDependencies` (real `AssetCombinationLibrary`; tests inject a fixture).
- **Exit criteria:** unit gate passes; existing suites stay green; `all()` returns 348 combinations / `colours()` 159 from the real asset; behaviour methods pend cleanly; app still builds.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — Behaviour: bounded suggest + ranking (LIB-3)

- **Kind:** behavior
- **Target AC:** AC-3 (bounded to the dictionary), AC-4 (rank by nearest-colour ΔE00)
- **Depends on:** ITEST-4 (G-2), LIB-2 · **Blocks:** COMBO-2
- **Files:** `lib/combinations/asset_combination_library.dart` (`suggestFor`)
- **Tasks:**
  1. Implement `suggestFor(anchor, {maxDeltaE})`: for each shipped combination compute `min deltaE00(colour.lab, anchor)`; keep combinations whose nearest colour ≤ `maxDeltaE` (G-4 threshold); return `CombinationSuggestion`s sorted ascending by that distance, each carrying its `nearest`.
  2. Draw **only** from the shipped combinations (AC-3) — no synthesis.
  3. Unit-test: ranking order, the bound, nearest-colour selection, ties, empty result when nothing is near.
- **Exit criteria:** unit + coverage on touched files; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-3, AC-4; `combinations_test.dart` green (`TestAC03_BoundedToDictionary`, `TestAC04_RankByCloseness`).
- **Augments:** none (fixture carries both comparator combinations).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — Behaviour: browse + search (LIB-4)

- **Kind:** behavior
- **Target AC:** AC-9 (browse by size), AC-10 (search a colour → its combinations)
- **Depends on:** COMBO-2 (a rendered library surface) · **Blocks:** SIGNOFF-1
- **Files:** `lib/combinations/asset_combination_library.dart` (`browse`, `search`)
- **Tasks:**
  1. `browse(size)`: the shipped combinations of exactly `size` colours (2/3/4), in book order.
  2. `search(query)`: match a colour by name (case-insensitive) or hue word, return the combinations whose colours include it; expose the matched colour.
  3. Unit-test: size partition counts (120/120/108), search hit/miss, name + hue matching.
- **Exit criteria:** unit + coverage on touched files; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-9, AC-10; `combinations_test.dart` green (`TestAC09_BrowseBySize`, `TestAC10_SearchColour`).
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
