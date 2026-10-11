# Module PROJECT — projects

**Status:** In progress — PROJECT-1 ✅ (shell), PROJECT-2 ✅ (enabler), PROJECT-3 ✅ (AC-6), PROJECT-4 ✅ (AC-7+AC-8); PROJECT-5 (AC-9) startable, then PROJECT-6 (AC-10)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/projects/` (Project model, ProjectSource, ProjectController, read endpoint, confusion-pair flagging, PDF export), `lib/compare/sample_source.dart` (persistent write-side on the existing seam — bs-03/04-owned, coordinate), `pubspec.yaml` (pdf package)
**Depends on:** DATA (store), reuses bs-03 `lib/a11y/cvd/confusion_check.dart` + injected `CvdProfile` · **Blocks:** SCREEN (renders project state)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 6,635,157 | 11m 41s |
| 2 | behavior (enabler) | — | ✅ Done | 4,357,106 | 18m 54s |
| 3 | behavior | AC-6 | ✅ Done | 9,896,853 | 23m 58s |
| 4 | behavior | AC-7, AC-8 | ✅ Done | 17,986,707 | 35m 50s |
| 5 | behavior | AC-9 | ⬜ Todo | | |
| 6 | behavior | AC-10 | ⬜ Todo | | |

## Interface reconciliation

- `Project` holds saved samples + recipes + a note + a source-photo reference + a size + last-edited; persisted by a new `ProjectSource` backed by DATA's store. Saved samples reuse bs-01/03 `Sample`.
- Persistent write-side added to the existing `SampleSource` seam (saved samples belong to projects); read signature unchanged.
- AC-9 reuses `DichromatConfusionCheck.confusable(a,b,profile)` + injected `CvdProfile` (D-4) — iterate the project's saved-sample pairs; **no new CVD math**. Graded against an independent in-harness reference (G5).
- PDF export (D-6): produces a studio-sheet model/bytes referencing each sample + recipe; a fake file sink in tests; the `lastExport` observable on the controller is the test seam.

## Open gates

- **G-4** ✅ resolved 2026-10-10 by Matt Quirk (pdf = pdf+printing, added by PROJECT-6; project "size" = free text). Phase 1 ✅ Done.
- **G-2** blocks Phases 2–6 (behavior; the enabler is behavior).

## Phase 1 — Shell: model, source, controller

- **Kind:** shell · **Target AC:** — · **Depends on:** DATA-2 (G-4) · **Blocks:** SCREEN-1, PROJECT-2
- **Files:** `lib/projects/project.dart` (model), `lib/projects/project_source.dart` (interface + persistent impl stub), `lib/projects/project_controller.dart` (skeleton), `lib/compare/sample_source.dart` (write-side stub), `lib/projects/project_read_endpoint.dart`
- **Tasks:** define `Project` + `ProjectSource` (persisted by DATA's store); `ProjectController` skeleton (no behaviour); `ProjectReadEndpoint` exposing projects list, opened project (note/photo/samples), confusionPairs, lastExport for tests; persistent `SampleSource` write-side stub.
- **Exit criteria:** unit gate on touched files; existing suite green; read endpoint exposes empty state.

### Result

- **Landed (shell, no AC):** New `lib/projects/`: `project.dart` (`Project` — an entity with `id`, `name`, free-text `size` (G-4), `samples`/`recipes` (reuse bs-01/03 `Sample` + bs-04 `Recipe`), `note`, `sourcePhotoRef` (D-10), `lastEdited`; `copyWith` + `toString`, no value-equality — entity like `Sample`); `project_source.dart` (`ProjectSource` seam + `InMemoryProjectSource` + `PersistentProjectSource` over DATA's `PersistentStore`, collection `projects`, keyed by id, `load`/`projects`/`saveProject`; project↔JSON incl. recipe/component/paint mapping, reusing the sample mapping below); `project_controller.dart` (`ProjectController` `ChangeNotifier` skeleton — `projects` read, `openedProject`/`confusionPairs`/`lastExport` shell getters; `ConfusionPair` typedef for PROJECT-5); `project_read_endpoint.dart` (`ProjectReadEndpoint` InheritedWidget, key `project-read-endpoint`, `.of`). `lib/compare/sample_source.dart` gains `PersistentSampleSource` (write-side over the store, collection `samples`, read signature unchanged) + public `sampleToJson`/`sampleFromJson` (reused by the project source). No screen, no `buildApp`/`main.dart`/`pubspec` change (endpoint mounting + prod wiring are SCREEN-1; pdf is PROJECT-6 per G-4).
- **Deviations (recorded):** (1) `ProjectController` reads `source.projects()` once at construction (snapshot, mirroring `PaletteController`) rather than holding the source — the `prefer_initializing_formals` lint can't be satisfied for a private *named* field; PROJECT-2+ own refresh-after-save. (2) `ConfusionPair` (`({Sample a, Sample b})`) is defined on the controller now so the read surface is real; PROJECT-5 fills the list and owns `confusion_pairs.dart`. (3) `lastExport` typed `Uint8List?` (plan D-6 "bytes"); PROJECT-6 may enrich to a model.
- **Verification:** `flutter analyze` clean. `flutter test --coverage` → **673 passing** (was 647; +26). Coverage gate vs `main`: **100%** on all touched files (`lib/projects/*` + `lib/compare/sample_source.dart`; 15 files reported, all 100%). Acceptance: n/a (shell; all 11 ACs still pending).
- **Fix passes:** 1/3 — pass 1: `flutter analyze` flagged a stray `dart:typed_data` import, `prefer_initializing_formals` on the controller, and a missing `CaptureAccuracy` import in a test; fixed all three (the implementation was correct from the first run). Pass 2 clean.
- **Justified exclusions:** on-sim bs-03/bs-04 acceptance suites not re-run — PROJECT-1 touches no screen/widget/integration code, `buildApp` is unchanged, and the comparison picker's `SampleSource.savedSamples()` read signature is unchanged (write-side added only); the host suite (which compiles `buildApp` + all comparison widget tests) is green. Consistent with DATA-2's note.
- **Closed by:** unit + coverage gate pass; existing suite green; read endpoint exposes empty state (tested).
- Tokens: see master ledger (PROJECT-1 row). **Phase total: 6,635,157 tokens, 11m 41s active (11m 41s wall).**

### Checkpoint / Handoff

- **Frozen interfaces:**
  - `Project({required id, required name, size, samples, recipes, note, sourcePhotoRef, lastEdited})` — entity (no `==`), `copyWith` (nullable fields can't be cleared through it), `toString`.
  - `ProjectSource.projects()` (read-only seam). `InMemoryProjectSource({catalogue})`. `PersistentProjectSource(PersistentStore)` — `static const collection = 'projects'`; `Future<void> load()` (**await before** the synchronous `projects()` read), `List<Project> projects()`, `Future<void> saveProject(Project)` (put keyed by `project.id` + reload).
  - `PersistentSampleSource(PersistentStore)` — `static const collection = 'samples'`; `load()` / `savedSamples()` / `saveSample(String id, Sample)`. Read side is the existing bs-03 `SampleSource.savedSamples()` (unchanged).
  - `sampleToJson(Sample)` / `sampleFromJson(Map)` — public top-level in `sample_source.dart`, reused by the project mapping so a sample round-trips identically in the catalogue or inside a project.
  - `ProjectController({required ProjectSource source})` — `projects` (snapshot at construction), `openedProject` (null), `confusionPairs` (`const []`), `lastExport` (null). `ConfusionPair = ({Sample a, Sample b})`.
  - `ProjectReadEndpoint` — `endpointKey = Key('project-read-endpoint')`, `.of(context)`, exposes the live `ProjectController`.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main`. Flutter SDK `/Users/matthew.quirk/development/flutter/bin`. drift's `NativeDatabase.memory()` runs under host `flutter test` — no sim needed for these shells.
- **Known gaps / deferred:** No production wiring (endpoint not mounted; `main.dart`/`pubspec`/pdf untouched) — **SCREEN-1 owns the deferred prod store wiring** (file-backed `DriftPersistentStore` + `FileSourcePhotoStore`, async main + path_provider + sqlite libs) and mounts `ProjectReadEndpoint` + `PaletteReadEndpoint`. No behaviour: `ProjectController` has no open/create/attach — the PROJECT-2 enabler adds create-project + attach (samples/recipes/note/photo) via `saveProject`, PROJECT-3 the list summary (AC-6), PROJECT-4 open note+photo (AC-7/8), PROJECT-5 fills `confusionPairs` (AC-9), PROJECT-6 produces `lastExport` (AC-10, adds pdf package).
- **Next phase should:** both shells (PALETTE-1, PROJECT-1) are now done → **SCREEN-1** is startable (Palette screen + keyed regions + E30–E34 + nav + mount both read endpoints + the deferred prod store wiring). All PROJECT/PALETTE/SCREEN behaviour phases remain **G-2**-blocked (approve the acceptance tests at ITEST-4); the ITEST stage follows SCREEN-1.

## Phase 2 — Enabler: create project + attach

- **Kind:** behavior · **Target AC:** — (enabler: makes real the Givens of AC-6/7/8/9/10 — a project exists with samples, recipes, a note, a source photo, a size and a last-edited time, all via public flows) · **Depends on:** PROJECT-1, ITEST-4 (G-2) · **Blocks:** PROJECT-3, PROJECT-4, PROJECT-5, PROJECT-6
- **Files:** `lib/projects/project_controller.dart`, `lib/projects/project_source.dart`, `lib/compare/sample_source.dart`
- **Tasks:** implement create-project; attach saved samples + recipes; set size; save a note; attach a source photo; stamp last-edited; persist all via the store.
- **Exit criteria:** unit gate; acceptance gate below.
- **Acceptance gate:** suite stays green; the precondition failures this unblocks (AC-6/7/8/9/10 Givens) disappear under the run-pending mode (those ACs remain pending on their own Thens).

### Result

- **Landed (enabler, no AC):** `ProjectController` gained the create/attach behaviour that makes a project real through public calls, mirroring `PaletteController.addPaintFromDataset`: `createProject({id, name, size?})` (stamps `lastEdited`, appends, persists), `attachSamples` / `attachRecipes` (append), `setSize`, `saveNote`, `attachSourcePhoto(id, SourcePhotoStore, bytes)` (writes bytes to the store, records the returned `sourcePhotoRef` — pixels never held on the project, D-10). Each change re-stamps `lastEdited` and persists through `PersistentProjectSource.saveProject` when the source can (a `PersistentProjectSource`); an in-memory source keeps the working list in memory only. A private `_mutate` helper finds the project by id (throws `StateError` if absent), applies the change via `copyWith`, replaces it in the working list, persists and `notifyListeners()`. The constructor now keeps `_source` and seeds a **mutable** working list from `source.projects()` (signature `ProjectController({required ProjectSource source})` unchanged).
- **Scope:** only `lib/projects/project_controller.dart` was modified. `lib/projects/project_source.dart` and `lib/compare/sample_source.dart` were **not** touched — PROJECT-1's `saveProject`/`load` and the reused `sampleToJson` already suffice; `attachSourcePhoto` takes the `SourcePhotoStore` as a parameter because `buildApp` wires the controller with `source:` only (no photo store), which is SCREEN-1-owned and out of this phase's file set.
- **Verification:** `flutter analyze` clean. `flutter test --coverage` → **704 passing**. Coverage gate vs `main`: **100%** on all touched files (incl. `lib/projects/project_controller.dart`; both branches of `_persist` and the `_mutate` not-found throw covered). Acceptance (iPhone 17 sim, under the global verify lock): **default run green 13/13** (10 pending skipped); **run-pending** AC-4 green, AC-1/2/3/5/6/7/8/9/10/11 red on their **own** owners' Thens/preconditions (AC-10 on PROJECT-4's open precondition) — the ITEST-4 red baseline, **unchanged** by this enabler.
- **Grade gate:** PROJECT-2 un-pends no AC and touched no acceptance-suite file. The only un-pended AC test (AC-4) was re-graded **A** by a fresh independent subagent against G1–G6 (matches the prior grid; confirmed PROJECT-2 could not have affected it). All-A grade grid stands.
- **Deviation (recorded):** the implemented ITEST-3 tests seed the Harbor project via the persistent save flow, not via a PROJECT-2 precondition, so no "PROJECT-2-precondition failure" existed to clear — the enabler's acceptance gate reduces to "suite green + baseline unchanged", both met. (ITEST-2/3 deviation from the plan's AC-test-design prose, documented in `palette_test.dart` and the rollup.)
- **Fix passes:** 0/3 — analyze, unit, coverage and both acceptance runs passed on the first full run.
- **Closed by:** unit + coverage gate; acceptance suite green (default) with the red baseline unchanged (run-pending); grade gate all-A.
- Tokens: see master ledger (PROJECT-2 row, deferred to rollup). **Phase total: 4,357,106 tokens, 18m 54s active (18m 54s wall).**

### Checkpoint / Handoff

- **Frozen interfaces (new this phase, on `ProjectController`):**
  - `Future<Project> createProject({required String id, required String name, String? size})` — creates, stamps `lastEdited = now`, appends to `projects`, persists, notifies; returns the created project.
  - `Future<Project> attachSamples(String projectId, List<Sample> samples)` / `Future<Project> attachRecipes(String projectId, List<Recipe> recipes)` — **append** (do not replace); re-stamp + persist + notify; `StateError` if `projectId` is absent.
  - `Future<Project> setSize(String projectId, String size)` / `Future<Project> saveNote(String projectId, String note)` — set the field; re-stamp + persist + notify.
  - `Future<Project> attachSourcePhoto(String projectId, SourcePhotoStore photos, Uint8List bytes)` — `photos.save(bytes)` → records the returned reference as `sourcePhotoRef`; re-stamp + persist + notify.
  - Persistence rule: changes persist only when the injected `ProjectSource` is a `PersistentProjectSource` (production + acceptance wiring); `projects` always reflects the controller's own working list. Reads (`openedProject`/`confusionPairs`/`lastExport`) are still shell state (PROJECT-4/5/6).
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · acceptance `flutter test integration_test/palette_test.dart -d <udid>` (± `--dart-define=BS06_RUN_PENDING=true`) via `coord.sh with-lock BS-06 <phase>`. Flutter SDK `/Users/matthew.quirk/development/flutter/bin`.
- **Known gaps / deferred:** no create/attach **UI** yet (controls inert in the SCREEN-1 shell); `openedProject`/`confusionPairs`/`lastExport` unimplemented. PROJECT-3 computes the AC-6 list summary (size/counts/last-edit label) off `projects`; PROJECT-4 wires open + exposes note/photo (AC-7/8) and must precede PROJECT-5/6; PROJECT-5 fills `confusionPairs` (AC-9); PROJECT-6 produces `lastExport` (AC-10, adds the pdf package). All four build on the create/attach API above and seed their Givens through the persistent save flow.
- **Next phase should:** any of PROJECT-3, PROJECT-4 (both on `lib/projects/project_controller.dart` — serialize the two against each other), PALETTE-3, SCREEN-2, SCREEN-3 — all startable now (G-2/G-4 resolved). PROJECT-5 and PROJECT-6 wait on PROJECT-4.

## Phase 3 — AC-6 projects list summary

- **Kind:** behavior · **Target AC:** AC-6 (full) · **Depends on:** PROJECT-2, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/projects/project_controller.dart`, projects-list view-model
- **Tasks:** compute and expose each project's size, sample count, recipe count and last-edited label for the Projects list.
- **Acceptance gate:** un-pend AC-6; `palette_test.dart` green through AC-6 (counts exact: 24×30 in, 6 samples, 3 recipes, edited today).

### Result

- **Landed (AC-6):** New `lib/projects/project_summary.dart` — `ProjectSummary` row read-model + `ProjectSummary.of(project, {now})`: pluralised `sampleCountLabel`/`recipeCountLabel` and a derived relative `lastEditedLabel` (calendar-day granularity → `Edited today` / `Edited yesterday` / `Edited N days ago`, null when never edited; `now` injected for determinism). `ProjectController` gains an additive `projectSummaries` getter (maps `projects` in order). `ProjectsRegion` now renders each project as a keyed row (`projectRowKey(id)`) of name + a `size · counts` detail line + the relative last-edit line, replacing the shell's name-only `Text`.
- **Acceptance (sim iPhone 17 Pro):** AC-6 un-pended (deleted its `bs06/pending.dart` row; scaffold-guard `expected` set + example AC moved to AC-7). Default run **19 passed / 4 skipped** (AC-7/8/9/10 pending); run-pending **AC-6 green, AC-7/8/9/10 red on their own Thens** (baseline unchanged).
- **Augmentation (TestAC06, owned here):** added an older-second-project **control** ("Old Study", edited 3 days ago, `9×12 in`, 2 samples, 1 recipe) and scoped every Then to its own `projectRowKey` — asserts the control row does **not** read "today", closing ITEST-3's non-blocking hardcoded-`today` follow-on. Discriminates: a row hardcoding `Edited today` fails the control.
- **Unit + coverage:** 734 tests green (+ `project_summary_test.dart` covering every `_plural` and `_lastEditedLabel` branch; `projectSummaries` getter test; a `ProjectsRegion` populated-row widget test). Coverage gate 100% line on all 27 touched `lib/` files (incl. the new `project_summary.dart`). `flutter analyze` clean.
- **Grade gate:** independent adversarial re-grade (fresh subagent, given the full prior grid + G1–G6) of all 7 un-pended ACs — **7×A (AC-4 with its standing data caveat), 0×B — PASS**. AC-6 clears the prior ITEST-3 hardcoded-`today` residual to a clean A (control discriminates; both Givens checked; per-row scoped; 6≠3 and 2≠1 reject count swaps; G6 clean). AC-1/2/3/4/5/11 verified unregressed. No augmentation owed.
- **Non-blocking residual (grader):** the control's `textContaining('1 recipe')` is a substring of `'1 recipes'`, so acceptance-level pluralisation grain is under-pinned; the exact singular is already pinned by `project_summary_test.dart`. Recorded, not owed.
- **Fix passes:** 0/3 (green on first full run). **Tokens / Time:** 9,896,853 / 23m 58s (incl. the grade-gate subagent).

### Checkpoint / Handoff

- **Frozen interfaces (new this phase):**
  - `ProjectSummary` (`lib/projects/project_summary.dart`): `ProjectSummary.of(Project, {DateTime? now})` + fields `id`/`name`/`size`/`sampleCount`/`recipeCount`/`lastEditedLabel` and `sampleCountLabel`/`recipeCountLabel`. Pure projection, no widgets/persistence.
  - `ProjectController.projectSummaries` → `List<ProjectSummary>` in `projects` order (additive; `projects`/`openedProject`/`confusionPairs`/`lastExport` unchanged).
  - `ProjectsRegion.projectRowKey(String id)` → stable per-row `Key` for scoped row assertions.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · acceptance `flutter test integration_test/palette_test.dart -d <udid>` (± `--dart-define=BS06_RUN_PENDING=true`) via `coord.sh with-lock BS-06 <phase>`. Flutter SDK `/Users/matthew.quirk/development/flutter/bin`; sim udid used: `36DD0BF6-C1F4-4958-856D-B021AC8A03EC` (iPhone 17 Pro).
- **Known gaps / deferred:** `openedProject`/`confusionPairs`/`lastExport` still shell state. **PROJECT-4** (AC-7/AC-8) is next and must precede PROJECT-5 (AC-9) and PROJECT-6 (AC-10); all three build on PROJECT-2's create/attach API and seed Givens through the persistent save flow. The open-project view PROJECT-4 mounts can reuse `ProjectSummary`/`projectRowKey` if useful but is not required to.
- **Next phase should:** run PROJECT-4 (AC-7 + AC-8) — the last startable PROJECT phase before PROJECT-5/6. One phase per session.

## Phase 4 — AC-7 + AC-8 open note+photo; note retained

- **Kind:** behavior · **Target AC:** AC-7 (full), AC-8 (full) · **Depends on:** PROJECT-2, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/projects/project_controller.dart`
- **Tasks:** opening a project exposes its note + source photo; the note persists and is shown again after the project is closed and reopened.
- **Acceptance gate:** un-pend AC-7, AC-8; suite green through AC-8; note round-trips across reopen (control: another project shows no note).

### Result

- **Landed (AC-7 + AC-8):** `ProjectController.openProject(String projectId)` sets `openedProject` to the live working-list project (so a reopened project carries its retained note + source-photo reference, AC-8) and notifies; `StateError` on an unknown id. `ProjectsRegion` now renders an open flow: each project row is a tappable `GestureDetector` (keyed `projectRowKey(id)`) opening that project by id, the E33 `openProjectKey` button opens the first project (inert only when the list is empty), and a keyed `_OpenProjectView` (`openProjectViewKey`) shows the opened project's note verbatim plus its source photo — `_SourcePhoto` loads the bytes from the injected `SourcePhotoStore` (`AppScope.of(context).sourcePhotoStore`) by `sourcePhotoRef` and renders `Image.memory` (D-10: the project keeps only the reference; `errorBuilder` swallows the suite's non-decodable placeholder bytes so the `Image` still mounts). `E34` export stays inert (PROJECT-6).
- **Cross-module touches (recorded):** besides the PROJECT-owned `project_controller.dart`, this phase edited `lib/palette/projects_region.dart` (SCREEN-owned — mounts the open-project view; the plan Files listed only the controller) and the harness `integration_test/palette_harness.dart` (`whenOpenProject(name)` now switches to the Projects view and taps the **named** project's row, closing ITEST-1's "`name` ignored" follow-on — SCREEN-2's E31 toggle means the list is no longer mounted in the default view). Sequential single-session run, so no claim conflict.
- **Augmentation (TestAC07 → PROJECT-4, closed):** AC-7's photo Then was a bare unscoped `find.byType(Image)` (B pending). Now scoped to `openProjectViewKey` and tied to the stored bytes: `isA<MemoryImage>()` + `(image as MemoryImage).bytes == harborPhotoBytes` — rejects a decorative/wrong-bytes image; the note Then is likewise scoped. Discriminates against pre-PROJECT-4 code (no open-project view existed). Row marked ✅.
- **Acceptance (sim iPhone 17, under the verify lock):** AC-7 + AC-8 un-pended (deleted their `bs06/pending.dart` rows; scaffold-guard `expected` set → `{AC-9, AC-10}`; still-pending example moved to AC-9). **Default run 21 passed / 2 skipped** (AC-9/AC-10 pending). **Run-pending:** AC-7 ✅, AC-8 ✅ green; AC-9 red on its own Then (`confusionPairs == []`, PROJECT-5) and AC-10 red on its own Then (`lastExport == null`, PROJECT-6) — the still-pending red baseline preserved, and AC-10 now fails on PROJECT-6's Then rather than the open precondition (PROJECT-4 wired opening, so AC-10's "has opened the project" Given is now real).
- **Unit + coverage:** `flutter analyze` clean. `flutter test --coverage` → **741 passing** (+7: `openProject` found/retained/StateError; four open-project-view widget tests covering note+photo, E33-first, no-note/no-photo, absent-bytes). Coverage gate vs `main`: **100%** line on all 27 touched `lib/` files (incl. `lib/palette/projects_region.dart` + `lib/projects/project_controller.dart`).
- **Grade gate:** independent fresh-subagent adversarial re-grade (given the full prior grid + G1–G6) of all 9 un-pended ACs — **9×A, 0×B — PASS**. **AC-7 cleared B pending PROJECT-4 → A** via the TestAC07 augmentation; AC-8 unregressed and G6-distinct; AC-1/2/3/4/5/6/11 unregressed (AC-6 specifically not broken by the tappable-row/open-view change). AC-4 keeps its standing uniform-measured-dataset data caveat (not a G-rule violation).
- **Fix passes:** 0/3 — analyze, unit, coverage and both acceptance runs passed on the first full run. (An initial acceptance run failed to load the test because `FNP_COORD_REPO` pointed `coord.sh` at the main checkout, not the worktree — an invocation/cwd error, fixed by pointing it at the worktree; the shared git common-dir keeps the verify lock the same. Not a code fix pass.)
- **Closed by:** unit + coverage gate; acceptance suite green (default) with AC-7/AC-8 green under run-pending and the still-pending baseline preserved; grade gate all-A.
- Tokens: see master ledger (PROJECT-4 row). **Phase total: 17,986,707 tokens, 35m 50s active (35m 50s wall).**

### Checkpoint / Handoff

- **Frozen interfaces (new this phase):**
  - `ProjectController.openProject(String projectId)` → sets `openedProject` to the live working-list project (retained note + `sourcePhotoRef`), notifies; `StateError` if the id is absent. `openedProject` now returns that project (was always null).
  - `ProjectsRegion.openProjectViewKey` → `Key('palette-open-project-view')`: the open-project view, scope for the shown note + photo. Project rows are tappable (`projectRowKey(id)`) and open by id; `openProjectKey` (E33) opens the first project. The open-project view reads the source photo from `AppScope.of(context).sourcePhotoStore` by `sourcePhotoRef` and renders `Image.memory` (with `errorBuilder`).
  - Harness: `whenOpenProject(name)` switches to the Projects view and taps the named row (per-project open).
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · acceptance `flutter test integration_test/palette_test.dart -d <udid>` (± `--dart-define=BS06_RUN_PENDING=true`) via `coord.sh with-lock BS-06 <phase>` — **set `FNP_COORD_REPO` to the worktree (`/Users/matthew.quirk/Nuance-bs06`), not the main checkout**, or `coord.sh` runs the test from main. Flutter SDK `/Users/matthew.quirk/development/flutter/bin`; sim udid used: `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (iPhone 17).
- **Known gaps / deferred:** `confusionPairs`/`lastExport` still shell state. **PROJECT-5** (AC-9) is next — iterate the opened project's saved-sample pairs through the injected bs-03 `DichromatConfusionCheck` + `CvdProfile` and render the flagged pairs + a "check by value" warning (its augmentation TestAC09 adds the non-flag control); then **PROJECT-6** (AC-10) produces `lastExport` (adds the pdf package). Both build on the open flow this phase landed — AC-9/AC-10's `whenOpenProject` Given is now real.
- **Next phase should:** run PROJECT-5 (AC-9). One phase per session.

## Phase 5 — AC-9 confusion pair flagged

- **Kind:** behavior · **Target AC:** AC-9 (full) · **Depends on:** PROJECT-2, ITEST-4 (G-2); reuses bs-03 `ConfusionCheck` · **Blocks:** —
- **Files:** `lib/projects/project_controller.dart`, `lib/projects/confusion_pairs.dart` (glue over `DichromatConfusionCheck`)
- **Tasks:** iterate the opened project's saved-sample pairs through the injected `ConfusionCheck` + `CvdProfile`; expose and render the flagged pairs ("check by value"). No new CVD math.
- **Acceptance gate:** un-pend AC-9; suite green; the seeded confusable pair is flagged and a clearly-distinct pair is **not** (control).
- **Augments:** `TestAC09`: strengthen with the non-flag control once real pairs are computed (closes the pre-seeded limit).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 6 — AC-10 export PDF studio sheet

- **Kind:** behavior · **Target AC:** AC-10 (full) · **Depends on:** PROJECT-2, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/projects/project_export.dart`, `lib/projects/project_controller.dart`, `pubspec.yaml`
- **Tasks:** generate a PDF studio sheet of the opened project's samples + recipes; expose it as `lastExport` (bytes/model); write through a file sink (faked in tests).
- **Acceptance gate:** un-pend AC-10; suite green; `lastExport` is a PDF whose content references each sample + each recipe.
- **Augments:** `TestAC10`: strengthen the content assertion to the real PDF model (closes the pre-seeded limit).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->
