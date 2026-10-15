# Module PROV — runtime provenance/evidence model

**Status:** ✅ Done — PROV-3 ✅ (promotion on an own swatch + opinions never promote; AC-9 ✅, AC-10 ✅). All PROV ACs (AC-7, AC-8, AC-9, AC-10) delivered; module complete.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/domain/provenance.dart`, `lib/domain/sample.dart` (extend `EvidencePoint`), new `lib/domain/provenance_derivation.dart` and `lib/domain/provenance_read_endpoint.dart`.
**Depends on:** the existing `Provenance`/`ProvenanceTier`/`Sample`/`EvidencePoint` (`lib/domain/`) · **Blocks:** ITEST-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 4,740,008 | 18m 41s |
| 2 | behavior | AC-7, AC-8 | ✅ Done | 7,347,169 | 13m 47s |
| 3 | behavior | AC-9, AC-10 | ✅ Done | 8,356,426 | 20m 58s |

## Interface reconciliation

- **Extend, don't replace.** `ProvenanceTier {measured, calculated, estimated, confirmed}` and `Provenance{tier, note, label}` stay. `EvidencePoint` gains a non-null `EvidenceKind kind` (today it carries only `coordinates` + `source: String`). A default keeps existing call-sites compiling, but every new evidence point is constructed with an explicit kind.
- **`EvidenceKind`** (origins from the spec's Scenario Outline + the promotion rule): `instrumentMeasured`, `solverCalculated`, `llmSeed`, `photographedSwatch` (the user's own measured mix), `opinion`.
- **Tier derivation (SI D9: "a value's shown tier is derived from its evidence").** `ProvenanceDerivation.tierFor(List<EvidencePoint>)` by precedence, opinions excluded: `photographedSwatch` → **confirmed** · else `instrumentMeasured` → **measured** · else `solverCalculated` → **calculated** · else `llmSeed` → **estimated**. A single-origin value therefore derives exactly its spec tier (AC-7); a mixed set derives the best (drives AC-9). `opinion` never contributes (AC-10).
- **Labels.** The spec's full qualifiers ("Estimated — not yet verified", "Confirmed — you measured this") are produced here (via `Provenance.note`/a label helper); the existing `Provenance.label` ("Estimated"/"Confirmed") is unchanged, so bs-01/bs-06/bs-10 display is untouched.
- **Append-only.** Appending evidence returns a value whose `evidence` is `[...old, new]` — prior points never dropped/reordered. `Sample` is immutable; the add is a `copyWith`-style return (or a small `EvidenceLog` wrapper), and there is **no** remove/replace in the API.
- **Boundary with bs-05.** bs-13 owns the enforced **rule** (which evidence kind promotes, and that opinions don't). The self-confirmation **flow** (capturing the swatch, wiring it to a stored value) is bs-05/capture (D-3) — PROV exposes the rule as a pure function + an append so bs-05 can drive it.

## Open gates

- **G-1** (spec) ✅ and **G-2** (tests, approved 2026-10-15 @ `2fd5dfe`) ✅ both resolved — the whole PROV module (PROV-1/2/3) is complete. No open gate blocks this module.

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
- **Acceptance gate:** un-pend AC-7; `TestAC07_EnforcedProvenanceTierByOrigin` (all four cases) green. **AC-8 is already un-pended** (ITEST-3 found `TestAC08_EvidenceAppendOnly` green at baseline — the PROV-1 shell froze a working append-only add); PROV-2 keeps it green and carries its unit coverage, no un-pend needed. All earlier ACs stay green.
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
- **Augments:** closes the AC-9 augmentation pre-seeded on the ITEST AC-9 test (promotion exercisable once this rule exists). **✅ Resolved** — the AC-9 test now drives promotion through `promoteWithOwnSwatch` and asserts the instrument-measured own swatch promotes likewise.

### Result — PROV-3  <!-- 2026-10-15 -->

Promotion rule landed; AC-9 and AC-10 un-pended and green. The one `lib/` change is the new `promoteWithOwnSwatch` on `lib/domain/provenance_derivation.dart`:
- **`promoteWithOwnSwatch(evidence, swatch, {fallback = estimated})`** — records the painter's own measured [swatch] and re-derives the tier. It is a thin compose of the frozen `appendEvidence` + `tierFor`: it appends `swatch` as an `EvidenceKind.photographedSwatch` self-confirmation point (keeping the swatch's measured `coordinates`/`source`) and returns a record `({List<EvidencePoint> evidence, ProvenanceTier tier})`. An Estimated value (LLM seed only) therefore becomes **Confirmed** (AC-9), driven only by the swatch; the earlier evidence is retained (append-only, rides on `tierFor`).
- **Design decision (self-confirmation is device-agnostic).** The spec's AC-9 promotes an Estimated value on "a photographed **or instrument-measured** swatch for it" → "Confirmed — you measured this". The frozen `tierFor` maps `photographedSwatch`→Confirmed and a *generic* `instrumentMeasured` reading→Measured (AC-7's spectrophotometer row). The reconciliation: recording a swatch of **your own mix** is self-confirmation whatever the capture device, so the wrapper stamps `photographedSwatch` regardless — a photographed or instrument-measured own swatch both promote to Confirmed, while a generic instrument reading recorded as plain evidence stays Measured. This honours AC-9 literally and the frozen `tierFor` without re-deriving the locked kind→tier map. The independent grader confirmed it spec-faithful and A-grade.
- **No change to `sample.dart`** was needed (the plan listed it as a permitted file); `tierFor`/`appendEvidence`/`qualifier` are unchanged from PROV-2.

**Behaviour unchanged across the app by construction:** `promoteWithOwnSwatch` (like the rest of `ProvenanceDerivation`) has no production call-site — `grep` confirms the only `lib/` references to `ProvenanceDerivation`/`promoteWithOwnSwatch` are doc comments in `sample.dart`; the self-confirmation *flow* that would drive it is bs-05/capture (D-3). So no bs-01..bs-12 flow's tier shifts; no cross-feature regression run is warranted (the only `lib/` change is unreachable from production, same as PROV-2).

**Test changes:** added 3 unit tests to `test/domain/provenance_derivation_test.dart` (the own-photographed-swatch promotion to Confirmed with append-only retention; the instrument-measured own swatch promoting likewise *vs* a raw instrument reading deriving only Measured; promotion driven by the swatch not the fallback). Augmented the AC-9 acceptance test in `integration_test/bs13/dataset_test.dart` to drive the transition through `promoteWithOwnSwatch` and assert the instrument-likewise + the generic-reading contrast (the pre-seeded augmentation). Un-pended AC-9/AC-10 in `pending.dart` (removed their rows; added PROV-3 to `completedBehaviorPhases`; updated the owner-comment map), and kept the harness pending-gate guard tests consistent in `dataset_test.dart` (AC-9/AC-10 → the `unpended` set; the "skips a pending AC" example moved AC-9 → AC-3, still pending). No AC test was weakened; the AC-10 acceptance test is unchanged and now runs by default.

**Verification:** `flutter analyze` clean · unit **1352/0** (+3 promotion tests) · coverage gate **100% on all touched files** (`COVERAGE_GATE_BASE=7015390`; `provenance_derivation.dart` 100%) · bs-13 acceptance **default 18 pass / 1 skip** (AC-9/AC-10 now run; only AC-3 pending) · **run-pending 18 pass / 1 fail** (AC-9 ✅, AC-10 ✅; only AC-3 red, owned by GUARD-2). Grade gate: fresh independent grader (G1–G6) over the 10 un-pended AC tests → **8 straight A (AC-2,5,6,7,8,9,10,11) + 2 A-core/B-pending-GUARD-2 (AC-1,4), 0 below A**; AC-9 and AC-10 graded **A** (no augmentation owed). Fix passes: 0/3 (green on the first full run). Tokens 8,356,426 · Time 20m 58s.

### Checkpoint / Handoff — PROV-3

- **PROV module complete.** All four PROV ACs delivered: AC-7 (tier-by-origin), AC-8 (append-only), AC-9 (promotion on an own swatch), AC-10 (opinions never promote). `ProvenanceDerivation` now exposes `tierFor` · `appendEvidence` · `qualifier` · `promoteWithOwnSwatch`, all stable.
- **Frozen for GUARD-2 / SIGNOFF-1:** the only remaining pending AC is **AC-3** (GUARD-2, ratios-from-solver guard). SIGNOFF-1 additionally needs **G-3** (the owner's real-world Phase-0.5 fidelity decision over the SEED-5 manifest — D-5 gap). PROV-3 introduced no new gap.
- **Verification commands:** unchanged — `flutter analyze`; `flutter test --coverage`; `COVERAGE_GATE_BASE=7015390 dart run tool/coverage_gate.dart`; bs-13 acceptance `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester` (default) and `--dart-define=BS13_RUN_PENDING=true` (run-pending). bs-13's suite is pure-Dart on `flutter-tester` — no device lane. flutter at `~/development/flutter/bin`; cwd `/Users/matthew.quirk/Nuance-bs13`.
- **Known gaps:** none introduced by PROV-3. AC-3 (GUARD-2) remains the only red run-pending AC; the SEED-5 manifest D-5 fidelity gap is G-3's to confirm/accept at sign-off.

### Result — PROV-2  <!-- 2026-10-15 -->

Tier-by-origin derivation landed; AC-7 un-pended and green, AC-8 kept green. The one `lib/` change is `lib/domain/provenance_derivation.dart`:
- **`tierFor`** now implements the real origin precedence (strongest contributing origin wins): `photographedSwatch` → Confirmed · `instrumentMeasured` → Measured · `solverCalculated` → Calculated · `llmSeed` → Estimated; `opinion` never contributes, and when nothing contributes (empty or opinion-only) the stored tier stands via the `fallback`. A single-origin value derives exactly its spec tier (AC-7); a mixed set derives the best (this is what PROV-3's promotion rides on). Signature unchanged.
- **`qualifier(tier)`** (new) produces the spec's full user-facing qualifier — "Estimated — not yet verified", "Confirmed — you measured this"; Measured/Calculated carry no qualifier (plain `Provenance.label`). This is the only place the qualifier text lives; `Provenance.label` is unchanged, so the bs-01/bs-06/bs-10 display layer is untouched.
- **`appendEvidence`** left exactly as the PROV-1 shell froze it (`[...old, new]`) — AC-8 (append-only) stays green and carries its unit coverage here; no API change.
- **Task 3 (tier never absent):** enforced by construction — `Provenance.tier` is a required non-null field and `tierFor` is total (always returns a `ProvenanceTier`). No change to `sample.dart` was needed; the plan listed it as a permitted file but PROV-2 needed none.

**Behaviour unchanged across the app by construction:** `tierFor`/the read endpoint are called only from `ProvenanceReadEndpoint` (a bs-13 test-observation seam), which no production flow mounts (`grep` confirms no call-site outside `lib/domain/provenance*`), and every existing `EvidencePoint` defaults to `kind: opinion` (non-contributing). So no bs-01..bs-12 flow's tier shifts.

**Test changes:** `test/domain/provenance_shell_test.dart` encoded the PROV-1 *stub* behaviour (`tierFor` returns the fallback) — that contract is now replaced, so it was rewritten as `test/domain/provenance_derivation_test.dart` covering the real precedence (every branch incl. mixed-origin + opinion-inert), the qualifier (all four tiers), the frozen append, and the read endpoint deriving the real tier. Acceptance: un-pended AC-7 in `pending.dart` (removed its row; added PROV-2 to `completedBehaviorPhases`) and kept the harness pending-gate guard tests consistent in `dataset_test.dart` (AC-7 → the `unpended` set; the "skips a pending AC" example moved AC-7 → AC-9). No AC test was weakened; the AC-7 acceptance test is unchanged and now runs by default.

**Verification:** `flutter analyze` clean · unit **1349/0** (−5 shell tests, +12 derivation tests) · coverage gate **100% on all touched files** (`COVERAGE_GATE_BASE=7015390`; `provenance_derivation.dart` 100%) · bs-13 acceptance **default 16 pass / 3 skip** (AC-7 now runs; only AC-9/AC-10 pending) · **run-pending 18 pass / 1 fail** (AC-7 ✅, AC-8 ✅, AC-9/AC-10 green early but still pending→PROV-3 un-pends; only AC-3 red, owned by GUARD-2). Grade gate: fresh independent grader (G1–G6) over the 8 un-pended AC tests → **6 straight A (AC-2,5,6,7,8,11) + 2 A-core/B-pending-GUARD-2 (AC-1,4), 0 below A**; AC-7 graded **A** (no augmentation owed). No cross-feature regression run — the only `lib/` change is unreachable from production (reasoned above), so no other feature's suite exercises it. Fix passes: 0/3 (green on the first full run). Tokens 7,347,169 · Time 13m 47s.

### Checkpoint / Handoff — PROV-2

- **Frozen for PROV-3:** `ProvenanceDerivation.tierFor` real precedence (strongest contributing origin; opinion inert; fallback when none) and `qualifier(tier)` are stable. `appendEvidence` unchanged. The read endpoint's `derivedTier` now reflects the real derivation.
- **PROV-3** adds the promotion wrapper (append a `photographedSwatch`/`instrumentMeasured` point to an Estimated value, then re-derive → Confirmed — a thin compose of `appendEvidence` + `tierFor`) and keeps opinions inert (AC-10). **Note:** with the real `tierFor` landed, AC-9 and AC-10 already pass under run-pending (promotion = append + derive; opinion-only derives Estimated). PROV-3's job is to add the promotion **wrapper** API, un-pend AC-9/AC-10 (delete their `pending.dart` rows, add PROV-3 to `completedBehaviorPhases`), close the AC-9 B-pending augmentation (assert the transition *through the wrapper* + instrument-swatch promotes likewise), and carry the unit coverage. Keep the "skips a pending AC" harness example pointing at a still-pending AC (AC-3) after un-pending AC-9.
- **Verification commands:** unchanged — `flutter analyze`; `flutter test --coverage`; `COVERAGE_GATE_BASE=7015390 dart run tool/coverage_gate.dart`; bs-13 acceptance `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester` (default) and `--dart-define=BS13_RUN_PENDING=true` (run-pending). bs-13's suite is pure-Dart on `flutter-tester` — no device lane. flutter at `~/development/flutter/bin`; cwd `/Users/matthew.quirk/Nuance-bs13`. GOTCHA: const-only constructors show uncovered — invoke non-const (`// ignore: prefer_const_constructors`) in a test.
- **Known gaps:** none introduced. AC-3 (GUARD-2) remains the only red run-pending AC.

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
