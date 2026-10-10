# Module DATA — persistence & scaffold

**Status:** In progress
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** branch & CI scaffolding for bs-06; `pubspec.yaml` (DB dependency); `lib/store/` (persistent store + source-photo storage); `AppDependencies`/`buildApp` wiring for the store; `integration_test/bs06/pending.dart` + the `BS06_RUN_PENDING` define
**Depends on:** — · **Blocks:** PALETTE, PROJECT (both consume the store)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 4,537,759 | 11m 44s |
| 2 | shell | — | ⬜ Next | | |

## Interface reconciliation

- The store sits **behind** the existing read-only seams `PaletteSource` (`lib/recipes/palette_source.dart`) and `SampleSource` (`lib/compare/sample_source.dart`), adding a write-side without changing their read signatures; PALETTE/PROJECT define the write methods they need and DATA provides the persistent implementation. The recipes code is not touched.
- A new `ProjectSource` (defined in PROJECT-1) is persisted by the same store.
- Spec vs architecture: SI line 209 names a single "Local data store (on-device DB)"; this module is that component. Photo pixels are stored as files referenced by the store (D-10).

## Open gates

- **G-1** (approve the draft spec) ✅ resolved 2026-10-10 by Matt Quirk. **G-3** (bs-04 merged to `main`) ✅ resolved 2026-10-10 (merged @ `2684ac6`). Phase 1 (scaffold) ✅ Done.
- **G-4** blocks Phase 2 (shell): confirm the on-device DB package (D-1) and the reviewed-dataset/PDF decisions before building the store. **DATA-2 cannot start until G-4 is resolved.**

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

### Result

- Landed: branch `feat/bs-06-palette-and-projects` off `main` @ `bfd4289` (bs-04 merged, bs-06 plan + G-1/G-3 resolved) in worktree `/Users/matthew.quirk/Nuance-bs06`. Added `integration_test/bs06/pending.dart` (bs-04 mirror; keyed on `BS06_RUN_PENDING`; **all 11 ACs seeded** → owning phase: AC-1→SCREEN-2, AC-2/3→PALETTE-3, AC-4→PALETTE-2, AC-5→PALETTE-4, AC-6→PROJECT-3, AC-7/8→PROJECT-4, AC-9→PROJECT-5, AC-10→PROJECT-6, AC-11→SCREEN-3; PROJECT-2 enabler owns none) and `integration_test/palette_test.dart` (runner + 3 scaffold integrity guards). No product code.
- Fix passes: 0/3 · Suites run: unit+coverage (host); bs-06 runner on sim under verify lock. Other feature suites not run (scaffold adds no `lib/` code — nothing they exercise changed).
- Tests: 579 unit/widget passing; bs-06 runner 3 guards passing on sim (iPhone 17). Coverage (touched `lib/`): none touched → gate PASS. Acceptance: n/a (no AC tests yet; all 11 pending).
- Helper naming: implemented the proven bs-04 API (`acTestWidgets`/`pendingSkipReason`/`runPending`) rather than the plan's loosely-described `ac(t, "AC-n")`, for cross-feature consistency — ITEST-1/2/3 build on it.
- Gate sanity: planted `lib/_gate_probe.dart` with one uncovered branch (+ an under-exercising test) → gate **FAILED** (`lib/_gate_probe.dart: 2/3 lines, uncovered line 6`, exit 1); removed → gate **PASS** (nothing touched, exit 0). Probe deleted; tree holds only the two scaffold test files.
- Justified exclusions: none
- Closed by: gate pass (scaffold tooling proven both ways)
- Tokens: see master ledger (DATA-1 row). **Phase total: 4,537,759 tokens, 11m 44s active (11m 44s wall).**

### Checkpoint / Handoff

- **Frozen:** `integration_test/bs06/pending.dart` mechanism (`pendingACs`, `behaviorPhases`, `pendingSkipReason`, `acTestWidgets`, `runPending`, `BS06_RUN_PENDING` define). ITEST-2/3 add tests; behaviour phases un-pend by deleting a row — do not rename the API.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · acceptance default `flutter test integration_test/palette_test.dart -d <booted-udid>` / run-pending add `--dart-define=BS06_RUN_PENDING=true`. Flutter SDK: `/Users/matthew.quirk/development/flutter/bin`. Run device/sim commands under `coord.sh with-lock bs-06-palette-and-projects <PHASE>` (wrap in `bash -c 'cd <worktree> && …'` — `with-lock` runs from the coord repo). Always pass `-d <udid>` (no device ⇒ zero tests, false green).
- **Known gaps:** no product code, no harness yet (ITEST-1), no persistent store (DATA-2, gated by G-4).
- **Next phase should:** **DATA-2 is blocked by G-4** (on-device DB package + reviewed-dataset/PDF/project-size decisions). Resolve G-4 first; then DATA-2 adds the persistent store behind the existing seams + a new `ProjectSource`, wired into `AppDependencies`/`buildApp`, with a unit round-trip. Alternatively, with G-4 still open, the shells `PALETTE-1`/`PROJECT-1` are **also** G-4-blocked; nothing else in stage 2 is startable until G-4 resolves.

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
