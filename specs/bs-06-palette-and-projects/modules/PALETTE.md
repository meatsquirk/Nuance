# Module PALETTE — paints & palettes

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/domain/paint.dart` (schema extension — **bs-04-owned, coordinate**), `lib/recipes/palette_source.dart` (write-side on the existing seam — bs-04-owned), `lib/palette/` (PaletteController, read endpoint, dataset loader), `assets/paints/` (reviewed dataset asset)
**Depends on:** DATA (store) · **Blocks:** SCREEN (renders palette state), PALETTE-4 wires into RECIPE (bs-04 `RecipeController`)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

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
