# Module MERGE — append-only merge, crowd refine, never-promote, rate-limit

**Status:** ✅ Done — MERGE-1..MERGE-5 all done (AC-8/9/10/11/12 ✅, all graded A); module complete
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/sharing/merge/evidence_merge.dart`, `crowd_refine.dart`, `source_rate_limiter.dart`, `mapping_evidence_endpoint.dart`; an **additive** edit to bs-13's `lib/domain/sample.dart` (surface-drift: the enum lives there, not `provenance.dart`) to add `EvidenceKind.peerContributed`, plus the matching `MeasurementTier.fromEvidenceKind` case in `mix_accuracy_record.dart`.
**Depends on:** CORE, RECORD, **bs-13 PROV** (append-only add, `ProvenanceDerivation.tierFor`, clustering rule) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 5,237,948 | 11m 08s |
| 2 | behavior | AC-10 | ✅ Done | 6,290,218 | 11m 35s |
| 3 | behavior | AC-8 + AC-11 | ✅ Done | 6,284,723 | 15m 51s |
| 4 | behavior | AC-9 | ✅ Done | 7,077,181 | 14m 53s |
| 5 | behavior | AC-12 | ✅ Done | 7,627,140 | 15m 13s |

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

### Result — MERGE-3 (AC-8 + AC-11 crowd refine: robust central estimate, outlier discard)

- **Landed:** `CrowdRefine.refine` now recomputes an Estimated mapping's value as the **robust central estimate** of its peer-contributed evidence when any is present (else the stored `current` stands). The estimator: coordinate-wise median → each point's Euclidean distance from it scored by the Iglewicz–Hoaglin **modified z-score** (`0.6745·(d−median)/MAD`, threshold 3.5), outliers discarded, the estimate is the mean of the survivors. The tier is still derived by bs-13's `tierFor` over the full evidence log (peer-contributed ignored), so a refined value stays Estimated and the crowd never promotes it (AC-9 carried green). Only `crowd_refine.dart` touched in `lib/`.
- **Surface drift reconciled (D-6).** The plan's D-6 / Gap-analysis said the estimate "reuses bs-13's source-agnostic clustering rule". bs-13's merged surface exposes a *tier* rule (`tierFor`) and append-only add but **no** central-estimate / clustering API, so the robust estimator is implemented here in `crowd_refine.dart`. D-6's intent is still honoured — bs-14 reuses bs-13's **evidence model** (append-only, source-tagged `EvidencePoint`s) and adds no new *evidence* representation; the estimator over that model is new because there was none to reuse. AC-8 and AC-11 share this one code path with distinct fixtures.
- **Acceptance gate:** AC-8 and AC-11 un-pended (deleted from `bs14/pending.dart`; MERGE-3 added to `completedBehaviorPhases`; `harness_test` pending-set guard updated: `unpended` += AC-8/AC-11, completed += MERGE-3). `TestAC08_ClusteredRefine` and `TestAC11_OutlierDiscarded` run and pass; AC-9/AC-12 still skip (pending). Whole bs-14 suite green: `refine_test` 2 pass/2 skip, `harness_test` 12/0, `exchange_and_merge_test` (AC-10) green, `consent_and_record_test` (AC-3/4/5) green.
- **Grade gate:** fresh independent reviewer — **AC-8 A, AC-11 A** on first grade; AC-1/3/4/5/10 unchanged, remain A. **7 A / 0** over un-pended AC-1,3,4,5,8,10,11. Reviewer confirmed the fixtures discriminate both named wrong impls (ignore-the-crowd ~15 off; plain-average-all ~9–10 toward the outlier; tolerance band 1.5). Two non-A-denying notes recorded in the grid (tests accept any valid robust estimator — correct, the spec pins none; AC-11 omits the stale-seed-far Given but still rejects ignore-the-crowd).
- **Unit:** analyze clean; `crowd_refine_test` rewritten shell→behaviour (11 tests, covers the ≤2-point, MAD-0, odd/even-median, outlier-discard and no-crowd branches); full unit **1537/0**; coverage gate **100%** on the 1 touched lib file (`dart run tool/coverage_gate.dart cc36137`). Fix passes **0/3**.
- **Tokens / Time:** 6,284,723 / 15m 51s.

### Checkpoint / Handoff — after MERGE-3

- **Frozen:** `CrowdRefine.refine(current, evidence, {fallback})` now returns the robust central estimate of the peer-contributed points (outliers discarded) as its `value`, with the tier derived (never promoted) from the full log. With no peer-contributed evidence the stored `current` stands. The private estimator (`_robustCentralEstimate`/`_coordinateWiseMedian`/`_median`/`_mean`/`_distance`) is internal — consumers depend only on `refine`'s contract.
- **Verification commands:** flutter at `~/development/flutter/bin`. Unit+cov: `flutter test --coverage` then `dart run tool/coverage_gate.dart <phase-base>`. Acceptance (host, one app-booting file per invocation): `flutter test integration_test/bs14/refine_test.dart -d flutter-tester` (+ `--dart-define=BS14_RUN_PENDING=true` for red baseline).
- **Next:** MERGE-4 (AC-9 never-promote) — depends on MERGE-3 (done) + G-2 (resolved); un-pends AC-9 and makes the carried `TestAC09` augmentation (a peer record declaring an instrument tier still derives `estimated` / "not yet verified"), closing AC-9's *B pending MERGE-4* to A. Then MERGE-5 (AC-12, independent of the MERGE chain — needs only MERGE-1). EXCHANGE-3 (AC-7) remains independently startable; EXCHANGE-2/4 still need G-4.

### Result — MERGE-4 (AC-9 crowd evidence never promotes to Confirmed)

- **Landed:** the never-promote invariant for AC-9 is already structurally enforced by MERGE-1/MERGE-2's design — `EvidenceMerge.ingest` unconditionally stamps every incoming peer record `kind: peerContributed` (its declared `MeasurementTier` discarded), and bs-13's `ProvenanceDerivation.tierFor` has no `peerContributed` branch, so peer evidence falls through to the stored `fallback` (Estimated). MERGE-4 added the **derivation glue** that surfaces this the way the painter sees it: `CrowdRefine.refine` now derives the tier once and sets `RefineResult.label = derivation.qualifier(tier)`, so the refiner itself produces the user-facing provenance text ("Estimated — not yet verified") from bs-13's single source of truth rather than a string rebuilt downstream. Only `crowd_refine.dart` touched in `lib/` (`RefineResult` gains a `label` field in its ctor/`==`/`hashCode`/`toString`; `refine` computes it).
- **Acceptance gate:** AC-9 un-pended (deleted from `bs14/pending.dart`; MERGE-4 added to `completedBehaviorPhases`; `harness_test` pending-set guard updated: `unpended` += AC-9, `containsAll` += MERGE-4). `TestAC09_NeverPromotes` runs and passes in the default suite; whole bs-14 suite green with only later-phase ACs skipped (AC-2/6/7/12). Default: `refine_test` 3 pass/1 skip (AC-12), `harness_test` 12/0, `consent_and_record_test` 4/0, `exchange_and_merge_test` 1/0 (AC-10). Run-pending `refine_test`: AC-8/9/11 pass, AC-12 red (→ MERGE-5).
- **Augmentations (both made, `TestAC09`):** **(1)** after the real `merge.ingest`, assert the log holds exactly 5 `peerContributed` points, the prior `llmSeed` point unchanged and first, length 6 — realizing the "refined by peer records" Given through the public surface (G1). **(2)** a peer record **declaring `MeasurementTier.instrument`** is ingested; assert the appended point is still `peerContributed` (declared tier discarded) and the derived tier + label stay Estimated — proving `peerContributed` is *actively excluded*, not merely absent. This rejects the plausible wrong impl that maps a record's declared tier to an `instrumentMeasured` point (which `tierFor` would raise to Measured). The own-swatch control (`promoteWithOwnSwatch` → Confirmed / "Confirmed — you measured this") is retained (G3/G5: the reading CAN change). Label assertions now read `result.label` (product-sourced), not a test-rebuilt qualifier.
- **Grade gate:** fresh independent reviewer (fresh subagent, G1–G6, given the prior grid) — **AC-9 A** (upgraded from *B pending MERGE-4*; both cited gaps — the unasserted Given and the no-promoting-peer rejection — closed by the two augmentations). AC-1/3/4/5/8/10/11 re-graded, all remain A (AC-8/AC-11 read only `.value`, unaffected by the new `.label`). **8 A / 0** over un-pended AC-1,3,4,5,8,9,10,11. No downgrades.
- **Unit:** analyze clean; `crowd_refine_test` extended (RefineResult group now covers `label` in ctor/equality/hashCode/toString; two `refine` label assertions); full unit **1537/0**; coverage gate **100% (line)** on the 1 touched lib file (`dart run tool/coverage_gate.dart 18a13f4`). Fix passes **0/3** (all gates passed first run).
- **Tokens / Time:** 7,077,181 / 14m 53s.

### Checkpoint / Handoff — after MERGE-4

- **Frozen:** `RefineResult` now carries a third field, `label` (the user-facing provenance qualifier), required in its const ctor and part of `==`/`hashCode`/`toString`. `CrowdRefine.refine` populates it from `derivation.qualifier(tier)`; for crowd/peer evidence that is always "Estimated — not yet verified" (AC-9). Any later consumer constructing a `RefineResult` directly must pass a `label` (only the unit test did; the harness/endpoints build it via `refine`). The never-promote invariant is now covered end-to-end at the value *and* the painter-facing-label grain.
- **Verification commands:** flutter at `~/development/flutter/bin`. Unit+cov: `flutter test --coverage` then `dart run tool/coverage_gate.dart <phase-base>`. Acceptance (host, one app-booting file per invocation): `flutter test integration_test/bs14/refine_test.dart -d flutter-tester` (+ `--dart-define=BS14_RUN_PENDING=true` for the AC-12 red).
- **Next:** MERGE-5 (AC-12 per-source rate limit, in `source_rate_limiter.dart` + `evidence_merge.dart`) — needs only MERGE-1, independent of the MERGE-2→3→4 chain; un-pends AC-12 (the last MERGE red). EXCHANGE-3 (AC-7) remains independently startable; EXCHANGE-2/4 still need G-4; CORE-4 (AC-2) needs EXCHANGE-3. SIGNOFF-1 last.

### Result — MERGE-5 (AC-12 per-source rate limit)

- **Landed:** the per-source volume bound is now enforced inside `EvidenceMerge.ingest`. `SourceRateLimiter` became the real stateful counter — `admit(source)` returns true and counts the admission while that source is below `maxPerSource`, false (counting nothing) once it reaches the cap, keeping a separate count per source so one source at its cap never affects another's budget. `EvidenceMerge` gained a `const` `maxPerSource` field (default `SourceRateLimiter.defaultMaxPerSource = 50`) and now, per `ingest` call, builds a fresh limiter, **seeds it with the peer-contributed points already in `existing`** (so the cap bounds a source's whole contribution across the append-only log, not just one batch), then admits each incoming record — appending the source-tagged `peerContributed` point when admitted, skipping it when over cap. AC-10's append-only/source-tagged behaviour is preserved (distinct-source records stay far under the cap). Both `source_rate_limiter.dart` and `evidence_merge.dart` touched in `lib/`.
- **Design note (const-constructibility forced the shape).** The AC-12 test and the harness construct `const EvidenceMerge()` directly, so `EvidenceMerge` must stay const — it therefore cannot hold a stateful limiter field; it holds only the `maxPerSource` cap and creates the limiter internally per call. Scope §6.6 names no number, so `defaultMaxPerSource = 50` is the fixed bound (the shell's "provisional" note dropped).
- **Acceptance gate:** AC-12 un-pended (deleted from `bs14/pending.dart`; MERGE-5 added to `completedBehaviorPhases` and `behaviorPhases`; `harness_test` pending-set guard updated: `unpended` += AC-12, `containsAll` += MERGE-5). `TestAC12_RateLimited` runs and passes; whole bs-14 suite green with only AC-2/6/7 skipped. Default: `refine_test` 4 pass/0 skip (AC-8/9/11/12), `harness_test` 12/0, `exchange_and_merge_test` 1 pass/2 skip (AC-10; AC-6/7 pending), `consent_and_record_test` 4 pass/1 skip (AC-1/3/4/5; AC-2 pending).
- **Grade gate:** fresh independent reviewer (fresh subagent, G1–G6, given the prior grid, re-ran all three files live) — **AC-12 A** (first grade: drives the real `EvidenceMerge.ingest`/`SourceRateLimiter`, both Thens at exact value — flooder capped at exactly 50, honest peer's 5 all accepted — rejecting both no-cap and global-cap-that-starves-others). **AC-9 A** graded fresh in full (closing the *B pending MERGE-4* that MERGE-4's commit never recorded in the grid — see the grid's late MERGE-4 note). AC-10 re-verified carefully (shares `evidence_merge.dart`): distinct-source counts of 1 stay under cap, append-only unchanged, no regression. AC-1/3/4/5/8/11 all remain A. **9 A / 0** over un-pended AC-1,3,4,5,8,9,10,11,12. No downgrades.
- **Unit:** analyze clean; `source_rate_limiter_test` rewritten shell→behaviour (5 tests: default cap, explicit cap, cap-then-reject, per-source independence, zero-cap); `evidence_merge_test` extended with an AC-12 group (5 tests: default cap, single-source cap, no-starvation, cross-batch seeding from existing peer points, non-peer existing points not charged). Full unit **1544/0** (+7); coverage gate **100% (line)** on both touched lib files (`dart run tool/coverage_gate.dart c9c22b6`). Fix passes **0/3** (all gates passed first run).
- **Tokens / Time:** 7,627,140 / 15m 13s.

### Checkpoint / Handoff — after MERGE-5

- **Frozen:** `SourceRateLimiter` is now stateful — `admit(source)` counts per source and rejects once a source reaches `maxPerSource` (default 50); a limiter instance bounds a whole stream. `EvidenceMerge` now takes `maxPerSource` (const, default `SourceRateLimiter.defaultMaxPerSource`) and `ingest` enforces the per-source cap over the whole log (existing peer points seed the count), while keeping AC-10's append-only, source-tagged semantics for admitted records. The **MERGE module is complete** (MERGE-1..5 all done; AC-8/9/10/11/12 ✅, all A).
- **Verification commands:** flutter at `~/development/flutter/bin`. Unit+cov: `flutter test --coverage` then `dart run tool/coverage_gate.dart <phase-base>`. Acceptance (host, one app-booting file per invocation): `flutter test integration_test/bs14/refine_test.dart -d flutter-tester` (+ `--dart-define=BS14_RUN_PENDING=true` for the pending ACs).
- **Next:** EXCHANGE-3 (AC-7, no peer ⇒ no exchange/no wait) is startable now. CORE-4 (AC-2) needs EXCHANGE-3. EXCHANGE-2 (AC-6) and EXCHANGE-4 (enabler) need **G-4** (still open). SIGNOFF-1 last (needs CORE-4, EXCHANGE-4). All MERGE reds are now closed.
