# Module FLOW — Compare + Recipes screen swaps

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/compare/**`, `lib/recipes/**` (screen/region/control widgets only — not controllers, sources, read endpoints or `recipes/engine/**`).
**Depends on:** ITEST (G-2) · **Blocks:** GUARD

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| FLOW-1 | behavior | AC-6 | ⬜ Todo | | |
| FLOW-2 | behavior | AC-7 | ⬜ Todo | | |

## Interface reconciliation

Consumes the bs-17 wrappers. Changes only the Compare/Recipes control and region widgets; comparison and
recipe controllers, the difference/statement/confusion logic, `recipes/engine/**` and the read endpoints are
frozen (D-2). Ranked-by / out-of-gamut copy is unchanged — only its text style moves to the design system.

## Open gates

G-2 blocks both phases. FLOW-1 and FLOW-2 touch disjoint dirs (`lib/compare` vs `lib/recipes`) and may run in
either order or in parallel once G-2 is open.

## Phase FLOW-1 — behavior: Compare (AC-6)

- **Kind:** behavior
- **Target AC:** AC-6 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** GUARD-1
- **Files:** `lib/compare/actions_bar.dart`, `slots_region.dart`, `difference_region.dart`, `statement_region.dart`, `confusion_region.dart`, `comparison_screen.dart`.
- **Tasks:**
  1. "Compare as A"/"Compare as B" → `PillButton.secondary`; "Find mixing recipes" → `PillButton.primary`; the speak action → `SpeakButton`.
  2. Wrap the difference and statement regions in `SurfaceCard`; remove the superseded `OutlinedButton`/`TextButton`/`Card`.
- **Exit criteria:** `lib/compare` suite + bs-03 relative-comparison suite green.
- **Acceptance gate:** un-pend AC-6; `TestAC06_Compare` green with earlier ACs; sibling suites green.

## Phase FLOW-2 — behavior: Recipes (AC-7)

- **Kind:** behavior
- **Target AC:** AC-7 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** GUARD-1
- **Files:** `lib/recipes/recipe_list_region.dart`, `target_region.dart`, `controls_region.dart`, `gamut_banner.dart`, `recipes_screen.dart`.
- **Tasks:**
  1. Render each recipe row in a `SurfaceCard`; the ranked-by note and out-of-gamut banner in the design-system mono/body styles; recipe actions as `PillButton`.
  2. Remove the ad-hoc `Card`/`ListTile`/buttons these superseded.
- **Exit criteria:** `lib/recipes` suite + bs-04 mixing-recipes + bs-05 correction-loop suites green.
- **Acceptance gate:** un-pend AC-7; `TestAC07_Recipes` green with earlier ACs; sibling suites green.
