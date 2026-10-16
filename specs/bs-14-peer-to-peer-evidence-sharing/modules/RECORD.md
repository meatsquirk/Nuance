# Module RECORD — the anonymous mix-accuracy record

**Status:** In progress — RECORD-1 ✅, RECORD-2 ✅ (AC-3 + AC-4, graded A); RECORD-3 (AC-5) next (G-2 resolved)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/sharing/record/mix_accuracy_record.dart`, `record_builder.dart`, `content_hash.dart`, `record_inspect_endpoint.dart`.
**Depends on:** CORE (package + wiring), bs-13 (SEED declared-palette + PROV evidence) · **Blocks:** EXCHANGE (records to gossip), MERGE (record ⇆ evidence)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 5,181,744 | 12m 49s |
| 2 | behavior | AC-3 + AC-4 | ✅ Done | 12,296,700 | 24m 58s |
| 3 | behavior | AC-5 | ⬜ Todo | | |

## Interface reconciliation

- The record is built from a painter's confirmed/measured mix (bs-13 `photographedSwatch`/instrument `EvidencePoint` + the declared palette brand/line/medium from the SEED palette model). The record is the *only* thing that ever crosses the boundary (D-4).
- `contentHash` is over the record's canonical serialized content (paint-id set sorted, declared palette, rounded CIELAB/CIELCh, tier) so byte-identical records collapse at exchange (D-7) while distinct measurements remain distinct.
- Measurement tier maps from bs-13's evidence kind (instrument / reference-card / card-less), not a new scale.

## Open gates

- **G-2** blocks RECORD-2, RECORD-3 (behavior). No gate blocks RECORD-1.

## Phase 1 — Shell: record type, hash, builder, read endpoint

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CORE-2 · **Blocks:** RECORD-2, EXCHANGE-1, EXCHANGE-2
- **Files:** `lib/sharing/record/mix_accuracy_record.dart`, `content_hash.dart`, `record_builder.dart`, `record_inspect_endpoint.dart`.
- **Tasks:**
  1. `MixAccuracyRecord { PaintCombination paintCombination; DeclaredPalette declaredPalette; MeasuredColour measuredColour; MeasurementTier tier }` — immutable, value-equal; canonical serialization; `contentHash` getter. `PaintCombination` = sorted canonical paint ids; `DeclaredPalette` = brand/line/medium; `MeasuredColour` = CIELAB + CIELCh; `MeasurementTier` from bs-13 evidence kind.
  2. `RecordBuilder` interface + skeleton impl (returns nothing yet) that will build from a confirmed `Sample`/`EvidencePoint` + palette.
  3. `RecordInspectEndpoint` exposing a `prepared` record and the selected `shareSet` for assertions.
  4. No behavior: builder returns empty; existing suite green.
- **Exit criteria:** unit gate (100% touched); serialization + hash round-trip covered; read endpoint observable.

## Phase 2 — AC-3 + AC-4: record carries only evidence, nothing personal

- **Kind:** behavior
- **Target AC:** AC-3 (full) + AC-4 (full)
- **Depends on:** RECORD-1, G-2 · **Blocks:** RECORD-3, SIGNOFF-1
- **Files:** `lib/sharing/record/record_builder.dart`.
- **Tasks:**
  1. Build a `MixAccuracyRecord` from a confirmed/measured mix: populate exactly the four fields (AC-3).
  2. Redaction by construction — the record type structurally cannot hold a photograph, project, saved sample, CVD profile, identifier or location; the builder reads only the four permitted inputs (AC-4). Prove with app state that *does* contain a project/sample/profile: none appears in the prepared record.
- **Exit criteria:** unit + coverage; acceptance gate; grade gate.
- **Acceptance gate:** un-pend AC-3 and AC-4; `TestAC03_RecordCarriesOnlyEvidence` and `TestAC04_NothingPersonalLeaves` passing (and all earlier ACs).

## Phase 3 — AC-5: no declared palette ⇒ not shared

- **Kind:** behavior
- **Target AC:** AC-5 (full)
- **Depends on:** RECORD-2, G-2 · **Blocks:** EXCHANGE-2, SIGNOFF-1
- **Files:** `lib/sharing/record/record_builder.dart` (share-set selection).
- **Tasks:**
  1. At share-set selection, exclude any candidate record whose declared palette is absent; record the reason "not interpretable — no declared palette" (D-8, scope §6.6).
- **Exit criteria:** unit + coverage; acceptance gate; grade gate.
- **Acceptance gate:** un-pend AC-5; `TestAC05_NoPaletteNotShared` passing (and all earlier ACs).

### Result — RECORD-1 (shell) ✅

- **Landed** `lib/sharing/record/` (4 files, no behaviour):
  - `mix_accuracy_record.dart` — `MixAccuracyRecord{paintCombination, declaredPalette, measuredColour, tier}` immutable/value-equal with a `canonicalForm` (rounded CIELAB/CIELCh to 2 dp, fixed field order + separators) and a `contentHash` getter (D-7). Supporting value types: `PaintCombination.of(ids)` (trim/dedup/sort → canonical), `DeclaredPalette{brand,line,medium}` with `isPresent` (the AC-5 interpretability test) + `canonical`, `CielchCoordinates{lightness,chroma,hue}`, `MeasuredColour{lab,lch}`, and `MeasurementTier{instrument,referenceCard,cardLess}` with `fromEvidenceKind` (bs-13 `EvidenceKind` → tier: instrumentMeasured→instrument, photographedSwatch→referenceCard, solver/llm/opinion→cardLess).
  - `content_hash.dart` — `contentHashOf(canonical)`: dependency-free FNV-1a/64 (no `crypto` dep), rendered as unsigned 16-char hex (two 32-bit halves, so a set top bit never yields a leading `-`). Stable across runs/isolates (unlike `Object.hashCode`) — the seen-set relies on that.
  - `record_builder.dart` — `RecordBuilder` interface (`prepare`/`selectShareSet`) + skeleton `EvidenceRecordBuilder` that builds/ shares nothing (RECORD-2/RECORD-3 fill it). **Not yet injected into `SharingDependencies`** — kept to the module's own files (the scope wiring is deferred to when a behaviour phase needs it).
  - `record_inspect_endpoint.dart` — `RecordInspectEndpoint` InheritedWidget (keyed `record-inspect-endpoint`; `prepared` + `shareSet`; `of`/`maybeOf`; `updateShouldNotify`), the AC-4/AC-5 observation seam. Empty/null in the shell.
- **Gates:** `flutter analyze` clean. **Unit 1464/0** (+32: content_hash 5, mix_accuracy_record 19, record_builder 3, record_inspect_endpoint 5). **Coverage 100% line on all 9 touched files** (the 4 new + CORE-2's 5) vs `c00422f` — PASS. bs-14's own acceptance suite has no tests yet (ITEST stage) ⇒ nothing to run.
- **No AC** (shell). **Fix passes: 2/3** — (1) the empty/high-bit hash rendered 17 chars with a leading `-` → unsigned two-half hex; (2) three `const` value-type constructors showed 0 coverage (only ever built as compile-time constants) → a test builds them from non-const locals so they execute. **Tokens** 5,181,744 · **Time** 12m 49s.

### Checkpoint / Handoff — after RECORD-1

- **Frozen interfaces (consumed by RECORD-2/3, EXCHANGE, MERGE):**
  - `MixAccuracyRecord(paintCombination, declaredPalette, measuredColour, tier)` — `canonicalForm`, `contentHash`, value `==`/`hashCode`.
  - `PaintCombination.of(Iterable<String>)` / `PaintCombination(List<String>)`; `canonical` getter.
  - `DeclaredPalette({brand, line, medium})` — `isPresent` (all three non-blank ⇒ shareable, the AC-5 gate), `canonical`.
  - `CielchCoordinates({lightness, chroma, hue})`, `MeasuredColour({lab, lch})`.
  - `MeasurementTier.fromEvidenceKind(EvidenceKind)`.
  - `contentHashOf(String)` (FNV-1a/64, unsigned 16-hex).
  - `RecordBuilder` (`MixAccuracyRecord? prepare(Sample, {DeclaredPalette? palette})`; `List<MixAccuracyRecord> selectShareSet(Iterable<MixAccuracyRecord>)`); skeleton `EvidenceRecordBuilder` (const).
  - `RecordInspectEndpoint` — `endpointKey`, `prepared`, `shareSet`, `of`/`maybeOf`.
- **Wiring note:** the record builder is **not** yet a `SharingDependencies` field (RECORD-1 stayed within its own files). RECORD-2 (behaviour) adds `recordBuilder` to `SharingDependencies` in `lib/sharing/sharing_scope.dart` (+ a one-line construction in `build_app.dart`) when it needs the live builder injected; the ITEST harness can mount `RecordInspectEndpoint` directly.
- **Verification commands:** flutter at `~/development/flutter/bin`. Unit: `flutter test`. Coverage: `flutter test --coverage` then `dart run tool/coverage_gate.dart c00422f` (**must be the full-suite coverage run** — a subset run reports CORE-2's files as "NO COVERAGE DATA"). A new value class must be constructed at runtime (non-const) in a test or the `const` constructor line shows 0 coverage.
- **Next:** RECORD-2 (AC-3+AC-4, behaviour) — **blocked on G-2**. MERGE-1 (shell) is startable in parallel. EXCHANGE-1 (shell) depends on RECORD-1 (now done) and is startable.

### Result — RECORD-2 (behavior, AC-3 + AC-4) ✅

- **Landed** `EvidenceRecordBuilder.prepare` (`lib/sharing/record/record_builder.dart`): builds a `MixAccuracyRecord` from a confirmed/measured `Sample` + declared palette, carrying exactly the four fields — `paintCombination` (canonical from the sample's recipe), `declaredPalette` (as given, absent carried through for RECORD-3 to exclude), `measuredColour` (the sample's CIELAB + a CIELCh from the injected `ColorScience`, default `const ColorScienceImpl()`), and `tier` (the strongest `MeasurementTier` over the sample's evidence kinds; no evidence ⇒ card-less floor). Returns null when the sample declares no paints (no mix to share). Redaction is by construction — the builder reads only `paintIds`, `coordinates`, `evidence`; the record type structurally cannot hold a name/project/profile/source id (AC-4). `selectShareSet` stays a no-op (RECORD-3 owns AC-5).
- **AC-3 combination-source reconciliation (resolved):** the frozen `prepare(Sample, {palette})` takes no combination arg, so the paints ride on the input — added an optional `Sample.paintIds` field (`lib/domain/sample.dart`, default `const []`, in the type's established optional-field pattern; the selective `sampleToJson` is unchanged, consistent with the other non-serialized tags). The `confirmedEvidence` harness fixture now carries `seedMapping.candidatePaintIds`. No AC-test `prepare(...)` call signature changed.
- **Acceptance gate:** un-pended **AC-3 + AC-4** (deleted both rows in `pending.dart`; added `RECORD-2` to `completedBehaviorPhases`); `TestAC03_RecordCarriesOnlyEvidence` + `TestAC04_NothingPersonalLeaves` **green** on `-d flutter-tester`, AC-1 still green, AC-2/AC-5..AC-12 still pending. Harness guard (`harness_test.dart`) updated to the new un-pended set `{AC-1,AC-3,AC-4}` → 12/12.
- **Gates:** `flutter analyze` clean. Unit **1527/0** (+ record_builder behaviour tests, Sample `paintIds` default/copyWith). Coverage **100% line on all 20 touched lib files** vs `c00422f` — PASS (the const default `ColorScienceImpl()` needed a runtime, non-const builder construction in a test to cover it).
- **Grade:** fresh independent reviewer, G1–G6. AC-4 **A** first pass; AC-1 **A** (no drift). AC-3 came back **B** (G4/G5: the paint combination asserted only as non-empty + already-sorted — vacuous). Fixed in-phase with the prescribed value assertion `expect(record.paintCombination, seedCombination)` (strengthen-only, discriminates wrong/extra/missing ids); re-graded **A**. **3 A / 0** over the un-pended tests. **Fix passes: 1/3.**
- **Tokens** 12,296,700 · **Time** 24m 58s.

### Checkpoint / Handoff — after RECORD-2

- **Frozen interfaces (consumed by RECORD-3, EXCHANGE, MERGE):**
  - `EvidenceRecordBuilder({ColorScience colorScience = const ColorScienceImpl()})` — `prepare(Sample, {DeclaredPalette? palette}) → MixAccuracyRecord?` now builds (null iff no declared paints); `selectShareSet` still returns `[]` (RECORD-3).
  - `Sample.paintIds` (`List<String>`, default `const []`) — the mix's recipe the record's `paintCombination` is sourced from; empty for a non-mix sample. Carried on `copyWith`; not serialized by `sampleToJson` (in-pattern with the other non-persisted tags).
- **Known gaps:** none new. AC-5 (no-palette exclusion) is still RECORD-3's at `selectShareSet`; RECORD-2 carries an absent palette through unchanged so RECORD-3 can exclude it.
- **Verification commands:** unchanged from RECORD-1 — flutter at `~/development/flutter/bin`; unit `flutter test`; coverage `flutter test --coverage` then `dart run tool/coverage_gate.dart c00422f` (full-suite run); bs-14 acceptance `flutter test integration_test/bs14/consent_and_record_test.dart -d flutter-tester` (run-pending adds `--dart-define=BS14_RUN_PENDING=true`). Construct a new value class non-const in a test or the const-ctor line reads 0.
- **Next:** RECORD-3 (AC-5, behaviour) — fills `selectShareSet` to exclude absent-palette candidates. Startable now (G-2 resolved); disjoint from the MERGE chain and MERGE-5.
