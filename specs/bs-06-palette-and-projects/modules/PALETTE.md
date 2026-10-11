# Module PALETTE — paints & palettes

**Status:** In progress — PALETTE-1 ✅ (shell), PALETTE-2 ✅ (AC-4), PALETTE-3 ✅ (AC-2/AC-3); PALETTE-4 (AC-5) startable next
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/domain/paint.dart` (schema extension — **bs-04-owned, coordinate**), `lib/recipes/palette_source.dart` (write-side on the existing seam — bs-04-owned), `lib/palette/` (PaletteController, read endpoint, dataset loader), `assets/paints/` (reviewed dataset asset)
**Depends on:** DATA (store) · **Blocks:** SCREEN (renders palette state), PALETTE-4 wires into RECIPE (bs-04 `RecipeController`)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 8,841,030 | 14m 46s |
| 2 | behavior | AC-4 | ✅ Done | 8,539,454 | 17m 29s |
| 3 | behavior | AC-2, AC-3 | ✅ Done | 7,967,376 | 26m 47s |
| 4 | behavior | AC-5 | ⬜ Todo | | |

## Interface reconciliation

- `Paint` gains `brand`, `line`, `provenance` (`ProvenanceTier`) **additively** with defaults (D-2); bs-04's `Paint` value-equality, solver maps and `FakeSpeech` AC-12 ("names the paint") must stay green — verify against the bs-04 suite after the schema change.
- Reuses the existing read-only `PaletteSource` seam, adding a persistent write-side implementation backed by DATA's store; the recipes solve path is untouched (D-1).
- AC-5 reuses bs-04 `RecipeController.selectPalette` + `_solve(…,palette)` (D-5) — PALETTE-4 only surfaces selection on the Palette screen and re-points the active palette.
- Reviewed dataset (D-3): a bundled read-only asset + loader; provenance of each dataset paint is preserved on add (AC-4).

## Open gates

- **G-4** blocks Phase 1 (reviewed-dataset shape & provenance defaults; DB package).
- **G-2** blocks Phases 2–4 (behavior).

## Phase 1 — Shell: schema, dataset, controller

- **Kind:** shell · **Target AC:** — · **Depends on:** DATA-2 (G-4) · **Blocks:** SCREEN-1, PALETTE-2
- **Files:** `lib/domain/paint.dart`, `lib/recipes/palette_source.dart`, `lib/palette/palette_controller.dart`, `lib/palette/paint_dataset.dart` (+ loader), `assets/paints/` + `pubspec.yaml` asset entry, `lib/palette/palette_read_endpoint.dart`
- **Tasks:**
  1. Extend `Paint` additively (brand/line/provenance, defaults); keep const value-equality; run the bs-04 suite to confirm green.
  2. Ship the reviewed paint dataset asset + a read-only loader (no free-hand values).
  3. `PaletteController` skeleton: holds palettes, `selectedPalette`, myPaints list; no behaviour yet (add/select are stubs).
  4. Persistent `PaletteSource` write-side stub backed by DATA's store; `PaletteReadEndpoint` (InheritedWidget, stable `endpointKey`, `.of(context)`) exposing palettes/selectedPalette/myPaints for tests.
- **Exit criteria:** unit gate passes on touched files; bs-04 acceptance suite still green after the `Paint` change; read endpoint exposes empty/default state.

### Result

- **Landed (shell, no AC):** `Paint` extended **additively** (`brand`, `line` default null; `provenance` `ProvenanceTier` default `measured` per G-4) — value-equality/hashCode/`toString` updated, every bs-04 call site unchanged. New `lib/palette/`: `paint_dataset.dart` (`parseReviewedPaints(String)` read-only CSV loader + `kReviewedPaints` const mirror of the bundled asset); `palette_controller.dart` (`PaletteController` `ChangeNotifier` — `palettes`/`selectedPalette`/`myPaints` reads, `selectPalette` state-setter, holds the reviewed dataset); `palette_read_endpoint.dart` (`PaletteReadEndpoint` InheritedWidget, `endpointKey` `palette-read-endpoint`, `.of`). `lib/recipes/palette_source.dart` gains `PersistentPaletteSource` (write-side over DATA's `PersistentStore`: `load`/`palettes`/`savePalette`, collection `palettes`) + private paint↔JSON mapping. New asset `assets/paints/reviewed_paints.csv` (8 reviewed W&N oils incl. Titanium White PW6 Measured + Ultramarine Blue) + `pubspec.yaml` `assets/paints/` entry.
- **Deviation from the literal task list (recorded):** Task 3 said "add/select are stubs". `selectPalette` is implemented as a plain active-palette state-setter (not AC behaviour — AC-5's solve wiring to `RecipeController.selectPalette` is PALETTE-4, D-5); `addPaintFromDataset` is **not** added here — it is AC-4 behaviour and lands in PALETTE-2 (whose file list already includes `palette_controller.dart`), wired to `PersistentPaletteSource.savePalette`. The persistent write-side is fully implemented + tested (not a bare stub) so the seam is real for PALETTE-2. No mixing/recipe code reopened.
- **Verification:** `flutter analyze` clean. `flutter test --coverage` → **647 unit/widget passing** (was 617; +30). Coverage gate vs `main`: **100%** on all 10 touched `lib/` files (`paint.dart`, `palette/*`, `recipes/palette_source.dart`, + DATA's files still-vs-main). bs-04 acceptance suite re-run on-sim (iPhone 17, under verify lock): **24 tests incl. all 12 ACs green** after the `Paint` change (interface-reconciliation requirement met).
- **Fix passes:** 2/3 — pass 1: `flutter analyze` flagged `prefer_initializing_formals` on the controller + a missing `ColorCoordinates` import in `paint_dataset_test.dart`; dropped the unused private `_source` field (compute from the param) and added the import. Pass 2 clean. (Both were test/lint fixes; the implementation was correct from the first run.)
- **Justified exclusions:** none on coverage. The bs-06 acceptance suite (`palette_test.dart`) is still all-pending (ITEST stage not started) — not this phase's gate.
- **Closed by:** unit + coverage gate pass; bs-04 suite green on-sim; read endpoint exposes empty/default state (tested).
- Tokens: see master ledger (PALETTE-1 row). **Phase total: 8,841,030 tokens, 14m 46s active.**

### Checkpoint / Handoff

- **Frozen interfaces:**
  - `Paint` now carries `brand`/`line` (`String?`, default null) and `provenance` (`ProvenanceTier`, default `measured`). Additive — a schema change beyond adding nullable/defaulted fields needs re-verifying the bs-04 suite.
  - `parseReviewedPaints(String csv)` → `List<Paint>` and `const kReviewedPaints` (lib/palette/paint_dataset.dart). CSV columns: `id,name,brand,line,medium,pigment_index,provenance,cielab_l,cielab_a,cielab_b`; `#`/blank/header lines skipped; empty brand/line/pigment → null; unknown medium/provenance throws. The const mirrors `assets/paints/reviewed_paints.csv`; `test/palette/reviewed_paint_dataset_test.dart` guards the two — keep them in the same order.
  - `PaletteController({required PaletteSource source, List<Paint> reviewedDataset = kReviewedPaints})`: `palettes`, `selectedPalette` (first palette, or null if empty), `myPaints` (the `'My paints'` palette's paints, or empty), `selectPalette(PaintPalette)` (notifies; no-op if unchanged), `reviewedDataset`. `static const myPaintsName = 'My paints'`.
  - `PaletteReadEndpoint` — `endpointKey = Key('palette-read-endpoint')`, `.of(context)`, exposes the live `PaletteController`.
  - `PersistentPaletteSource(PersistentStore)` — `static const collection = 'palettes'`; `Future<void> load()` (populate cache from store; **await before** the synchronous `palettes()` read), `List<PaintPalette> palettes()`, `Future<void> savePalette(PaintPalette)` (put keyed by name + reload). Paint↔JSON mapping is private to the file.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · bs-04 suite `flutter test integration_test/recipes_test.dart -d <booted-udid>` (under `coord.sh with-lock BS-06 <PHASE>`). Flutter SDK `/Users/matthew.quirk/development/flutter/bin`. Booted sim this session: iPhone 17 `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`.
- **Known gaps / deferred:**
  - **No production wiring yet.** `main.dart`/`buildApp` untouched: no Palette screen exists until SCREEN-1, so the real file-backed `DriftPersistentStore` + `FileSourcePhotoStore` injection (async main + `path_provider` + `sqlite3_flutter_libs` native libs) is **deferred to SCREEN-1**, where a screen first reads the store. This narrows PALETTE-1's blast radius and avoids a `main.dart`/`pubspec` merge conflict with the concurrent PROJECT-1 session. The DATA-2 handoff nominated PALETTE-1/PROJECT-1 for this; the authoritative PALETTE-1 task list and exit criteria did not require it. **SCREEN-1 owns it** (see master Next phase).
  - `addPaintFromDataset` not implemented (PALETTE-2, AC-4); `selectPalette` tracks local state only — PALETTE-4 adds the `RecipeController.selectPalette` wiring (AC-5, D-5).
- **Next phase should:** PROJECT-1 (∥, disjoint `lib/projects/`) is startable now; SCREEN-1 follows both shells and must do the deferred production store wiring. PALETTE-2→3→4 are all G-2-blocked (behavior).

## Phase 2 — AC-4 add paint from reviewed dataset

- **Kind:** behavior · **Target AC:** AC-4 (full) · **Depends on:** PALETTE-1, ITEST-4 (G-2) · **Blocks:** PALETTE-3
- **Files:** `lib/palette/palette_controller.dart`, `lib/palette/paint_dataset.dart`
- **Tasks:** implement add-paint-from-dataset: choosing a dataset paint adds it to the active palette with the dataset's provenance preserved and persists it.
- **Exit criteria:** unit gate; acceptance + grade gates below.
- **Acceptance gate:** un-pend AC-4; `palette_test.dart` green (`TestAC04_AddPaintFromDataset` + all earlier ACs).
- **Augments:** `TestAC02`: once paints can be added, AC-2's test builds its Given via this flow (precondition that named PALETTE-2 now resolves). *(Not owed — see Result: ITEST-2 seeded AC-2's Given directly, not through the add flow, so no AC-2 precondition names PALETTE-2; TestAC02's augmentation is owned by PALETTE-3.)*

### Result

- **Landed (AC-4 — full):** `PaletteController.addPaintFromDataset(Paint)` — appends the chosen reviewed-dataset paint to the "My paints" palette **exactly as the dataset holds it** (`paints: [...?current?.paints, paint]`, no per-field reconstruction, so provenance/pigment index/masstone are preserved), creating "My paints" if absent and keeping the active palette pointed at the updated instance when it was selected. Persists through `PersistentPaletteSource.savePalette` when the source can (production + acceptance wiring); an in-memory source (shell/unit tests) keeps the add in memory only. The E32 add control in `paint_list_region.dart` is wired (was inert): `onPressed` opens a reviewed-dataset picker (`showModalBottomSheet`, new `datasetPickerKey`) listing `controller.reviewedDataset` by name; tapping one returns that exact `Paint` and calls `addPaintFromDataset`; dismissing adds nothing.
- **Deviation from the declared file list (recorded):** the phase's Files named only `palette_controller.dart` + `paint_dataset.dart`, but AC-4's acceptance test taps the real E32 control and then the picker, so the picker UI had to be wired in `lib/palette/paint_list_region.dart` too. `paint_dataset.dart` needed no change (the reviewed dataset already carries "Ultramarine Blue"). No PALETTE-3-owned rendering (identity/badge) was touched — only the add button's action + the picker.
- **Un-pended:** deleted the `'AC-4': 'PALETTE-2'` row in `integration_test/bs06/pending.dart`. Updated the DATA-1 scaffold guard `pending map covers exactly AC-1..AC-11` → `pending map is exactly the still-pending ACs (shrinks as they land)`, asserting the explicit remaining set {AC-1,2,3,5,6,7,8,9,10,11} — kept honest (non-vacuous, every key a real AC), not weakened; each future behavior phase removes its own row.
- **Augmentations:** none owed by PALETTE-2. The module plan's pre-seeded `TestAC02`-via-PALETTE-2 augmentation did not materialise: ITEST-2 seeded AC-2's Given directly via `givenPalette(palettes:…)`, so no AC-2 precondition names PALETTE-2; the only PALETTE-2 Given-precondition lives inside AC-4's own test and is now satisfied. TestAC02 (exact tier + medium) stays owned by PALETTE-3, TestAC05 by PALETTE-4.
- **Verification:** `flutter analyze` clean. `flutter test --coverage` → **694 unit/widget passing** (+6: 5 controller tests incl. persistent round-trip + a non-measured-provenance paint that would catch a hardcoded-`measured` bug, and the screen picker test). Coverage gate vs `main`: **100%** line coverage on all **24** touched `lib/` files (incl. `palette_controller.dart`, `paint_list_region.dart`). Acceptance (`palette_test.dart`, default mode on iPhone-17 sim `5AB9D06D…` under the verify lock): **13 passing, 10 skipped** — AC-4 now executes **green**, the other 10 ACs correctly still pending; whole suite green. No cross-feature suite needed (only `lib/palette/` — bs-06-owned — was touched).
- **Grade gate:** independent adversarial re-grade (fresh subagent, given the ITEST-2 grid + G1–G6) — **AC-4 = A (with caveat) — PASS**, no downgrade. Caveat (unchanged from ITEST-2): the shipped reviewed dataset is uniformly `measured` and `Paint.provenance` defaults to `measured`, so "provenance preserved" can't be separated from a hardcoded-`measured` impl at the acceptance layer — non-blocking (the impl appends the exact object; the new unit test uses an `estimated` dataset paint to catch that bug at the unit level). Grid: `behavior-test-completeness-bs-06-palette-and-projects.md` (PALETTE-2 section appended).
- **Fix passes:** 0/3 — every gate passed on the first full run.
- **Justified exclusions:** none.
- Tokens: see master ledger (PALETTE-2 row). **Phase total: see dashboard row.**

### Checkpoint / Handoff

- **Frozen interfaces:**
  - `PaletteController.addPaintFromDataset(Paint paint) → Future<void>` — appends `paint` to the "My paints" palette (creating it if absent), preserving the paint verbatim; persists via `PersistentPaletteSource.savePalette` when the injected source supports it; notifies listeners. Adds no dedup (appends on repeat).
  - `PaintListRegion.datasetPickerKey = Key('palette-dataset-picker')` — the reviewed-dataset picker (a `showModalBottomSheet` `ListView` of `ListTile(Text(paint.name))`) the E32 add control opens; a tap pops the chosen `Paint`.
  - Unchanged: the PALETTE-1 frozen interfaces (`PaletteController({required PaletteSource source, …})`, `myPaints`, `selectPalette`, `PersistentPaletteSource`, etc.). The constructor signature is unchanged — the write seam is the private `_source` field read inside `addPaintFromDataset`.
- **Verification commands:** unchanged from PALETTE-1 — `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · acceptance `flutter test integration_test/palette_test.dart -d <booted-udid>` under `coord.sh with-lock BS-06 <PHASE>`. Flutter SDK `/Users/matthew.quirk/development/flutter/bin`. Booted sim this session: iPhone 17 `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`.
- **Known gaps / deferred:**
  - **PALETTE-3 (AC-2/AC-3)** renders the paint row (brand/line/medium/pigment index + the provenance **badge**) and the provenance legend, and makes the owed **TestAC02** augmentation (exact tier **and** medium at a non-subsumed grain). It edits `paint_list_region.dart` — the add-button + picker wiring landed here must stay; PALETTE-3 adds row rendering alongside it.
  - **PALETTE-4 (AC-5)** wires `selectPalette` → `RecipeController.selectPalette` and makes the owed **TestAC05** augmentation (recipes ⊆ the selected palette).
  - Production still opens on Capture (paletteEntry null); the file-backed store wiring landed in SCREEN-1. The in-memory (non-persistent) branch of `addPaintFromDataset` is shell/test-only — production injects a `PersistentPaletteSource`.
- **Next phase should:** PALETTE-3 (AC-2/AC-3) — startable now (its only dep PALETTE-2 is done). Runs concurrently with the PROJECT chain, SCREEN-2 and SCREEN-3 (disjoint files), but **serialize against PALETTE-4** on `palette_controller.dart`.

## Phase 3 — AC-2 + AC-3 paint identity/provenance + legend

- **Kind:** behavior · **Target AC:** AC-2 (full), AC-3 (full) · **Depends on:** PALETTE-2, ITEST-4 (G-2) · **Blocks:** PALETTE-4
- **Files:** `lib/palette/palette_controller.dart`, `lib/palette/` list/legend view-models; `lib/widgets/` paint-row + provenance-badge + legend widgets
- **Tasks:** render each paint with brand/line/medium/pigment index + a provenance **badge** (not colour alone); render the provenance legend with the four exact tier strings.
- **Exit criteria:** unit gate; acceptance + grade gates below.
- **Acceptance gate:** un-pend AC-2, AC-3; `palette_test.dart` green through AC-3.
- **Augments:** `TestAC02`: strengthen the badge assertion to the real rendered tier (closes the pre-seeded limit).

### Result

- **Landed (AC-2 + AC-3 — full):** new `lib/widgets/paint_row.dart` (`PaintRow`) renders each paint's identity — name, a `brand · line · pigment index` line, the **medium** as its own labelled widget (`PaintRow.mediumKeyFor(id)` → "Oil"/"Acrylic", distinct from the "Artists' Oil" line text) — plus a `ProvenanceBadge(Provenance(paint.provenance))` stating the tier in words, never colour alone (keys `rowKeyFor`/`mediumKeyFor`/`badgeKeyFor`). New `lib/widgets/provenance_legend.dart` (`ProvenanceLegend`) renders one keyed entry per `ProvenanceTier` with AC-3's four exact strings ("Measured", "Calculated", "Estimated — not yet verified", "Confirmed — you measured this"). `paint_list_region.dart` now renders `PaintRow` per paint (was `Text(paint.name)`); `provenance_legend_region.dart` now renders `ProvenanceLegend` (was a placeholder). No controller change needed (AC-2/AC-3 are pure rendering over the existing `myPaints` read). `palette_screen.dart` **not** touched (SCREEN-owned).
- **Un-pended:** deleted the `AC-2`/`AC-3` rows in `integration_test/bs06/pending.dart`; updated the scaffold guard's `expected` still-pending set to `{AC-1,5,6,7,8,9,10,11}` (kept exact/non-vacuous).
- **Augmentations (TestAC02 — made):** widened AC-2's acceptance test to assert the **exact rendered tier** via the per-paint `ProvenanceBadge` widget (not a row substring) **and** the **medium** via the dedicated `mediumKeyFor` label (closing the `find.textContaining('Oil')` subsumption the ITEST-2 grader flagged), with a differently-tiered, different-medium control paint ("Phthalo Green", acrylic/estimated) seeded through the persistent save flow — rejecting a hardcoded Measured/Oil row. Discriminating: every new assertion fails against the pre-PALETTE-3 name-only row.
- **Verification:** `flutter analyze` clean. `flutter test --coverage` → **699 unit/widget passing** (+5: paint_row 3, provenance_legend 2). Coverage gate vs `main`: **100%** line coverage on all **26** touched `lib/` files (incl. the two new widgets). Acceptance (`palette_test.dart`, default mode, iPhone 17 sim `5AB9D06D…` under the verify lock): **15 passing, 8 skipped** — AC-2, AC-3, AC-4 execute green, the other 8 ACs correctly still pending. One pre-existing shell unit test (`palette_screen_test.dart` "seeded state…") needed a `scrollUntilVisible` before its off-screen projects assertion, because the taller multi-line paint rows push the last region past the lazy ListView's 600px test viewport — a test-mechanic scroll, not a weakened assertion (recorded here).
- **Grade gate:** independent adversarial re-grade (fresh subagent, G1–G6, given the full prior grid) of every un-pended AC test — **AC-2 = A** (cleared from *B pending PALETTE-3*), **AC-3 = A**, **AC-4 = A (with caveat)**. **3×A — PASS (no unsanctioned B).** No augmentation remains owed by PALETTE-3. Grid: `behavior-test-completeness-bs-06-palette-and-projects.md` (PALETTE-3 section appended).
- **Fix passes:** 1/3 — pass 1 fixed only the `palette_screen_test.dart` lazy-ListView scroll (above); all product gates passed on the first full run.
- **Justified exclusions:** none.
- Tokens: see master ledger (PALETTE-3 row). **Phase total: see dashboard row / ledger.**

### Checkpoint / Handoff

- **Frozen interfaces:**
  - `PaintRow({required Paint paint})` (`lib/widgets/paint_row.dart`) — renders a paint's identity + `ProvenanceBadge`. Stable keys: `PaintRow.rowKeyFor(id)`, `PaintRow.mediumKeyFor(id)` (dedicated medium label), `PaintRow.badgeKeyFor(id)`. `static String mediumLabel(PaintMedium)` → "Oil"/"Acrylic".
  - `ProvenanceLegend()` (`lib/widgets/provenance_legend.dart`) — one entry per `ProvenanceTier`; `ProvenanceLegend.entryKeyFor(tier)`, `static String legendText(tier)` (the four exact AC-3 strings).
  - `PaintListRegion` / `ProvenanceLegendRegion` keep their `regionKey`s unchanged; they now delegate rendering to the two widgets above.
  - Unchanged: all PALETTE-1/PALETTE-2 frozen interfaces (`PaletteController`, `addPaintFromDataset`, `datasetPickerKey`, `PersistentPaletteSource`).
- **Verification commands:** unchanged — `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · acceptance `flutter test integration_test/palette_test.dart -d <booted-udid>` under `coord.sh with-lock BS-06 <PHASE>` (the with-lock cds to `$FNP_COORD_REPO` = the primary checkout, so wrap the command: `-- bash -c 'cd <worktree> && flutter test …'`). Flutter SDK `/Users/matthew.quirk/development/flutter/bin`. Booted sim this session: iPhone 17 `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`.
- **Known gaps / deferred:**
  - **PALETTE-4 (AC-5)** wires `selectPalette` → `RecipeController.selectPalette` and makes the owed **TestAC05** augmentation (recipes ⊆ the selected palette). It edits `palette_controller.dart` — this phase did **not** touch that file, so no merge concern with PALETTE-3's committed work.
  - Production still opens on Capture (paletteEntry null); the real Palette screen is only reached under the acceptance harness / SCREEN wiring. The paint row renders no colour swatch (AC-2 requires identity + badge, not colour) — a future UX nicety, not an AC.
- **Next phase should:** PALETTE-4 (AC-5) — startable now (dep PALETTE-3 done). Runs concurrently with the PROJECT chain, SCREEN-2 and SCREEN-3 (disjoint files); it is the only remaining PALETTE phase and owns `palette_controller.dart` outright now.

## Phase 4 — AC-5 selected palette drives recipes

- **Kind:** behavior · **Target AC:** AC-5 (full) · **Depends on:** PALETTE-1, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/palette/palette_controller.dart`, wiring to bs-04 `lib/recipes/recipe_controller.dart` (via the existing `selectPalette` API — no reopen of frozen solve code)
- **Tasks:** surface the painter's palettes on the Palette screen and make selecting one call `RecipeController.selectPalette`, so recipe search re-solves against only that palette.
- **Exit criteria:** unit gate; acceptance + grade gates below.
- **Acceptance gate:** un-pend AC-5; `palette_test.dart` green through AC-5; `RecipeReadEndpoint.selectedPalette` reflects the selection and recipes ⊆ the selected palette.
- **Augments:** `TestAC05`: strengthen the "recipes ⊆ Travel set" assertion once selection is real (closes the pre-seeded limit).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->
