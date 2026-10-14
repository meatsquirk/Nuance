# Module MERGE — append-only merge, crowd refine, never-promote, rate-limit

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/sharing/merge/evidence_merge.dart`, `crowd_refine.dart`, `source_rate_limiter.dart`, `mapping_evidence_endpoint.dart`; an **additive** edit to bs-13's `lib/domain/provenance.dart` to add `EvidenceKind.peerContributed`.
**Depends on:** CORE, RECORD, **bs-13 PROV** (append-only add, `ProvenanceDerivation.tierFor`, clustering rule) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-10 | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
