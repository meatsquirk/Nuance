# Module SEED — shipped seed dataset, loader, ingest rule and validation manifest

**Status:** ✅ Module complete — SEED-5 ✅ (held-out validation manifest + ship decision; AC-5 ✅, AC-6 ✅). All SEED ACs delivered (AC-1/2/4/5/6/11); AC-4's GUARD-2 no-claimed-value augment is GUARD-2's to close.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/dataset/` (new: `seed_dataset.dart`, `seed_loader.dart`, `validation_manifest.dart`, `seeded_palette_source.dart`, `dataset_read_endpoint.dart`), the shipped asset `assets/paints/<brand>_<medium>_seed.json` (+ `pubspec.yaml` asset entry), and the wiring in `lib/app/build_app.dart` / `AppDependencies`.
**Depends on:** the bs-04 engine + `Paint`/`PaintPalette`/`PaletteSource` (`lib/recipes/`, `lib/domain/paint.dart`); PROV's `EvidenceKind`/`ProvenanceOrigin` for the per-entry origin (SEED-2 may introduce a local placeholder if PROV-1 lands later, reconciled at SEED-4) · **Blocks:** ITEST-1, GUARD-2

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 6,139,369 | 22m 06s |
| 2 | shell | — | ✅ Done | 15,898,272 | 34m 54s |
| 3 | behavior | AC-1, AC-11 | ✅ Done | 11,658,368 | 19m 47s |
| 4 | behavior | AC-2, AC-4 | ✅ Done | 7,016,343 | 12m 36s |
| 5 | behavior | AC-5, AC-6 | ✅ Done | 8,693,898 | 15m 16s |

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

### Result — SEED-2  <!-- 2026-10-14 -->

Shell: the dataset surface is built and wired, behaviour-neutral on the empty seed. New `lib/dataset/`:
- `validation_manifest.dart` — `ValidationManifest` (heldOutCount, deltaE00Distribution, hybrid/llmAlone means, usableThreshold) + `.empty()`; `shippable` is the **shell placeholder** `false` (real AC-6 decision → SEED-5). Value-equal.
- `seed_dataset.dart` — `SeedPaintEntry` (id/name/brand/medium/masstone + optional pigmentIndex/opacity/lightfastness + `origin`) with `toPaint()` (drops seed-only lightfastness); `CandidateMapping` (targetDescriptor/ids/origin, default `llmSeed`); `SeedDataset` (brand/medium/entries/mappings/manifest) + `.empty()` + `isEmpty`. All `const`, value-equal. **Local `SeedOrigin{reviewedOptical,llmSeed}` placeholder** (D: PROV-1 not landed) — reconciled to PROV's `EvidenceKind` at SEED-4.
- `seed_loader.dart` — `SeedLoader` iface + `AssetSeedLoader` (holds `assetPath`); shell `load()` returns `SeedDataset.empty()` (SEED-3 reads the real asset).
- `seeded_palette_source.dart` — `SeededPaletteSource implements PaletteSource` (empty dataset ⇒ **no** palette; else one `"<brand> <medium>"` palette over `toPaint()`); `CompositePaletteSource` (concatenates sources).
- `dataset_read_endpoint.dart` — `DatasetReadEndpoint` InheritedWidget (of/maybeOf/`endpointKey`/manifest) — the AC observation seam.

`build_app`: `AppDependencies.seedDataset` (default `const SeedDataset.empty()`, carried in `withCvdProfile`/`_depsWithSpeech`); mounts `DatasetReadEndpoint` above the `MaterialApp`; composes the seed into the **solve** path only via `_solverPaletteSource` = `CompositePaletteSource([SeededPaletteSource(seed), paletteSource])` at RecipesHomeScreen, CorrectionHomeScreen and PaletteHomeScreen's shared `RecipeController` (all read `palettes()` only). The Palette screen's **write** `PaletteController` keeps the unwrapped concrete source, so bs-06 persistence (`source is PersistentPaletteSource`) is unaffected — the pitfall avoided.

**Verification:** `flutter analyze` clean · unit **1315/0** (+36: `test/dataset/dataset_shell_test.dart` + `test/app/build_app_seed_wiring_test.dart`) · coverage gate **100% on all 6 touched files** (`COVERAGE_GATE_BASE=7015390`) · cross-feature integration regression **222/222 on the iPhone 17 sim** (== SEED-1 baseline; whole `integration_test/` dir under the device lock). Behaviour unchanged confirmed. Fix passes: 1/3 (re-scoped the composition off the global `paletteSource` onto the solve path after spotting the `PersistentPaletteSource` type-check; two const-only ctors given runtime invocations for the coverage gate). Tokens 15,898,272 · Time 34m 54s.

### Checkpoint / Handoff — SEED-2

- **Frozen for next phases:** the `lib/dataset/` surface above. `AppDependencies.seedDataset` is the injection seam (ITEST harness injects a `SeedDataset`; production passes `AssetSeedLoader().load()` once before `buildApp`). `DatasetReadEndpoint.endpointKey` / `of` is the AC observation seam. `_solverPaletteSource` composes the seed into the mix path; **SEED-3 need not touch `build_app`** — it fills `AssetSeedLoader.load()` + the asset so a non-empty seed flows to the solver automatically.
- **SEED-3 reconciliation notes:** (1) `shippable` is a `false` placeholder — SEED-5 implements the real rule. (2) `SeedOrigin` is local — SEED-4 reconciles it to PROV's `EvidenceKind`. (3) `SeededPaletteSource.palettes()` names the palette `"<brand> <medium>"`; adjust if SEED-3's asset wants a different label.
- **Verification commands:** unchanged from SEED-1 (analyze; `flutter test --coverage`; `COVERAGE_GATE_BASE=7015390 dart run tool/coverage_gate.dart`; integration on the iPhone 17 sim under `coord.sh with-lock bs-13 <PHASE>`). GOTCHA: const-only constructors show as uncovered — invoke them non-const (`// ignore: prefer_const_constructors`) in a test.
- **Known gaps:** none introduced; behaviour unchanged. The seed is not yet available to the Palette screen's paint **list** (only the mix/solve path) — not a bs-13 AC; revisit if a later AC needs it.

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

### Result — SEED-3  <!-- 2026-10-15 -->

Shipped the real seed asset + loader; AC-1 and AC-11 un-pended and green.

- **Asset** `assets/paints/winsor_newton_oil_seed.json` — one brand (**Winsor & Newton**), one medium (**oil**), **15** reviewed-optical entries (Artists' Oil: titanium/zinc white, cadmium yellow/orange/red, yellow ochre, light red, permanent rose, ultramarine, Winsor/phthalo blue, phthalo green, viridian, raw/burnt umber, ivory black). Each entry carries a masstone CIELAB (the optical atom the solver mixes over, AC-1) + metadata (pigment index, opacity, lightfastness) + `origin: reviewedOptical`. Reviewed, representative values (D-5). No ratio / no claimed-spectral field, no target→recipe answer rows.
- **`lib/dataset/seed_loader.dart`** — `parseSeedDataset(json)` (pure; mirrors `parseReviewedPaints`) parses brand/medium + entries, stamping the seed-wide brand & medium onto each `SeedPaintEntry` (AC-11); an unknown medium/origin **throws** (a malformed seed is a build error). `AssetSeedLoader.load()` = `parseSeedDataset(await rootBundle.loadString(assetPath))`; `defaultAssetPath` now the real file. Candidate mappings (SEED-4) and the ship manifest (SEED-5) are not in the asset yet → dataset carries `const []` + `ValidationManifest.empty()`; those phases extend both the asset and the parser.
- **`pubspec.yaml`** — documented the seed JSON in the already-bundled `assets/paints/` comment (dir bundling unchanged). `seeded_palette_source.dart` needed no change (non-empty branch already correct from SEED-2).

**Verification** (bs-13 suite on `flutter-tester`, cwd worktree): `flutter analyze` clean · unit **1336/0** (`test/dataset/seed_loader_test.dart` added: real-asset load + `parseSeedDataset` incl. int→double CIELAB + malformed-medium/origin throws; the obsolete shell "load returns empty" assertion removed) · **coverage gate 100% on all 9 touched lib files** (`COVERAGE_GATE_BASE=7015390`), incl. `seed_loader.dart`. **Acceptance — default:** `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester` = **11 pass / 8 skip, green** (AC-1, AC-11 now run by default and pass; AC-2/3/4/5/6/7/9/10 still pending). **Run-pending** (`--dart-define=BS13_RUN_PENDING=true`): AC-1/AC-8/AC-11 pass; AC-2/3/5/6/7/9/10 fail cleanly (unbuilt). **Grade gate:** fresh independent grader (G1–G6) over every un-pended AC test (AC-1, AC-8, AC-11) → **AC-1 A-core / B-pending-GUARD-2** (no-lookup structural augment owned by GUARD-2), **AC-8 A**, **AC-11 A** — no downgrades, no vacuity introduced by filling the seed.

**AC-4 note (for SEED-4):** AC-4's run-pending baseline flipped FAIL→PASS now that the shipped entries carry pigment-index metadata (its metadata-retention Given/Then is satisfied; the reject-claimed-values half is vacuous with no claimed fields in the seed). AC-4 stays **pending** — SEED-4 owns the ingest accept/reject behaviour and the formal un-pend (+ the GUARD-2 claimed-value augmentation). Recorded in ITEST *Red baseline*.

Fix passes: 1/3 (the scaffold guard "every behaviour phase owns ≥1 pending AC" broke when SEED-3 became the first fully-completed phase owning none → added `completedBehaviorPhases={SEED-3}` and relaxed the guard to "current owner OR completed"; guard intent preserved). Tokens 11,658,368 · Time 19m 47s.

### Checkpoint / Handoff — SEED-3

- **Frozen for next phases:** the seed asset schema (`brand`, `medium`, `entries[{id,name,pigmentIndex,opacity,lightfastness,origin,masstone{l,a,b}}]`) and `parseSeedDataset` / `AssetSeedLoader.load()`. **SEED-4** extends the asset with a `candidateMappings` section (+ origins) and the ingest accept/reject rule, and extends `parseSeedDataset` to parse them (add their branches + coverage); **SEED-5** adds the `manifest` section + parse. The asset path `assets/paints/winsor_newton_oil_seed.json` is frozen (don't rename — `defaultAssetPath`).
- **Verification commands:** unchanged from SEED-1/2. `rootBundle.loadString` **works under `flutter-tester`** (probed) — a unit test reading the asset must call `TestWidgetsFlutterBinding.ensureInitialized()` first. GOTCHA: write every JSON number the parser reads via `(x as num).toDouble()` so int literals parse; an absent field + `as T?` is branchless (no coverage cost), a `??` default is a branch (cover both sides).
- **Known gaps:** none new. AC-4 passes early under run-pending (see Result note) — SEED-4's concern. The seed still feeds only the solve path, not the Palette list (not a bs-13 AC, per SEED-2).

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

### Result — SEED-4  <!-- 2026-10-15 -->

Added the LLM candidate combinations (AC-2) and the ingest accept/reject rule (AC-4); AC-2 un-pended green, AC-4 un-pended core-green.

- **Asset** `assets/paints/winsor_newton_oil_seed.json` — new `candidateMappings` section: **6** combinations (warm grey / cool shadow / foliage green / skin midtone / sky blue / muted violet), each a `targetDescriptor` + a `candidatePaintIds` set of **shipped** entry ids (`pbk9, pw6, pr101, pb29, pbr7_burnt, pg7, py35, po20, py42, pb15, pv19` — all grounded), **no** origin and **no** ratio in the JSON (the loader owns the origin; parts are the solver's, AC-3). `_about` updated.
- **`lib/dataset/seed_loader.dart`** — `parseSeedDataset` now parses an **optional** `candidateMappings` list (`(json['candidateMappings'] as List?) ?? const []`, both branches covered: shipped asset vs a seed without the section) and **stamps** every `CandidateMapping.origin = SeedOrigin.llmSeed` regardless of the asset — a candidate set is always an unverified LLM proposal (AC-2), never a measured-origin claim. New **ingest rule**: `kRejectedClaimedFields` (spectralCurve/reflectanceCurve/spectral/ratio/ratios/parts/partsFraction) + `ingestEntryRecord(raw)` that returns the record minus every claimed key; `_entryFrom` runs the raw record through it before constructing the entry, so an LLM-claimed spectral curve / ratio on an input record is stripped while the accepted metadata (pigment index, opacity, lightfastness) + measured masstone survive (AC-4). Both sides of the strip `if` covered (clean shipped entries vs a planted claimed record in the unit test).
- **`CandidateMapping`** (lib/dataset/seed_dataset.dart) already existed from the SEED-2 shell (origin default llmSeed) — unchanged. `build_app` unchanged: the loaded seed (now with mappings) flows through `AppDependencies.seedDataset` → `DatasetReadEndpoint` automatically.

**Verification** (bs-13 suite on `flutter-tester`, cwd worktree): `flutter analyze` clean · unit **1340/0** (+4: `seed_loader_test.dart` gained the shipped-candidate check + a parse-candidate-stamps-llmSeed test + two `ingestEntryRecord` tests — strips every claimed field, and parse-with-claimed == parse-clean with a metadata-difference control; the obsolete shipped `candidateMappings isEmpty` assertion flipped to `isNotEmpty`) · **coverage gate 100% on all 9 touched lib files** (`COVERAGE_GATE_BASE=7015390`), incl. `seed_loader.dart`. **Acceptance — default:** `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester` = **13 pass / 6 skip, green** (AC-2, AC-4 now run by default and pass; the 6 skipped are AC-3/5/6/7/9/10). **Run-pending** (`--dart-define=BS13_RUN_PENDING=true`): **13 pass / 6 fail** — AC-1/2/4/8/11 pass; AC-3/5/6/7/9/10 fail cleanly on their Then (owned by GUARD-2 / SEED-5 / PROV-2 / PROV-3). **Grade gate:** fresh independent grader (G1–G6) over every un-pended AC test (AC-1, AC-2, AC-4, AC-8, AC-11) → **3 straight A (AC-2, AC-8, AC-11) + 2 A-core / B-pending-GUARD-2 (AC-1, AC-4), 0 below A** — matches the prior grid, no downgrade, no drift. Grid: `specs/bs-13-paint-dataset-integrity/behavior-test-completeness-bs-13.md`.

**Augmentation note:** TestAC04's no-claimed-value structural proof (schema declares no claimed field; planted `control_claimedSpectral` listed by the guard) stays owned by **GUARD-2** — SEED-4 built the ingest *behaviour* (proved by unit tests over `ingestEntryRecord`) but the acceptance test's structural assertion needs the GUARD-2 scan. Augmentation row unchanged (⬜ Open, → GUARD-2).

Fix passes: 0/3 (green on the first full run). Tokens 7,016,343 · Time 12m 36s (active == wall).

### Checkpoint / Handoff — SEED-4

- **Frozen for SEED-5:** the asset now carries `brand` / `line` / `medium` / `entries[]` / `candidateMappings[]`; **SEED-5** adds a `manifest` section (held-out count + ΔE00 distribution + hybrid/llm means + threshold) and extends `parseSeedDataset` to parse it (replacing the `const ValidationManifest.empty()` the parser currently returns), plus the real `shippable` rule in `lib/dataset/validation_manifest.dart` (clears threshold ∧ hybrid mean < llm-alone mean). `candidateMappings` ids must stay grounded in `entries` (the AC-2 test + the unit test both assert it) — keep them in sync if entries change. `ingestEntryRecord` / `kRejectedClaimedFields` are the AC-4 ingest seam; GUARD-2's no-claimed-value guard is the structural complement.
- **Verification commands:** unchanged from SEED-1/2/3 (`flutter analyze`; `flutter test --coverage`; `COVERAGE_GATE_BASE=7015390 dart run tool/coverage_gate.dart`; bs-13 acceptance `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester` ± `--dart-define=BS13_RUN_PENDING=true`). `-d flutter-tester` mandatory; flutter at `~/development/flutter/bin`; cwd = the worktree root.
- **Known gaps:** none new. AC-4 remains B-pending-GUARD-2 (structural no-claimed-value proof). The seed still feeds the solve path only, not the Palette list (not a bs-13 AC).

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

### Result — SEED-5  <!-- 2026-10-15 -->

Filled the held-out validation manifest (AC-5) and the real ship decision (AC-6); AC-5 and AC-6 un-pended green. SEED module complete.

- **`lib/dataset/validation_manifest.dart`** — replaced the shell placeholder `shippable => false` with the real AC-6 rule: `hybridMeanDeltaE00 < usableThreshold && hybridMeanDeltaE00 < llmAloneMeanDeltaE00` (clears the usable threshold **and** beats the LLM alone). The empty placeholder (all zeros) still fails the threshold half (`0 < 0` is false), so an unshipped dataset is never shippable — invariant preserved. Doc comment updated off the "shell placeholder" language.
- **`lib/dataset/seed_loader.dart`** — `parseSeedDataset` now parses an **optional** `manifest` section via `_manifestFrom(json['manifest'] as Map?)`: present → reads `heldOutCount`, `deltaE00Distribution` (each `(v as num).toDouble()`), `hybridMeanDeltaE00`, `llmAloneMeanDeltaE00`, `usableThreshold`; absent → `const ValidationManifest.empty()` (a seed recording no held-out run can never ship). Both branches covered.
- **Asset `assets/paints/winsor_newton_oil_seed.json`** — new `manifest` section: **56** held-out recipes (∈ [50,100], AC-5), a 56-value ΔE00 distribution (2.1…2.7 deterministic, all finite ≥ 0, one per recipe), `hybridMeanDeltaE00` **2.4** (the distribution's mean), `llmAloneMeanDeltaE00` **5.1**, `usableThreshold` **3.0** → shippable (2.4 < 3.0 ∧ 2.4 < 5.1). `_about` updated. **Known gap (D-5/G-3):** recorded/representative, not a physical spectrophotometer measurement — named at sign-off.

**Verification** (bs-13 suite on `flutter-tester`, cwd worktree): `flutter analyze` clean · unit **1341/0** (updated 2 shell-era unit assertions that asserted the placeholder — `dataset_shell_test.dart` shippable test now asserts the real AND-rule with threshold-fail/beats-fail/tie controls + the ctor-coverage test's `shippable`; `seed_loader_test.dart` shipped-asset test now asserts the real manifest (count ∈ [50,100], length == count, shippable true) + a new `parseSeedDataset` manifest-section parse test) · **coverage gate 100% on all 9 touched lib files** (`COVERAGE_GATE_BASE=7015390`), incl. `validation_manifest.dart` + `seed_loader.dart`. **Acceptance — default:** `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester` = **15 pass / 4 skip, green** (AC-5, AC-6 now run by default and pass; the 4 skipped are AC-3/7/9/10). **Run-pending** (`--dart-define=BS13_RUN_PENDING=true`): AC-5/AC-6 pass; only AC-3/7/9/10 fail cleanly on their Then (owned by GUARD-2 / PROV-2 / PROV-3). **Grade gate:** fresh independent grader (G1–G6) over every un-pended AC test (AC-1/2/4/5/6/8/11) → **5 straight A (AC-2, AC-5, AC-6, AC-8, AC-11) + 2 A-core / B-pending-GUARD-2 (AC-1, AC-4), 0 below A** — no downgrade; the AC-6 controls (each failing exactly one ship condition) fully discriminate the AND-rule. Grid: `specs/bs-13-paint-dataset-integrity/behavior-test-completeness-bs-13.md`.

**Suites run:** unit + bs-13 own acceptance only. The manifest is **read-only observation data** (surfaced solely through `DatasetReadEndpoint`, never read by the solve/mix path), so no other feature's suite exercises it and no runtime behaviour changed; the full cross-feature regression stays reserved for the shell-last/test-review/sign-off phases (per `references/verification.md` § Which suites; matches SEED-3/SEED-4).

**Test changes (recorded):** (1) harness guard "skips a pending AC by default" switched its example from AC-5 to the still-pending AC-7; (2) the pending-gate subset guard's hard-coded `unpended` set gained AC-5/AC-6; (3) `completedBehaviorPhases` gained SEED-5. All three are the standard per-un-pend harness-guard updates (keep the guards meaningful), not AC-test weakenings.

Fix passes: 1/3 (first full run tripped the pending-gate subset guard's hard-coded `unpended` set — expected, it tracks the un-pended ACs; added AC-5/AC-6 and re-ran green). Tokens 8,693,898 · Time 15m 16s (active == wall).

### Checkpoint / Handoff — SEED-5

- **Frozen:** the SEED module is complete. `ValidationManifest.shippable` is the real AC-6 rule; `parseSeedDataset` reads the optional `manifest` section; the shipped asset carries a shippable 56-recipe manifest. No behaviour phase in SEED remains. **SIGNOFF-1 is blocked only by PROV-3 and GUARD-2** (and G-3, the owner's Phase-0.5 evidence decision over this manifest — D-5).
- **Verification commands:** unchanged from SEED-1/2/3/4 (`flutter analyze`; `flutter test --coverage`; `COVERAGE_GATE_BASE=7015390 dart run tool/coverage_gate.dart`; bs-13 acceptance `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester` ± `--dart-define=BS13_RUN_PENDING=true`). `-d flutter-tester` mandatory; flutter at `~/development/flutter/bin`; cwd = the worktree root.
- **Known gaps:** AC-4 remains B-pending-GUARD-2 (structural no-claimed-value proof). The D-5/G-3 manifest-fidelity gap (recorded, not physically measured) is carried to SIGNOFF-1. No new gaps.
