# Module DATA — persistence & scaffold

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** branch & CI scaffolding for bs-06; `pubspec.yaml` (DB dependency); `lib/store/` (persistent store + source-photo storage); `AppDependencies`/`buildApp` wiring for the store; `integration_test/bs06/pending.dart` + the `BS06_RUN_PENDING` define
**Depends on:** — · **Blocks:** PALETTE, PROJECT (both consume the store)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ⬜ Todo | | |
| 2 | shell | — | ⬜ Todo | | |

## Interface reconciliation

- The store sits **behind** the existing read-only seams `PaletteSource` (`lib/recipes/palette_source.dart`) and `SampleSource` (`lib/compare/sample_source.dart`), adding a write-side without changing their read signatures; PALETTE/PROJECT define the write methods they need and DATA provides the persistent implementation. The recipes code is not touched.
- A new `ProjectSource` (defined in PROJECT-1) is persisted by the same store.
- Spec vs architecture: SI line 209 names a single "Local data store (on-device DB)"; this module is that component. Photo pixels are stored as files referenced by the store (D-10).

## Open gates

- **G-1** (approve the draft spec) ✅ resolved 2026-10-10 by Matt Quirk. **G-3** (bs-04 merged to `main`) ✅ resolved 2026-10-10 (merged @ `2684ac6`). Phase 1 (scaffold) is now startable.
- **G-4** blocks Phase 2 (shell): confirm the on-device DB package (D-1) and the reviewed-dataset/PDF decisions before building the store.

## Phase 1 — Scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (gated by G-1, G-3) · **Blocks:** DATA-2
- **Files:** `integration_test/bs06/pending.dart`, `integration_test/palette_test.dart` (empty runner target), CI note if needed
- **Tasks:**
  1. Branch `feat/bs-06-palette-and-projects` from `main` **after** bs-04 is merged (G-3); record the branch point commit.
  2. Baseline: `flutter analyze` clean, `flutter test --coverage` green, `dart run tool/coverage_gate.dart main` passes on the clean tree.
  3. Add the bs-06 pending-gate skeleton `integration_test/bs06/pending.dart` with the `ac(t, "AC-n")` helper keyed on `BS06_RUN_PENDING` (dart-define), every AC-1..11 pending → owning phase; and a `palette_test.dart` runner entry.
  4. Gate sanity: confirm the coverage gate **fails** on a planted uncovered line and passes once removed.
- **Exit criteria:** branch exists off merged-bs-04 `main`; baseline recorded (analyze/test/coverage all green); pending gate compiles with all 11 ACs pending; gate proven to fail-on-gap and pass-on-clean. No product code.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — Persistent store shell

- **Kind:** shell
- **Target AC:** —
- **Depends on:** DATA-1 (gated by G-4) · **Blocks:** PALETTE-1, PROJECT-1
- **Files:** `pubspec.yaml`, `lib/store/` (store interface + on-device impl + source-photo file storage), `lib/app/build_app.dart` + `AppDependencies` (inject the store), `assets/` registration if the DB needs a path
- **Tasks:**
  1. Add the chosen on-device DB package (G-4) to `pubspec.yaml` (project-local dependency only).
  2. Define a persistent store interface (open/migrate; CRUD primitives the sources need) + its on-device implementation; keep it behind an interface so tests can substitute an in-memory-backed double exercising the same contract.
  3. Add source-photo storage (store a file reference; a fake sink is used in tests — D-10).
  4. Wire the store into `AppDependencies`/`buildApp` in the existing injection pattern; production assembly unchanged in behaviour (no screen yet).
- **Exit criteria:** unit gate (100% line coverage on touched `lib/` files) passes; existing suite stays green; store opens/migrates and round-trips a primitive in a unit test; no behaviour change to shipped screens.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
