# bs-13 Paint-dataset-integrity — behaviour-test completeness grade

- **Date:** 2026-10-15
- **Phase:** SEED-4 (AC-2 `candidateMappings` loader + AC-4 `ingestEntryRecord` reject rule just landed; AC-2 / AC-4 un-pended)
- **Grader:** independent acceptance-test grader (did not author the tests)
- **Scope graded:** the un-pended AC tests in `integration_test/bs13/dataset_test.dart` — AC-1, AC-2, AC-4, AC-8, AC-11. (AC-3/5/6/7/9/10 remain pending and are not graded here.)
- **Rubric:** grade A requires ALL of G1–G6; a limit only a later phase can close is recorded as "A-core / B pending `<phase>`", not a plain B.

## Grade grid

| AC | Test | Grade | G1 Given checked | G2 configured answers | G3 settled negatives | G4 grain & value | G5 rejects what | G6 one AC | Rejects (wrong impls caught) |
|----|------|-------|------------------|-----------------------|----------------------|------------------|-----------------|-----------|------------------------------|
| AC-1 | `TestAC01_RecipesSolvedFromOpticalData` | **A-core / B pending GUARD-2** | ✓ entries non-empty, every masstone finite, candidate mappings carry id-sets only — all read through `DatasetReadEndpoint` before the solve | ✓ recipe solved by the real `SubtractiveMixingEngine` over the shipped seed's optical data (behaviour from the asset, not a script) | n/a (no negative Then) | ✓ `every` component is a seed optical paint; predicted colour == engine's forward mix within 1.0 per L/a/b (raw observable, not a derived field) | ✓ core: a retrieved/stored answer whose `predictedColor` is not forward-consistent with its components is rejected. **Augmentation pending GUARD-2:** the source-level no-lookup-table structural proof (zero offenders over `lib/` + `control_lookupTable` listed) is not assertable until GUARD-2 fills the real scan | ✓ | a recipe retrieved from a stored target→recipe answer (not forward-mix-consistent); components not drawn from the seed atoms; an empty-shell seed (fails naming SEED-3) |
| AC-2 | `TestAC02_CandidatesFromLlm` | **A** | ✓ `mappings` non-empty read through endpoint before the Then; seed-id set collected from the dataset | ✓ reads the shipped asset's `candidateMappings` that the loader stamps `llmSeed`; reload is the real `AssetSeedLoader`, not a fixture | ✓ `speech.utterances` empty asserted after `pumpAndSettle`; non-vacuity of the sink is pinned by the suite-level "FakeSpeech actually captures" control | ✓ `every` mapping origin == `llmSeed`; `every` candidate id references a shipped entry; reload equality; speech empty | ✓ fabricated/dangling candidate ids (grounding check); a runtime-LLM (non-deterministic across loads) impl (reload-equality control); a boot that narrates (speech-empty); an origin other than `llmSeed` | ✓ (candidates-from-LLM + no-runtime-LLM are one AC) | candidate ids not grounded in shipped entries; non-deterministic runtime generation; runtime narration on boot; mis-stamped origin |
| AC-4 | `TestAC04_MetadataAcceptedClaimedValuesRejected` | **A-core / B pending GUARD-2** | ✓ entries non-empty, `withMeta` (pigmentIndex present) non-empty read before the Then | ✓ the shipped seed is the ingest result (`ingestEntryRecord` runs in the real parser); retention observed on the loaded dataset | n/a (no negative Then in the un-pended half) | ✓ `for each` metadata-bearing entry: pigment index retained, masstone finite, and survives mapping to `Paint` (per-item grain) | ✓ core: an ingest that drops accepted metadata or fails to carry it onto `Paint` is rejected. **Augmentation pending GUARD-2:** the no-claimed-value structural proof (schema declares no claimed field; planted claimed-value entry listed by the guard) is the GUARD-2 half — this test asserts only the metadata-retention half, so the correct ceiling here is A-core / B pending GUARD-2 | ✓ | an ingest that strips a valid pigment index; a map-to-`Paint` that loses accepted metadata; (claimed-value rejection deferred to GUARD-2) |
| AC-8 | `TestAC08_EvidenceAppendOnly` | **A** | ✓ base value's existing evidence read through `provenanceOf(base)` before the append | ✓ behaviour comes from the real `ProvenanceDerivation.appendEvidence`; Given built as data | ✓ "nothing dropped / unchanged" asserted by exact equality; pure synchronous derivation, no settle needed; immutability control (`base.evidence` unchanged) present | ✓ exact length (2, then 3), first/last identity, full-list order equality | ✓ a prepend (first/last fail); an in-place mutation (base unchanged fails); a drop/replace of an earlier point (monotonic 3-point control fails) | ✓ | prepend; mutate-in-place; remove/replace losing history; reorder |
| AC-11 | `TestAC11_ShippedSeedStaysNarrow` | **A** | ✓ entries non-empty read through endpoint before the scope Thens | ✓ scope read from the shipped asset via the endpoint | n/a (no negative Then) | ✓ brand non-empty, medium non-null, `every` entry one brand + one medium, count ∈ [12,18] | ✓ the count range [12,18] genuinely discriminates the shipped asset (a 30-paint or empty seed fails); non-empty brand/medium reject the empty shell. (The per-entry one-brand/one-medium checks are architecturally guaranteed by the parser stamping seed-wide scope, so they add little separation — the count-range and non-empty-scope checks carry G5) | ✓ | a too-wide seed (>18 paints); the empty shell (no brand/medium, 0 entries); a seed outside the pinned ~15 scope |

## Counts

- **Straight A:** 3 — AC-2, AC-8, AC-11
- **A-core / B pending `<phase>`:** 2 — AC-1 (pending GUARD-2), AC-4 (pending GUARD-2)
- **Below A (plain B, no augmentation row):** 0

## Downgrades against prior grid

None. The grid matches the prior grid exactly:

- AC-1 — A-core / B pending GUARD-2 (unchanged). SEED-3's shipped asset makes the core assertable at A; the no-lookup-table structural augmentation remains owned by GUARD-2.
- AC-2 — A (unchanged; un-pended at SEED-4). The loader stamps `llmSeed`, grounds candidate ids in shipped entries, and the reload-equality + speech-empty controls reject a runtime-LLM impl — assertable at A now.
- AC-4 — A-core / B pending GUARD-2 (unchanged; un-pended at SEED-4). The ingest reject rule (`ingestEntryRecord`) exists in lib, but this acceptance test asserts only the metadata-retention half; the no-claimed-value structural proof is the GUARD-2 augmentation, so A-core / B pending GUARD-2 is the correct ceiling.
- AC-8 — A (unchanged; green at baseline).
- AC-11 — A (unchanged).

## Gate status

**No plain-B rows with no augmentation.** Every non-straight-A row carries a named augmentation phase (GUARD-2) — no gate failure to fix.
