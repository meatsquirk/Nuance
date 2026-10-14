# Module SEED — shipped seed dataset, loader, ingest rule and validation manifest

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/dataset/` (new: `seed_dataset.dart`, `seed_loader.dart`, `validation_manifest.dart`, `seeded_palette_source.dart`, `dataset_read_endpoint.dart`), the shipped asset `assets/paints/<brand>_<medium>_seed.json` (+ `pubspec.yaml` asset entry), and the wiring in `lib/app/build_app.dart` / `AppDependencies`.
**Depends on:** the bs-04 engine + `Paint`/`PaintPalette`/`PaletteSource` (`lib/recipes/`, `lib/domain/paint.dart`); PROV's `EvidenceKind`/`ProvenanceOrigin` for the per-entry origin (SEED-2 may introduce a local placeholder if PROV-1 lands later, reconciled at SEED-4) · **Blocks:** ITEST-1, GUARD-2

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
