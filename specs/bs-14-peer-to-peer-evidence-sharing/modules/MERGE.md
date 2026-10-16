# Module MERGE — append-only merge, crowd refine, never-promote, rate-limit

**Status:** In progress — MERGE-1, MERGE-2 ✅ done (AC-10 ✅); next is MERGE-3 (AC-8 + AC-11)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/sharing/merge/evidence_merge.dart`, `crowd_refine.dart`, `source_rate_limiter.dart`, `mapping_evidence_endpoint.dart`; an **additive** edit to bs-13's `lib/domain/sample.dart` (surface-drift: the enum lives there, not `provenance.dart`) to add `EvidenceKind.peerContributed`, plus the matching `MeasurementTier.fromEvidenceKind` case in `mix_accuracy_record.dart`.
**Depends on:** CORE, RECORD, **bs-13 PROV** (append-only add, `ProvenanceDerivation.tierFor`, clustering rule) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 5,237,948 | 11m 08s |
| 2 | behavior | AC-10 | ✅ Done | 6,290,218 | 11m 35s |
| 3 | behavior | AC-8 + AC-11 | ⬜ Todo | | |
| 4 | behavior | AC-9 | ⬜ Todo | | |
| 5 | behavior | AC-12 | ⬜ Todo | | |

## Interface reconciliation

- **Depends on bs-13's real surface (G-3).** Appending uses bs-13's append-only `EvidencePoint` add (none dropped/reordered); tier is derived by bs-13's `ProvenanceDerivation.tierFor`; the estimate reuses bs-13's source-agnostic clustering rule (robust central estimate, outlier discard) — bs-14 adds **no** new estimator (D-6).
- `EvidenceKind.peerContributed` is added to bs-13's enum (MERGE-1). In the tier-by-origin precedence it refines an Estimated value but is **not** a promoter to Confirmed; only the painter's own `photographedSwatch`/instrument evidence promotes (D-2, AC-9). Keep the edit additive so it merges cleanly with bs-13.
- A received `MixAccuracyRecord` becomes one `EvidencePoint { coordinates: measuredColour, source: <device/source id>, kind: peerContributed }`.
- `MappingEvidenceEndpoint` exposes a mapping's derived value, its source-tagged evidence list, and the derived tier/label for assertions.

## Open gates

- **G-2** blocks all MERGE behavior. **G-3** (bs-13 merged) is required for MERGE-1 onward (the append/derivation/clustering API must exist).

## Phase 1 — Shell: merge, refine, rate-limiter, read endpoint, EvidenceKind

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CORE-2, RECORD-1, bs-13 (G-3) · **Blocks:** MERGE-2, MERGE-5
- **Files:** `evidence_merge.dart`, `crowd_refine.dart`, `source_rate_limiter.dart`, `mapping_evidence_endpoint.dart`, additive edit to `lib/domain/provenance.dart`.
- **Tasks:**
  1. Add `EvidenceKind.peerContributed` to bs-13's enum (additive; default-safe).
  2. `EvidenceMerge` interface (ingest `List<MixAccuracyRecord>` → append peer-contributed `EvidencePoint`s), `CrowdRefine` (recompute via bs-13 clustering), `SourceRateLimiter` — all skeletons (no behavior).
  3. `MappingEvidenceEndpoint` observing derived value + evidence list + tier/label.
  4. No behavior: existing suite + bs-13 derivation unchanged.
- **Exit criteria:** unit gate (100% touched); bs-13 derivation tests still green; read endpoint observable.

## Phase 2 — AC-10: append-only, source-tagged merge

- **Kind:** behavior
- **Target AC:** AC-10 (full)
- **Depends on:** MERGE-1, G-2 · **Blocks:** MERGE-3
- **Files:** `evidence_merge.dart`.
- **Tasks:**
  1. Ingest records arriving from several distinct device sources for one mapping: each appended via bs-13's append-only add and tagged `peerContributed` with its source; prior points unchanged, order preserved, none overwritten.
- **Exit criteria:** unit + coverage; acceptance gate; grade gate.
- **Acceptance gate:** un-pend AC-10; `TestAC10_AppendOnlyMerge` passing (and all earlier ACs).

## Phase 3 — AC-8 + AC-11: crowd refine (robust central estimate, outlier discard)

- **Kind:** behavior
- **Target AC:** AC-8 (full) + AC-11 (full)
- **Depends on:** MERGE-2, G-2 · **Blocks:** MERGE-4
- **Files:** `crowd_refine.dart`.
- **Tasks:**
  1. Recompute an Estimated mapping's value as the robust central estimate of its clustered peer records, discarding outliers (not a plain mean) — reusing bs-13's clustering rule (AC-8).
  2. The same path rejects a statistical outlier rather than averaging it in; AC-11 exercises it with a far-outlier fixture.
- **Exit criteria:** unit + coverage; acceptance gate; grade gate.
- **Acceptance gate:** un-pend AC-8 and AC-11; `TestAC08_ClusteredRefine` and `TestAC11_OutlierDiscarded` passing (and all earlier ACs).

## Phase 4 — AC-9: crowd evidence never promotes to Confirmed

- **Kind:** behavior
- **Target AC:** AC-9 (full)
- **Depends on:** MERGE-3, G-2 · **Blocks:** SIGNOFF-1
- **Files:** `crowd_refine.dart`, derivation glue over bs-13's `ProvenanceDerivation`.
- **Tasks:**
  1. After refinement, the user-facing provenance stays "Estimated — not yet verified"; tier stays `estimated`. Peer evidence (any kind, including one claiming an instrument tier) never promotes; only the painter's own measured mix does (D-2).
- **Exit criteria:** unit + coverage; acceptance gate; grade gate.
- **Acceptance gate:** un-pend AC-9; `TestAC09_NeverPromotes` passing (and all earlier ACs).
- **Augments:** `TestAC09`: add a case where a peer record declares an instrument tier and assert it still derives `estimated` / "not yet verified".

## Phase 5 — AC-12: per-source rate limit

- **Kind:** behavior
- **Target AC:** AC-12 (full)
- **Depends on:** MERGE-1, G-2 · **Blocks:** SIGNOFF-1
- **Files:** `source_rate_limiter.dart`, `evidence_merge.dart`.
- **Tasks:**
  1. Bound the volume accepted from any one source (scope §6.6): a stream from a single source is capped at the per-source limit; excess rejected; other sources unaffected (no global starvation).
- **Exit criteria:** unit + coverage; acceptance gate; grade gate.
- **Acceptance gate:** un-pend AC-12; `TestAC12_RateLimited` passing (and all earlier ACs).

### Result — MERGE-1 (shell)

- **Landed (4 new files in `lib/sharing/merge/`, all skeletons, no behaviour):**
  - `evidence_merge.dart` — `SourcedRecord({source, record})` value type + `EvidenceMerge({derivation})` whose `ingest(existing, incoming)` returns `existing` unmodified (MERGE-2 appends each as a `peerContributed` point via bs-13's `appendEvidence`).
  - `crowd_refine.dart` — `RefineResult({value, tier})` + `CrowdRefine({derivation})` whose `refine(current, evidence, {fallback})` returns `current` unchanged with the tier from bs-13's `tierFor` (peer evidence never promotes → stays `fallback`). MERGE-3 computes the robust central estimate; MERGE-4 proves never-promote.
  - `source_rate_limiter.dart` — `SourceRateLimiter({maxPerSource})` (`defaultMaxPerSource = 50`, provisional) whose `admit(source)` always returns true in the shell. MERGE-5 enforces the per-source bound.
  - `mapping_evidence_endpoint.dart` — `MappingEvidenceView({value, evidence, tier, label})` + `MappingEvidenceEndpoint` (`InheritedWidget`, `endpointKey`, nullable `view`, `of`/`maybeOf`), the suite's read seam; `view` null in the shell.
- **Additive edits (default-safe):** `lib/domain/sample.dart` — added `EvidenceKind.peerContributed` (doc: refines only, never contributes to the tier; `tierFor` already ignores kinds outside its precedence, so no derivation change). `lib/sharing/record/mix_accuracy_record.dart` — added the `peerContributed` case to `MeasurementTier.fromEvidenceKind` → `cardLess` (keeps the exhaustive switch complete).
- **Surface-drift reconciled:** the enum lives in `lib/domain/sample.dart`, not `provenance.dart` (as the plan's D-2 / Files lines predate the bs-13 merge). The edit is additive and merges cleanly.
- **Verification:** analyze clean; unit **1511/0** (+23: merge 28 new, record +1); coverage gate **100% on all 19 touched lib files** (`dart run tool/coverage_gate.dart c00422f`); whole existing suite green; bs-13 derivation tests unchanged and green. No device/integration run (shell, no AC). Fix passes: 0/3.
- **Tokens / Time:** 5,237,948 / 11m 08s.

### Checkpoint / Handoff — after MERGE-1

- **Frozen interfaces (consumed by MERGE-2..5, ITEST, the behaviour phases):**
  - `EvidenceKind.peerContributed` (in `lib/domain/sample.dart`) — refine-only, non-promoting.
  - `SourcedRecord({required String source, required MixAccuracyRecord record})` — value `==`.
  - `EvidenceMerge({ProvenanceDerivation derivation})` — `List<EvidencePoint> ingest(List<EvidencePoint> existing, Iterable<SourcedRecord> incoming)` (shell: returns `existing` unmodifiable).
  - `CrowdRefine({ProvenanceDerivation derivation})` — `RefineResult refine(ColorCoordinates current, List<EvidencePoint> evidence, {ProvenanceTier fallback = estimated})`; `RefineResult({ColorCoordinates value, ProvenanceTier tier})` value `==`.
  - `SourceRateLimiter({int maxPerSource})` — `bool admit(String source)` (shell: always true); `static const defaultMaxPerSource = 50`.
  - `MappingEvidenceEndpoint` — `endpointKey`, nullable `view`, `of`/`maybeOf`; `MappingEvidenceView({required ColorCoordinates value, List<EvidencePoint> evidence, ProvenanceTier tier, String label})` value `==`.
- **Wiring note:** nothing in `lib/sharing/merge/` is yet a `SharingDependencies` field or mounted in `build_app.dart` — behaviour-neutral shell. The ITEST harness mounts `MappingEvidenceEndpoint` directly; MERGE behaviour phases populate its `view`.
- **Verification commands:** flutter at `~/development/flutter/bin`. Unit: `flutter test`. Coverage: `flutter test --coverage` then `dart run tool/coverage_gate.dart c00422f`. Construct value classes non-const in a test or the const-ctor line reads 0.
- **Next:** MERGE-2 (AC-10 append-only source-tagged merge) — blocked on **G-2** (and the ITEST stage: the AC test must exist). MERGE-3/4/5 follow. The shell stage is now complete (CORE-2, RECORD-1, EXCHANGE-1, MERGE-1 all done) → the ITEST stage (ITEST-1..5) is startable; ITEST-5 is the test review resolving **G-2**.

### Result — MERGE-2 (AC-10 append-only, source-tagged merge)

- **Landed:** `EvidenceMerge.ingest` now folds each incoming `SourcedRecord` into the evidence log via bs-13's append-only `ProvenanceDerivation.appendEvidence` — each becomes one `EvidencePoint { coordinates: record.measuredColour.lab, source: <arrival id>, kind: peerContributed }`, appended in arrival order after the prior points, returned as an unmodifiable view. Prior points unchanged, order preserved, nothing overwritten or deduped; distinct peer measurements each add a point. No new estimator (D-6); rides bs-13's append-only add. Only `evidence_merge.dart` touched in `lib/`.
- **Acceptance gate:** AC-10 un-pended (deleted from `bs14/pending.dart`; MERGE-2 added to `completedBehaviorPhases`; harness pending-set guard updated). `TestAC10_AppendOnlyMerge` runs and passes in the default suite; whole bs-14 suite green with only later-phase ACs skipped (AC-2/6/7/8/9/11/12). `exchange_and_merge_test` +1 (AC-10) ~2 (AC-6/7); `harness_test` 12/0; `consent_and_record_test` green; `refine_test` all-skipped green.
- **Grade gate:** fresh independent reviewer — **AC-10 A** (G1/G2/G4/G5/G6 pass, G3 n/a synchronous; rejects dedup, overwrite, reorder, dropped source, mislabelled kind, wrong coords). AC-1/3/4/5 untouched, remain A. **5 A / 0** over un-pended AC-1,3,4,5,10.
- **Unit:** analyze clean; `evidence_merge_test` rewritten shell→behaviour (8 tests); full unit **1532/0**; coverage gate **100%** on the 1 touched lib file (`dart run tool/coverage_gate.dart c8738f6`). Fix passes 0/3.
- **Tokens / Time:** 6,290,218 / 11m 35s.

### Checkpoint / Handoff — after MERGE-2

- **Frozen:** `EvidenceMerge.ingest(existing, incoming)` is now the real append-only merge (above). The returned log is the source-tagged evidence MERGE-3 refines (robust central estimate over the clustered peer points) and MERGE-4 derives the never-promote tier from. `peerContributed` points carry the measured `lab` and source id.
- **Verification commands:** flutter at `~/development/flutter/bin`. Unit+cov: `flutter test --coverage` then `dart run tool/coverage_gate.dart <phase-base>`. Acceptance (host, one app-booting file per invocation): `flutter test integration_test/bs14/exchange_and_merge_test.dart -d flutter-tester` (+ `--dart-define=BS14_RUN_PENDING=true` for red baseline).
- **Next:** MERGE-3 (AC-8 + AC-11: clustered crowd refine + outlier discard, in `crowd_refine.dart`) — depends on MERGE-2 (done) + G-2 (resolved). MERGE-4 (AC-9) then MERGE-5 (AC-12). EXCHANGE-3 (AC-7) remains independently startable; EXCHANGE-2/4 still need G-4.
