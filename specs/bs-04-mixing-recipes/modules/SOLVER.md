# Module SOLVER — Inverse recipe search

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/recipes/solver.dart` (inverse search + ranking), `lib/recipes/gamut.dart` (out-of-gamut), `lib/recipes/muddying.dart` (complementary-crossing detector), `lib/recipes/trace.dart` (trace-component identification)
**Depends on:** MIX (forward KM, `Recipe`, `deltaE00`) · **Blocks:** SCREEN behavior, RECIPES-4 (a recipe to speak), SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 (SOLVER-1) | shell | — | ⬜ Todo | | |
| 2 (SOLVER-2) | behavior | AC-3, AC-4, AC-6 | ⬜ Todo | | |
| 3 (SOLVER-3) | behavior | AC-9 | ⬜ Todo | | |
| 4 (SOLVER-4) | behavior | AC-8 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `SpectralEngine.inverse(ColorCoordinates target, List<Paint> palette, MixOptions opts)` →
  `List<Recipe>` sorted top-K; `isMuddying(Recipe)` (muddying.dart); `nearestWhenOutOfGamut(...)` /
  `outOfGamut` on the result (gamut.dart); `traceComponents(Recipe)` (trace.dart, threshold 2%, D-7).
- **Consumes:** MIX forward (to score each candidate's predicted colour), `deltaE00`, `Paint`/`Recipe`.
- **Reconciliation:** the inverse body lives on `SpectralEngine` (one `MixingEngine`), so SOLVER edits the
  class MIX created; SOLVER's own files (`gamut`/`muddying`/`trace`) keep SOLVER-3/4 file-disjoint from each
  other and from SCREEN/RECIPES.

## Open gates

None of its own. SOLVER-2 inherits MIX-2's forward (which needs G-3/G-4), so it cannot start until MIX-2 is
done.

## Phase 1 (SOLVER-1) — Inverse skeleton + stubs

- **Kind:** shell
- **Target AC:** —
- **Depends on:** MIX-1 (types/interface) · **Blocks:** SOLVER-2 (and ITEST-1 wiring)
- **Files:** `lib/recipes/solver.dart`, `lib/recipes/gamut.dart`, `lib/recipes/muddying.dart`,
  `lib/recipes/trace.dart`
- **Tasks:**
  1. Scaffold the subset-enumeration structure (iterate palette subsets of size 1..`maxPaints`), with the
     per-subset optimizer, ranking, gamut check, muddying check and trace identification as **stubs**
     (`inverse` returns `[]`).
  2. Unit-test the stubs (shape only) to 100% coverage on touched files.
- **Exit criteria:** `flutter analyze` clean; unit green; behavior unchanged (`inverse` still returns `[]`);
  integration suite unchanged.
- **Acceptance gate:** *(n/a — shell)*

## Phase 2 (SOLVER-2) — Inverse search, top-K, prefer fewer paints (AC-3, AC-4, AC-6)

- **Kind:** behavior
- **Target AC:** AC-3 (full), AC-4 (full), AC-6 (full)
- **Depends on:** MIX-2 (real forward + deltaE00), RECIPES-3 (target set) · **Blocks:** SOLVER-3, SOLVER-4, SCREEN-2, RECIPES-4
- **Files:** `lib/recipes/solver.dart`
- **Tasks:**
  1. Implement the per-subset bounded volume optimizer (`v≥0`, `Σv=1`) minimizing ΔE00 to the target
     (warm-start from a K/S-space NNLS fit); enumerate subsets by size so **palette-only** is structural
     (AC-3) and fewer paints come first.
  2. Return the **top 3–5** deduped recipes, each with parts + the forward-predicted colour (AC-4).
  3. Rank by ΔE00, tie-break fewer paints within a small tolerance (AC-6; optional chroma penalty, D-8).
     Record the tolerance in the Result.
  4. Finalize the `TestAC04`/`TestAC06`/`TestAC07` fixtures now that the solver produces real recipes, and
     close their augmentation rows.
- **Exit criteria:** `inverse` returns in well under the ~1–2s NFR over the fixture palette; deterministic.
- **Acceptance gate:** un-pend AC-3, AC-4, AC-6; suite green with their tests passing; later ACs pending.
- **Augments:** close `TestAC04` (list length ∈ [3,5]; each recipe has parts + predicted colour),
  `TestAC06` (2-paint index < 4-paint index at similar ΔE), `TestAC07` (finalize the trace fixture a real
  solved recipe produces — SCREEN-2 asserts the rendering).

## Phase 3 (SOLVER-3) — Out-of-gamut + nearest (AC-9)

- **Kind:** behavior
- **Target AC:** AC-9 (full)
- **Depends on:** SOLVER-2 · **Blocks:** SIGNOFF-1 · ∥ SOLVER-4, SCREEN-2, RECIPES-4, MIX-3 (file-disjoint)
- **Files:** `lib/recipes/gamut.dart` (+ a small hook in `solver.dart`)
- **Tasks:**
  1. When the best achievable ΔE00 exceeds the gamut threshold, mark the result `outOfGamut` and offer the
     nearest mix labelled **as nearest, not a match** (D-11). Record the threshold in the Result.
- **Exit criteria:** an in-gamut target is never flagged; `TARGET_VIVID_TURQUOISE` is.
- **Acceptance gate:** un-pend AC-9; suite green with `TestAC09_OutOfGamut` passing.

## Phase 4 (SOLVER-4) — Muddying detector (AC-8)

- **Kind:** behavior
- **Target AC:** AC-8 (full)
- **Depends on:** SOLVER-2 · **Blocks:** SIGNOFF-1 · ∥ SOLVER-3, SCREEN-2, RECIPES-4, MIX-3 (file-disjoint)
- **Files:** `lib/recipes/muddying.dart` (+ a small hook in `solver.dart`)
- **Tasks:**
  1. Flag a recipe `muddying` when its paints cross a complementary hue pair (families ≈180° apart, D-6),
     from the paints' hue angles. Record the band around 180° in the Result.
- **Exit criteria:** a same-family recipe is not flagged (control); a yellow↔blue crossing is.
- **Acceptance gate:** un-pend AC-8; suite green with `TestAC08_MuddyingFlag` passing; close its augmentation.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
