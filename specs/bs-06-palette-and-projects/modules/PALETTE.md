# Module PALETTE — paints & palettes

**Status:** In progress — PALETTE-1 ✅ done (shell); PALETTE-2 (AC-4) startable once G-2 resolves
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/domain/paint.dart` (schema extension — **bs-04-owned, coordinate**), `lib/recipes/palette_source.dart` (write-side on the existing seam — bs-04-owned), `lib/palette/` (PaletteController, read endpoint, dataset loader), `assets/paints/` (reviewed dataset asset)
**Depends on:** DATA (store) · **Blocks:** SCREEN (renders palette state), PALETTE-4 wires into RECIPE (bs-04 `RecipeController`)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 8,841,030 | 14m 46s |
| 2 | behavior | AC-4 | ⬜ Todo | | |
| 3 | behavior | AC-2, AC-3 | ⬜ Todo | | |
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
- **Augments:** `TestAC02`: once paints can be added, AC-2's test builds its Given via this flow (precondition that named PALETTE-2 now resolves).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — AC-2 + AC-3 paint identity/provenance + legend

- **Kind:** behavior · **Target AC:** AC-2 (full), AC-3 (full) · **Depends on:** PALETTE-2, ITEST-4 (G-2) · **Blocks:** PALETTE-4
- **Files:** `lib/palette/palette_controller.dart`, `lib/palette/` list/legend view-models; `lib/widgets/` paint-row + provenance-badge + legend widgets
- **Tasks:** render each paint with brand/line/medium/pigment index + a provenance **badge** (not colour alone); render the provenance legend with the four exact tier strings.
- **Exit criteria:** unit gate; acceptance + grade gates below.
- **Acceptance gate:** un-pend AC-2, AC-3; `palette_test.dart` green through AC-3.
- **Augments:** `TestAC02`: strengthen the badge assertion to the real rendered tier (closes the pre-seeded limit).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — AC-5 selected palette drives recipes

- **Kind:** behavior · **Target AC:** AC-5 (full) · **Depends on:** PALETTE-1, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/palette/palette_controller.dart`, wiring to bs-04 `lib/recipes/recipe_controller.dart` (via the existing `selectPalette` API — no reopen of frozen solve code)
- **Tasks:** surface the painter's palettes on the Palette screen and make selecting one call `RecipeController.selectPalette`, so recipe search re-solves against only that palette.
- **Exit criteria:** unit gate; acceptance + grade gates below.
- **Acceptance gate:** un-pend AC-5; `palette_test.dart` green through AC-5; `RecipeReadEndpoint.selectedPalette` reflects the selection and recipes ⊆ the selected palette.
- **Augments:** `TestAC05`: strengthen the "recipes ⊆ Travel set" assertion once selection is real (closes the pre-seeded limit).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->
