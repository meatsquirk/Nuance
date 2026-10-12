# Module ITEST — acceptance integration suite

**Status:** ✅ Done — ITEST-1 ✅, ITEST-2 ✅, ITEST-3 ✅, ITEST-4 ✅ (**G-2 approved 2026-10-11, Matt Quirk** — acceptance suite accepted as-is; behavior stage unblocked)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/palette_harness.dart`, `integration_test/palette_test.dart`, `integration_test/bs06/pending.dart`, bs-06 additions to `integration_test/fakes/` (fake file sink for photo + PDF export)
**Depends on:** all shell phases (DATA-2, PALETTE-1, PROJECT-1, SCREEN-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness + smoke) | ✅ Done | | |
| 2 | acceptance-tests | AC-1,2,3,4,5,11 | ✅ Done | 10,977,843 | 25m 32s |
| 3 | acceptance-tests | AC-6,7,8,9,10 | ✅ Done | 6,732,201 | 27m 32s |
| 4 | test-review | — (G-2) | ✅ Done | 1,760,963 | 3m 34s |

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

### Result

Registered one *pending* `acTestWidgets` per AC in `palette_test.dart`'s new `palette ACs (ITEST-2)` group (AC-1, 2, 3, 4, 5, 11), each Given built through a public flow (persistent save flows via `givenPalette`, or an E-control `when…`) and checked before the When.
- **Files:** `integration_test/palette_test.dart` only (+ `import recipes/palette.dart` for `PaintPalette`). No `lib/` touched. Test names carry the `AC-n` id; the catalogue's `TestACnn_*` names are kept in the comments/scenario mapping.
- **Default run (pending skipped):** 12/12 green on the iPhone-17 sim via the verify lock — the 6 new AC tests correctly skip.
- **Red baseline (`--dart-define=BS06_RUN_PENDING=true`):** all 6 fail as intended (table below) — 5 on a Then, AC-4 on its Given-precondition naming PALETTE-2; every failure a clean `TestFailure` (no compile/harness error). Rest of the suite green.
- **Scaffold-guard fix (recorded):** the DATA-1 guard `pendingSkipReason skips a pending AC by default…` read the *ambient* `runPending`, so it failed under run-pending mode (never exercised in ITEST-1, which ran no run-pending pass). Rewrote it to assert both modes deterministically via `forceRunPending: false/true` — strengthens the guard, does not weaken it.
- **Grade gate:** independent adversarial grader (fresh subagent, given the prior grid + G1–G6) — **4×A, 2×B-pending — PASS**. A: AC-1, AC-3, AC-4 (A-with-caveat), AC-11. *B pending PALETTE-3*: AC-2 (badge/medium can't discriminate until the real tier renders). *B pending PALETTE-4*: AC-5 (only the active-palette re-point asserted; "recipes ⊆ Travel set" needs PALETTE-4's recipe seam). Both B rows have augmentation rows below. Grid: `behavior-test-completeness-bs-06-palette-and-projects.md` (ITEST-2 section appended).
- **Grader finding folded in:** AC-2's `textContaining('Oil')` medium check is subsumed by the line text "Artists' Oil" (a medium-omitting impl would pass) — the medium can't be asserted non-subsumed until PALETTE-3 renders a medium widget, so the **TestAC02 augmentation was widened** to own that (plus the exact tier). AC-11 hardening (a second-profile control proving the label tracks the injected profile) is a non-blocking follow-on for SCREEN-3 — see handoff.
- **Verification:** `flutter analyze` clean; no `lib/` change → unit coverage gate N/A (whole-set stays 100%). Fix passes: 1/3 (pass 1 fixed the run-pending scaffold-guard failure; the 6 AC reds are the intended baseline, not failures to fix).
- **Tokens / Time:** see dashboard row (filled from the ledger).

### Checkpoint / Handoff

- **Frozen for ITEST-3 / the behaviour phases:** the `palette ACs (ITEST-2)` group registers AC-1/2/3/4/5/11; each un-pends by deleting its row in `bs06/pending.dart`. ITEST-3 adds the `projects` group (AC-6..10) to the **same file** — run serially against ITEST-2 (shared `palette_test.dart`), appending after this group.
- **How each AC un-pends green:** AC-1 → SCREEN-2 (view toggle hides the non-active region); AC-2/AC-3 → PALETTE-3 (paint-row identity+badge, legend four tiers); AC-4 → PALETTE-2 (E32 picker offers the reviewed dataset, add preserves the dataset Paint); AC-5 → PALETTE-4 (selection re-points + its augmentation); AC-11 → SCREEN-3 (card renders the injected estimate + navigates).
- **Augmentations owed (this phase's ACs):** TestAC02 → PALETTE-3 (exact provenance tier **and** medium at a non-subsumed grain); TestAC05 → PALETTE-4 (every returned recipe's paints ⊆ the selected palette, disjoint-palette control). SCREEN-3 should also add AC-11 a second-profile control (non-blocking hardening the grader recommended).
- **Verification commands:** unchanged from ITEST-1 (see its handoff). Default: `flutter test integration_test/palette_test.dart -d <booted-udid>` via `coord.sh with-lock`; red baseline: add `--dart-define=BS06_RUN_PENDING=true`. Flutter SDK `/Users/matthew.quirk/development/flutter/bin`; booted sim udid mandatory.
- **Known gaps:** AC-6..10 not yet written (ITEST-3). Behaviour un-built — the 6 ACs here stay pending/red until their owners land (all blocked on G-2).

## Phase 3 — AC tests: projects

- **Kind:** acceptance-tests · **Target AC:** AC-6, AC-7, AC-8, AC-9, AC-10 · **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Files:** `integration_test/palette_test.dart` (projects group)
- **Tasks:** one pending test per AC (`TestAC06_ProjectsListSummary`, `TestAC07_OpenProjectNotePhoto`, `TestAC08_NoteRetainedOnReopen`, `TestAC09_ConfusionPairFlagged`, `TestAC10_ExportPdfStudioSheet`); Givens via PROJECT-2 flows with precondition assertions naming PROJECT-2; run-pending → red baseline.
- **Exit criteria:** as ITEST-2.

### Result

Registered one *pending* `acTestWidgets` per AC in `palette_test.dart`'s new `project ACs (ITEST-3)` group (AC-6, 7, 8, 9, 10), appended after ITEST-2's group in the same file (run serially — shared file).
- **Files:** `integration_test/palette_test.dart` only. No `lib/` touched. Each Given is built through a public flow — the project seeded via `givenPalette(projects: [harborProject])` (production `PersistentProjectSource.saveProject` + `load()`, the same seam PROJECT-2 attaches through) — and checked through the read endpoints before the When. Following ITEST-2's AC-2 precedent, the Givens are seeded via the persistent save flow rather than PROJECT-2's not-yet-built create UI, so each test's red-baseline failure lands on its own owner's behaviour.
- **Default run (pending skipped):** 12/12 green on the iPhone-17 sim via the verify lock — the 5 new AC tests correctly skip (11 pending total skipped).
- **Red baseline (`--dart-define=BS06_RUN_PENDING=true`):** all 5 fail cleanly (table below) — 4 on a Then, AC-10 on its opened-project Given-precondition (naming PROJECT-4, which precedes PROJECT-6); every failure a clean `TestFailure` (no compile/harness error). Whole suite otherwise green (+12 −11).
- **Grade gate:** independent adversarial grader (fresh subagent, given the ITEST-2 grid + G1–G6) — initially **2×A, 2×B-pending, 1 unsanctioned B** (FAIL): AC-7's "source photo is shown" rested on a bare, unscoped `find.byType(Image)` with no augmentation (G4). **Resolved in-phase:** added the **TestAC07 → PROJECT-4** augmentation row (tie the shown photo to `harborPhotoRef`/`harborPhotoBytes` via a keyed/scoped widget), and folded in AC-10's G1 opened-project Given-check. Re-graded **2×A (AC-6, AC-8), 3×B-pending (AC-7→PROJECT-4, AC-9→PROJECT-5, AC-10→PROJECT-6) — PASS (no unsanctioned B)**. Grid: `behavior-test-completeness-bs-06-palette-and-projects.md` (ITEST-3 section appended).
- **Non-blocking follow-on:** PROJECT-3 should add an older-second-project control so AC-6's `'today'` can't be satisfied by a hardcoded string (same class as ITEST-2's AC-11 recommendation; recorded in the handoff, not a blocking augmentation).
- **Verification:** `flutter analyze` clean; no `lib/` change → unit coverage gate N/A (whole-set stays 100%). Fix passes: 1/3 (pass 1 added the TestAC07 augmentation + AC-10 Given-check; the 5 AC reds are the intended baseline, not failures to fix).
- **Tokens / Time:** see dashboard row (filled from the ledger).

### Checkpoint / Handoff

- **Frozen for ITEST-4 / the behaviour phases:** the `project ACs (ITEST-3)` group registers AC-6/7/8/9/10; each un-pends by deleting its row in `bs06/pending.dart`. All 11 ACs now have a pending test + red baseline. ITEST-4 (test review) assembles the packet across both groups and opens **G-2**.
- **How each AC un-pends green:** AC-6 → PROJECT-3 (project-row summary: size/counts/last-edit); AC-7/AC-8 → PROJECT-4 (open-project view renders note + source photo; note retained on reopen); AC-9 → PROJECT-5 (`confusionPairs` filled for the opened project); AC-10 → PROJECT-6 (`lastExport` PDF). PROJECT-4 precedes PROJECT-6, so AC-10's opened-project Given is real by its un-pend run; PROJECT-4 precedes PROJECT-5, so AC-9's open is real by its un-pend run.
- **Augmentations owed (this phase's ACs):** TestAC07 → PROJECT-4 (tie the shown source photo to `harborPhotoRef`/`harborPhotoBytes`, not a bare `Image` type-match); TestAC09 → PROJECT-5 (add a clearly-distinct pair, assert NOT flagged); TestAC10 → PROJECT-6 (assert the produced PDF references each sample + each recipe). Non-blocking: PROJECT-3 older-second-project `'today'` control.
- **Verification commands:** unchanged from ITEST-1/2 (see ITEST-1 handoff). Default: `flutter test integration_test/palette_test.dart -d <booted-udid>` via `coord.sh with-lock`; red baseline: add `--dart-define=BS06_RUN_PENDING=true`. Flutter SDK `/Users/matthew.quirk/development/flutter/bin`; booted sim udid mandatory.
- **Known gaps:** behaviour un-built — all 11 ACs stay pending/red until their owners land (all blocked on G-2). AC-8's "reopen" is the persistent seed→load round-trip, not an app-driven close/reopen (documented in the packet).

## Phase 4 — Test review (G-2)

- **Kind:** test-review · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Preconditions:** ITEST-2 + ITEST-3 done; whole-suite grade grid all A (or *B pending <phase>*).
- **Tasks:** assemble the review packet (per AC: test name, Given checks, When, Then + Rejects in a line or two; red-baseline summary; augmentations scheduled + closing phase; grid path + counts; what to look at first). Set this phase `⏸ Awaiting review`, G-2 *awaiting decision*; stop with: `/feature-next-phase --gate bs-06-palette-and-projects G-2 approved | "<changes>"`.

### Review packet (G-2) — for human approval

The acceptance suite for bs-06 (11 pending integration tests, one per AC) is ready for review
**before any behavior is coded**. All tests live in `integration_test/palette_test.dart` and drive the
real app assembled by `buildApp` through the keyed widget tree + read endpoints; only infrastructure
(speech/haptics, the source-photo/PDF file sink, the on-device store) is faked — no colour/ΔE/confusion
math is faked. Each AC un-pends by deleting its row in `integration_test/bs06/pending.dart`; its owning
behavior phase then makes it pass.

**Look at first (reviewer):**
1. **The vision-profile fixture split** (Interface reconciliation, above): the plan asked for one app-wide
   `deutanModerate` profile for both AC-9 and AC-11, but the shipped `DichromatConfusionCheck` only fires
   when a pair's post-projection ΔE00 < 3.0 (D-5) — a *moderate* deutan never reaches that, so it would
   flag nothing. AC-9's spec names only "the painter's confusion line" (no severity), so the harness
   exposes two profiles: `deutanModerate` (AC-11's estimate text + suite default) and `deutanDichromat`
   (full; AC-9's genuine collapse). **Please confirm this is acceptable.**
2. **AC-8's "reopen" is a persistent seed→load round-trip**, not an app-driven close/reopen (the app has no
   close yet). It genuinely tests "the exact persisted note is shown on open" — a distinct discriminating
   assertion from AC-7 — but it is not an in-app reopen cycle. Flagged so the Given/When comments don't
   mislead.
3. **The five B-pending grades** (AC-2, AC-5, AC-7, AC-9, AC-10): each is a test that cannot fully
   discriminate until the behavior it checks exists, and each has a scheduled augmentation row (below) that
   its owning phase must close to A. No B is being handed over as an "optional" item.

**Per-AC (test name · Given checks · When · Then + Rejects):**

- **AC-1 · `TestAC01_SwitchViews`** (owner SCREEN-2, grade **A**)
  - *Given:* My paints view is shown to start (`PaintListRegion` present).
  - *When:* painter switches to Projects (`whenSwitchToProjects`, E31).
  - *Then:* Projects region present **and** paint list `findsNothing` — shown *instead of*, not alongside; a paired control switches back and asserts the inverse. *Rejects:* a toggle that shows both, a one-way/stuck toggle.

- **AC-2 · `TestAC02_PaintIdentityProvenance`** (owner PALETTE-3, grade **B pending PALETTE-3**)
  - *Given:* "Titanium White" seeded in My paints; checked via `myPaints` for brand/line/medium/`PW6`/`provenance == measured`.
  - *When:* the My paints list is shown.
  - *Then:* row shows name, brand, line, medium, pigment index **and** the "Measured" badge (not colour alone), scoped to the paint-list region. *Rejects:* a name/colour-only row. *Limited:* every reviewed paint is `measured` and the default is `measured`, so a hardcoded badge passes, and the medium check `'Oil'` is subsumed by the line "Artists' Oil" — PALETTE-3 augmentation must assert the **exact tier** (differently-tiered paint) **and** the **medium at a non-subsumed grain**.

- **AC-3 · `TestAC03_ProvenanceLegend`** (owner PALETTE-3, grade **A**)
  - *Given:* legend region present.
  - *When:* the legend is shown.
  - *Then:* all four tiers by their exact spec strings — "Measured", "Calculated", "Estimated — not yet verified", "Confirmed — you measured this". *Rejects:* a placeholder legend or a subset of tiers.

- **AC-4 · `TestAC04_AddPaintFromDataset`** (owner PALETTE-2, grade **A** with caveat)
  - *Given:* My paints empty; painter opens the add-paint flow (`whenAddPaint`, E32). Given precond (names PALETTE-2): the reviewed dataset is offered, listing "Ultramarine Blue".
  - *When:* painter chooses "Ultramarine Blue" from the dataset.
  - *Then:* exactly the reviewed-dataset `Paint` is added — `equals(ultramarine)`, provenance/pigment/masstone preserved. *Rejects:* a free-hand or blanked value, a lost-provenance copy.

- **AC-5 · `TestAC05_SelectedPaletteDrivesRecipes`** (owner PALETTE-4, grade **B pending PALETTE-4**)
  - *Given:* palettes "My paints" + "Travel set" (disjoint), first active; checked via `palettes`/`selectedPalette`.
  - *When:* painter selects "Travel set" (`whenSelectPalette`).
  - *Then:* `selectedPalette` re-points to Travel set with its disjoint id-set. *Rejects:* an impl that ignores selection / stays on My paints. *Limited:* no recipe surface is mounted until PALETTE-4, so this asserts the active-pointer proxy, not the spec's "recipes solve only against Travel set" — PALETTE-4 augmentation adds "every returned recipe's paints ⊆ selected palette" + disjoint control.

- **AC-6 · `TestAC06_ProjectsListSummary`** (owner PROJECT-3, grade **A**)
  - *Given:* "Harbor at Dusk" seeded (24×30 in, 6 samples, 3 recipes, edited today); checked via `projects.single` incl. `lastEdited` `inDays == 0`.
  - *When:* Projects list is shown.
  - *Then:* row shows the size string, `'6 samples'`, `'3 recipes'` (6≠3 catches a swap) and a case-insensitive "today", scoped to `ProjectsRegion`. *Rejects:* the shell's name-only row. *Non-blocking follow-on:* PROJECT-3 should add an older-second-project control so "today" can't be hardcoded.

- **AC-7 · `TestAC07_OpenProjectNotePhoto`** (owner PROJECT-4, grade **B pending PROJECT-4**)
  - *Given:* "Harbor at Dusk" has a note + source photo (seeded into the file sink, round-trips); `openedProject` null to start.
  - *When:* painter opens the project (`whenOpenProject`).
  - *Then:* `openedProject` is "Harbor at Dusk" carrying its `sourcePhotoRef`; the note text is shown; an `Image` is rendered. *Rejects:* no-open, note/photo absent. *Limited:* the photo Then is a bare `find.byType(Image)` untied to the source bytes — PROJECT-4 augmentation ties the shown photo to `harborPhotoRef`/`harborPhotoBytes` via a keyed/scoped widget.

- **AC-8 · `TestAC08_NoteRetainedOnReopen`** (owner PROJECT-4, grade **A**)
  - *Given:* note saved on "Harbor at Dusk", read back from the loaded persistent source (the *retained* value, non-empty guard against a vacuous "" match).
  - *When:* painter reopens the project.
  - *Then:* `openedProject?.note == harborNote` at the model grain **and** shown verbatim. *Rejects:* a default/placeholder/truncated note. *Caveat (see item 2):* "reopen" is the persistent seed→load round-trip, not an app-driven close/reopen.

- **AC-9 · `TestAC09_ConfusionPairFlagged`** (owner PROJECT-5, grade **B pending PROJECT-5**)
  - *Given:* project holds "Mid Raw Umber" + "Ultramarine Shadow" under a full `deutanDichromat`; the pair is confirmed confusable via the harness's **independent** `referenceConfusable` (never the shipped detector it grades — G2).
  - *When:* painter opens the project.
  - *Then:* exactly that pair appears in `confusionPairs` and a "check …" warning is shown. *Rejects:* no-flag, wrong-pair. *Limited:* `anyElement` can't reject an over-flagging impl at baseline — PROJECT-5 augmentation adds a clearly-distinct pair asserted **not** flagged.

- **AC-10 · `TestAC10_ExportPdfStudioSheet`** (owner PROJECT-6, grade **B pending PROJECT-6**)
  - *Given:* "Harbor at Dusk" (6 samples, 3 recipes), `lastExport` null; project opened (Given precond names PROJECT-4, which precedes PROJECT-6).
  - *When:* painter exports the project (`whenExportProject`, D-6 — bytes, no disk write).
  - *Then:* `lastExport` is non-null and begins with the `%PDF-` magic bytes. *Rejects:* a null/empty/placeholder blob. *Limited:* content ("references each sample + each recipe") needs a real PDF — PROJECT-6 augmentation asserts it.

- **AC-11 · `TestAC11_VisionCardEstimateAndOpen`** (owner SCREEN-3, grade **A**)
  - *Given:* `deutanModerate` injected (configured Given, G2); card present; `selfAssessmentOpen` false.
  - *When:* painter chooses to retake from the card (`whenRetakeAssessment`).
  - *Then:* card shows the exact estimate "deutan-type, moderate" (from the injected profile); `selfAssessmentOpen` flips false→true. *Rejects:* a blank/wrong card, a no-op retake. *Non-blocking follow-on:* SCREEN-3 should add a second-profile control so the label can't be a constant.

**Red-baseline summary** (run-pending mode, `--dart-define=BS06_RUN_PENDING=true`): all 11 AC tests fail
cleanly — 9 on a Then, 2 (AC-4, AC-10) on a Given precondition naming the owning phase; every failure a
`TestFailure` (no compile/harness/panic error). Default run (pending skipped): **12/12 green** (2 smoke +
6 fixture guards + the scaffold-guard group; the 11 AC tests correctly skip). Rest of the suite green.
Per-test rows: the *Red baseline* table below.

**Augmentations scheduled** (the five B-pending tests reach A when their owner closes these — *Test
augmentations* table below): TestAC02 → PALETTE-3 · TestAC05 → PALETTE-4 · TestAC07 → PROJECT-4 ·
TestAC09 → PROJECT-5 · TestAC10 → PROJECT-6.

**Grade grid:** `specs/bs-06-palette-and-projects/behavior-test-completeness-bs-06-palette-and-projects.md`
— ITEST-1 scaffold/harness/fixtures **15×A**; ITEST-2 (AC-1,2,3,4,5,11) **4×A, 2×B-pending**; ITEST-3
(AC-6,7,8,9,10) **2×A, 3×B-pending**. Whole-suite AC grades: **6×A, 5×B-pending — no unsanctioned B**.
All grades by fresh independent adversarial graders.

**To record the decision:** `/feature-next-phase --gate bs-06-palette-and-projects G-2 approved | "<changes>"`

### Result

ITEST-4 (test-review) assembled the G-2 review packet above across ITEST-2 (AC-1,2,3,4,5,11) and ITEST-3
(AC-6,7,8,9,10): per-AC test name, Given checks, When, Then + Rejects; the red-baseline summary; the five
scheduled augmentations with closing phases; the grade-grid path and counts; and the three items to look
at first (the vision-profile fixture split needing confirmation, AC-8's round-trip "reopen" caveat, the
five sanctioned B-pending grades). No `lib/` and no test code touched — plan files only. Phase set
`⏸ Awaiting review`; **G-2** set *awaiting decision*. The behavior stage (PALETTE-2→4, PROJECT-2→6,
SCREEN-2/3) stays blocked until a human records the G-2 decision.

### Checkpoint / Handoff

- **G-2 approved 2026-10-11 (Matt Quirk)** — acceptance suite accepted as-is: the two-profile fixture
  split (`deutanModerate`/`deutanDichromat`) confirmed acceptable, AC-8's persistent seed→load round-trip
  "reopen" accepted, and the 5 sanctioned B-pending grades accepted with their augmentations owed by the
  owning behavior phases. ITEST-4 ✅ Done; stage 3 closed; every behavior phase unblocked.
- **Behavior stage now open.** Startable first (no behavior dependency): PALETTE-2 (AC-4), PROJECT-2
  (enabler), SCREEN-2 (AC-1), SCREEN-3 (AC-11); PALETTE-3/4 and PROJECT-3→6 follow per the dependency graph
  (PROJECT-2 before all PROJECTs; PROJECT-4 before PROJECT-5 and PROJECT-6). Each behavior phase un-pends
  its AC (delete the row in `bs06/pending.dart`), closes its owed augmentation (TestAC02→PALETTE-3,
  TestAC05→PALETTE-4, TestAC07→PROJECT-4, TestAC09→PROJECT-5, TestAC10→PROJECT-6), and re-grades every
  un-pended test to A.
- **Verification commands:** unchanged (see ITEST-1 handoff). No verification run this phase (no code).

## Red baseline  <!-- filled by the AC-test phases (run-pending) -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_SwitchViews | **FAIL** (Then) | Then: paint-list region still present after switch (shell shows both views) — `palette_test.dart:245` | SCREEN-2 | **A** |
| AC-2 | TestAC02_PaintIdentityProvenance | **FAIL** (Then) | Then: row has no "Winsor & Newton" (shell renders name only) — `:293`. *(Given seeded via the persistent save flow, not the E32 add flow — AC-2 depends only on its owner PALETTE-3, a deliberate deviation from the catalogue's add-flow Given.)* | PALETTE-3 | **B pending PALETTE-3** |
| AC-3 | TestAC03_ProvenanceLegend | **FAIL** (Then) | Then: legend has no "Measured" (placeholder only) — `:323` | PALETTE-3 | **A** |
| AC-4 | TestAC04_AddPaintFromDataset | **FAIL** (Given precond, names owner) | Given precondition: add-paint flow offers no "Ultramarine Blue" (E32 inert) — `:345` | PALETTE-2 | **A** (caveat) |
| AC-5 | TestAC05_SelectedPaletteDrivesRecipes | **FAIL** (Then) | Then: selectedPalette stays "My paints" (selection inert) — `:391` | PALETTE-4 | **B pending PALETTE-4** |
| AC-6 | TestAC06_ProjectsListSummary | **FAIL** (Then) | Then: Projects region has no "24×30 in" (shell renders `project.name` only) — `palette_test.dart:489`. *(Project seeded via the persistent save flow; AC-6 depends only on its owner PROJECT-3's row summary.)* | PROJECT-3 | **A** |
| AC-7 | TestAC07_OpenProjectNotePhoto | **FAIL** (Then) | Then: `openedProject` null — the project did not open (open is inert) — `:535` | PROJECT-4 | **B pending PROJECT-4** |
| AC-8 | TestAC08_NoteRetainedOnReopen | **FAIL** (Then) | Then: `openedProject?.note` null after reopen (open inert) — `:567` | PROJECT-4 | **A** |
| AC-9 | TestAC09_ConfusionPairFlagged | **FAIL** (Then) | Then: `confusionPairs` empty — no pair flagged (shell returns `const []`) — `:615`. Injects `deutanDichromat`; Given confirmed via the independent `referenceConfusable`. | PROJECT-5 | **B pending PROJECT-5** |
| AC-10 | TestAC10_ExportPdfStudioSheet | **FAIL** (Given precond, names PROJECT-4) | Given precondition: `openedProject` null — "has opened the project" needs PROJECT-4's open (precedes PROJECT-6) — `:660`. The export Then (`lastExport` → `%PDF-`) is the discriminator once opened. | PROJECT-6 | **B pending PROJECT-6** |
| AC-11 | TestAC11_VisionCardEstimateAndOpen | **FAIL** (Then) | Then: card has no "deutan-type, moderate" estimate (placeholder) — `:413` | SCREEN-3 | **A** |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC02 | badge + medium can't be asserted non-subsumed until the real tier/medium render (medium check currently subsumed by the "Artists' Oil" line text, grader finding) | PALETTE-3 | assert the exact rendered provenance tier **and** the medium at a non-subsumed grain (a dedicated medium label/widget, not the line text) on the paint row | ✅ Closed by PALETTE-3 (exact rendered tier via `ProvenanceBadge` + medium via the dedicated `PaintRow.mediumKeyFor` label, not the line text; differently-tiered/different-medium control; AC-2 → A) — status cell corrected at SIGNOFF-1 |
| TestAC05 | "recipes ⊆ Travel set" can't discriminate until selection re-points the solver | PALETTE-4 | assert every returned recipe's paints ⊆ the selected palette (disjoint-palette control) | ✅ Closed by PALETTE-4 (AC-5 → A) |
| TestAC07 | "the source photo is shown" is a type-only `find.byType(Image)` untied to the source photo until PROJECT-4 mounts the open-project view (a decorative/wrong-bytes image would pass) | PROJECT-4 | assert the source photo via a widget keyed/scoped to the open-project view and tied to `harborPhotoRef`/`harborPhotoBytes` (not a bare `Image` type-match) | ✅ Closed by PROJECT-4 (scoped to `openProjectViewKey`; `isA<MemoryImage>()` + `.bytes == harborPhotoBytes`; AC-7 → A) |
| TestAC09 | a non-flag control needs real pair computation | PROJECT-5 | add a clearly-distinct pair and assert it is **not** flagged | ✅ Closed by PROJECT-5 (control "Mid Raw Umber"/"Hull Red" asserted **not** flagged + `hasLength(1)` rejects over-flagging; AC-9 → A) |
| TestAC10 | PDF content can't be asserted until a real sheet is produced | PROJECT-6 | assert the produced PDF references each sample + each recipe | ✅ Closed by PROJECT-6 (`%PDF-` magic bytes + each sample by name and each recipe by its ` + `-joined paint-list, each recipe carrying a unique paint so an omission is caught; AC-10 → A) — status cell corrected at SIGNOFF-1 |
