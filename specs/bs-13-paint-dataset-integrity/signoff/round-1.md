# Sign-off packet — Paint dataset integrity and provenance (bs-13) — Round 1

**Feature:** bs-13-paint-dataset-integrity · **Spec:** [bs-13-paint-dataset-integrity.feature](../../bs-13-paint-dataset-integrity.feature)
**Prepared:** 2026-10-15 (SIGNOFF-1) · **At code:** `feat/bs-13-paint-dataset-integrity` @ `b7b9b26` (GUARD-2; the sign-off commit is stamped on the decision)
**Decision:** ⏸ **Awaiting** — recorded via `/feature-next-phase --signoff bs13 approved | changes "<items>"`

bs-13 keeps the shipped paint data honest. It ships a **read-only seed dataset asset + loader** (`lib/dataset/`: one brand / one medium / 15 paints, each entry carrying per-paint optical data + metadata + a provenance origin), extends the **runtime provenance/evidence model** (`lib/domain/`: an `EvidenceKind` on each evidence point, a tier-by-origin derivation, an append-only add, and the Estimated→Confirmed promotion rule), and adds three **reusable integrity guards** (test-support only, `integration_test/bs13/guards/`: ratios-only-from-the-solver, no-lookup-table, no-claimed-value-stored). All 11 acceptance criteria are automated, coded, un-pended and green by default == run-pending (the pending map is empty). A fresh independent whole-suite re-grade is **11 A / 0 below A**. This packet is the evidence for the decision.

**G-3 resolved at this sign-off (2026-10-15, Matt Quirk): the named gap D-5 is accepted.** The bs-13 automated tests prove the manifest's *shape* (held-out count 50–100 + a one-ΔE00-per-recipe distribution) and the *ship-decision logic* (clears threshold **and** hybrid beats LLM-alone) over a recorded/representative validation manifest, and the seed's optical values are a reviewed representative set — **not** a physical spectrophotometer run. The real Phase-0.5 weekend-of-swatching validation is owned by the Phase-0.5 accuracy gate and is carried here as the one known gap.

---

## 1. Preconditions (checked mechanically, not from memory)

| Precondition | State |
|---|---|
| Every other phase done | ✅ 14/14 build phases ✅ Done (SEED-1…5, PROV-1…3, GUARD-1/2, ITEST-1…4) |
| Every AC ✅ in the coverage table | ✅ AC-1…AC-11 all ✅ Done (all 11 automated) |
| Pending list empty | ✅ `integration_test/bs13/pending.dart` → pending set empty; all 11 ACs run in **both** default and run-pending modes (19/0 == 19/0) |
| No open row in ITEST *Test augmentations* | ✅ all three closed — AC-1 no-lookup → GUARD-2, AC-4 no-claimed-value → SEED-4 (ingest) + GUARD-2 (schema guard), AC-9 promotion → PROV-3 |
| Fresh whole-suite grade grid all A | ✅ **11 A / 0 below A** (fresh-context adversarial grader, this session; appended to [behavior-test-completeness-bs-13.md](../behavior-test-completeness-bs-13.md) as "SIGNOFF-1 — whole-suite re-grade") |
| Decision/dependency gates | G-1 (spec) ✅, G-2 (test review) ✅. **G-3 (AC-5/AC-6 real-world fidelity, D-5) resolved at this sign-off — gap accepted by the owner** |

---

## 2. Full verification (worktree `Nuance-bs13` on `feat/bs-13-paint-dataset-integrity` @ `b7b9b26`, this session)

Toolchain: Flutter (project-local, `~/development/flutter`). bs-13's own acceptance suite runs on **`-d flutter-tester`** (the host VM, cwd = repo root): it is pure-Dart (seed dataset / provenance model / source-scan guards; no camera, no platform channels), so no iOS-sim device is needed and none is used for it. The **cross-feature regression** of the other 11 feature suites (bs-01…bs-10, inherited from `main` @ `7015390`) runs on the iOS **simulator** (one booted iPhone 17, under the shared device lane via `coord.sh with-lock`) because those suites need sqlite/path_provider platform channels + real rendering the host lacks. Machine-readable results (`flutter test --machine`) were produced on this run; the summary page (§7) is built from them.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze lib integration_test/bs13` | **No issues found!** (clean) |
| Unit + coverage | `flutter test --coverage` | **1352 passed, 0 failed, 0 skipped** |
| Coverage gate | `COVERAGE_GATE_BASE=7015390 dart run tool/coverage_gate.dart main` | **PASS** — 100% line coverage on all touched `lib/` files (first run; no flake) |
| Acceptance — bs-13 (default) | `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester --machine` | **19 passed, 0 failed, 0 skipped** |
| Acceptance — bs-13 (run-pending) | same `+ --dart-define=BS13_RUN_PENDING=true` | **19 passed, 0 failed, 0 skipped** — identical to default (pending map empty) |
| Cross-feature regression — bs-01…bs-10 suites | `flutter test integration_test/{advanced_capture,capture,comparison,correction,daltonization,display,harness,palette,readout,recipes,self_assessment}_test.dart -d <iPhone 17 udid> --machine` | **222 passed, 0 failed, 0 skipped** |
| **Cross-feature regression — total** | bs-13 (flutter-tester 19) + bs-01…bs-10 (sim 222) | **241 passed, 0 failed, 0 skipped** |
| Grade grid (fresh context) | whole-suite re-grade vs G1–G6 | **11 A / 0 below A — PASS** |

Per-suite (sim): advanced_capture 21 · capture 19 · comparison 26 · correction 22 · daltonization 25 · display 21 · harness 5 · palette 23 · readout 12 · recipes 24 · self_assessment 24 = **222** (== the SEED-1 baseline exactly; no regression).

**What bs-13 changes in `lib/`:** a new `lib/dataset/` package (seed dataset types, `SeedLoader`/`AssetSeedLoader`, `SeededPaletteSource`, `DatasetReadEndpoint`, `ValidationManifest`) wired through `lib/app/build_app.dart` behind the existing `PaletteSource` seam, and an extension of `lib/domain/` provenance (`EvidenceKind`, `ProvenanceDerivation` with `tierFor` / `appendEvidence` / `promoteWithOwnSwatch`, `ProvenanceReadEndpoint`). The seed asset is read-only; the mixing engine, colour science and the rest of the app are untouched. Everything else bs-13 ships is reusable test-support under `integration_test/bs13/`.

---

## 3. Per-AC result

Each AC's acceptance test is un-pended and green in both modes; every formerly-red AC had a genuine red baseline at ITEST-2/3 (AC-8 was green-at-baseline — the append-ready list shape already existed — and its behaviour phase keeps it green under unit coverage). Each test carries a discriminating control; the structural facets of AC-1/AC-3/AC-4 are proven by the reusable guards.

| AC | Scenario (Rule) | Acceptance test (integration) | Behaviour phase(s) | Status |
|---|---|---|---|---|
| AC-1 | Recipes are solved from stored optical data, not looked up | `TestAC01_RecipesSolvedFromOpticalData` | SEED-3 (+ GUARD-2 no-lookup augment) | ✅ A |
| AC-2 | Candidate paint combinations come from the LLM | `TestAC02_CandidatesFromLlm` | SEED-4 | ✅ A |
| AC-3 | Every shipped ratio comes from the solver, never the LLM | `TestAC03_RatiosFromSolverNeverLlm` | GUARD-2 | ✅ A |
| AC-4 | LLM metadata accepted, LLM-claimed measured values rejected | `TestAC04_MetadataAcceptedClaimedValuesRejected` | SEED-4 (+ GUARD-2 no-claimed-value augment) | ✅ A |
| AC-5 | A held-out recipe set is mixed and measured before shipping | `TestAC05_HeldOutValidationRecorded` | SEED-5 | ✅ A |
| AC-6 | The seed ships only if it clears the threshold and beats the LLM alone | `TestAC06_SeedShipsOnlyOnEvidence` | SEED-5 | ✅ A |
| AC-7 | Every value carries an enforced provenance tier (4 origins) | `TestAC07_EnforcedProvenanceTierByOrigin` | PROV-2 | ✅ A |
| AC-8 | Evidence behind a value is stored append-only | `TestAC08_EvidenceAppendOnly` | PROV-2 | ✅ A |
| AC-9 | An Estimated value is promoted only by a photographed/measured swatch | `TestAC09_PromotedOnlyByMeasuredSwatch` | PROV-3 | ✅ A |
| AC-10 | Opinions never promote a value | `TestAC10_OpinionsNeverPromote` | PROV-3 | ✅ A |
| AC-11 | The shipped seed covers one brand, one medium and ~15 paints | `TestAC11_ShippedSeedStaysNarrow` | SEED-3 | ✅ A |

**Reusable integrity guards** (the acceptance mechanism for AC-1/3/4, `integration_test/bs13/guards/`, no product code):
- `ratioProvenanceGuard` (AC-3) — scans `lib/` for any `partsFraction:` production site outside the two sanctioned authorities (`subtractive_engine.dart` the physics solver, which originates ratios; `project_source.dart` which only rehydrates a previously-solver-produced persisted ratio — spec-faithful, grader-confirmed as the *only* two production sites), and scans the seed schema for a declared ratio field. Shipped result: **zero offenders**; control `control_llmRatio` is flagged.
- `noLookupTableGuard` (AC-1) — rejects a stored target-colour→recipe answer mapping. Shipped schema: **empty**; control `control_lookupTable` names the planted `control_lookup_table.dart`.
- `noClaimedValueGuard` (AC-4) — rejects any LLM-claimed spectral curve / ratio field in the seed schema. Shipped schema: **empty**; control `control_claimedSpectral` names the planted `control_claimed_spectral.dart`.

---

## 4. Design decisions behind the acceptance (for the reviewer)

- **D-1 Verify via shipped manifest + guards; no live pipeline.** bs-13 ships no runtime LLM and no in-app network path (SI: offline, single-user). The build-time seeding/validation is carried as a reviewed shipped manifest, and bs-13 asserts the integrity invariants hold on what ships via reusable guards.
- **D-3 Provenance tier derived from append-only evidence, enforced in the domain model** (SI D9), not UI policy. bs-13 owns the enforced schema **rule**; the self-confirmation *flow* (capturing the swatch) stays bs-05/capture.
- **D-4 Guards are reusable test-support, no product code** — keeps the coverage gate scoped to the real product changes (dataset + provenance model).
- **D-7 AC-10 (opinions never promote) is a schema invariant, not a voting feature** — the single-user app has no voting UI.

---

## 5. Known gaps and deferred items

- **D-5 (accepted at G-3) — manifest validation is recorded, not physical.** AC-5/AC-6 prove the manifest's shape (held-out count 56 ∈ [50,100] + a one-ΔE00-per-recipe distribution) and the ship-decision logic (clears usable threshold **AND** hybrid mean ΔE00 < LLM-alone mean), over a recorded/representative manifest — **not** a spectrophotometer measurement; the seed's optical values are a reviewed representative set, not instrument-measured. The physical Phase-0.5 validation (SI: a weekend of swatching) is owned by the Phase-0.5 accuracy gate. **Accepted by the owner at this sign-off.**
- **Measured tier is reachable by schema but not exercised by shipped data.** `ProvenanceDerivation.tierFor` maps a spectrophotometer origin → Measured; the shipped seed carries no instrument-measured entry (it needs the deferred measured-pigment engine, SI). The rule is enforced and unit/acceptance-tested via fixtures; no shipped value claims Measured falsely.
- No open **Known flakes** affect this feature's own suite (pure-Dart on flutter-tester). The two carried environment notes — never run the acceptance suite without a `-d` device (false green), and run the cross-feature regression per the device lane on the sim — were both honoured in §2.

---

## 6. Gates

| Gate | Kind | Status |
|---|---|---|
| G-1 | decision — approve the spec | ✅ Resolved 2026-10-14 — Matt Quirk |
| G-2 | decision — approve the acceptance tests (ITEST-4 packet) | ✅ Resolved 2026-10-15 — Matt Quirk (round 1) |
| G-3 | decision — real-world Phase-0.5 fidelity (AC-5/AC-6, D-5) | ✅ Resolved 2026-10-15 — Matt Quirk: **D-5 gap accepted** (representative manifest proves schema + ship-logic, not a physical run) |

---

## 7. Token usage and cost per AC

From the *Token usage* ledger (18 sessions, **125,834,464 tokens**) priced at API list rates (2026-09-25); all 18 sessions priced from their transcripts. **Feature total: $113.60** (input $0.01, cache write $31.46, cache read $60.74, output $21.39). Span: first start 2026-10-14 14:16 EDT → last end 2026-10-15 12:44 EDT; **Σ active 6h 42m (Σ wall 8h 10m)**.

Per-stage subtotals: scaffold $4.99 · shells $22.81 · acceptance-tests $19.72 + test-review $1.87 · behaviour (direct) $49.33 · sign-off $8.90 · other activities (plan, decisions) $5.99. Per-AC fully-loaded cost ranges $9.03 (AC-2) → $14.52 (AC-1, which SEED-3 + GUARD-2 both touch); direct-only ranges $4.81 (AC-11) → $8.68 (AC-1).

Full breakdown: [cost-per-ac-round-1.md](cost-per-ac-round-1.md).

Summary scorecard: https://claude.ai/artifact/AWzjkeB1KGZnxDRDxa5r9n (headline checked against this run — 11/11 ACs, 11 A/0, unit 1352/0, bs-13 19/19, cross-feature regression 241/0).

---

## 8. Manual walkthrough — how a reviewer sees each Rule working

All commands run from the worktree `/Users/matthew.quirk/Nuance-bs13` with `~/development/flutter/bin` on `PATH`.

**Rule — the dataset stores per-paint optical data, not RGB→recipe answers (AC-1, AC-11).**
`flutter test integration_test/bs13/dataset_test.dart -d flutter-tester --plain-name TestAC01` loads the real shipped seed via `AssetSeedLoader`, solves a recipe for a target with the real bs-04 `SubtractiveMixingEngine`, and asserts the predicted colour equals `engine.forward(components)` within 1.0 ΔLab — a fact a retrieved stored answer need not satisfy. `TestAC11` pins the scope (one brand / one medium / 15 paints). To *see* the seed, open `assets/` → the shipped seed asset, or read `lib/dataset/seed_dataset.dart`: every entry carries masstone optical data + metadata, and there is no target→recipe column. The no-lookup guard (`integration_test/bs13/guards/no_lookup_table_guard.dart`) returns empty over the real schema and flags the planted `control_lookup_table.dart`.

**Rule — the LLM proposes paint combinations; the solver produces ratios (AC-2, AC-3, AC-4).**
`TestAC02` shows every candidate mapping carries origin `llmSeed` and each candidate id is grounded in a shipped entry, and two loads return identical mappings (build-time, no runtime LLM; boot drives no speech). `TestAC03` runs `ratioProvenanceGuard()` → zero offenders over `lib/` + schema, and the control lists `control_llm_ratio.dart`; a reviewer can confirm by `grep -rn 'partsFraction:' lib/` → exactly `subtractive_engine.dart` (origin) and `project_source.dart` (rehydration). `TestAC04` shows pigment index / opacity / lightfastness are retained through `toPaint()`, while `noClaimedValueGuard()` proves the schema declares no spectral/ratio claimed field (control: `control_claimed_spectral.dart`).

**Rule — the seed is validated before it ships (AC-5, AC-6).**
`TestAC05` reads the shipped `ValidationManifest`: held-out count 56 ∈ [50,100], a non-empty distribution with one ΔE00 per recipe, all finite ≥ 0. `TestAC06` shows `manifest.shippable` is true for the shipped seed and the passing fixture, and **false** for each single-condition control (`control_manifestFailThreshold`, `control_manifestFailBeatsLlm`) — proving the ship rule is the AND of "clears threshold" and "beats LLM-alone", not either alone. (Known gap D-5: the distribution is recorded/representative, not a physical spectrophotometer run — accepted at G-3.)

**Rule — provenance is enforced in the schema (AC-7, AC-8).**
`TestAC07` derives a tier for each of the four spec origins via `ProvenanceDerivation.tierFor` — spectrophotometer → Measured, solver-over-measured → Calculated, unconfirmed LLM seed → "Estimated — not yet verified", user's own measured mix → "Confirmed — you measured this" — with a contrasting fallback on every row so the answer must come from the origin. `TestAC08` appends a new evidence point and asserts the earlier point is retained, order preserved, prior list unchanged (a monotonic 3-point control rejects prepend/mutate/drop/reorder).

**Rule — an LLM-seeded value never graduates except on physical evidence (AC-9, AC-10).**
`TestAC09` starts from an Estimated value (LLM seed only), records the painter's own photographed/instrument swatch via `promoteWithOwnSwatch`, and the value becomes Confirmed while the earlier LLM-seed evidence is retained — and the device-agnostic crux discriminates: the *same* raw instrument reading through `tierFor` alone yields only Measured, so an impl that merely appended the raw kind would fail. `TestAC10` offers only an opinion and the value stays Estimated, paired with an inertness control (`tierFor([llmSeed, instrument]) == measured`) proving the derivation *can* raise a tier — so the non-promotion is real, not a vacuous fallback.

**Rule — the shipped seed stays narrow (AC-11).** See the first Rule above — `TestAC11` pins one brand, one medium, 15 paints (count ∈ [12,18]).

**Reviewer quick-run (everything bs-13 owns, both modes):**
```
cd /Users/matthew.quirk/Nuance-bs13 && export PATH="$HOME/development/flutter/bin:$PATH"
flutter analyze lib integration_test/bs13
flutter test --coverage && COVERAGE_GATE_BASE=7015390 dart run tool/coverage_gate.dart main
flutter test integration_test/bs13/dataset_test.dart -d flutter-tester
flutter test integration_test/bs13/dataset_test.dart -d flutter-tester --dart-define=BS13_RUN_PENDING=true
```
