# Module RECORD — the anonymous mix-accuracy record

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/sharing/record/mix_accuracy_record.dart`, `record_builder.dart`, `content_hash.dart`, `record_inspect_endpoint.dart`.
**Depends on:** CORE (package + wiring), bs-13 (SEED declared-palette + PROV evidence) · **Blocks:** EXCHANGE (records to gossip), MERGE (record ⇆ evidence)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-3 + AC-4 | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
