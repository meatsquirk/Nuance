# Module PROJECT — projects

**Status:** In progress — PROJECT-1 ✅ done (shell); PROJECT-2 (enabler) startable once G-2 resolves
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/projects/` (Project model, ProjectSource, ProjectController, read endpoint, confusion-pair flagging, PDF export), `lib/compare/sample_source.dart` (persistent write-side on the existing seam — bs-03/04-owned, coordinate), `pubspec.yaml` (pdf package)
**Depends on:** DATA (store), reuses bs-03 `lib/a11y/cvd/confusion_check.dart` + injected `CvdProfile` · **Blocks:** SCREEN (renders project state)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 6,635,157 | 11m 41s |
| 2 | behavior (enabler) | — | ⬜ Todo | | |
| 3 | behavior | AC-6 | ⬜ Todo | | |
| 4 | behavior | AC-7, AC-8 | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — AC-6 projects list summary

- **Kind:** behavior · **Target AC:** AC-6 (full) · **Depends on:** PROJECT-2, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/projects/project_controller.dart`, projects-list view-model
- **Tasks:** compute and expose each project's size, sample count, recipe count and last-edited label for the Projects list.
- **Acceptance gate:** un-pend AC-6; `palette_test.dart` green through AC-6 (counts exact: 24×30 in, 6 samples, 3 recipes, edited today).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — AC-7 + AC-8 open note+photo; note retained

- **Kind:** behavior · **Target AC:** AC-7 (full), AC-8 (full) · **Depends on:** PROJECT-2, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/projects/project_controller.dart`
- **Tasks:** opening a project exposes its note + source photo; the note persists and is shown again after the project is closed and reopened.
- **Acceptance gate:** un-pend AC-7, AC-8; suite green through AC-8; note round-trips across reopen (control: another project shows no note).

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

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
