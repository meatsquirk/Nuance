# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 ✅ (harness + fixtures + smoke); next ITEST-2 ∥ ITEST-3
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/palette_harness.dart`, `integration_test/palette_test.dart`, `integration_test/bs06/pending.dart`, bs-06 additions to `integration_test/fakes/` (fake file sink for photo + PDF export)
**Depends on:** all shell phases (DATA-2, PALETTE-1, PROJECT-1, SCREEN-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness + smoke) | ✅ Done | | |
| 2 | acceptance-tests | AC-1,2,3,4,5,11 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-6,7,8,9,10 | ⬜ Todo | | |
| 4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the public surface is the real app assembled by `buildApp(deps)` with the PaletteScreen entry marker — rendered widget tree (keyed region finders) + the read endpoints `PaletteReadEndpoint`, `ProjectReadEndpoint`, and (AC-5) `RecipeReadEndpoint`. Everything real except infrastructure sinks: `FakeSpeech`/`FakeHaptics` (existing), a fake file sink for the source photo + PDF export, and an in-memory-backed store double that implements the **same write-side interface** as the production on-device store. No colour/ΔE/confusion math is faked.
- **Observation points:** AC-1 region presence/absence; AC-2/3 rendered paint row + legend text; AC-4 `PaletteReadEndpoint.myPaints` provenance; AC-5 `RecipeReadEndpoint.selectedPalette` + recipe paints; AC-6 `ProjectReadEndpoint.projects` counts + rendered row; AC-7/8 note/photo text + round-trip; AC-9 `ProjectReadEndpoint.confusionPairs` + rendered flag, graded against an independent `DichromatConfusionCheck` reference built in the harness; AC-10 `ProjectReadEndpoint.lastExport` PDF model; AC-11 card estimate text + observed navigation.
- **Vision-profile fixtures (ITEST-1 amendment — confirm at the G-2 review):** the plan's single app-wide `deutanModerate` for both AC-9 and AC-11 is infeasible — the shipped `DichromatConfusionCheck` flags a pair only when its post-projection ΔE00 < 3.0 (D-5), which a *moderate* deutan never reaches, so a moderate profile flags nothing. AC-9's spec names only "the painter's confusion line" (no severity) and each scenario builds a fresh app, so the harness exposes two profiles: `deutanModerate` (severity 0.6 → AC-11's "deutan-type, moderate" estimate; the suite default) and `deutanDichromat` (full → AC-9's genuine collapse). The one harbor pair that confuses is guard-backed by the shipped detector **and** the independent reference.
- **Pending gate:** `integration_test/bs06/pending.dart` with `ac(t, "AC-n")` calling `t.skip`/`Skipf`-equivalent unless `--dart-define=BS06_RUN_PENDING=true`; a `pendingACs` map (AC → owning phase) asserted non-vacuously (every key names a real phase; the map's size matches the un-pended count). Un-pending = delete one row.

## Phase 1 — Harness + fixtures + pending gate + smoke

- **Kind:** acceptance-tests · **Depends on:** DATA-2, PALETTE-1, PROJECT-1, SCREEN-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/palette_harness.dart`, `integration_test/palette_test.dart`, `integration_test/bs06/pending.dart`, `integration_test/fakes/fake_file_sink.dart`
- **Tasks:** Given/When/Then vocabulary over the wired shells; the four fixtures (`reviewedDataset`, `twoPalettes`, `harborProject`, `deutanModerate`); the pending gate with all 11 ACs pending → owning phase; default + run-pending runner targets; a never-pending smoke test proving the Palette screen assembles end-to-end through `buildApp`.
- **Exit criteria:** suite green with the smoke test passing and all 11 ACs pending (default run skips them); harness/smoke graded (no vacuous passes; comments match checks; deterministic — poll, no fixed sleep).

### Result

Landed the harness over the wired SCREEN-1 shells and proved it end-to-end on the sim.
- **Files:** `integration_test/palette_harness.dart` (new: Given/When/Then vocabulary + fixtures + independent deutan reference + `givenPalette` entry), `integration_test/palette_test.dart` (2 smoke tests + 6 fixture guards; kept DATA-1's 3 pending-gate guards), `integration_test/fakes/fake_file_sink.dart` (new: recording `SourcePhotoStore`, D-10). `bs06/pending.dart` was already seeded with all 11 ACs in DATA-1 — unchanged (re-exported by the harness).
- **Harness:** drives the real app through `buildApp` + a `PaletteEntry`, with **persistent** sources (`PersistentPaletteSource`/`PersistentProjectSource`/`PersistentSampleSource`) over a shared `InMemoryPersistentStore` seeded via their public save flows and loaded before assembly — so the behaviour phases' write-side flows persist/round-trip through the same interface production uses. Only infrastructure is faked: `FakeSpeech`/`FakeHaptics`, `FakeFileSink` (source photo), the in-memory store. Colour/confusion math is real.
- **Fixtures:** `reviewedDataset = kReviewedPaints` (carries AC-2's Titanium White + AC-4's Ultramarine Blue); `twoPalettes` ("My paints"/"Travel set", disjoint ids, AC-5); `harborProject` (24×30 in, 6 samples, 3 recipes, note, source photo, AC-6..AC-10); vision profiles — see the fixture amendment below.
- **Fixture amendment (confirm at review):** the plan's single `deutanModerate` for both AC-9 and AC-11 is infeasible — the shipped `DichromatConfusionCheck` fires only when the *post-projection* ΔE00 < 3.0 (D-5), which a moderate deutan never reaches, so a "moderate" profile flags no realistic pair. AC-9's spec names only "the painter's confusion line" (no severity) and each scenario builds a fresh app, so the harness exposes **two** profiles: `deutanModerate` (severity 0.6, AC-11's "deutan-type, moderate" estimate + suite default) and `deutanDichromat` (full, AC-9's genuine collapse). Verified: exactly one harbor pair (Mid Raw Umber / Ultramarine Shadow) confuses under the full profile — proj ΔE00 ≈ 0.77, normal ≈ 22.0 — agreed by the shipped detector **and** the independent reference; Hull Red is a non-flag control; the moderate profile flags nothing (proj ≈ 9.70).
- **Verification:** `flutter analyze` clean; unit `flutter test --coverage` 688 green (no `lib/` touched → coverage gate PASS, whole-set 100%); acceptance `flutter test integration_test/palette_test.dart -d <iPhone-17-udid>` **12/12 green** (2 smoke + 6 fixtures + 3 gate guards), run through the verify lock. Default run skips pending (no AC tests registered yet — those are ITEST-2/3). No run-pending/red-baseline this phase (no AC tests). Fix passes: 0/3 (2 analyze errors fixed before first full run: missing `material` import; nullable `Sample.name` key).
- **Grade gate:** an independent grader (fresh context) graded the harness, smoke and fixtures **15×A, 0×B — PASS**; grid at `specs/bs-06-palette-and-projects/behavior-test-completeness-bs-06-palette-and-projects.md`. It independently re-ran a Viénot-1999 deutan projection + CIEDE2000 in Python, confirming the one confusable pair and the controls. Noted caveat (not a B): the independent *projection* reuses bs-03's Viénot coefficients (bit-identical to the shipped projection at severity 1.0), so a shared-matrix transcription error would not be caught — the ΔE00 metric and the predicate/threshold logic ARE independently checked. Follow-ons for later phases: PROJECT-5 could give the projection reference external numeric validation; PROJECT-4 will need per-project open keys (`whenOpenProject(name)` currently ignores `name`, taps the single shell control).
- **Tokens / Time:** 11,716,367 · 29m 01s (active = wall).

### Checkpoint / Handoff

- **Frozen interfaces (what ITEST-2/3 import from `palette_harness.dart`):**
  - `Future<PaletteHarness> givenPalette(tester, {palettes, projects, savedSamples, photos, cvdProfile = deutanModerate})` — builds the real app; pumps a fresh tree each call (disposes the prior `PaletteHomeScreen` State). Seeds the persistent sources via their save flows + loads them before assembly.
  - `PaletteHarness` read seams: `paletteController`/`projectController` (via the read endpoints), `palettes`, `selectedPalette`, `myPaints`, `projects`, `openedProject`, `confusionPairs`, `lastExport`, `speech`, `haptics`, `photos`, `selfAssessmentOpen`. `when…` actions: `whenSwitchToProjects`/`whenSwitchToMyPaints` (E31), `whenAddPaint` (E32, PALETTE-2), `whenSelectPalette(name)` (PALETTE-4, named precondition), `whenOpenProject(name)` (E33, PROJECT-4), `whenExportProject` (E34, PROJECT-6), `whenRetakeAssessment` (E30, SCREEN-3). Inert controls tap with `warnIfMissed: false`.
  - Fixtures: `reviewedDataset`, `twoPalettes`/`PALETTE_MY_PAINTS`/`PALETTE_TRAVEL_SET`, `harborProject`/`harborSamples`/`harborRecipes`/`harborNote`/`harborPhotoRef`/`harborPhotoBytes`, `deutanModerate`, `deutanDichromat`, the sample constants (`SAMPLE_MID_RAW_UMBER`, `SAMPLE_ULTRAMARINE_SHADOW`, `SAMPLE_HARBOR_SKY`, `SAMPLE_HULL_RED`, `SAMPLE_WARM_SAND`, `SAMPLE_DEEP_SHADOW`). Independent confusion: `referenceConfusable(a,b)` + re-exported `referenceDeltaE00` / `referenceDeutanProjectedDeltaE00`.
  - `FakeFileSink` (`save`/`read`/`exists`/`delete` + `seed(ref,bytes)`, `writes`, `saved`, `lastBytes`).
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · acceptance: `flutter test integration_test/palette_test.dart -d <booted-udid>` (add `--dart-define=BS06_RUN_PENDING=true` for run-pending). Flutter SDK `/Users/matthew.quirk/development/flutter/bin`. A booted sim udid is mandatory; run the sim suite through the verify lock (`coord.sh with-lock`). `coord.sh` cd's to the coord repo, so wrap the sim run as `bash -c "cd <worktree> && flutter test …"`.
- **Known gaps:** no per-AC tests yet (ITEST-2/3); no red baseline yet. The caveat + follow-ons above.
- **Next phase should:** ITEST-2 (AC-1,2,3,4,5,11) ∥ ITEST-3 (AC-6,7,8,9,10) — register one *pending* `acTestWidgets` per AC in `palette_test.dart` using this harness, build Givens through public flows (precondition assertions naming owners for behaviour not yet built), run run-pending for the red baseline, and grade. AC-9 uses `givenPalette(cvdProfile: deutanDichromat)`; AC-11 uses the default `deutanModerate`.

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
