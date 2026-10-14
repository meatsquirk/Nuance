# Module PROV — runtime provenance/evidence model

**Status:** In progress — PROV-1 ✅ shell (derivation/read-endpoint seams wired, behaviour-neutral)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/domain/provenance.dart`, `lib/domain/sample.dart` (extend `EvidencePoint`), new `lib/domain/provenance_derivation.dart` and `lib/domain/provenance_read_endpoint.dart`.
**Depends on:** the existing `Provenance`/`ProvenanceTier`/`Sample`/`EvidencePoint` (`lib/domain/`) · **Blocks:** ITEST-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 4,740,008 | 18m 41s |
| 2 | behavior | AC-7, AC-8 | ⬜ Todo | | |
| 3 | behavior | AC-9, AC-10 | ⬜ Todo | | |

## Interface reconciliation

- **Extend, don't replace.** `ProvenanceTier {measured, calculated, estimated, confirmed}` and `Provenance{tier, note, label}` stay. `EvidencePoint` gains a non-null `EvidenceKind kind` (today it carries only `coordinates` + `source: String`). A default keeps existing call-sites compiling, but every new evidence point is constructed with an explicit kind.
- **`EvidenceKind`** (origins from the spec's Scenario Outline + the promotion rule): `instrumentMeasured`, `solverCalculated`, `llmSeed`, `photographedSwatch` (the user's own measured mix), `opinion`.
- **Tier derivation (SI D9: "a value's shown tier is derived from its evidence").** `ProvenanceDerivation.tierFor(List<EvidencePoint>)` by precedence, opinions excluded: `photographedSwatch` → **confirmed** · else `instrumentMeasured` → **measured** · else `solverCalculated` → **calculated** · else `llmSeed` → **estimated**. A single-origin value therefore derives exactly its spec tier (AC-7); a mixed set derives the best (drives AC-9). `opinion` never contributes (AC-10).
- **Labels.** The spec's full qualifiers ("Estimated — not yet verified", "Confirmed — you measured this") are produced here (via `Provenance.note`/a label helper); the existing `Provenance.label` ("Estimated"/"Confirmed") is unchanged, so bs-01/bs-06/bs-10 display is untouched.
- **Append-only.** Appending evidence returns a value whose `evidence` is `[...old, new]` — prior points never dropped/reordered. `Sample` is immutable; the add is a `copyWith`-style return (or a small `EvidenceLog` wrapper), and there is **no** remove/replace in the API.
- **Boundary with bs-05.** bs-13 owns the enforced **rule** (which evidence kind promotes, and that opinions don't). The self-confirmation **flow** (capturing the swatch, wiring it to a stored value) is bs-05/capture (D-3) — PROV exposes the rule as a pure function + an append so bs-05 can drive it.

## Open gates

- **G-1** (spec) blocks the feature; **G-2** (tests) blocks PROV-2/PROV-3.

## Phase 1 — Shell: EvidenceKind, derivation seam, append-only add, read endpoint

- **Kind:** shell
- **Target AC:** —
- **Depends on:** SEED-1 · **Blocks:** ITEST-1
- **Files:** `lib/domain/sample.dart` (add `EvidenceKind` + `EvidencePoint.kind`), `lib/domain/provenance_derivation.dart` (seam), `lib/domain/provenance_read_endpoint.dart`
- **Tasks:**
  1. Add `enum EvidenceKind {...}` and the non-null `kind` field on `EvidencePoint` (with a safe default so existing constructors compile); value-equality updated.
  2. `ProvenanceDerivation.tierFor(evidence)` + an append-only add — **stubs** in the shell (e.g. derivation returns the current stored tier; append returns a plain `[...old, new]`) so behavior is unchanged until PROV-2.
  3. `ProvenanceReadEndpoint`: exposes a value's derived tier + its evidence list (read-only) for the acceptance suite.
  4. Keep the whole suite green (no behavior change).
- **Exit criteria:** unit gate (100% touched); existing unit + acceptance suites green; behavior unchanged.
- **Acceptance gate:** —
- **Augments:** —

## Phase 2 — AC-7, AC-8: tier-by-origin derivation + append-only evidence

- **Kind:** behavior
- **Target AC:** AC-7 (full — 4 origins), AC-8 (full)
- **Depends on:** PROV-1, ITEST-4 (G-2) · **Blocks:** PROV-3
- **Files:** `lib/domain/provenance_derivation.dart`, `lib/domain/sample.dart`
- **Tasks:**
  1. Implement `tierFor` by the precedence above so each of the four origins derives its spec tier (AC-7); produce the full qualifier label/note for Estimated and Confirmed.
  2. Implement the append-only add: `appendEvidence(point)` returns a value whose evidence grows by one with every earlier point retained in order; no remove/replace (AC-8).
  3. Enforce the tier is carried on every value (the derived tier, never absent).
- **Exit criteria:** unit gate; acceptance gate below.
- **Acceptance gate:** un-pend AC-7, AC-8; `TestAC07_EnforcedProvenanceTierByOrigin` (all four cases) and `TestAC08_EvidenceAppendOnly` green (and all earlier ACs).
- **Augments:** —

## Phase 3 — AC-9, AC-10: promotion on swatch; opinions never promote

- **Kind:** behavior
- **Target AC:** AC-9 (full), AC-10 (full)
- **Depends on:** PROV-2 · **Blocks:** SIGNOFF-1
- **Files:** `lib/domain/provenance_derivation.dart` (promotion), `lib/domain/sample.dart`
- **Tasks:**
  1. Promotion: appending a `photographedSwatch` (or `instrumentMeasured`) evidence point to an Estimated value (llmSeed only) re-derives the tier to **Confirmed** (AC-9) — a thin wrapper over append + `tierFor`, so it is driven **only** by the swatch evidence.
  2. Opinions: appending an `opinion` point re-derives to the **same** tier — never a promotion (AC-10); assert `control_opinionOnly` stays Estimated.
- **Exit criteria:** unit gate; acceptance gate below.
- **Acceptance gate:** un-pend AC-9, AC-10; `TestAC09_PromotedOnlyByMeasuredSwatch` and `TestAC10_OpinionsNeverPromote` green (and all earlier ACs).
- **Augments:** closes the AC-9 augmentation pre-seeded on the ITEST AC-9 test (promotion exercisable once this rule exists).

### Result — PROV-1  <!-- 2026-10-14 -->

Shell: the runtime provenance seam is wired, behaviour-neutral. Changes:
- `lib/domain/sample.dart` — new `enum EvidenceKind {instrumentMeasured, solverCalculated, llmSeed, photographedSwatch, opinion}` (the spec's four origins + `opinion`); `EvidencePoint` gains a non-null `kind` with a **safe default `EvidenceKind.opinion`** (non-contributing — keeps every existing call-site compiling unchanged, and never silently promotes). `kind` added to `==`/`hashCode`; `toString` deliberately unchanged (keeps the existing exact-match unit test green).
- `lib/domain/provenance_derivation.dart` (new) — `ProvenanceDerivation` (const): `tierFor(evidence, {fallback = estimated})` **stub returns `fallback`** so no flow's tier shifts until PROV-2; `appendEvidence(evidence, point)` returns `[...evidence, point]` (append-only, no remove/replace — SI D9). Signatures frozen for PROV-2/PROV-3.
- `lib/domain/provenance_read_endpoint.dart` (new) — `ProvenanceReadEndpoint(sample)` pure-Dart observation seam: `evidence` + `derivedTier` (derives via `ProvenanceDerivation`, falling back to the stored `Provenance.tier`). Not a widget — the AC-7/8/9/10 facts are pure-domain, so the ITEST harness observes a `Sample` directly.

PROV stays entirely in `lib/domain/` with no `package:flutter` import. No production call-site constructs an explicit kind yet (the own-swatch wiring in `correction_controller` is bs-05's — D-3), so behaviour is unchanged by construction.

**Verification:** `flutter analyze` clean · unit **1322/0** (+7: 2 `EvidencePoint.kind` cases in `test/domain/sample_test.dart` + `test/domain/provenance_shell_test.dart`) · coverage gate **100% on all touched files** (`COVERAGE_GATE_BASE=7015390`; gate also re-confirms SEED-2's files) · cross-feature integration regression **222/222 on the iPhone 17 sim** (== SEED-1/SEED-2 baseline; whole `integration_test/` dir under the device lock — run because `sample.dart` is a shared domain type other features exercise). Behaviour unchanged confirmed. Fix passes: 0/3 (passed on the first full run). Tokens 4,740,008 · Time 18m 41s.

### Checkpoint / Handoff — PROV-1

- **Frozen for PROV-2/PROV-3:** `EvidenceKind` (5 values), `EvidencePoint.kind` (default `opinion`); `ProvenanceDerivation.tierFor(List<EvidencePoint>, {ProvenanceTier fallback})` and `.appendEvidence(List<EvidencePoint>, EvidencePoint)`; `ProvenanceReadEndpoint(sample).{evidence, derivedTier}`.
- **PROV-2** fills `tierFor` with the origin precedence (`photographedSwatch`→confirmed · `instrumentMeasured`→measured · `solverCalculated`→calculated · `llmSeed`→estimated; `opinion` never contributes → returns `fallback`) and the full Estimated/Confirmed qualifier labels/notes; **PROV-3** adds the promotion wrapper (append a measured/photographed swatch → re-derive to Confirmed) + opinions-never-promote. Both are body-only changes — signatures are stable, so ITEST can bind to them now.
- **Reconciliation for SEED-4:** SEED's local `SeedOrigin{reviewedOptical, llmSeed}` maps to `EvidenceKind` — `llmSeed`→`EvidenceKind.llmSeed`; `reviewedOptical` is the reviewed representative masstone, so map to `instrumentMeasured` (or a reviewed-optical kind if SEED-4 finds the distinction matters). SEED-4 owns that decision.
- **Verification commands:** unchanged from SEED-2 (analyze; `flutter test --coverage`; `COVERAGE_GATE_BASE=7015390 dart run tool/coverage_gate.dart`; integration on the iPhone 17 sim under `coord.sh with-lock bs-13 <PHASE>` — FNP_COORD_REPO=main, `cd` into the worktree inside `bash -c`). GOTCHA: const-only/const constructors show uncovered — invoke non-const (`// ignore: prefer_const_constructors`) in a test.
- **Known gaps:** none introduced; behaviour unchanged (inert default kind, unused seams). GUARD-1 is the last remaining shell — ITEST-1 cannot start until it lands.
