# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/palette_harness.dart`, `integration_test/palette_test.dart`, `integration_test/bs06/pending.dart`, bs-06 additions to `integration_test/fakes/` (fake file sink for photo + PDF export)
**Depends on:** all shell phases (DATA-2, PALETTE-1, PROJECT-1, SCREEN-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness + smoke) | ⬜ Todo | | |
| 2 | acceptance-tests | AC-1,2,3,4,5,11 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-6,7,8,9,10 | ⬜ Todo | | |
| 4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the public surface is the real app assembled by `buildApp(deps)` with the PaletteScreen entry marker — rendered widget tree (keyed region finders) + the read endpoints `PaletteReadEndpoint`, `ProjectReadEndpoint`, and (AC-5) `RecipeReadEndpoint`. Everything real except infrastructure sinks: `FakeSpeech`/`FakeHaptics` (existing), a fake file sink for the source photo + PDF export, and an in-memory-backed store double that implements the **same write-side interface** as the production on-device store. No colour/ΔE/confusion math is faked.
- **Observation points:** AC-1 region presence/absence; AC-2/3 rendered paint row + legend text; AC-4 `PaletteReadEndpoint.myPaints` provenance; AC-5 `RecipeReadEndpoint.selectedPalette` + recipe paints; AC-6 `ProjectReadEndpoint.projects` counts + rendered row; AC-7/8 note/photo text + round-trip; AC-9 `ProjectReadEndpoint.confusionPairs` + rendered flag, graded against an independent `DichromatConfusionCheck` reference built in the harness; AC-10 `ProjectReadEndpoint.lastExport` PDF model; AC-11 card estimate text + observed navigation.
- **Pending gate:** `integration_test/bs06/pending.dart` with `ac(t, "AC-n")` calling `t.skip`/`Skipf`-equivalent unless `--dart-define=BS06_RUN_PENDING=true`; a `pendingACs` map (AC → owning phase) asserted non-vacuously (every key names a real phase; the map's size matches the un-pended count). Un-pending = delete one row.

## Phase 1 — Harness + fixtures + pending gate + smoke

- **Kind:** acceptance-tests · **Depends on:** DATA-2, PALETTE-1, PROJECT-1, SCREEN-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/palette_harness.dart`, `integration_test/palette_test.dart`, `integration_test/bs06/pending.dart`, `integration_test/fakes/fake_file_sink.dart`
- **Tasks:** Given/When/Then vocabulary over the wired shells; the four fixtures (`reviewedDataset`, `twoPalettes`, `harborProject`, `deutanModerate`); the pending gate with all 11 ACs pending → owning phase; default + run-pending runner targets; a never-pending smoke test proving the Palette screen assembles end-to-end through `buildApp`.
- **Exit criteria:** suite green with the smoke test passing and all 11 ACs pending (default run skips them); harness/smoke graded (no vacuous passes; comments match checks; deterministic — poll, no fixed sleep).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — AC tests: paints, palette, card

- **Kind:** acceptance-tests · **Target AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-11 · **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-3
- **Files:** `integration_test/palette_test.dart` (palette group)
- **Tasks:** one pending test per AC per the master catalogue (`TestAC01_SwitchViews`, `TestAC02_PaintIdentityProvenance`, `TestAC03_ProvenanceLegend`, `TestAC04_AddPaintFromDataset`, `TestAC05_SelectedPaletteDrivesRecipes`, `TestAC11_VisionCardEstimateAndOpen`); Givens built through public flows with precondition assertions naming owning phases; run-pending mode → record the red baseline below.
- **Exit criteria:** suite green with these pending; red baseline recorded; grade grid all A (or *B pending <phase>* with an augmentation row).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — AC tests: projects

- **Kind:** acceptance-tests · **Target AC:** AC-6, AC-7, AC-8, AC-9, AC-10 · **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Files:** `integration_test/palette_test.dart` (projects group)
- **Tasks:** one pending test per AC (`TestAC06_ProjectsListSummary`, `TestAC07_OpenProjectNotePhoto`, `TestAC08_NoteRetainedOnReopen`, `TestAC09_ConfusionPairFlagged`, `TestAC10_ExportPdfStudioSheet`); Givens via PROJECT-2 flows with precondition assertions naming PROJECT-2; run-pending → red baseline.
- **Exit criteria:** as ITEST-2.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — Test review (G-2)

- **Kind:** test-review · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Preconditions:** ITEST-2 + ITEST-3 done; whole-suite grade grid all A (or *B pending <phase>*).
- **Tasks:** assemble the review packet (per AC: test name, Given checks, When, Then + Rejects in a line or two; red-baseline summary; augmentations scheduled + closing phase; grid path + counts; what to look at first). Set this phase `⏸ Awaiting review`, G-2 *awaiting decision*; stop with: `/feature-next-phase --gate bs-06-palette-and-projects G-2 approved | "<changes>"`.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Red baseline  <!-- filled by the AC-test phases (run-pending) -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_SwitchViews | expect FAIL | Then: Projects region shown / paints gone | SCREEN-2 | — |
| AC-2 | TestAC02_PaintIdentityProvenance | expect FAIL | Given precondition: add-paint (PALETTE-2) then Then: provenance badge | PALETTE-3 | — |
| AC-3 | TestAC03_ProvenanceLegend | expect FAIL | Then: four tier strings | PALETTE-3 | — |
| AC-4 | TestAC04_AddPaintFromDataset | expect FAIL | Then: provenance preserved on add | PALETTE-2 | — |
| AC-5 | TestAC05_SelectedPaletteDrivesRecipes | expect FAIL | Then: recipes ⊆ selected palette | PALETTE-4 | — |
| AC-6 | TestAC06_ProjectsListSummary | expect FAIL | Given precondition: project (PROJECT-2) then Then: counts | PROJECT-3 | — |
| AC-7 | TestAC07_OpenProjectNotePhoto | expect FAIL | Then: note + photo shown | PROJECT-4 | — |
| AC-8 | TestAC08_NoteRetainedOnReopen | expect FAIL | Then: note after reopen | PROJECT-4 | — |
| AC-9 | TestAC09_ConfusionPairFlagged | expect FAIL | Then: pair flagged | PROJECT-5 | — |
| AC-10 | TestAC10_ExportPdfStudioSheet | expect FAIL | Then: PDF references samples+recipes | PROJECT-6 | — |
| AC-11 | TestAC11_VisionCardEstimateAndOpen | expect FAIL | Then: estimate shown + navigation | SCREEN-3 | — |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC02 | provenance badge can't render until the real tier is shown | PALETTE-3 | assert the exact rendered provenance tier on the paint row | ⬜ Open |
| TestAC05 | "recipes ⊆ Travel set" can't discriminate until selection re-points the solver | PALETTE-4 | assert every returned recipe's paints ⊆ the selected palette (disjoint-palette control) | ⬜ Open |
| TestAC09 | a non-flag control needs real pair computation | PROJECT-5 | add a clearly-distinct pair and assert it is **not** flagged | ⬜ Open |
| TestAC10 | PDF content can't be asserted until a real sheet is produced | PROJECT-6 | assert the produced PDF references each sample + each recipe | ⬜ Open |
