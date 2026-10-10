# Module SCREEN — Correction screen UI

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/correction/correction_screen.dart` + per-region keyed widgets under `lib/correction/regions/` (`check_region.dart`, `difference_region.dart`, `correction_region.dart`, `speak_region.dart`, `rephotograph_region.dart`, `save_region.dart`)
**Depends on:** LOOP (controller/state/endpoint), CORRECT (`Difference`/`Correction` types) · **Blocks:** the behaviour phases render into these regions

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |

(No separate SCREEN behaviour phases: each behaviour phase in LOOP/CORRECT renders into its own region widget — the master plan's *Parallel windows* explains why this keeps the screen side file-disjoint.)

## Interface reconciliation

- `CorrectionScreen({required CorrectionController controller})`, rendered inside `CorrectionReadEndpoint` by `CorrectionHomeScreen`. It lays out the regions; each region widget carries a `static const Key regionKey` the harness finds by `find.byKey(...)`, mirroring bs-04's region pattern (`TargetRegion`, `RecipeListRegion`, `GamutBanner`).
- Region → AC / element map:
  - `CheckRegion` — **E26** "Check my mix" (AC-1, filled by LOOP-3).
  - `DifferenceRegion` — the difference body: ΔE00 + verdict + the value-leading decomposition (AC-2/AC-3, CORRECT-2); the within-tolerance "very close" state (AC-6, CORRECT-4).
  - `CorrectionRegion` — the correction body: paint + amount, "a touch of" for traces (AC-4/AC-5, CORRECT-3); the **no-correction** state when within tolerance (AC-6, CORRECT-4).
  - `SpeakRegion` — **E27** "Speak correction" (AC-7, LOOP-4).
  - `RephotographRegion` — **E28** "Re-photograph swatch" (AC-8, LOOP-5).
  - `SaveRegion` — **E29** "Save confirmed mix" (AC-9, LOOP-6); the confirmed provenance surfaces in a later readout's `ProvenanceBadge` (AC-10, reused from bs-01/bs-06), not on this screen.

## Open gates

- None of its own. The region **contents** inherit G-4 (verdict words, amounts, label) from CORRECT/LOOP.

## Phase 1 — Correction screen scaffold (SCREEN-1)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** LOOP-2 · **Blocks:** every behaviour phase
- **Files:** `correction_screen.dart` + the six keyed region widgets, all inert (placeholder content bound to `controller`/`state`, no behaviour)
- **Tasks:**
  1. Build `CorrectionScreen` with the six region widgets, each with its `static const Key regionKey`, reading from the controller but asserting nothing yet.
  2. Ensure `CorrectionHomeScreen` (LOOP-2) renders it under the read endpoint.
  3. 100% coverage on touched files; the existing suite stays green; the smoke test (ITEST-1) can find every `regionKey`.
- **Exit criteria:** `flutter analyze` clean; unit + coverage gate pass on touched files; behavior unchanged (the screen is reachable only via the new `correctionEntry`/`toCorrection`).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
