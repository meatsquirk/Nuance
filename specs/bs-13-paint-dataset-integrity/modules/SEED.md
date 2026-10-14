# Module SEED — shipped seed dataset, loader, ingest rule and validation manifest

**Status:** In progress — SEED-1 ✅ (scaffold); next SEED-2 (shell)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/dataset/` (new: `seed_dataset.dart`, `seed_loader.dart`, `validation_manifest.dart`, `seeded_palette_source.dart`, `dataset_read_endpoint.dart`), the shipped asset `assets/paints/<brand>_<medium>_seed.json` (+ `pubspec.yaml` asset entry), and the wiring in `lib/app/build_app.dart` / `AppDependencies`.
**Depends on:** the bs-04 engine + `Paint`/`PaintPalette`/`PaletteSource` (`lib/recipes/`, `lib/domain/paint.dart`); PROV's `EvidenceKind`/`ProvenanceOrigin` for the per-entry origin (SEED-2 may introduce a local placeholder if PROV-1 lands later, reconciled at SEED-4) · **Blocks:** ITEST-1, GUARD-2

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 6,139,369 | 22m 06s |
| 2 | shell | — | ⬜ Todo | | |
| 3 | behavior | AC-1, AC-11 | ⬜ Todo | | |
| 4 | behavior | AC-2, AC-4 | ⬜ Todo | | |
| 5 | behavior | AC-5, AC-6 | ⬜ Todo | | |

## Interface reconciliation

- **Seed entry vs `Paint`.** `SeedPaintEntry` carries the solver's optical data (`masstone` CIELAB), the LLM-trusted metadata (`pigmentIndex`, `opacity`, `lightfastness`), and a provenance `origin`. It maps to the frozen bs-04 `Paint` (`id`, `name`, `medium`, `masstone`, `pigmentIndex`, `opacity`) via a `toPaint()` — SEED never changes `Paint`'s shape. `lightfastness` is seed-only metadata (not on `Paint`).
- **No ratios, no claimed spectral curves.** The seed schema has **no** ratio field and **no** reflectance-curve field. Ratios are solver output (AC-3/GUARD-2); spectral curves belong to the deferred measured-pigment engine, not the v1 seed. The ingest rule (SEED-4) strips any such field from an input record.
- **`PaletteSource` seam (bs-04 D-5).** `SeededPaletteSource implements PaletteSource` lists the shipped seed as a palette. bs-06's persistent user palettes coexist behind the same interface; `build_app` composes both (the shipped seed is always available, user palettes add to it). SEED does not touch bs-06's store.
- **Candidate mappings & manifest.** `SeedDataset` carries the optical entries, the LLM `candidateMappings` (target descriptor → candidate paint-id set, origin `llmSeed`), and the `ValidationManifest`. `DatasetReadEndpoint` exposes all three for the acceptance suite.

## Open gates

- **G-1** (approve the spec) — ✅ Resolved 2026-10-14 16:06: approved — Matt Quirk (spec banner flipped to approval line). SEED-1 unblocked.
- **G-3** (owner confirms real Phase-0.5 evidence, or accepts the gap) is a SIGNOFF-1 decision over SEED-5's manifest (D-5).

## Phase 1 — Scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1) · **Blocks:** SEED-2, PROV-1, GUARD-1
- **Files:** none in `lib/`; branch + CI only
- **Tasks:**
  1. Branch `feat/bs-13-paint-dataset-integrity` off `main` @ `7015390` (confirm the PLAN commit is its first commit).
  2. Baseline: `flutter analyze`, `flutter test` (unit) and the full `integration_test` acceptance run — record counts (the inherited green baseline).
  3. Self-check the toolchain: run the coverage gate (`tool/coverage_gate.dart`) on the clean tree (passes) and on a planted uncovered line (fails); confirm `flutter test integration_test/... -d flutter-tester` runs tests (not zero) — the repo already has both, so this is a verify, not a build.
- **Exit criteria:** branch exists off `7015390`; baseline counts recorded in the Result; coverage gate + acceptance runner proven to pass-clean / fail-on-gap. No product code.

### Result — SEED-1  <!-- 2026-10-14 -->

Scaffold **verify** (no product code; branch + toolchain already inherited). Branch `feat/bs-13-paint-dataset-integrity` confirmed off `main` @ `7015390`: its first commit is the PLAN `87c405e` (parent `7015390`), then GATE-DECISION `ffc69a1` — `BASE` for this phase. (`main` has since advanced to `de88ee1` with bs-11 merged + bs-12 PLAN; no rebase at scaffold — bs-13 adds no `lib/`.)

**Baseline recorded (inherited, green):**
- `flutter analyze` → **No issues found** (0 warnings/errors).
- Unit: `flutter test` → **1279 pass / 0 fail**; `coverage/lcov.info` emitted.
- Integration (whole suite green on the **iPhone 17 sim**): **222 pass / 0 fail** across the 11 `integration_test/*_test.dart` files.

**Toolchain self-check (`tool/coverage_gate.dart`, `COVERAGE_GATE_BASE=7015390`):**
- Clean tree → `no touched lib/**.dart files — nothing to gate. PASS` (exit 0).
- Planted uncovered line in `lib/readout/temperature_line.dart` → `FAIL — 4/5 lines covered — uncovered lines: 23` (exit 1); probe reverted, tree clean.
- Acceptance runner: `flutter test <file> -d flutter-tester` runs non-zero tests (not a false-green) — `-d` mandatory.

**Host-vs-sim note (non-regression):** on the host `flutter-tester` device the whole-dir run cannot relaunch the app between files (run **per-file**), and 4 UI/persistence tests fail — bs-06 `palette_test` AC-3 (provenance-legend region absent) + AC-5 (palette text absent), bs-07 `self_assessment_test` AC-4 (seeded prior = null), bs-08 `display_test` AC-9 (speech phrasing). All 4 are **green on the iPhone 17 sim** (verified under the device lock: display 21/0, palette 23/0, self_assessment 24/0) — they need platform channels (sqlite/path_provider) + real rendering that the host lacks. bs-13's own suite is pure-Dart dataset/model → `flutter-tester`-clean. Logged in Known flakes.

Fix passes: 0/3 (verify only). No `lib/` change → coverage gate not applicable beyond the self-check. Tokens 6,139,369 · Time 22m 06s (active == wall).

### Checkpoint / Handoff — SEED-1

- **Frozen for next phases:** branch off `main` @ `7015390`; `BASE` = `ffc69a1`. SEED-2 ∥ PROV-1 ∥ GUARD-1 are now startable (disjoint file ownership — see master plan Parallel windows).
- **Verification commands** (reuse; `export PATH="$HOME/development/flutter/bin:$PATH"`, no `timeout` on macOS):
  - Analyze: `flutter analyze`
  - Unit + coverage: `flutter test --coverage`
  - Coverage gate: `COVERAGE_GATE_BASE=7015390 dart run tool/coverage_gate.dart` (pin base to the merge-base, not `main`, so bs-11's merged `lib/` isn't counted as touched)
  - bs-13 own acceptance (once ITEST lands): `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester` (+ `--dart-define=BS13_RUN_PENDING=true` for red baseline)
  - Cross-feature regression: run **per-file**; UI/persistence files (`palette`, `self_assessment`, `display`, …) on the **iPhone 17 sim** via `coord.sh with-lock bs-13 <PHASE> --wait 900 -- …`; pure-Dart files fine on `flutter-tester`.
- **Known gaps:** none introduced. The 4 host-only failures are pre-existing platform-channel/rendering differences, not regressions.

## Phase 2 — Shell: dataset types, loader, seeded palette source, read endpoint

- **Kind:** shell
- **Target AC:** — (wires the surface the ACs observe)
- **Depends on:** SEED-1 · **Blocks:** ITEST-1
- **Files:** `lib/dataset/seed_dataset.dart`, `lib/dataset/seed_loader.dart`, `lib/dataset/validation_manifest.dart`, `lib/dataset/seeded_palette_source.dart`, `lib/dataset/dataset_read_endpoint.dart`; `lib/app/build_app.dart` (wiring)
- **Tasks:**
  1. `SeedPaintEntry` (id, name, brand, medium, masstone, pigmentIndex?, opacity?, lightfastness?, origin) + `toPaint()`; value-equal, `const`.
  2. `CandidateMapping` (target descriptor, candidate paint-ids, origin) and `SeedDataset` (brand, medium, entries, candidateMappings, manifest). `ValidationManifest` (heldOutCount, deltaE00Distribution, hybridMeanDeltaE00, llmAloneMeanDeltaE00, usableThreshold, shippable getter) — shapes only, no logic yet.
  3. `SeedLoader` interface + `AssetSeedLoader` (reads the asset); **shell returns an empty/placeholder dataset** so assembly is behavior-neutral until SEED-3.
  4. `SeededPaletteSource implements PaletteSource` over the loaded dataset (empty in the shell).
  5. `DatasetReadEndpoint`: exposes the loaded `SeedDataset` + `ValidationManifest` for the acceptance suite (a read-only observation seam).
  6. Wire `AssetSeedLoader` + `SeededPaletteSource` into `build_app`/`AppDependencies` behind defaults that keep the existing suite green.
- **Exit criteria:** unit gate (100% on touched files); the existing unit + acceptance suites stay green; behavior unchanged (empty seed).
- **Acceptance gate:** —
- **Augments:** —

## Phase 3 — AC-1, AC-11: ship the seed asset + loader; solve from it

- **Kind:** behavior
- **Target AC:** AC-1 (full), AC-11 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SEED-4, GUARD-2
- **Files:** `assets/paints/<brand>_<medium>_seed.json`, `pubspec.yaml`, `lib/dataset/seed_loader.dart`, `lib/dataset/seeded_palette_source.dart`
- **Tasks:**
  1. Author the shipped seed asset: **one brand, one medium, ~15 paints** (12–18), each entry with a masstone CIELAB (optical data) + metadata + origin. Reviewed representative values (D-5).
  2. `AssetSeedLoader` loads and parses the asset into a `SeedDataset`; `SeededPaletteSource` exposes it as a palette the solver can mix from.
  3. Prove AC-1: a recipe for a target is produced by `realEngine.inverse` over the seed's optical data — not retrieved as a stored answer (the seed has no answer rows to retrieve from).
- **Exit criteria:** unit gate; acceptance gate below.
- **Acceptance gate:** un-pend AC-1, AC-11; `TestAC01_RecipesSolvedFromOpticalData` and `TestAC11_ShippedSeedStaysNarrow` green (and all earlier ACs).
- **Augments:** `TestAC01`: once GUARD-2 lands, add the no-lookup-table structural assertion + the `control_lookupTable` rejection.

## Phase 4 — AC-2, AC-4: candidate-origin manifest + ingest accept/reject

- **Kind:** behavior
- **Target AC:** AC-2 (full), AC-4 (full)
- **Depends on:** SEED-3 · **Blocks:** SEED-5
- **Files:** `lib/dataset/seed_loader.dart` (ingest rule), `lib/dataset/seed_dataset.dart` (candidate mappings), the seed asset (candidate mappings + metadata)
- **Tasks:**
  1. Stamp every `CandidateMapping` with origin `llmSeed` (the LLM proposes the paint sets); expose via `DatasetReadEndpoint` (AC-2).
  2. Ingest rule in `AssetSeedLoader`: **accept** metadata fields (pigment index, opacity, lightfastness); **reject/strip** any claimed spectral-curve or ratio field on an input record, retaining the valid metadata (AC-4).
  3. Prove the split with `control_claimedSpectral` (metadata kept, claimed values absent from the stored entry).
- **Exit criteria:** unit gate; acceptance gate below.
- **Acceptance gate:** un-pend AC-2, AC-4; `TestAC02_CandidatesFromLlm` and `TestAC04_MetadataAcceptedClaimedValuesRejected` green (and all earlier ACs).
- **Augments:** `TestAC04`: once GUARD-2 lands, add the schema guard that no stored entry carries a claimed spectral/ratio field.

## Phase 5 — AC-5, AC-6: validation manifest + ship decision

- **Kind:** behavior
- **Target AC:** AC-5 (full), AC-6 (full)
- **Depends on:** SEED-4 · **Blocks:** SIGNOFF-1
- **Files:** `lib/dataset/validation_manifest.dart`, the seed asset's manifest section
- **Tasks:**
  1. Fill the `ValidationManifest`: a held-out recipe set (count in [50, 100]) with a recorded ΔE00 distribution (summary stats), plus `hybridMeanDeltaE00`, `llmAloneMeanDeltaE00`, `usableThreshold` (AC-5).
  2. Implement the `shippable` decision: **true iff** the distribution clears `usableThreshold` **and** `hybridMeanDeltaE00 < llmAloneMeanDeltaE00` (AC-6).
  3. Prove the controls `control_manifestFailThreshold` / `control_manifestFailBeatsLlm` are each **not shippable**.
- **Exit criteria:** unit gate; acceptance gate below. **Known gap (D-5/G-3):** the manifest is recorded/representative, not a physical measurement — named at sign-off.
- **Acceptance gate:** un-pend AC-5, AC-6; `TestAC05_HeldOutValidationRecorded` and `TestAC06_SeedShipsOnlyOnEvidence` green (and all earlier ACs).
- **Augments:** —

<!-- Per-phase Result / Checkpoint sections are recorded under each phase above as `### Result — <PHASE>` / `### Checkpoint / Handoff — <PHASE>`. -->
