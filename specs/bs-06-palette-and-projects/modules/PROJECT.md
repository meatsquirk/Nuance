# Module PROJECT — projects

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/projects/` (Project model, ProjectSource, ProjectController, read endpoint, confusion-pair flagging, PDF export), `lib/compare/sample_source.dart` (persistent write-side on the existing seam — bs-03/04-owned, coordinate), `pubspec.yaml` (pdf package)
**Depends on:** DATA (store), reuses bs-03 `lib/a11y/cvd/confusion_check.dart` + injected `CvdProfile` · **Blocks:** SCREEN (renders project state)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
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

- **G-4** blocks Phase 1 (pdf package; project "size" semantics).
- **G-2** blocks Phases 2–6 (behavior; the enabler is behavior).

## Phase 1 — Shell: model, source, controller

- **Kind:** shell · **Target AC:** — · **Depends on:** DATA-2 (G-4) · **Blocks:** SCREEN-1, PROJECT-2
- **Files:** `lib/projects/project.dart` (model), `lib/projects/project_source.dart` (interface + persistent impl stub), `lib/projects/project_controller.dart` (skeleton), `lib/compare/sample_source.dart` (write-side stub), `lib/projects/project_read_endpoint.dart`
- **Tasks:** define `Project` + `ProjectSource` (persisted by DATA's store); `ProjectController` skeleton (no behaviour); `ProjectReadEndpoint` exposing projects list, opened project (note/photo/samples), confusionPairs, lastExport for tests; persistent `SampleSource` write-side stub.
- **Exit criteria:** unit gate on touched files; existing suite green; read endpoint exposes empty state.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

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
